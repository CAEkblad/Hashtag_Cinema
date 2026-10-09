import SwiftUI

/// A monthly email for past clients and the sphere: market, listings, a homeowner tip.
struct NewsletterView: View {
    @Environment(CinemaStore.self) private var store
    @State private var includeMarket = true
    @State private var includeListings = true
    @State private var includeTip = true
    @State private var includeEvents = true
    @State private var medianPrice = ""
    @State private var daysOnMarket = ""
    @State private var personalNote = ""

    private var month: Int { Calendar.current.component(.month, from: Date()) }
    private var monthName: String { Date().formatted(.dateTime.month(.wide)) }

    /// Florida homeowner reminders, one per month.
    static func homeownerTip(month: Int) -> String {
        switch month {
        case 1: return "Property tax bills paid in January still get a 2% discount. Pay by January 31."
        case 2: return "Bought a home last year? File for your homestead exemption with the county property appraiser by March 1."
        case 3: return "Book your AC tune up now, before the summer rush. A clean filter every month saves real money."
        case 4: return "Spring is the time to check your roof, gutters and screens before the rainy season."
        case 5: return "Hurricane season starts June 1. Restock water, batteries and meds, and photograph your home for insurance."
        case 6: return "Hurricane season is here. Review your policy and know your evacuation zone."
        case 7: return "Summer storms are daily now. Clear gutters and check that your sump and drains are flowing."
        case 8: return "Your TRIM notice arrives this month. It shows your proposed property taxes and how to appeal."
        case 9: return "September is peak hurricane season. Trim trees away from the roof and secure loose patio items."
        case 10: return "Cooler weather is perfect for pressure washing, sealing pavers and repainting the front door."
        case 11: return "Property tax bills arrive this month. Pay in November and you get a 4% discount."
        default: return "Hurricane season ended November 30. Now is a great time to schedule your wind mitigation inspection."
        }
    }

    private var events: [String] {
        FloridaCalendar.moments(month: month, city: store.homeCity)
            .filter { $0.id.contains("-event-") }
            .map(\.title)
    }

    private var listings: [Listing] {
        store.listings.filter { $0.status == .active || $0.status == .comingSoon }
    }

    private var newsletter: String {
        var lines = ["\(monthName) in \(store.homeCity.name)", ""]
        let note = personalNote.trimmingCharacters(in: .whitespacesAndNewlines)
        lines.append(note.isEmpty ? "Hi friends! Here's what's happening in our market this month." : note)
        if includeMarket, !medianPrice.isEmpty || !daysOnMarket.isEmpty {
            lines += ["", "MARKET IN A MINUTE"]
            if !medianPrice.isEmpty { lines.append("Median sale price: \(medianPrice)") }
            if !daysOnMarket.isEmpty { lines.append("Average days on market: \(daysOnMarket)") }
            lines.append("Curious what your home is worth today? Reply and I'll send a free update.")
        }
        if includeListings, !listings.isEmpty {
            lines += ["", "HOMES I'M LISTING"]
            lines += listings.map { "- \($0.address): \($0.priceLabel), \($0.specsLine) (\($0.status.title))" }
        }
        if includeEvents, !events.isEmpty {
            lines += ["", "AROUND TOWN"]
            lines += events.prefix(3).map { "- \($0)" }
        }
        if includeTip {
            lines += ["", "HOMEOWNER TIP", Self.homeownerTip(month: month)]
        }
        lines += ["", "The best compliment I can get is a referral. If someone you know is thinking about buying or selling, I'd love to help.", "", store.profile.name]
        if !store.brandKit.phone.isEmpty { lines.append(store.brandKit.phone) }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(monthName) newsletter")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("One email a month keeps you top of mind with everyone you know. We fill it in, you hit send.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    TextField("A personal note to start (optional)", text: $personalNote, axis: .vertical)
                        .lineLimit(2...4)
                    Toggle("Market in a minute", isOn: $includeMarket)
                    if includeMarket {
                        TextField("Median price, like $415,000", text: $medianPrice)
                        TextField("Days on market, like 38", text: $daysOnMarket)
                            .keyboardType(.numberPad)
                    }
                    Toggle("My listings (\(listings.count))", isOn: $includeListings)
                    Toggle("Around town\(events.isEmpty ? " (nothing this month)" : "")", isOn: $includeEvents)
                    Toggle("Homeowner tip", isOn: $includeTip)
                }
                .font(.cinema(14))
                .tint(Theme.red)
                .cardStyle()

                Text(newsletter)
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                ShareLink(item: newsletter, subject: Text("\(monthName) in \(store.homeCity.name)")) {
                    Label("Send by email or text", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("Use your own market numbers from the MLS. Only email people who've agreed to hear from you.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Newsletter")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }
}
