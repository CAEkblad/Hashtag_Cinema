import Foundation
import CoreLocation

// MARK: - Regions

/// Florida broken into the regions agents actually talk about.
enum FloridaRegion: String, CaseIterable, Identifiable, Codable {
    case tampaBay
    case suncoast
    case southwest
    case southFlorida
    case keys
    case treasureCoast
    case spaceCoast
    case centralFlorida
    case heartland
    case natureCoast
    case northCentral
    case daytonaFlagler
    case firstCoast
    case bigBend
    case panhandle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tampaBay: return "Tampa Bay"
        case .suncoast: return "Sarasota and Manatee"
        case .southwest: return "Southwest Florida"
        case .southFlorida: return "South Florida"
        case .keys: return "Florida Keys"
        case .treasureCoast: return "Treasure Coast"
        case .spaceCoast: return "Space Coast"
        case .centralFlorida: return "Central Florida"
        case .heartland: return "Polk and the Heartland"
        case .natureCoast: return "Nature Coast"
        case .northCentral: return "North Central Florida"
        case .daytonaFlagler: return "Daytona and Flagler"
        case .firstCoast: return "Jacksonville and the First Coast"
        case .bigBend: return "Tallahassee and the Big Bend"
        case .panhandle: return "Panhandle and Emerald Coast"
        }
    }

    var blurb: String {
        switch self {
        case .tampaBay: return "Hillsborough, Pinellas, Pasco and Hernando. Waterfront, growth suburbs and a big relocation market."
        case .suncoast: return "Manatee and Sarasota. Gulf beaches, master planned communities and snowbirds."
        case .southwest: return "Lee, Collier, Charlotte and inland counties. Canals, golf and seasonal buyers."
        case .southFlorida: return "Miami-Dade, Broward and Palm Beach. Condos, luxury and international buyers."
        case .keys: return "Monroe County. Island living, boating and second homes."
        case .treasureCoast: return "Martin, St. Lucie, Indian River and Okeechobee. Quieter coast, fast growth inland."
        case .spaceCoast: return "Brevard County. Launch views, beaches and aerospace jobs."
        case .centralFlorida: return "Orange, Seminole, Osceola, Lake and Sumter. Theme parks, lakes and new construction."
        case .heartland: return "Polk, Highlands and Hardee. Lakes, value and commuters to Tampa and Orlando."
        case .natureCoast: return "Citrus, Levy, Dixie and Taylor. Springs, manatees and Old Florida."
        case .northCentral: return "Alachua, Marion and surrounding counties. College towns and horse country."
        case .daytonaFlagler: return "Volusia and Flagler. Beaches, racing and retirees."
        case .firstCoast: return "Duval, St. Johns, Clay, Nassau and Baker. Military, golf and top growth suburbs."
        case .bigBend: return "Leon and the Big Bend. State capital, universities and coastal fishing towns."
        case .panhandle: return "Escambia to Gulf County. Emerald Coast beaches, military bases and vacation rentals."
        }
    }

    var icon: String {
        switch self {
        case .tampaBay: return "water.waves"
        case .suncoast: return "sun.horizon.fill"
        case .southwest: return "sailboat.fill"
        case .southFlorida: return "building.2.fill"
        case .keys: return "beach.umbrella.fill"
        case .treasureCoast: return "shippingbox.fill"
        case .spaceCoast: return "airplane.departure"
        case .centralFlorida: return "sparkles"
        case .heartland: return "leaf.fill"
        case .natureCoast: return "tortoise.fill"
        case .northCentral: return "graduationcap.fill"
        case .daytonaFlagler: return "flag.checkered"
        case .firstCoast: return "star.fill"
        case .bigBend: return "building.columns.fill"
        case .panhandle: return "sun.max.fill"
        }
    }
}

// MARK: - Traits

