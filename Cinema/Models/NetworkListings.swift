import Foundation

/// A home another agent shared with the #Cinema agent network, including
/// coming soon and off market homes that buyers can't find on the portals.
struct NetworkListing: Identifiable, Codable, Hashable {
    enum Status: String, Codable, CaseIterable, Identifiable {
        case comingSoon, offMarket, active
        var id: String { rawValue }
        var title: String {
            switch self {
            case .comingSoon: return "Coming soon"
            case .offMarket: return "Off market"
            case .active: return "Active"
            }
        }
    }

    var id = UUID()
    var address: String
    var cityName: String
    var state: String = "FL"
    var price: Int
    var beds: Int
    var baths: Double
    var sqft: Int
    var yearBuilt: Int
    var daysOnMarket: Int
    var originalPrice: Int
    var priceCuts: Int
    var status: Status
    var remarks: String
    var features: [ListingFeature]
    var agentName: String
    var brokerage: String
    var isKW: Bool
    /// The area's typical price per square foot, for spotting value.
    var areaPPSF: Int
    var isMine = false

    var ppsf: Int { sqft > 0 ? price / sqft : 0 }
    var priceLabel: String { price.formatted(.currency(code: "USD").precision(.fractionLength(0))) }
    var place: String { "\(cityName), \(state)" }
    var specs: String { "\(beds) bd · \(baths.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(baths))" : String(format: "%.1f", baths)) ba · \(sqft.formatted()) sq ft" }
}

/// Another agent's buyer, posted so listing agents can say "I have one for you."
struct BuyerNeedPost: Identifiable, Codable, Hashable {
    var id = UUID()
    var agentName: String
    var brokerage: String
    var isKW: Bool
    var cityName: String
    var maxPrice: Int
    var minBeds: Int
    var mustHaves: [ListingFeature]
    var note: String
}

/// Why a home is worth a buyer's look, beyond what a portal filter shows.
struct GemScore {
    var score: Int
    var reasons: [String]
    var isGem: Bool { score >= 60 && reasons.count >= 2 }

    static let motivatedPhrases: [(String, String)] = [
        ("motivated", "Remarks say the seller is motivated"),
        ("bring all offers", "Remarks say bring all offers"),
        ("bring offers", "Remarks say bring offers"),
        ("as-is", "Sold as is, often priced to move"),
        ("as is", "Sold as is, often priced to move"),
        ("estate sale", "Estate sale, families often want a quick, simple close"),
        ("tlc", "Needs some TLC, room to build equity"),
        ("assumable", "Assumable loan, could mean a lower rate"),
        ("seller credit", "Seller is offering a credit"),
        ("relocat", "Seller is relocating, timing may matter more than price"),
        ("price improvement", "Recent price improvement")
    ]

    static func score(_ listing: NetworkListing, for buyer: BuyerWish?, myOffice: String, kwMode: Bool) -> GemScore {
        var points = 30
        var reasons: [String] = []

        if let buyer {
            if listing.price > Int(Double(buyer.maxPrice) * 1.05) || listing.beds < buyer.minBeds { points -= 40 }
            if !buyer.cityNames.isEmpty && !buyer.cityNames.contains(listing.cityName) { points -= 15 }
            let has = buyer.mustHaves.filter { listing.features.contains($0) }.count
            if !buyer.mustHaves.isEmpty {
                points += has * 6
                if has == buyer.mustHaves.count { reasons.append("Has every must have: \(buyer.mustHaves.map(\.title).joined(separator: ", "))") }
            }
            let room = buyer.maxPrice - listing.price
            if room >= 25_000 { reasons.append("\((Double(room)).compactMoney) under their budget, room to negotiate or update") }
        }

        if listing.areaPPSF > 0 && listing.ppsf > 0 {
            let gap = Double(listing.areaPPSF - listing.ppsf) / Double(listing.areaPPSF)
            if gap >= 0.08 {
                points += Int(gap * 120)
                reasons.append("$\(listing.ppsf)/sq ft, \(Int((gap * 100).rounded()))% under the area's $\(listing.areaPPSF)")
            }
        }
        if listing.priceCuts > 0 && listing.originalPrice > listing.price {
            points += 8 + listing.priceCuts * 3
            reasons.append("Price cut \(listing.priceCuts == 1 ? "once" : "\(listing.priceCuts) times"), \(Double(listing.originalPrice - listing.price).compactMoney) off")
        }
        if listing.daysOnMarket >= 45 && listing.status == .active {
            points += 8
            reasons.append("\(listing.daysOnMarket) days on market, the seller may be ready to deal")
        }
        if listing.status != .active {
            points += 12
            reasons.append("\(listing.status.title): not on the portals yet, less competition")
        }
        let remarks = listing.remarks.lowercased()
        for (phrase, reason) in motivatedPhrases where remarks.contains(phrase) && !reasons.contains(reason) {
            points += 7
            reasons.append(reason)
        }
        if listing.features.contains(.newRoof) || listing.features.contains(.impactWindows) {
            points += 4
            reasons.append("Newer roof or impact windows can mean lower insurance")
        }
        if !myOffice.isEmpty && listing.brokerage == myOffice && !listing.isMine {
            points += 6
            reasons.append(kwMode ? "In-house: both sides stay in your Market Center" : "In-house: both sides stay in your brokerage")
        } else if kwMode && listing.isKW && !listing.isMine {
            points += 3
            reasons.append("KW to KW: easy to coordinate with a fellow associate")
        }
        return GemScore(score: max(0, min(100, points)), reasons: reasons)
    }
}

