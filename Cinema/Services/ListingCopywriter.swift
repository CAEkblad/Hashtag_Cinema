import Foundation

/// Writes listing descriptions, captions and open house follow ups on the phone.
/// Fair housing safe: describes the home and the area, never who should live there.
/// The backend version (Claude) uses the same inputs when it is connected.
enum ListingCopywriter {
    enum Tone: String, CaseIterable, Identifiable {
        case warm
        case luxury
        case punchy

        var id: String { rawValue }

        var title: String {
            switch self {
            case .warm: return "Warm"
            case .luxury: return "Luxury"
            case .punchy: return "Short and punchy"
            }
        }
    }

    static func description(for listing: Listing, tone: Tone) -> String {
        let cityName = listing.city?.name ?? "town"
        let features = listing.features.map(\.phrase)
        let featureLine = list(features.prefix(4).map { $0 })
        let extra = features.dropFirst(4).map { $0 }
        let area = areaLine(listing)
        let size = listing.squareFeet.map { " with \($0.formatted()) square feet" } ?? ""

        switch tone {
        case .warm:
            var text = "Welcome home to \(listing.address). This \(listing.beds) bedroom, \(listing.bathsLabel) bath home in \(cityName)\(size) is ready for its next chapter."
            if !featureLine.isEmpty { text += " Inside and out you'll find \(featureLine)." }
            if !extra.isEmpty { text += " Bonus: \(list(extra))." }
            text += " \(area) Schedule your private showing today."
            return text
        case .luxury:
            var text = "An exceptional \(listing.beds) bedroom residence in \(cityName)\(size), \(listing.address) pairs refined design with effortless Florida living."
            if !featureLine.isEmpty { text += " Highlights include \(featureLine)." }
            if !extra.isEmpty { text += " Additional appointments: \(list(extra))." }
            text += " \(area) Private tours by appointment."
            return text
        case .punchy:
            var lines = ["\(listing.beds) bed. \(listing.bathsLabel) bath. \(cityName)."]
            if let first = listing.features.first { lines.append("\(first.title). ") }
            if listing.features.count > 1 { lines.append(listing.features.dropFirst().prefix(3).map(\.title).joined(separator: ". ") + ".") }
            lines.append(area)
            lines.append("Don't wait on this one.")
            return lines.joined(separator: " ").replacingOccurrences(of: ".  ", with: ". ")
        }
    }

    static func socialCaption(for listing: Listing) -> String {
        let cityName = listing.city?.name ?? ""
        let kind = listing.status.posterKind
        let tag = cityName.filter { $0.isLetter }.lowercased()
        let top = listing.features.prefix(2).map(\.title).joined(separator: " and ")
        let featureText = top.isEmpty ? "" : " \(top)."
        return "\(kind.title) in \(cityName)! \(listing.specsLine) at \(listing.address).\(featureText) \(listing.priceLabel). Comment \(kind.keyword) for the details. #\(tag)realestate #floridahomes"
    }

    static func followUp(for visitor: OpenHouseVisitor, listing: Listing, agentName: String) -> String {
        let first = visitor.name.split(separator: " ").first.map { String($0) } ?? visitor.name
        let me = agentName.split(separator: " ").first.map { String($0) } ?? agentName
        if visitor.workingWithAgent {
            return "Hi \(first), it's \(me). Thanks for stopping by \(listing.address) today. If you or your agent have any questions or want a second look, just reply here."
        }
        if visitor.preapproved {
            return "Hi \(first), it's \(me). Great meeting you at \(listing.address). Since you're pre-approved, want me to set up a private showing or send a few similar homes in \(listing.city?.name ?? "the area")?"
        }
        return "Hi \(first), it's \(me). Thanks for coming to the open house at \(listing.address). Want me to send you similar homes and connect you with a great local lender? No pressure at all."
    }

    /// A friendly note for the neighbors. Neighbors often know the next buyer, or are the next seller.
    static func neighborInvite(for listing: Listing, openHouse: OpenHouse, agentName: String) -> String {
        let me = agentName.split(separator: " ").first.map { String($0) } ?? agentName
        let rooms = "\(listing.beds) bed, \(listing.baths.formatted()) bath"
        return "Hi neighbor! I'm \(me), the agent for \(listing.address). You're invited to our open house, \(openHouse.label). Stop by early for a first look before the crowds. It's a \(rooms) home listed at \(listing.priceLabel). Know someone who'd love to live by you? Bring them along. And if you're curious what your own home is worth, I'm happy to put together a free value report."
    }

    private static func areaLine(_ listing: Listing) -> String {
        guard let city = listing.city else { return "" }
        if let highlight = city.highlights.first(where: { !$0.lowercased().contains("spring training") }) {
            return "Enjoy everything \(city.name) offers, including \(lowerFirst(highlight))."
        }
        if city.has(.beach) { return "Minutes to the beach and the best of \(city.name)." }
        if city.has(.lakes) { return "Close to the lakes, parks and everyday conveniences of \(city.name)." }
        return "Close to shopping, dining and everyday conveniences in \(city.countyLine)."
    }

    private static func list(_ items: [String]) -> String {
        switch items.count {
        case 0: return ""
        case 1: return items[0]
        case 2: return "\(items[0]) and \(items[1])"
        default: return items.dropLast().joined(separator: ", ") + ", and " + (items.last ?? "")
        }
    }

    private static func lowerFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        // Keep proper nouns like "Bayshore" capitalized; only lower generic openers.
        let generic = ["The ", "Minutes ", "Top ", "One ", "Hundreds ", "Front "]
        if generic.contains(where: { text.hasPrefix($0) }) {
            return first.lowercased() + text.dropFirst()
        }
        return text
    }
}

/// Monthly payment estimate with Florida style taxes and insurance.
struct PaymentEstimate {
    var price: Double
    var downPercent: Double
    var rate: Double
    var years: Int
    var taxRate: Double
    var insuranceYearly: Double
    var hoaMonthly: Double

    var loanAmount: Double { price * (1 - downPercent / 100) }

    var principalAndInterest: Double {
        let monthlyRate = rate / 100 / 12
        let n = Double(years * 12)
        guard monthlyRate > 0 else { return loanAmount / max(n, 1) }
        return loanAmount * monthlyRate * pow(1 + monthlyRate, n) / (pow(1 + monthlyRate, n) - 1)
    }

    var taxesMonthly: Double { price * taxRate / 100 / 12 }
    var insuranceMonthly: Double { insuranceYearly / 12 }
    /// Rough mortgage insurance when the down payment is under 20%.
    var pmiMonthly: Double { downPercent < 20 ? loanAmount * 0.005 / 12 : 0 }
    var total: Double { principalAndInterest + taxesMonthly + insuranceMonthly + hoaMonthly + pmiMonthly }

    var parts: [(String, Double)] {
        [("Principal and interest", principalAndInterest), ("Property taxes", taxesMonthly), ("Insurance", insuranceMonthly), ("HOA", hoaMonthly), ("Mortgage insurance", pmiMonthly)]
            .filter { $0.1 > 0.5 }
    }
}
