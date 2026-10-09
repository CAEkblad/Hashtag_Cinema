import SwiftUI

enum PosterKind: String, CaseIterable, Identifiable, Codable {
    case justListed
    case comingSoon
    case openHouse
    case underContract
    case priceImproved
    case justSold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .justListed: return "JUST LISTED"
        case .comingSoon: return "COMING SOON"
        case .openHouse: return "OPEN HOUSE"
        case .underContract: return "UNDER CONTRACT"
        case .priceImproved: return "PRICE IMPROVED"
        case .justSold: return "JUST SOLD"
        }
    }

    var shortTitle: String {
        switch self {
        case .justListed: return "Just listed"
        case .comingSoon: return "Coming soon"
        case .openHouse: return "Open house"
        case .underContract: return "Under contract"
        case .priceImproved: return "Price improved"
        case .justSold: return "Just sold"
        }
    }

    var icon: String {
        switch self {
        case .justListed: return "house.fill"
        case .comingSoon: return "clock.fill"
        case .openHouse: return "door.left.hand.open"
        case .underContract: return "signature"
        case .priceImproved: return "arrow.down.circle.fill"
        case .justSold: return "checkmark.seal.fill"
        }
    }

    var keyword: String {
        switch self {
        case .justListed, .priceImproved: return "TOUR"
        case .comingSoon: return "EARLY"
        case .openHouse: return "OPEN"
        case .underContract: return "NEXT"
        case .justSold: return "VALUE"
        }
    }
}

enum PosterStyle: String, CaseIterable, Identifiable {
    case classic
    case bold
    case luxury

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum PosterSize: String, CaseIterable, Identifiable {
    case story
    case post
    case square

    var id: String { rawValue }

    var title: String {
        switch self {
        case .story: return "Story 9:16"
        case .post: return "Post 4:5"
        case .square: return "Square"
        }
    }

    /// Height divided by width.
    var ratio: CGFloat {
        switch self {
        case .story: return 16.0 / 9.0
        case .post: return 5.0 / 4.0
        case .square: return 1
        }
    }
}

struct PosterDetails: Equatable {
    var kind: PosterKind = .justListed
    var address = ""
    var cityLine = ""
    var price = ""
    var beds = 3
    var baths = 2.0
    var squareFeet = ""
    var openHouseDate = Date()
    var agentName = ""
    var agentPhone = ""
    var brokerage = ""

    var priceLabel: String? {
        let digits = price.filter(\.isNumber)
        guard let value = Int(digits), value > 0 else { return nil }
        return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    var bathsLabel: String {
        baths.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(baths))" : String(format: "%.1f", baths)
    }

    var specsLine: String {
        var parts = ["\(beds) bed", "\(bathsLabel) bath"]
        let sqft = squareFeet.filter(\.isNumber)
        if let value = Int(sqft), value > 0 { parts.append("\(value.formatted()) sq ft") }
        return parts.joined(separator: "  ·  ")
    }

    var openHouseLabel: String {
        openHouseDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().hour().minute())
    }

    /// Ready to paste caption, written for the poster type.
    func caption(cityName: String) -> String {
        let place = address.isEmpty ? cityName : "\(address), \(cityName)"
        let price = priceLabel.map { " \($0)." } ?? ""
        let specs = "\(beds) bed, \(bathsLabel) bath"
        let tag = cityName.filter { $0.isLetter }.lowercased()
        let hashtags = "#\(tag)realestate #\(tag)homes #floridarealestate"
        switch kind {
        case .justListed:
            return "JUST LISTED in \(cityName)! \(specs) at \(place).\(price) Comment \(kind.keyword) and I'll send you the details and a private showing time. \(hashtags) #justlisted"
        case .comingSoon:
            return "COMING SOON to \(cityName). \(specs) at \(place).\(price) Want to see it before it hits the market? Comment \(kind.keyword). \(hashtags) #comingsoon"
        case .openHouse:
            return "OPEN HOUSE \(openHouseLabel) at \(place). \(specs).\(price) Stop by and say hi, or comment \(kind.keyword) for the details. \(hashtags) #openhouse"
        case .underContract:
            return "UNDER CONTRACT in \(cityName)! Congrats to my buyers and sellers at \(place). Thinking about your next move? Comment \(kind.keyword). \(hashtags) #undercontract"
        case .priceImproved:
            return "PRICE IMPROVED at \(place).\(price) \(specs) in \(cityName). Comment \(kind.keyword) to book a showing. \(hashtags) #priceimproved"
        case .justSold:
            return "JUST SOLD in \(cityName)! \(place). Curious what your home is worth in today's market? Comment \(kind.keyword) and I'll send you a free home value report. \(hashtags) #justsold"
        }
    }
}

/// A finished poster, kept in the agent's posters and shared with the office pool.
struct PosterItem: Identifiable, Hashable {
    var id = UUID()
    var kind: PosterKind
    var address: String
    var caption: String
    var createdAt: Date
    var imageData: Data?
}
