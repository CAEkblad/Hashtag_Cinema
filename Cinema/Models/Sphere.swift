import Foundation

/// A client who already closed with the agent. Staying in touch every year is
/// where most repeat and referral business comes from.
struct PastClient: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var address: String
    var cityName: String
    var closeDate: Date
    var side: Testimonial.Side
    var phone: String = ""
    var reminderOn: Bool = false

    var firstName: String { name.split(separator: " ").first.map(String.init) ?? name }

    /// The next time the closing date comes around, today included.
    func nextAnniversary(from now: Date = Date()) -> Date {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.month, .day], from: closeDate)
        let start = max(calendar.startOfDay(for: now).addingTimeInterval(-1), closeDate)
        return calendar.nextDate(after: start, matching: parts, matchingPolicy: .nextTimePreservingSmallerComponents) ?? closeDate
    }

    func daysUntilAnniversary(from now: Date = Date()) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: nextAnniversary(from: now)).day ?? 0
    }

    func yearsAtNextAnniversary(from now: Date = Date()) -> Int {
        max(1, Calendar.current.dateComponents([.year], from: closeDate, to: nextAnniversary(from: now)).year ?? 1)
    }

    var anniversaryLine: String {
        let days = daysUntilAnniversary()
        let years = yearsAtNextAnniversary()
        let label = "\(years) year anniversary"
        switch days {
        case 0: return "\(label) is today"
        case 1: return "\(label) is tomorrow"
        default: return "\(label) in \(days) days"
        }
    }
}

/// A pro the agent trusts and recommends to clients.
struct Vendor: Identifiable, Hashable, Codable {
    enum Category: String, CaseIterable, Identifiable, Codable {
        case lender, inspector, title, insurance, stager, cleaner, handyman, pool, landscaper, movers

        var id: String { rawValue }

        var title: String {
            switch self {
            case .lender: return "Lenders"
            case .inspector: return "Home inspectors"
            case .title: return "Title and closing"
            case .insurance: return "Insurance"
            case .stager: return "Stagers"
            case .cleaner: return "Cleaners"
            case .handyman: return "Handyman and repairs"
            case .pool: return "Pool service"
            case .landscaper: return "Lawn and landscaping"
            case .movers: return "Movers"
            }
        }

        var icon: String {
            switch self {
            case .lender: return "banknote.fill"
            case .inspector: return "magnifyingglass.circle.fill"
            case .title: return "doc.text.fill"
            case .insurance: return "umbrella.fill"
            case .stager: return "sofa.fill"
            case .cleaner: return "sparkles"
            case .handyman: return "hammer.fill"
            case .pool: return "drop.fill"
            case .landscaper: return "leaf.fill"
            case .movers: return "shippingbox.fill"
            }
        }
    }

    var id = UUID()
    var name: String
    var company: String
    var category: Category
    var phone: String = ""
    var email: String = ""
    var note: String = ""

    var contactLine: String { [phone, email].filter { !$0.isEmpty }.joined(separator: " · ") }
}

/// Ready to send texts for past clients.
enum SphereCopy {
    static func anniversary(_ client: PastClient, agentName: String) -> String {
        let me = agentName.split(separator: " ").first.map(String.init) ?? agentName
        let years = client.yearsAtNextAnniversary()
        return "Happy \(years) year home anniversary, \(client.firstName)! I can't believe it's been \(years == 1 ? "a whole year" : "\(years) years") since you got the keys to \(client.address). I hope it's been everything you wanted. If you ever need a recommendation for anything house related, I'm always here. \(me)"
    }

    static func valueCheckIn(_ client: PastClient, agentName: String) -> String {
        let me = agentName.split(separator: " ").first.map(String.init) ?? agentName
        return "Hi \(client.firstName), it's \(me). Homes around \(client.cityName) have been moving, and I was curious how yours would stack up. Want a free, no pressure update on what \(client.address) is worth today? Just reply yes."
    }

    static func referralAsk(agentName: String) -> String {
        let me = agentName.split(separator: " ").first.map(String.init) ?? agentName
        return "Hi! It's \(me). Quick favor: if you hear of anyone thinking about buying or selling this year, I'd be honored if you passed along my name. I'll take great care of them, just like you. Thank you!"
    }
}
