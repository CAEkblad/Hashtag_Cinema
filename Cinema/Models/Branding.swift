import SwiftUI
import UIKit

/// The agent's look on every poster, graphic and showcase: headshot, logo,
/// accent color and contact line. Saved on the phone; synced to the profile
/// when the backend is live.
struct BrandKit: Codable, Equatable {
    var accentHex: UInt32 = 0xE11D2E
    var phone = ""
    var website = ""
    var tagline = ""
    var headshotData: Data? = nil
    var logoData: Data? = nil

    var accent: Color { Color(hex: accentHex) }
    var headshotImage: UIImage? { headshotData.flatMap(UIImage.init(data:)) }
    var logoImage: UIImage? { logoData.flatMap(UIImage.init(data:)) }

    var completion: Int {
        [headshotData != nil, logoData != nil, !phone.isEmpty, !tagline.isEmpty, accentHex != 0xE11D2E]
            .filter { $0 }.count
    }

    struct Swatch: Hashable {
        let name: String
        let hex: UInt32
    }

    static let swatches: [Swatch] = [
        Swatch(name: "CloseUp red", hex: 0xE11D2E),
        Swatch(name: "Classic black", hex: 0x141416),
        Swatch(name: "Navy", hex: 0x1F3A5F),
        Swatch(name: "Ocean", hex: 0x0E7490),
        Swatch(name: "Palm", hex: 0x15803D),
        Swatch(name: "Gold", hex: 0xB08D57),
        Swatch(name: "Coral", hex: 0xF26B5B),
        Swatch(name: "Plum", hex: 0x6D28D9)
    ]
}

// MARK: - Testimonials

struct Testimonial: Identifiable, Hashable, Codable {
    enum Side: String, Codable, CaseIterable, Identifiable {
        case buyer, seller
        var id: String { rawValue }
        var title: String { self == .buyer ? "Buyer" : "Seller" }
    }

    var id = UUID()
    var clientName: String
    var quote: String
    var stars: Int
    var side: Side
    var cityName: String
    var date: Date
}

// MARK: - Market update

struct MarketSnapshot: Equatable {
    var cityName: String
    var periodLabel: String
    var medianPrice: Int
    var priceChangePercent: Double
    var daysOnMarket: Int
    var activeListings: Int
    var newListings: Int

    var priceLabel: String { medianPrice.formatted(.currency(code: "USD").precision(.fractionLength(0))) }

    var changeLabel: String {
        let sign = priceChangePercent > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", priceChangePercent))%"
    }

    /// Plain English read of the numbers. Kept simple and hedged on purpose.
    var takeaway: String {
        if daysOnMarket >= 60 { return "Homes are taking longer to sell. Buyers have more room to negotiate." }
        if daysOnMarket <= 25 { return "Homes are moving fast. Sellers who price it right are winning." }
        if priceChangePercent <= -2 { return "Prices softened a little. A good window for buyers who are ready." }
        if priceChangePercent >= 3 { return "Prices are climbing. Sellers are in a strong spot." }
        return "A balanced market. Pricing and presentation make the difference."
    }

    func script(agentFirstName: String) -> String {
        let direction = priceChangePercent == 0 ? "held steady" : (priceChangePercent > 0 ? "went up \(changeLabel)" : "dipped \(changeLabel.replacingOccurrences(of: "-", with: ""))")
        return "Here's the \(cityName) market for \(periodLabel) in 30 seconds. The median price is \(priceLabel), and it \(direction). Homes are selling in about \(daysOnMarket) days, with \(activeListings) on the market and \(newListings) new this month. \(takeaway) Want to know what this means for your home? Comment MARKET and I'll send you my full breakdown."
    }
}
