import Foundation

// MARK: - Plan my week

/// One video on the weekly plan.
struct PlannedVideo: Identifiable, Hashable {
    var id = UUID()
    var day: Date
    var idea: Idea
    var isDone = false
}

// MARK: - Achievements

struct Achievement: Identifiable, Hashable {
    var id: String
    var title: String
    var detail: String
    var icon: String
    var progress: Int
    var goal: Int
    var points: Int

    var isUnlocked: Bool { progress >= goal }
    var fraction: Double { goal == 0 ? 1 : min(1, Double(progress) / Double(goal)) }
}

/// Creator levels from points earned filming, posting, learning and checking in.
enum CreatorLevel: Int, CaseIterable {
    case rookie, risingStar, localCelebrity, marketIcon

    static func forPoints(_ points: Int) -> CreatorLevel {
        allCases.last { points >= $0.minPoints } ?? .rookie
    }

    var title: String {
        switch self {
        case .rookie: return "Rookie Creator"
        case .risingStar: return "Rising Star"
        case .localCelebrity: return "Local Celebrity"
        case .marketIcon: return "Market Icon"
        }
    }

    var minPoints: Int {
        switch self {
        case .rookie: return 0
        case .risingStar: return 500
        case .localCelebrity: return 1_500
        case .marketIcon: return 4_000
        }
    }

    var icon: String {
        switch self {
        case .rookie: return "sparkle"
        case .risingStar: return "star.fill"
        case .localCelebrity: return "flame.fill"
        case .marketIcon: return "crown.fill"
        }
    }

    var next: CreatorLevel? { CreatorLevel(rawValue: rawValue + 1) }
}

// MARK: - Lead follow up

enum FollowUpTemplate: String, CaseIterable, Identifiable {
    case firstReply, openHouseThanks, checkIn, booked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstReply: return "First reply"
        case .openHouseThanks: return "Thanks for visiting"
        case .checkIn: return "Friendly check in"
        case .booked: return "Showing confirmed"
        }
    }

    func message(lead: Lead, agentFirstName: String, cityName: String) -> String {
        let first = lead.name.split(separator: " ").first.map(String.init) ?? lead.name
        switch self {
        case .firstReply:
            return "Hi \(first)! It's \(agentFirstName). Thanks for commenting \(lead.keyword) on my video. I'd love to send you the details. Are you looking to buy in \(cityName) soon, or just keeping an eye on the market?"
        case .openHouseThanks:
            return "Hi \(first), it's \(agentFirstName). Thanks for stopping by the open house at \(lead.openHouseAddress ?? "the home") today! What did you think? I can send you similar homes or set up a private tour."
        case .checkIn:
            return "Hi \(first), \(agentFirstName) here. Just checking in. Anything I can help with in your home search? New listings in \(cityName) are moving fast this week."
        case .booked:
            return "Hi \(first)! You're all set for the showing. I'll meet you there and bring the disclosures. Text me if anything changes. See you soon! \(agentFirstName)"
        }
    }
}
