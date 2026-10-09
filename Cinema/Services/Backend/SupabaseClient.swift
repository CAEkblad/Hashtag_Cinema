import Foundation
import Security

/// Small Supabase client built on URLSession, so the app needs no packages.
/// Covers what the app uses: email code sign in, table reads and writes,
/// Edge Functions and Storage uploads.
final class SupabaseClient: @unchecked Sendable {
    /// Nil until AppConfig has a real project URL and anon key.
    static let shared: SupabaseClient? = {
        guard AppConfig.isBackendConfigured, let url = AppConfig.supabaseURL else { return nil }
        return SupabaseClient(url: url, anonKey: AppConfig.supabaseAnonKey)
    }()

    struct AuthSession: Codable {
        var accessToken: String
        var refreshToken: String
        var expiresAt: Date
        var userID: String
        var email: String?
    }

    struct APIError: LocalizedError {
        var status: Int
        var message: String
        var errorDescription: String? { message }
    }

    let url: URL
    let anonKey: String
    private(set) var session: AuthSession?
    private let http: URLSession
    private let lock = NSLock()

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            let precise = ISO8601DateFormatter()
            precise.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = precise.date(from: text) ?? ISO8601DateFormatter().date(from: text) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Bad date \(text)")
        }
        return decoder
    }()

    init(url: URL, anonKey: String, http: URLSession = .shared) {
        self.url = url
        self.anonKey = anonKey
        self.http = http
        self.session = Keychain.read(AuthSession.self, key: "supabase.session")
    }

    var isSignedIn: Bool { session != nil }
    var userID: String? { session?.userID }

    // MARK: Auth (email one-time code)

    /// Emails a 6 digit code. New emails get an account automatically.
    func sendCode(email: String) async throws {
        struct Body: Encodable { var email: String; var createUser: Bool }
        _ = try await send("auth/v1/otp", method: "POST", body: Body(email: email, createUser: true), authorized: false)
    }

    func verify(email: String, code: String) async throws {
        struct Body: Encodable { var type: String; var email: String; var token: String }
        let data = try await send("auth/v1/verify", method: "POST", body: Body(type: "email", email: email, token: code), authorized: false)
        try store(tokenResponse: data)
    }

    func signOut() {
        lock.lock()
        session = nil
        lock.unlock()
        Keychain.delete(key: "supabase.session")
    }

    private struct TokenResponse: Decodable {
        struct User: Decodable { var id: String; var email: String? }
        var accessToken: String
        var refreshToken: String
        var expiresIn: Double
        var user: User
    }

    private func store(tokenResponse data: Data) throws {
        let token = try Self.decoder.decode(TokenResponse.self, from: data)
        let fresh = AuthSession(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            expiresAt: Date().addingTimeInterval(token.expiresIn),
            userID: token.user.id,
            email: token.user.email
        )
        lock.lock()
        session = fresh
        lock.unlock()
        Keychain.write(fresh, key: "supabase.session")
    }

    private func refreshIfNeeded() async throws {
        guard let current = session, current.expiresAt.timeIntervalSinceNow < 60 else { return }
        struct Body: Encodable { var refreshToken: String }
        let data = try await send("auth/v1/token?grant_type=refresh_token", method: "POST", body: Body(refreshToken: current.refreshToken), authorized: false)
        try store(tokenResponse: data)
    }

    // MARK: Database (PostgREST)

    func select<Row: Decodable>(_ table: String, query: [URLQueryItem] = [], as type: Row.Type = Row.self) async throws -> [Row] {
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "select", value: "*")] + query
        let suffix = components.percentEncodedQuery.map { "?\($0)" } ?? ""
        let data = try await send("rest/v1/\(table)\(suffix)", method: "GET", body: Optional<String>.none)
        return try Self.decoder.decode([Row].self, from: data)
    }

    func insert<Row: Encodable>(_ table: String, _ row: Row) async throws {
        _ = try await send("rest/v1/\(table)", method: "POST", body: row, headers: ["Prefer": "return=minimal"])
    }

    func update<Patch: Encodable>(_ table: String, id: String, _ patch: Patch) async throws {
        _ = try await send("rest/v1/\(table)?id=eq.\(id)", method: "PATCH", body: patch, headers: ["Prefer": "return=minimal"])
    }

    // MARK: Edge Functions

    func invoke<Response: Decodable>(_ function: String, body: some Encodable, as type: Response.Type = Response.self) async throws -> Response {
        let data = try await send("functions/v1/\(function)", method: "POST", body: body)
        return try Self.decoder.decode(Response.self, from: data)
    }

    // MARK: Storage

    /// Uploads a local file to `bucket/path`. Raw clips go to `raw-videos/<user id>/<clip id>.mov`.
    func upload(bucket: String, path: String, fileURL: URL, contentType: String) async throws {
        try await refreshIfNeeded()
        var request = URLRequest(url: url.appendingPathComponent("storage/v1/object/\(bucket)/\(path)"))
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        authorize(&request, authorized: true)
        let (data, response) = try await http.upload(for: request, fromFile: fileURL)
        try check(response, data)
    }

    // MARK: Plumbing

    private func authorize(_ request: inout URLRequest, authorized: Bool) {
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        let bearer = authorized ? (session?.accessToken ?? anonKey) : anonKey
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
    }

    @discardableResult
    private func send<Body: Encodable>(_ path: String, method: String, body: Body?, authorized: Bool = true, headers: [String: String] = [:]) async throws -> Data {
        if authorized { try await refreshIfNeeded() }
        guard let target = URL(string: path, relativeTo: url) else { throw URLError(.badURL) }
        var request = URLRequest(url: target)
        request.httpMethod = method
        request.timeoutInterval = 60
        authorize(&request, authorized: authorized)
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try Self.encoder.encode(body)
        }
        let (data, response) = try await http.data(for: request)
        try check(response, data)
        return data
    }

    private func check(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]).flatMap {
                ($0["msg"] ?? $0["message"] ?? $0["error_description"] ?? $0["error"]) as? String
            } ?? "Request failed (\(http.statusCode))"
            throw APIError(status: http.statusCode, message: message)
        }
    }
}

/// Keeps the sign in session in the iOS Keychain.
enum Keychain {
    static func write<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        delete(key: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read<T: Decodable>(_ type: T.Type, key: String) -> T? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