/// What a city is known for. Drives the local idea engine.
enum CityTrait: String, CaseIterable, Identifiable, Codable {
    case beach
    case coastalCounty
    case boating
    case lakes
    case golf
    case retirement
    case snowbird
    case college
    case military
    case themeParks
    case historic
    case luxury
    case growth
    case condos
    case equestrian
    case space
    case shortTermRental
    case urban
    case suburban
    case smallTown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beach: return "Beach town"
        case .coastalCounty: return "Coastal county"
        case .boating: return "Boating"
        case .lakes: return "Lakes"
        case .golf: return "Golf"
        case .retirement: return "55+ and retirees"
        case .snowbird: return "Snowbirds"
        case .college: return "College town"
        case .military: return "Military"
        case .themeParks: return "Theme parks"
        case .historic: return "Historic"
        case .luxury: return "Luxury"
        case .growth: return "New construction"
        case .condos: return "Condos"
        case .equestrian: return "Horse country"
        case .space: return "Space Coast"
        case .shortTermRental: return "Vacation rentals"
        case .urban: return "Big city"
        case .suburban: return "Suburbs"
        case .smallTown: return "Small town"
        }
    }

    var icon: String {
        switch self {
        case .beach: return "beach.umbrella.fill"
        case .coastalCounty: return "water.waves"
        case .boating: return "sailboat.fill"
        case .lakes: return "drop.fill"
        case .golf: return "figure.golf"
        case .retirement: return "figure.walk"
        case .snowbird: return "bird.fill"
        case .college: return "graduationcap.fill"
        case .military: return "star.circle.fill"
        case .themeParks: return "sparkles"
        case .historic: return "building.columns.fill"
        case .luxury: return "diamond.fill"
        case .growth: return "hammer.fill"
        case .condos: return "building.2.fill"
        case .equestrian: return "figure.equestrian.sports"
        case .space: return "airplane.departure"
        case .shortTermRental: return "suitcase.rolling.fill"
        case .urban: return "building.fill"
        case .suburban: return "house.fill"
        case .smallTown: return "tree.fill"
        }
    }

    /// Size tiers are shown as the population line, not as chips.
    var isSizeTier: Bool { self == .urban || self == .suburban || self == .smallTown }
}

// MARK: - Cities

struct FloridaCity: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var county: String
    var region: FloridaRegion
    var population: Int?
    var lat: Double
    var lon: Double
    var traits: [CityTrait]
    var highlights: [String]
    var neighborhoods: [String]

    var displayName: String { "\(name), FL" }
    var countyLine: String { "\(county) County" }
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: lat, longitude: lon) }
    var chipTraits: [CityTrait] { traits.filter { !$0.isSizeTier } }

    var populationLabel: String? {
        guard let population, population > 0 else { return nil }
        return "About \(population.compact) people"
    }

    func has(_ trait: CityTrait) -> Bool { traits.contains(trait) }

    func distance(to other: FloridaCity) -> Double {
        let dLat = lat - other.lat
        let dLon = (lon - other.lon) * cos(lat * .pi / 180)
        return (dLat * dLat + dLon * dLon).squareRoot() * 69 // rough miles
    }

    enum CodingKeys: String, CodingKey {
        case id, name, county, region, population, lat, lon, traits, highlights, neighborhoods
    }

    init(id: String, name: String, county: String, region: FloridaRegion, population: Int?, lat: Double, lon: Double, traits: [CityTrait], highlights: [String] = [], neighborhoods: [String] = []) {
        self.id = id
        self.name = name
        self.county = county
        self.region = region
        self.population = population
        self.lat = lat
        self.lon = lon
        self.traits = traits
        self.highlights = highlights
        self.neighborhoods = neighborhoods
    }

    /// Unknown trait names are skipped so the backend can add traits without breaking older app builds.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        county = try c.decode(String.self, forKey: .county)
        region = try c.decode(FloridaRegion.self, forKey: .region)
        population = try c.decodeIfPresent(Int.self, forKey: .population)
        lat = try c.decode(Double.self, forKey: .lat)
        lon = try c.decode(Double.self, forKey: .lon)
        let rawTraits = try c.decodeIfPresent([String].self, forKey: .traits) ?? []
        traits = rawTraits.compactMap(CityTrait.init(rawValue:))
        highlights = try c.decodeIfPresent([String].self, forKey: .highlights) ?? []
        neighborhoods = try c.decodeIfPresent([String].self, forKey: .neighborhoods) ?? []
    }
}

