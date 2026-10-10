import Foundation
import ImageIO
import UIKit

/// A listing as it comes back from an MLS feed.
struct MLSListing: Identifiable, Hashable {
    var id: String { mlsNumber }
    var mlsNumber: String
    var address: String
    var city: String
    var state: String
    var postalCode: String
    var price: Int
    var beds: Int
    var baths: Double
    var squareFeet: Int?
    var yearBuilt: Int?
    var status: String
    var daysOnMarket: Int?
    var remarks: String
    var photoURLs: [URL]
    var agentName: String
    var officeName: String
    var hasPool: Bool

    var place: String { [city, state].filter { !$0.isEmpty }.joined(separator: ", ") }
    var priceLabel: String { price.formatted(.currency(code: "USD").precision(.fractionLength(0))) }
    var specs: String {
        var parts = ["\(beds) bd", "\(baths.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(baths))" : String(format: "%.1f", baths)) ba"]
        if let squareFeet, squareFeet > 0 { parts.append("\(squareFeet.formatted()) sq ft") }
        return parts.joined(separator: " · ")
    }
}

/// Pulls listings and their photos from the MLS.
///
/// Today it reads the SimplyRETS public test feed (sample listings with real
/// photos) so the import can be tried end to end. For real Tampa Bay listings,
/// Stellar MLS shares data through MLS Grid or Bridge under a broker, vendor and
/// MLS agreement. That feed will sit behind the CloseUp backend (an `mls-listing`
/// Edge Function), so the app never holds MLS credentials, and the app switches
/// over once `liveFeedURL` is set.
enum MLSService {
    enum Source {
        case testFeed
        case live(URL)
    }

    enum MLSError: LocalizedError {
        case notFound
        case network(String)
        var errorDescription: String? {
            switch self {
            case .notFound: return "No listing found with that MLS number."
            case .network(let text): return text
            }
        }
    }

    /// Set to the backend's MLS function once the Stellar feed is approved.
    static let liveFeedURL: URL? = nil

    static var source: Source { liveFeedURL.map { .live($0) } ?? .testFeed }
    static var isTestFeed: Bool { if case .testFeed = source { return true } else { return false } }

    // SimplyRETS publishes these demo credentials for its sample data.
    private static let testBase = URL(string: "https://api.simplyrets.com")!
    private static let testAuth = "Basic " + Data("simplyrets:simplyrets".utf8).base64EncodedString()

