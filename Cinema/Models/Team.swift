import Foundation

/// A real estate team: a leader, their agents, and one shared page everything flows into.
struct Team: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var leaderName: String
    var cityID: String
    var joinCode: String
    var tagline: String = "Local experts. Real results."
    var members: [TeamMember] = []
    var perks: [String] = Team.defaultPerks
    var leadRoutingOn = false
    var nextRouteIndex = 0
    var statsMonth: String?

    var city: FloridaCity? { FloridaMarkets.city(cityID) }
    var joinLink: String { "https://hashtagcinema.com/join?team=\(joinCode)" }

    static let defaultPerks = [
        "Leads from team marketing, shared fairly",
        "Pro listing shoots and weekly content from #Cinema",
        "Weekly coaching and accountability",
        "Done for you listing launches",
        "A team that celebrates your wins"
    ]
}

struct TeamMember: Identifiable, Codable, Equatable {
    enum Role: String, Codable, CaseIterable, Identifiable {
        case leader, agent, newAgent, isa, admin
        var id: String { rawValue }
        func title(_ lex: Lexicon) -> String {
            switch self {
            case .leader: return lex.isKW ? "Team Leader" : "Team lead"
            case .agent: return lex.isKW ? "Associate" : "Agent"
            case .newAgent: return "New agent"
            case .isa: return "Inside sales"
            case .admin: return "Operations"
            }
        }
    }

    var id = UUID()
    var name: String
    var role: Role = .agent
    var joinedAt: Date = Date()
    var videosThisMonth: Int = 0
    var leads: Int = 0
    var closings: Int = 0
    var isMe = false

    var initials: String { String(name.split(separator: " ").prefix(2).compactMap(\.first)).uppercased() }
}

/// Something a team member made or won, shown on the team page.
struct TeamFeedItem: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case video, poster, listing, sold, testimonial, milestone, join

        var icon: String {
            switch self {
            case .video: return "play.rectangle.fill"
            case .poster: return "rectangle.portrait.on.rectangle.portrait.fill"
            case .listing: return "house.fill"
            case .sold: return "key.fill"
            case .testimonial: return "heart.text.square.fill"
            case .milestone: return "trophy.fill"
            case .join: return "person.badge.plus"
            }
        }
    }

    var id = UUID()
    var authorName: String
    var kind: Kind
    var title: String
    var detail: String
    var date: Date
    var cheers: Int = 0
    var cheeredByMe = false
}
