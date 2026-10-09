import Foundation

// My Listings: one place per property for the shoot, posters, video, open
// houses, the listing description and every lead it brings in.

enum ListingStatus: String, CaseIterable, Identifiable, Codable {
    case comingSoon
    case active
    case underContract
    case sold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .comingSoon: return "Coming soon"
        case .active: return "Active"
        case .underContract: return "Under contract"
        case .sold: return "Sold"
        }
    }

    var icon: String {
        switch self {
        case .comingSoon: return "clock.fill"
        case .active: return "house.fill"
        case .underContract: return "signature"
        case .sold: return "checkmark.seal.fill"
        }
    }

    /// The poster that matches this stage.
    var posterKind: PosterKind {
        switch self {
        case .comingSoon: return .comingSoon
        case .active: return .justListed
        case .underContract: return .underContract
        case .sold: return .justSold
        }
    }
}

enum ListingFeature: String, CaseIterable, Identifiable, Codable {
    case pool
    case waterfront
    case gulfAccess
    case dock
    case lanai
    case newRoof
    case impactWindows
    case renovatedKitchen
    case openFloorPlan
    case homeOffice
    case garage
    case golfView
    case gated
    case noHOA
    case newConstruction
    case solar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pool: return "Pool"
        case .waterfront: return "Waterfront"
        case .gulfAccess: return "Gulf access"
        case .dock: return "Private dock"
        case .lanai: return "Screened lanai"
        case .newRoof: return "Newer roof"
        case .impactWindows: return "Impact windows"
        case .renovatedKitchen: return "Renovated kitchen"
        case .openFloorPlan: return "Open floor plan"
        case .homeOffice: return "Home office"
        case .garage: return "2 car garage"
        case .golfView: return "Golf course view"
        case .gated: return "Gated community"
        case .noHOA: return "No HOA"
        case .newConstruction: return "New construction"
        case .solar: return "Solar"
        }
    }

    /// The phrase used in a listing description.
    var phrase: String {
        switch self {
        case .pool: return "a sparkling pool"
        case .waterfront: return "water views from the moment you walk in"
        case .gulfAccess: return "direct Gulf access for boaters"
        case .dock: return "a private dock"
        case .lanai: return "a screened lanai made for Florida evenings"
        case .newRoof: return "a newer roof"
        case .impactWindows: return "impact windows"
        case .renovatedKitchen: return "a renovated kitchen"
        case .openFloorPlan: return "an open floor plan"
        case .homeOffice: return "a dedicated home office"
        case .garage: return "a two car garage"
        case .golfView: return "golf course views"
        case .gated: return "a gated community"
        case .noHOA: return "no HOA"
        case .newConstruction: return "brand new construction"
        case .solar: return "solar panels"
        }
    }
}

struct OpenHouseVisitor: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var phone: String
    var email: String
    var workingWithAgent: Bool
    var preapproved: Bool
    var timeline: String
    var signedInAt: Date
}

struct OpenHouse: Identifiable, Hashable {
    var id = UUID()
    var start: Date
    var end: Date
    var visitors: [OpenHouseVisitor] = []

    var label: String {
        "\(start.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())), \(start.timeOnly) to \(end.timeOnly)"
    }
}

/// Marketing steps for a listing, in the order they usually happen.
enum MarketingTask: String, CaseIterable, Identifiable, Codable {
    case bookShoot
    case comingSoonPoster
    case listingVideo
    case justListedPoster
    case description
    case socialPost
    case openHouse
    case website
    case justSoldPoster

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bookShoot: return "Book photos, video and drone"
        case .comingSoonPoster: return "Coming soon poster"
        case .listingVideo: return "Listing video"
        case .justListedPoster: return "Just listed poster"
        case .description: return "Listing description"
        case .socialPost: return "Post on all 4 platforms"
        case .openHouse: return "Hold an open house"
        case .website: return "Single property website"
        case .justSoldPoster: return "Just sold poster"
        }
    }

    var icon: String {
        switch self {
        case .bookShoot: return "camera.fill"
        case .comingSoonPoster: return "clock.fill"
        case .listingVideo: return "video.fill"
        case .justListedPoster: return "rectangle.portrait.on.rectangle.portrait.fill"
        case .description: return "text.alignleft"
        case .socialPost: return "paperplane.fill"
        case .openHouse: return "door.left.hand.open"
        case .website: return "globe"
        case .justSoldPoster: return "checkmark.seal.fill"
        }
    }

    /// Steps that make sense at this stage of the listing.
    func applies(to status: ListingStatus) -> Bool {
        switch self {
        case .justSoldPoster: return status == .sold || status == .underContract
        case .comingSoonPoster: return status == .comingSoon || status == .active
        default: return true
        }
    }
}

struct Listing: Identifiable, Hashable {
    var id = UUID()
    var address: String
    var cityID: String
    var price: Int
    var beds: Int
    var baths: Double
    var squareFeet: Int?
    var status: ListingStatus
    var features: [ListingFeature]
    var listedAt: Date
    var symbol: String = "house.fill"
    var paletteIndex: Int = 0
    var done: Set<MarketingTask> = []
    var openHouses: [OpenHouse] = []
    var description: String = ""

    var city: FloridaCity? { FloridaMarkets.city(cityID) }
    var cityLine: String { city?.displayName ?? "" }

    var priceLabel: String { price.formatted(.currency(code: "USD").precision(.fractionLength(0))) }

    var bathsLabel: String {
        baths.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(baths))" : String(format: "%.1f", baths)
    }

    var specsLine: String {
        var parts = ["\(beds) bed", "\(bathsLabel) bath"]
        if let squareFeet, squareFeet > 0 { parts.append("\(squareFeet.formatted()) sq ft") }
        return parts.joined(separator: " · ")
    }

    var tasks: [MarketingTask] { MarketingTask.allCases.filter { $0.applies(to: status) } }
    var progress: Double {
        let list = tasks
        guard !list.isEmpty else { return 0 }
        return Double(list.filter { done.contains($0) }.count) / Double(list.count)
    }

    var visitorCount: Int { openHouses.reduce(0) { $0 + $1.visitors.count } }
    var nextOpenHouse: OpenHouse? { openHouses.filter { $0.end >= Date() }.sorted { $0.start < $1.start }.first }
}