    /// Finds one listing by its MLS number.
    static func listing(mlsNumber raw: String) async throws -> MLSListing {
        let number = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !number.isEmpty else { throw MLSError.notFound }
        switch source {
        case .live(let url):
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "mls", value: number)]
            guard let request = components?.url else { throw MLSError.notFound }
            let items = try await fetch(URLRequest(url: request))
            guard let first = items.first else { throw MLSError.notFound }
            return first
        case .testFeed:
            // The listing number agents see, or the feed's own id.
            let matches = try await search(number, limit: 25)
            if let exact = matches.first(where: { $0.mlsNumber.caseInsensitiveCompare(number) == .orderedSame }) { return exact }
            if Int(number) != nil {
                var request = URLRequest(url: testBase.appendingPathComponent("properties/\(number)"))
                request.setValue(testAuth, forHTTPHeaderField: "Authorization")
                if let one = try? await fetch(request).first { return one }
            }
            throw MLSError.notFound
        }
    }

    /// Keyword search: address, city, ZIP or MLS number.
    static func search(_ query: String, limit: Int = 20) async throws -> [MLSListing] {
        switch source {
        case .live(let url):
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "limit", value: "\(limit)")]
            guard let request = components?.url else { return [] }
            return try await fetch(URLRequest(url: request))
        case .testFeed:
            var components = URLComponents(url: testBase.appendingPathComponent("properties"), resolvingAgainstBaseURL: false)
            var items = [URLQueryItem(name: "limit", value: "\(limit)")]
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { items.append(URLQueryItem(name: "q", value: trimmed)) }
            components?.queryItems = items
            guard let url = components?.url else { return [] }
            var request = URLRequest(url: url)
            request.setValue(testAuth, forHTTPHeaderField: "Authorization")
            return try await fetch(request)
        }
    }

    private static func fetch(_ request: URLRequest) async throws -> [MLSListing] {
        var request = request
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw MLSError.network("Couldn't reach the MLS. Check your connection and try again.")
        }
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 404 { throw MLSError.notFound }
            guard (200..<300).contains(http.statusCode) else { throw MLSError.network("The MLS returned an error (\(http.statusCode)).") }
        }
        let json = try? JSONSerialization.jsonObject(with: data)
        if let array = json as? [[String: Any]] { return array.compactMap(parse) }
        if let one = json as? [String: Any] {
            if let list = one["listings"] as? [[String: Any]] { return list.compactMap(parse) }
            return parse(one).map { [$0] } ?? []
        }
        return []
    }

    /// Reads a SimplyRETS style listing. Every field is optional so a feed that
    /// leaves something out still imports.
    static func parse(_ item: [String: Any]) -> MLSListing? {
        let address = item["address"] as? [String: Any] ?? [:]
        let property = item["property"] as? [String: Any] ?? [:]
        let mls = item["mls"] as? [String: Any] ?? [:]
        let agent = item["agent"] as? [String: Any] ?? [:]
        let office = item["office"] as? [String: Any] ?? [:]

        let number = string(item["listingId"]) ?? string(item["mlsId"]) ?? ""
        guard !number.isEmpty else { return nil }
        let street = string(address["full"]) ?? [string(address["streetNumber"]), string(address["streetName"])].compactMap { $0 }.joined(separator: " ")
        let photos = (item["photos"] as? [Any] ?? []).compactMap { string($0) }.compactMap { URL(string: $0) }.filter { $0.scheme == "https" || $0.scheme == "http" }
        let full = double(property["bathsFull"]) ?? 0
        let half = double(property["bathsHalf"]) ?? 0
        let baths = double(property["bathrooms"]) ?? (full + half * 0.5)
        let pool = string(property["pool"]) ?? ""

        return MLSListing(
            mlsNumber: number,
            address: street.isEmpty ? "Address not listed" : street,
            city: string(address["city"]) ?? "",
            state: string(address["state"]) ?? "",
            postalCode: string(address["postalCode"]) ?? "",
            price: Int(double(item["listPrice"]) ?? 0),
            beds: Int(double(property["bedrooms"]) ?? 0),
            baths: baths,
            squareFeet: double(property["area"]).map { Int($0) },
            yearBuilt: double(property["yearBuilt"]).map { Int($0) },
            status: string(mls["status"]) ?? "Active",
            daysOnMarket: double(mls["daysOnMarket"]).map { Int($0) },
            remarks: string(item["remarks"]) ?? "",
            photoURLs: photos,
            agentName: [string(agent["firstName"]), string(agent["lastName"])].compactMap { $0 }.joined(separator: " "),
            officeName: string(office["name"]) ?? "",
            hasPool: !pool.isEmpty && pool.lowercased() != "none" && pool.lowercased() != "no"
        )
    }

    private static func string(_ value: Any?) -> String? {
        switch value {
        case let text as String: return text.isEmpty ? nil : text
        case let number as NSNumber: return number.stringValue
        default: return nil
        }
    }

    private static func double(_ value: Any?) -> Double? {
        switch value {
        case let number as NSNumber: return number.doubleValue
        case let text as String: return Double(text.filter { $0.isNumber || $0 == "." })
        default: return nil
        }
    }

    /// Downloads photos in order, skipping any that fail.
    static func downloadPhotos(_ urls: [URL], progress: @escaping @MainActor (Double) -> Void) async -> [UIImage] {
        var images: [UIImage] = []
        for (index, url) in urls.enumerated() {
            if let (data, _) = try? await URLSession.shared.data(from: url), let image = UIImage(data: data) {
                images.append(image.downscaled(maxSide: 2048))
            }
            await progress(Double(index + 1) / Double(max(urls.count, 1)))
        }
        return images
    }
}

