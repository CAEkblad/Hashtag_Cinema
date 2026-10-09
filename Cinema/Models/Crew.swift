import Foundation

// #Cinema Crew: the photographers and videographers agents book through the app.
// Every booking runs through #Cinema (shooters sign a non-solicit), and shooters
// level up on jobs closed and five star ratings. Mirrors `shooter_tiers` on the backend.

enum CrewTier: String, CaseIterable, Identifiable, Codable {
    case rookie
    case pro
    case elite
    case legend

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rookie: return "Rookie"
        case .pro: return "Pro"
        case .elite: return "Elite"
        case .legend: return "Legend"
        }
    }

    var icon: String {
        switch self {
        case .rookie: return "camera.fill"
        case .pro: return "star.fill"
        case .elite: return "crown.fill"
        case .legend: return "trophy.fill"
        }
    }

    var paletteIndex: Int {
        switch self {
        case .rookie: return 1
        case .pro: return 4
        case .elite: return 3
        case .legend: return 5
        }
    }

    var minJobs: Int {
        switch self {
        case .rookie: return 0
        case .pro: return 25
        case .elite: return 100
        case .legend: return 300
        }
    }

    var minFiveStar: Int {
        switch self {
        case .rookie: return 0
        case .pro: return 15
        case .elite: return 70
        case .legend: return 230
        }
    }

    var minRating: Double {
        switch self {
        case .rookie: return 0
        case .pro: return 4.6
        case .elite: return 4.8
        case .legend: return 4.9
        }
    }

    /// Extra paid on every job at this tier, in dollars.
    var bonusPerJob: Int {
        switch self {
        case .rookie: return 0
        case .pro: return 10
        case .elite: return 25
        case .legend: return 50
        }
    }

    /// One time cash bonus for reaching the tier.
    var levelUpBonus: Int {
        switch self {
        case .rookie: return 0
        case .pro: return 100
        case .elite: return 500
        case .legend: return 1_500
        }
    }

    var perks: [String] {
        switch self {
        case .rookie: return ["Standard jobs in your market", "Training library"]
        case .pro: return ["First look at new jobs for 15 minutes", "Pro badge on your profile", "$10 bonus on every job"]
        case .elite: return ["First pick of luxury and brand shoots", "Gear stipend", "Quarterly prize drop", "$25 bonus on every job"]
        case .legend: return ["Market lead role with training pay", "Revenue share on shooters you recruit", "Annual trip", "$50 bonus on every job"]
        }
    }

    var next: CrewTier? {
        switch self {
        case .rookie: return .pro
        case .pro: return .elite
        case .elite: return .legend
        case .legend: return nil
        }
    }
}

enum ShooterSkill: String, CaseIterable, Identifiable, Codable {
    case listingPhotos
    case drone
    case video
    case brandVideo
    case headshots
    case twilight
    case matterport
    case events
    case podcast

    var id: String { rawValue }

    var title: String {
        switch self {
        case .listingPhotos: return "Listing photos"
        case .drone: return "Drone"
        case .video: return "Listing video"
        case .brandVideo: return "Agent brand video"
        case .headshots: return "Headshots"
        case .twilight: return "Twilight"
        case .matterport: return "3D tours"
        case .events: return "Events"
        case .podcast: return "Podcast"
        }
    }

    var icon: String {
        switch self {
        case .listingPhotos: return "camera.fill"
        case .drone: return "airplane"
        case .video: return "video.fill"
        case .brandVideo: return "person.crop.rectangle.fill"
        case .headshots: return "camera.aperture"
        case .twilight: return "moon.stars.fill"
        case .matterport: return "cube.transparent.fill"
        case .events: return "party.popper.fill"
        case .podcast: return "mic.fill"
        }
    }
}

struct PortfolioItem: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var symbol: String
    var paletteIndex: Int
    var isVideo: Bool = false
}