/// Every Florida city and town, bundled with the app (Data/florida_cities.json)
/// and mirrored in the `cities` table on the backend.
enum FloridaMarkets {
    static let all: [FloridaCity] = load()

    static let fallback = FloridaCity(
        id: "tampa-hillsborough", name: "Tampa", county: "Hillsborough", region: .tampaBay,
        population: 369_075, lat: 27.9475, lon: -82.4584,
        traits: [.boating, .coastalCounty, .college, .condos, .military, .themeParks, .urban],
        highlights: ["Gasparilla Pirate Festival in late January", "Bayshore Boulevard and the Riverwalk"],
        neighborhoods: ["South Tampa", "Hyde Park", "Seminole Heights", "Westchase"]
    )

    private static let byID: [String: FloridaCity] = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    private static func load() -> [FloridaCity] {
        guard let url = Bundle.main.url(forResource: "florida_cities", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let cities = try? JSONDecoder().decode([FloridaCity].self, from: data),
              !cities.isEmpty else {
            return [fallback]
        }
        return cities
    }

    static func city(_ id: String?) -> FloridaCity? {
        guard let id else { return nil }
        return byID[id]
    }

    static func cities(in region: FloridaRegion) -> [FloridaCity] {
        all.filter { $0.region == region }
    }

    /// Ranked search: exact start of name first, then contains, then county matches.
    static func search(_ query: String, limit: Int = 40) -> [FloridaCity] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            .replacingOccurrences(of: "saint ", with: "st. ")
        guard !q.isEmpty else { return Array(all.prefix(limit)) }
        var starts: [FloridaCity] = []
        var contains: [FloridaCity] = []
        var county: [FloridaCity] = []
        for city in all {
            let name = city.name.lowercased()
            if name.hasPrefix(q) {
                starts.append(city)
            } else if name.contains(q) {
                contains.append(city)
            } else if city.county.lowercased().hasPrefix(q) {
                county.append(city)
            }
        }
        return Array((starts + contains + county).prefix(limit))
    }

    static func nearby(_ city: FloridaCity, limit: Int = 8) -> [FloridaCity] {
        all.filter { $0.id != city.id }
            .sorted { $0.distance(to: city) < $1.distance(to: city) }
            .prefix(limit)
            .map { $0 }
    }

    /// Bigger nearby places first, so suggestions are towns people know.
    static func suggestedServiceAreas(for city: FloridaCity, limit: Int = 6) -> [FloridaCity] {
        all.filter { $0.id != city.id && $0.distance(to: city) < 30 }
            .sorted { ($0.population ?? 0) > ($1.population ?? 0) }
            .prefix(limit)
            .map { $0 }
    }
}

// MARK: - Goals

enum ContentGoal: String, CaseIterable, Identifiable, Codable {
    case moreListings
    case moreBuyers
    case personalBrand
    case relocation
    case recruit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .moreListings: return "Win more listings"
        case .moreBuyers: return "Find more buyers"
        case .personalBrand: return "Be the local expert"
        case .relocation: return "Attract people moving here"
        case .recruit: return "Recruit agents"
        }
    }

    var icon: String {
        switch self {
        case .moreListings: return "house.and.flag.fill"
        case .moreBuyers: return "key.fill"
        case .personalBrand: return "person.crop.circle.badge.checkmark"
        case .relocation: return "car.fill"
        case .recruit: return "person.3.fill"
        }
    }
}

// MARK: - Seasonal moments

struct SeasonalMoment: Identifiable, Hashable {
    var id: String
    var title: String
    var detail: String
    var icon: String
    var hook: String
    var category: IdeaCategory
}
