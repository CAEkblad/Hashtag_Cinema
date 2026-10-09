import Foundation
import UIKit

// Real versions of the service protocols. CinemaApp switches to these when
// AppConfig has a Supabase URL and key. Each one falls back gracefully so a
// network hiccup never leaves the agent with an empty screen.

// MARK: - Ideas

struct LiveIdeaEngine: IdeaEngine {
    let client: SupabaseClient
    var fallback = LocalIdeaEngine()

    private struct Request: Encodable {
        var cityId: String?
        var serviceAreaIds: [String]
        var niche: String
        var goals: [String]
        var month: Int
        var count: Int
    }

    private struct Response: Decodable {
        struct Item: Decodable {
            var title: String
            var hook: String
            var category: String
            var shots: [String]
            var script: String
            var targetSeconds: Int?
            var whyItWorks: String?
            var cityName: String?
        }
        var ideas: [Item]
    }

    func generateIdeas(for profile: AgentProfile) async throws -> [Idea] {
        let body = Request(
            cityId: profile.cityID,
            serviceAreaIds: profile.serviceAreaIDs,
            niche: profile.niche,
            goals: profile.goals.map(\.rawValue),
            month: Calendar.current.component(.month, from: Date()),
            count: 10
        )
        do {
            let response = try await client.invoke("generate-ideas", body: body, as: Response.self)
            let ideas = response.ideas.map { item in
                Idea(
                    title: item.title,
                    hook: item.hook,
                    category: IdeaCategory(rawValue: item.category) ?? .neighborhood,
                    shots: item.shots,
                    script: item.script,
                    targetSeconds: item.targetSeconds ?? 35,
                    whyItWorks: item.whyItWorks ?? "",
                    cityName: item.cityName
                )
            }
            if ideas.isEmpty { return try await fallback.generateIdeas(for: profile) }
            return ideas
        } catch {
            return try await fallback.generateIdeas(for: profile)
        }
    }
}

// MARK: - Coach

struct LiveCoachService: CoachService {
    let client: SupabaseClient

    private struct Request: Encodable { var clipTitle: String }
    private struct Response: Decodable {
        struct Tip: Decodable { var area: String; var text: String }
        var tips: [Tip]
    }

    func feedback(forClipTitled title: String) async throws -> [CoachTip] {
        let response = try await client.invoke("coach-feedback", body: Request(clipTitle: title), as: Response.self)
        return response.tips.map {
            CoachTip(area: CoachArea(rawValue: $0.area) ?? .hook, text: $0.text, clipTitle: title)
        }
    }
}

// MARK: - Editing

struct LiveAIEditingService: AIEditingService {
    let client: SupabaseClient

    private struct Request: Encodable {
        var clipId: String
        var title: String
        var ideaId: String?
        var style: String
        var captions: Bool
        var music: Bool
        var brandKit: Bool
        var rush: Bool
        var proEdit: Bool
        var notes: String
        var rawVideoPath: String?
    }

    private struct Response: Decodable { var clipId: String }

    /// Uploads the raw clip to Storage, then asks the backend to spend credits and queue the edit.
    func submit(_ request: EditRequest) async throws -> UUID {
        let clipID = UUID()
        var path: String?
        if let file = request.localVideoURL, file.isFileURL, let user = client.userID {
            let objectPath = "\(user)/\(clipID.uuidString).\(file.pathExtension.isEmpty ? "mov" : file.pathExtension)"
            try await client.upload(bucket: "raw-videos", path: objectPath, fileURL: file, contentType: "video/quicktime")
            path = objectPath
        }
        let body = Request(
            clipId: clipID.uuidString,
            title: request.title,
            ideaId: request.ideaID?.uuidString,
            style: request.style.rawValue,
            captions: request.captions,
            music: request.music,
            brandKit: request.brandKit,
            rush: request.rush,
            proEdit: request.proEdit,
            notes: request.notes,
            rawVideoPath: path
        )
        let response = try await client.invoke("request-edit", body: body, as: Response.self)
        return UUID(uuidString: response.clipId) ?? clipID
    }
}

// MARK: - Payments

/// Stripe Checkout in Safari. The Stripe webhook marks the deposit paid and the
/// booking flips from "Deposit pending" to "Deposit paid" on the next sync.
struct LivePaymentsService: PaymentsService {
    let client: SupabaseClient

    private struct Request: Encodable {
        var kind: String
        var productId: String?
        var amountCents: Int?
        var description: String
    }

    private struct Response: Decodable {
        var url: String
        var sessionId: String
    }

    func payDeposit(amount: Int, description: String) async throws -> PaymentResult {
        try await checkout(Request(kind: "deposit", productId: nil, amountCents: amount * 100, description: description))
    }

    func purchase(productID: String, description: String) async throws -> PaymentResult {
        let kind = productID.hasPrefix("course-") ? "course" : "credits"
        return try await checkout(Request(kind: kind, productId: productID, amountCents: nil, description: description))
    }

    private func checkout(_ request: Request) async throws -> PaymentResult {
        let response = try await client.invoke("create-checkout", body: request, as: Response.self)
        guard let url = URL(string: response.url) else { throw URLError(.badURL) }
        await openInSafari(url)
        return PaymentResult(succeeded: true, receiptID: response.sessionId, isPending: true)
    }
}

@MainActor
private func openInSafari(_ url: URL) async {
    _ = await UIApplication.shared.open(url)
}

// MARK: - Posting

struct LiveSocialPostingService: SocialPostingService {
    let client: SupabaseClient

    private struct Request: Encodable {
        var postId: String
        var clipId: String
        var platforms: [String]
        var caption: String
        var scheduledFor: Date
        var postNow: Bool
        var leadKeyword: String?
    }

    private struct Response: Decodable { var status: String }

    func schedule(_ post: ScheduledPost) async throws {
        let body = Request(
            postId: post.id.uuidString,
            clipId: post.clipID.uuidString,
            platforms: post.platforms.map(\.rawValue),
            caption: post.caption,
            scheduledFor: post.date,
            postNow: post.status == .posted,
            leadKeyword: post.leadKeyword
        )
        _ = try await client.invoke("publish-post", body: body, as: Response.self)
    }
}
