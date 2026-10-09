import Foundation

/// An agent in the #Cinema network who takes referrals in their city.
struct NetworkAgent: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var brokerage: String
    var cityID: String
    var specialties: [String]
    var closedReferrals: Int
    var rating: Double
    var languages: [String] = ["English"]

    var city: FloridaCity? { FloridaMarkets.city(cityID) }
    var initials: String { String(name.split(separator: " ").prefix(2).compactMap { $0.first }).uppercased() }
}

/// A client passed between agents, with the referral fee agreed up front.
struct AgentReferral: Identifiable, Hashable {
    enum Side: String, CaseIterable, Identifiable {
        case buyer, seller
        var id: String { rawValue }
        var title: String { self == .buyer ? "Buyer" : "Seller" }
    }

    enum Status: String, CaseIterable {
        case sent, accepted, underContract, closed

        var title: String {
            switch self {
            case .sent: return "Waiting to accept"
            case .accepted: return "Accepted"
            case .underContract: return "Under contract"
            case .closed: return "Closed, fee paid"
            }
        }
    }

    var id = UUID()
    var clientName: String
    var side: Side
    var cityID: String
    var priceRange: String
    var notes: String
    var otherAgentName: String
    var feePercent: Int
    var status: Status
    var isIncoming: Bool
    var date: Date

    var city: FloridaCity? { FloridaMarkets.city(cityID) }
}

enum NetworkDirectory {
    private static let firstNames = ["Ana", "Brian", "Carla", "Devon", "Elena", "Frank", "Gabriela", "Hector", "Isabel", "Jason", "Keisha", "Luis", "Monica", "Nate", "Olivia", "Pablo", "Quinn", "Rosa", "Steve", "Tanya"]
    private static let lastNames = ["Alvarez", "Bennett", "Castillo", "Dawson", "Ellis", "Fuentes", "Grant", "Hughes", "Ibarra", "Jensen", "Kim", "Lopez", "Mendez", "Nolan", "Ortiz", "Price", "Ramos", "Shaw", "Torres", "Vega"]
    private static let specialtyPool = ["Waterfront", "Luxury", "First time buyers", "Relocation", "Condos", "New construction", "55+ communities", "Investors", "Military and VA", "Golf communities"]

    /// Sample network: two agents in each of the 40 biggest Florida markets.
    static func sample() -> [NetworkAgent] {
        var rng = SeededGenerator(seed: 20_261_009)
        var agents: [NetworkAgent] = []
        for city in FloridaMarkets.all.prefix(40) {
            for _ in 0..<2 {
                let first = firstNames.randomElement(using: &rng) ?? "Alex"
                let last = lastNames.randomElement(using: &rng) ?? "Smith"
                var specialties = Array(specialtyPool.shuffled(using: &rng).prefix(2))
                if city.has(.military) && !specialties.contains("Military and VA") { specialties[0] = "Military and VA" }
                agents.append(NetworkAgent(
                    name: "\(first) \(last)",
                    brokerage: "\(city.name) Realty Group",
                    cityID: city.id,
                    specialties: specialties,
                    closedReferrals: Int.random(in: 1...28, using: &rng),
                    rating: Double(Int.random(in: 44...50, using: &rng)) / 10,
                    languages: Bool.random(using: &rng) ? ["English", "Spanish"] : ["English"]
                ))
            }
        }
        return agents
    }
}