enum NetworkSamples {
    static let listings: [NetworkListing] = [
        NetworkListing(address: "3105 W Bay to Bay Blvd", cityName: "Tampa", price: 689_000, beds: 3, baths: 2, sqft: 1_980, yearBuilt: 1956, daysOnMarket: 64, originalPrice: 749_000, priceCuts: 2, status: .active, remarks: "Motivated seller, bring all offers. Big lot with room for a pool.", features: [.garage, .openFloorPlan], agentName: "Carla Mendez", brokerage: "Sample KW Market Center, Tampa", isKW: true, areaPPSF: 412),
        NetworkListing(address: "6614 N Dexter Ave", cityName: "Tampa", price: 429_000, beds: 3, baths: 2, sqft: 1_610, yearBuilt: 1962, daysOnMarket: 0, originalPrice: 429_000, priceCuts: 0, status: .comingSoon, remarks: "Coming soon in Seminole Heights. New roof 2024, impact windows.", features: [.newRoof, .impactWindows, .lanai], agentName: "Marco Silva", brokerage: "Bay Area Realty", isKW: false, areaPPSF: 298),
        NetworkListing(address: "1217 Pinellas Point Dr S", cityName: "St. Petersburg", price: 525_000, beds: 3, baths: 2, sqft: 1_850, yearBuilt: 1971, daysOnMarket: 0, originalPrice: 525_000, priceCuts: 0, status: .offMarket, remarks: "Off market estate sale. Pool home, sold as-is. Family wants a simple close.", features: [.pool], agentName: "Luis Ortiz", brokerage: "Sample KW Market Center, St. Petersburg", isKW: true, areaPPSF: 335),
        NetworkListing(address: "407 Bayshore Dr", cityName: "Clearwater", price: 1_150_000, beds: 4, baths: 3, sqft: 2_640, yearBuilt: 1998, daysOnMarket: 21, originalPrice: 1_150_000, priceCuts: 0, status: .active, remarks: "Waterfront with private dock and Gulf access.", features: [.waterfront, .dock, .gulfAccess, .pool], agentName: "Ana Grant", brokerage: "Gulf Coast Properties", isKW: false, areaPPSF: 460),
        NetworkListing(address: "2210 Lake Osborne Ct", cityName: "Brandon", price: 389_000, beds: 4, baths: 2.5, sqft: 2_210, yearBuilt: 2004, daysOnMarket: 52, originalPrice: 415_000, priceCuts: 1, status: .active, remarks: "Price improvement! Seller relocating for work. Assumable VA loan.", features: [.garage, .homeOffice], agentName: "Devon Hughes", brokerage: "Sample KW Market Center, Brandon", isKW: true, areaPPSF: 210),
        NetworkListing(address: "88 Lakeview Ter", cityName: "Orlando", price: 465_000, beds: 3, baths: 2, sqft: 1_720, yearBuilt: 1988, daysOnMarket: 9, originalPrice: 465_000, priceCuts: 0, status: .active, remarks: "Lake view, updated kitchen.", features: [.renovatedKitchen, .lanai], agentName: "Isabel Torres", brokerage: "Central Florida Homes", isKW: false, areaPPSF: 280),
        NetworkListing(address: "5902 Palmer Ranch Pkwy", cityName: "Sarasota", price: 610_000, beds: 3, baths: 2, sqft: 2_050, yearBuilt: 2001, daysOnMarket: 0, originalPrice: 610_000, priceCuts: 0, status: .comingSoon, remarks: "Golf course view in a gated community. Coming soon to the network first.", features: [.golfView, .gated, .pool], agentName: "Steve Shaw", brokerage: "Sample KW Market Center, Sarasota", isKW: true, areaPPSF: 330),
        NetworkListing(address: "1830 Gulf Shore Blvd N", cityName: "Naples", price: 1_890_000, beds: 3, baths: 3, sqft: 2_400, yearBuilt: 2008, daysOnMarket: 88, originalPrice: 2_150_000, priceCuts: 3, status: .active, remarks: "Bring offers. Seller credit toward closing costs.", features: [.waterfront, .gated], agentName: "Olivia Price", brokerage: "Naples Luxury Group", isKW: false, areaPPSF: 890),
        NetworkListing(address: "7425 Baymeadows Way", cityName: "Jacksonville", price: 315_000, beds: 3, baths: 2, sqft: 1_540, yearBuilt: 1995, daysOnMarket: 33, originalPrice: 325_000, priceCuts: 1, status: .active, remarks: "Needs some TLC. Great investor opportunity near the base.", features: [.garage, .noHOA], agentName: "Nate Dawson", brokerage: "First Coast Realty", isKW: false, areaPPSF: 228),
        NetworkListing(address: "1601 Brickell Ave Unit 1204", cityName: "Miami", price: 725_000, beds: 2, baths: 2, sqft: 1_180, yearBuilt: 2014, daysOnMarket: 0, originalPrice: 725_000, priceCuts: 0, status: .offMarket, remarks: "Off market condo with bay views. Seller prefers a quiet sale.", features: [.waterfront], agentName: "Gabriela Fuentes", brokerage: "Sample KW Market Center, Miami", isKW: true, areaPPSF: 690),
        NetworkListing(address: "412 Peachtree Hills Ave", cityName: "Atlanta", state: "GA", price: 545_000, beds: 3, baths: 2.5, sqft: 1_990, yearBuilt: 1939, daysOnMarket: 0, originalPrice: 545_000, priceCuts: 0, status: .comingSoon, remarks: "Classic bungalow, coming soon. Updated kitchen and a home office.", features: [.renovatedKitchen, .homeOffice], agentName: "Keisha Bennett", brokerage: "KW Atlanta Sample", isKW: true, areaPPSF: 315),
        NetworkListing(address: "2718 Selwyn Ave", cityName: "Charlotte", state: "NC", price: 699_000, beds: 4, baths: 3, sqft: 2_620, yearBuilt: 1950, daysOnMarket: 47, originalPrice: 735_000, priceCuts: 1, status: .active, remarks: "Price improvement in Myers Park. Motivated seller.", features: [.garage, .homeOffice], agentName: "Brian Kim", brokerage: "Queen City Homes", isKW: false, areaPPSF: 305),
        NetworkListing(address: "1109 Shelby Ave", cityName: "Nashville", state: "TN", price: 625_000, beds: 3, baths: 2.5, sqft: 1_880, yearBuilt: 2019, daysOnMarket: 0, originalPrice: 625_000, priceCuts: 0, status: .offMarket, remarks: "Off market East Nashville new build. Owner relocating to Tampa.", features: [.newConstruction, .openFloorPlan], agentName: "Quinn Ellis", brokerage: "KW Nashville Sample", isKW: true, areaPPSF: 360)
    ]

    static let buyerNeeds: [BuyerNeedPost] = [
        BuyerNeedPost(agentName: "Rosa Ramos", brokerage: "Sample KW Market Center, Tampa", isKW: true, cityName: "Tampa", maxPrice: 1_400_000, minBeds: 3, mustHaves: [.pool], note: "Relocating family from Chicago, preapproved, wants South Tampa schools."),
        BuyerNeedPost(agentName: "Hector Vega", brokerage: "Coastal Real Estate", isKW: false, cityName: "Tampa", maxPrice: 2_000_000, minBeds: 4, mustHaves: [.waterfront], note: "Cash buyer, wants water and a dock. Can close in 21 days."),
        BuyerNeedPost(agentName: "Tanya Jensen", brokerage: "Sample KW Market Center, Brandon", isKW: true, cityName: "Brandon", maxPrice: 450_000, minBeds: 3, mustHaves: [], note: "First time buyers with an FHA preapproval.")
    ]
}
