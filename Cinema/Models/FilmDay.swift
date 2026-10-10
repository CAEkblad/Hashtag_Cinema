import Foundation

/// A batch filming session: several ideas filmed back to back, grouped by where
/// you film them, with outfit changes so the week's posts look like different days.
struct FilmDaySession: Codable, Equatable {
    /// A copy of each idea, so the session survives the idea feed refreshing.
    var ideas: [Idea]
    var filmed: [UUID] = []
    var skipped: [UUID] = []
    var startedAt = Date()

    var ideaIDs: [UUID] { ideas.map(\.id) }

    func isDone(_ id: UUID) -> Bool { filmed.contains(id) || skipped.contains(id) }
    var remaining: [UUID] { ideaIDs.filter { !isDone($0) } }
    var isComplete: Bool { remaining.isEmpty }
    var progress: Double { ideaIDs.isEmpty ? 0 : Double(ideaIDs.count - remaining.count) / Double(ideaIDs.count) }
}

/// Where an idea gets filmed. Ideas in the same spot are filmed together.
enum FilmSpot: Int, CaseIterable, Identifiable, Comparable {
    case desk, listing, neighborhood, onTheGo

    var id: Int { rawValue }

    static func < (a: FilmSpot, b: FilmSpot) -> Bool { a.rawValue < b.rawValue }

    init(_ category: IdeaCategory) {
        switch category {
        case .marketUpdate, .mythBuster, .clientStory: self = .desk
        case .listingTour, .openHouse: self = .listing
        case .neighborhood: self = .neighborhood
        case .dayInLife: self = .onTheGo
        }
    }

    var title: String {
        switch self {
        case .desk: return "At your desk or a clean wall"
        case .listing: return "At a listing"
        case .neighborhood: return "Out in the neighborhood"
        case .onTheGo: return "On the go"
        }
    }

    var icon: String {
        switch self {
        case .desk: return "person.crop.rectangle.fill"
        case .listing: return "house.fill"
        case .neighborhood: return "map.fill"
        case .onTheGo: return "car.fill"
        }
    }

    var tip: String {
        switch self {
        case .desk: return "Face a window so the light is on your face. Phone at eye level, about an arm and a half away."
        case .listing: return "Turn on every light and open the blinds. Film the room's best angle first, then the details."
        case .neighborhood: return "Film with the sun behind the camera, not behind you. Find a spot that says where you are."
        case .onTheGo: return "Parked cars only. Short clips are fine; you'll stitch them together in the edit."
        }
    }
}

enum FilmDayPlanner {
    /// Ideas in filming order: grouped by spot so you only move once per group.
    static func ordered(_ ideas: [Idea]) -> [Idea] {
        ideas.enumerated()
            .sorted { a, b in
                let sa = FilmSpot(a.element.category), sb = FilmSpot(b.element.category)
                return sa == sb ? a.offset < b.offset : sa < sb
            }
            .map(\.element)
    }

    /// About 4 takes per video plus a few minutes to reset, plus 10 minutes to set up.
    static func minutes(for ideas: [Idea]) -> Int {
        let filming = ideas.reduce(0) { $0 + max(3, Int((Double($1.targetSeconds) * 4 / 60).rounded(.up)) + 3) }
        let moves = Set(ideas.map { FilmSpot($0.category) }).count
        return 10 + filming + max(0, moves - 1) * 10
    }

    /// Change your top every 2 videos so a week of posts doesn't look like one afternoon.
    static func outfitChange(before index: Int) -> Bool { index > 0 && index % 2 == 0 }

    static let prep: [String] = [
        "Charge your phone and clear some storage",
        "Clean the camera lens",
        "Turn on Do Not Disturb",
        "Lay out 2 or 3 tops in different colors",
        "Clip on a mic or film somewhere quiet",
        "Water nearby, and read each script out loud once"
    ]
}