/// Listing photos saved on the phone, one folder per listing.
/// Writes are atomic (a new folder is swapped in) and encoding happens off the
/// main thread, so a 40 photo import never freezes the app or loses photos.
enum ListingPhotoStore {
    private static var root: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("ListingPhotos", isDirectory: true)
    }

    private static func folder(_ listingID: UUID) -> URL {
        root.appendingPathComponent(listingID.uuidString, isDirectory: true)
    }

    private static let covers = NSCache<NSString, UIImage>()
    private static let noCover = NSCache<NSString, NSNumber>()

    private static func forget(_ listingID: UUID) {
        covers.removeObject(forKey: listingID.uuidString as NSString)
        noCover.removeObject(forKey: listingID.uuidString as NSString)
    }

    static func files(_ listingID: UUID) -> [URL] {
        let dir = folder(listingID)
        let names = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        return names.filter { $0.hasSuffix(".jpg") }.sorted().map { dir.appendingPathComponent($0) }
    }

    static func count(_ listingID: UUID) -> Int { files(listingID).count }

    /// Full size photos for posters, reels and flyers.
    static func load(_ listingID: UUID, limit: Int = .max) -> [UIImage] {
        files(listingID).prefix(limit).compactMap { UIImage(contentsOfFile: $0.path) }
    }

    /// Small versions for grids, read straight from the JPEG without decoding the full photo.
    static func thumbnails(_ listingID: UUID, maxPixel: Int = 300) -> [UIImage] {
        files(listingID).compactMap { thumbnail(at: $0, maxPixel: maxPixel) }
    }

    static func thumbnail(at url: URL, maxPixel: Int) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: cg)
    }

    /// The first photo, small, cached in memory. Listings without photos are remembered too.
    static func cover(_ listingID: UUID) -> UIImage? {
        let key = listingID.uuidString as NSString
        if let cached = covers.object(forKey: key) { return cached }
        if noCover.object(forKey: key) != nil { return nil }
        guard let first = files(listingID).first, let small = thumbnail(at: first, maxPixel: 700) else {
            noCover.setObject(true, forKey: key)
            return nil
        }
        covers.setObject(small, forKey: key)
        return small
    }

    /// JPEG data for photos, scaled to 2048 px on the long side. Call off the main thread.
    static func encode(_ images: [UIImage]) -> [Data] {
        images.compactMap { $0.downscaled(maxSide: 2048).jpegData(compressionQuality: 0.85) }
    }

    /// Replaces every photo on the listing. The new set is written to a temporary
    /// folder first, so nothing is lost if the app closes halfway.
    static func replace(with photos: [Data], for listingID: UUID) {
        forget(listingID)
        let fm = FileManager.default
        try? fm.createDirectory(at: root, withIntermediateDirectories: true)
        let temp = root.appendingPathComponent("tmp-\(UUID().uuidString)", isDirectory: true)
        try? fm.createDirectory(at: temp, withIntermediateDirectories: true)
        for (index, data) in photos.enumerated() {
            try? data.write(to: temp.appendingPathComponent(String(format: "%03d.jpg", index)), options: .atomic)
        }
        let dir = folder(listingID)
        if fm.fileExists(atPath: dir.path) {
            _ = try? fm.replaceItemAt(dir, withItemAt: temp)
        } else {
            try? fm.moveItem(at: temp, to: dir)
        }
        try? fm.removeItem(at: temp)
    }

    /// Adds photos after the ones already saved, without touching them.
    static func append(_ photos: [Data], for listingID: UUID) {
        guard !photos.isEmpty else { return }
        forget(listingID)
        let dir = folder(listingID)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let next = (files(listingID).compactMap { Int($0.deletingPathExtension().lastPathComponent) }.max() ?? -1) + 1
        for (offset, data) in photos.enumerated() {
            try? data.write(to: dir.appendingPathComponent(String(format: "%03d.jpg", next + offset)), options: .atomic)
        }
    }

    static func delete(_ listingID: UUID) {
        forget(listingID)
        try? FileManager.default.removeItem(at: folder(listingID))
    }

    /// Removes photo folders for listings that no longer exist, and leftover temp folders.
    static func prune(keeping ids: Set<UUID>) {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: root.path)) ?? []
        for name in names where !(UUID(uuidString: name).map(ids.contains) ?? false) {
            try? FileManager.default.removeItem(at: root.appendingPathComponent(name))
        }
    }

    static func deleteAll() {
        covers.removeAllObjects()
        noCover.removeAllObjects()
        try? FileManager.default.removeItem(at: root)
    }
}
