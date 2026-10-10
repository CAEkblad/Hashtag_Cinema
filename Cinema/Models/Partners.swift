import Foundation

// Brokerage partner programs. Keller Williams is the first: agents who sign in
// with their KW email get the KW experience, 10% off to start, and are tied to
// their market center, which earns 10% of the revenue from its agents.
// More partners (other brokerages) are one more entry in `Partner.all`.

struct Partner: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var shortName: String
    var emailDomains: [String]
    /// Off every plan and credit pack for agents who sign up through the partner.
    var signupDiscountPercent: Int
    /// Share of agent revenue paid to the agent's office.
    var revenueSharePercent: Int
    /// What the partner calls an office.
    var officeWord: String

    static let kellerWilliams = Partner(
        id: "kw",
        name: "Keller Williams",
        shortName: "KW",
        emailDomains: ["kw.com"],
        signupDiscountPercent: 10,
        revenueSharePercent: 10,
        officeWord: "Market Center"
    )

    static let all: [Partner] = [.kellerWilliams]

    static func forEmail(_ email: String) -> Partner? {
        guard let domain = email.split(separator: "@").last?.lowercased(), email.contains("@") else { return nil }
        return all.first { partner in
            partner.emailDomains.contains { domain == $0 || domain.hasSuffix(".\($0)") }
        }
    }

    var officeTitle: String { officeWord.capitalized }
}

/// A partner office. For KW this is a market center.
struct MarketCenter: Identifiable, Hashable, Codable {
    var id: String
    var partnerID: String
    var name: String
    var cityID: String
    /// Shared by the MCA. Joining with it connects the agent right away.
    var joinCode: String
    var group: String?
    var agentCount: Int
    var isSample: Bool = false

    var city: FloridaCity? { FloridaMarkets.city(cityID) }
}

enum MembershipStatus: String, Codable {
    case none
    case pending
    case approved

    var title: String {
        switch self {
        case .none: return "Not connected"
        case .pending: return "Waiting for approval"
        case .approved: return "Verified"
        }
    }

    var icon: String {
        switch self {
        case .none: return "exclamationmark.circle.fill"
        case .pending: return "clock.fill"
        case .approved: return "checkmark.seal.fill"
        }
    }
}

/// An agent asking to join a market center. Leaders approve or decline.
struct JoinRequest: Identifiable, Hashable {
    var id = UUID()
    var agentName: String
    var email: String
    var team: String?
    var requestedAt: Date
}

/// Who a leader is posting as.
enum PostingIdentity: String, CaseIterable, Identifiable {
    case me
    case team
    case office

    var id: String { rawValue }
}

// MARK: - Office content pool

enum OfficeAssetKind: String, CaseIterable, Identifiable, Codable {
    case video
    case photos
    case poster

    var id: String { rawValue }

    var title: String {
        switch self {
        case .video: return "Videos"
        case .photos: return "Listing photos"
        case .poster: return "Posters"
        }
    }

    var icon: String {
        switch self {
        case .video: return "film.fill"
        case .photos: return "photo.on.rectangle.angled"
        case .poster: return "rectangle.portrait.on.rectangle.portrait.fill"
        }
    }
}

/// Content an agent shared with their office. Leaders can remix it into
/// brokerage content, always crediting the agent.
struct OfficeAsset: Identifiable, Hashable {
    var id = UUID()
    var agentName: String
    var kind: OfficeAssetKind
    var title: String
    var listingAddress: String?
    var status: String?
    var createdAt: Date
    var symbol: String
    var paletteIndex: Int
    var imageData: Data? = nil
    var remixCount: Int = 0
}