struct ShootReview: Identifiable, Hashable {
    var id = UUID()
    var author: String
    var rating: Int
    var text: String
    var date: Date
}

struct Shooter: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var cityID: String
    var bio: String
    var skills: [ShooterSkill]
    var tier: CrewTier
    var rating: Double
    var jobsCompleted: Int
    var fiveStarCount: Int
    var yearsShooting: Int
    var responseTime: String
    var nextOpening: Date
    var portfolio: [PortfolioItem]
    var reviews: [ShootReview]
    var backgroundChecked = true
    var insured = true
    var hasPart107 = false
    var gear: String = ""

    var city: FloridaCity? { FloridaMarkets.city(cityID) }

    var initials: String {
        String(name.split(separator: " ").prefix(2).compactMap { $0.first }).uppercased()
    }

    var ratingLabel: String { String(format: "%.1f", rating) }
}

// MARK: - Packages (the #Cinema listing rate card)

struct ShootPackage: Identifiable, Hashable {
    var id: String
    var name: String
    var price: Int
    /// Shown as "$1,999+" when the price is a starting point.
    var isStartingPrice = false
    var includes: [String]
    var isLuxury = false

    var priceLabel: String {
        "$\(price.formatted())\(isStartingPrice ? "+" : "")"
    }

    static let listing: [ShootPackage] = [
        ShootPackage(id: "photos-drone", name: "Photos + Drone", price: 179, includes: ["Interior and exterior photos", "Drone photos", "MLS sized and full res"]),
        ShootPackage(id: "video", name: "Video walkthrough", price: 219, includes: ["Walkthrough video", "Vertical cut for social", "No drone"]),
        ShootPackage(id: "video-drone", name: "Video + Drone", price: 299, includes: ["Walkthrough video with drone", "Vertical and wide cuts"]),
        ShootPackage(id: "full", name: "Full package", price: 399, includes: ["Photos, drone and video", "Vertical cuts for every platform", "Most popular"]),
        ShootPackage(id: "cinematic", name: "Cinematic", price: 799, includes: ["Luxury cinematic film", "Drone and gimbal", "Licensed music"], isLuxury: true),
        ShootPackage(id: "premium", name: "Premium", price: 1_499, includes: ["Cinematic film and photos", "Twilight and lifestyle scenes"], isLuxury: true),
        ShootPackage(id: "estate", name: "Estate", price: 1_999, isStartingPrice: true, includes: ["Full estate production", "Multiple days as needed"], isLuxury: true)
    ]
}

struct ShootAddOn: Identifiable, Hashable {
    var id: String
    var name: String
    var price: Int
    var perPhoto = false

    var priceLabel: String { "$\(price)\(perPhoto ? "/photo" : "")" }

    static let all: [ShootAddOn] = [
        ShootAddOn(id: "matterport", name: "Matterport 3D tour", price: 149),
        ShootAddOn(id: "twilight", name: "Sunset or twilight photos", price: 99),
        ShootAddOn(id: "floorplan", name: "Floor plan", price: 75),
        ShootAddOn(id: "website", name: "Single property website", price: 75),
        ShootAddOn(id: "oncamera", name: "Agent on camera", price: 75),
        ShootAddOn(id: "staging", name: "Virtual staging", price: 45, perPhoto: true),
        ShootAddOn(id: "rush", name: "Rush delivery", price: 75)
    ]
}

/// A photographer or videographer applying to shoot for #Cinema.
struct CrewApplication: Codable, Equatable {
    var name: String
    var email: String
    var phone: String
    var cityID: String
    var skills: [ShooterSkill]
    var portfolioURL: String
    var yearsShooting: Int
    var hasInsurance: Bool
    var hasPart107: Bool
    var agreedNonSolicit: Bool
    var submittedAt: Date
}

/// A job offered to a shooter in the Crew dashboard preview.
struct CrewJobOffer: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var address: String
    var date: Date
    var pay: Int
    var bonus: Int
    var skill: ShooterSkill
}
