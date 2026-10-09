import Foundation

// The app talks to every outside system through these protocols.
// Each has a Mock version so the app runs today. Swap in the real
// version (Supabase, Stripe, posting API, AI) one at a time.

// MARK: - Configuration

enum AppConfig {
    /// Fill these in when the Supabase project exists (Project Settings > API).
    static let supabaseURL = URL(string: "https://YOUR-PROJECT.supabase.co")
    static let supabaseAnonKey = "YOUR-ANON-KEY"

    /// Turn on once the real services are wired up.
    static let useMockServices = true
}

// MARK: - Requests

struct EditRequest: Codable, Hashable {
    var title: String
    var ideaID: UUID?
    var style: EditStyle
    var captions: Bool
    var music: Bool
    var brandKit: Bool
    var rush: Bool
    var proEdit: Bool
    var notes: String
    var localVideoURL: URL?

    /// Instant edit (AI only) costs 1 credit, Pro edit (AI plus editor) 2, rush adds 1.
    var creditCost: Int {
        (proEdit ? 2 : 1) + (rush ? 1 : 0)
    }
}

struct PaymentResult: Hashable {
    var succeeded: Bool
    var receiptID: String
}

// MARK: - Protocols

protocol IdeaEngine {
    /// Backend calls a language model (Claude or Llama) with the agent's market,
    /// niche, listings and what is working in the community.
    func generateIdeas(for profile: AgentProfile) async throws -> [Idea]
}

protocol AIEditingService {
    /// Uploads the clip, then the backend runs transcribe, AI edit plan, render,
    /// and routes to an editor when needed. Progress comes back by realtime updates.
    func submit(_ request: EditRequest) async throws -> UUID
}

protocol PaymentsService {
    /// $500 shoot deposits and credit packs run through Stripe.
    func payDeposit(amount: Int, description: String) async throws -> PaymentResult
    /// Courses and credit packs. Digital goods: web checkout link in the US, Apple in-app purchase as the fallback.
    func purchase(productID: String, description: String) async throws -> PaymentResult
}

protocol SocialPostingService {
    /// Unified posting API (for example Ayrshare) for the MVP.
    func schedule(_ post: ScheduledPost) async throws
}

protocol CoachService {
    /// AI coach reviews the raw clip and returns specific tips.
    func feedback(forClipTitled title: String) async throws -> [CoachTip]
}

// MARK: - Mocks

struct MockIdeaEngine: IdeaEngine {
    func generateIdeas(for profile: AgentProfile) async throws -> [Idea] {
        try await Task.sleep(nanoseconds: 900_000_000)
        let fresh = Idea(
            title: "Why \(profile.market) buyers are waiting",
            hook: "Everyone in \(profile.market) is asking me the same question.",
            category: .marketUpdate,
            shots: ["Direct to camera, tight framing", "Screen with one key number", "Close with a comment keyword"],
            script: "Everyone in \(profile.market) is asking me the same question: should I wait? Here is what the numbers say this month, and what I would do if I were buying today. Comment WAIT and I will send you my full breakdown.",
            targetSeconds: 35,
            whyItWorks: "Answering the question your market is already asking feels personal and timely."
        )
        return [fresh] + MockData.ideas.shuffled()
    }
}

struct MockAIEditingService: AIEditingService {
    func submit(_ request: EditRequest) async throws -> UUID {
        try await Task.sleep(nanoseconds: 600_000_000)
        return UUID()
    }
}

struct MockPaymentsService: PaymentsService {
    func payDeposit(amount: Int, description: String) async throws -> PaymentResult {
        try await Task.sleep(nanoseconds: 1_200_000_000)
        return PaymentResult(succeeded: true, receiptID: "pi_mock_\(Int.random(in: 10_000...99_999))")
    }

    func purchase(productID: String, description: String) async throws -> PaymentResult {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return PaymentResult(succeeded: true, receiptID: "pi_mock_\(productID.prefix(12))")
    }
}

struct MockSocialPostingService: SocialPostingService {
    func schedule(_ post: ScheduledPost) async throws {
        try await Task.sleep(nanoseconds: 700_000_000)
    }
}

struct MockCoachService: CoachService {
    func feedback(forClipTitled title: String) async throws -> [CoachTip] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            CoachTip(area: .hook, text: "Strong open. You got to the point in under 2 seconds.", clipTitle: title),
            CoachTip(area: .framing, text: "Raise the phone to eye level so you are not looking down at viewers.", clipTitle: title),
            CoachTip(area: .energy, text: "Smile on the last line. Endings with energy get more follows.", clipTitle: title)
        ]
    }
}
