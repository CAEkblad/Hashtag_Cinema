import Foundation

/// A day of showings for a buyer, in driving order.
struct ShowingTour: Identifiable, Hashable, Codable {
    var id = UUID()
    var buyerName: String
    var start: Date
    var minutesPerStop: Int = 30
    var stops: [TourStop] = []

    var firstName: String { buyerName.split(separator: " ").first.map(String.init) ?? buyerName }

    func time(for index: Int) -> Date {
        start.addingTimeInterval(TimeInterval(index * minutesPerStop * 60))
    }

    /// Opens every stop as one route. Works in Google Maps or any browser.
    var routeURL: URL? {
        guard !stops.isEmpty else { return nil }
        let parts = stops.map { $0.address.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))) ?? "" }
        return URL(string: "https://www.google.com/maps/dir/" + parts.joined(separator: "/"))
    }

    var label: String { start.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()) }
}

struct TourStop: Identifiable, Hashable, Codable {
    enum Reaction: String, CaseIterable, Codable {
        case love, maybe, no
        var title: String {
            switch self {
            case .love: return "Loved it"
            case .maybe: return "Maybe"
            case .no: return "Not for us"
            }
        }
        var icon: String {
            switch self {
            case .love: return "heart.fill"
            case .maybe: return "questionmark.circle.fill"
            case .no: return "hand.thumbsdown.fill"
            }
        }
    }

    var id = UUID()
    var address: String
    var price: String = ""
    var reaction: Reaction?
}

enum TourCopy {
    static func itinerary(_ tour: ShowingTour, agentName: String) -> String {
        let me = agentName.split(separator: " ").first.map(String.init) ?? agentName
        var lines = ["Hi \(tour.firstName)! Here's our tour for \(tour.label):", ""]
        for (index, stop) in tour.stops.enumerated() {
            let price = stop.price.isEmpty ? "" : " (\(stop.price))"
            lines.append("\(tour.time(for: index).formatted(date: .omitted, time: .shortened))  \(stop.address)\(price)")
        }
        if let url = tour.routeURL { lines += ["", "Route: \(url.absoluteString)"] }
        lines += ["", "I'll meet you at the first home. Bring your list of must haves! \(me)"]
        return lines.joined(separator: "\n")
    }

    static func recap(_ tour: ShowingTour, agentName: String) -> String {
        let me = agentName.split(separator: " ").first.map(String.init) ?? agentName
        var lines = ["Great touring with you today, \(tour.firstName)! Here's where we landed:", ""]
        for reaction in TourStop.Reaction.allCases {
            let group = tour.stops.filter { $0.reaction == reaction }
            guard !group.isEmpty else { continue }
            lines.append("\(reaction.title.uppercased())")
            lines += group.map { "- \($0.address)" }
            lines.append("")
        }
        if tour.stops.contains(where: { $0.reaction == .love }) {
            lines.append("Want to talk about an offer on your favorite? I can pull comps tonight.")
        } else {
            lines.append("Now that we know what you don't want, I'll line up a better set for next time.")
        }
        lines.append(me)
        return lines.joined(separator: "\n")
    }
}
