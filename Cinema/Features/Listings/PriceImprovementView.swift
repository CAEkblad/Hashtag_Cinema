import SwiftUI
import UIKit

/// Everything to send the day a listing's price drops: update the price, then
/// tell the people who already showed interest before anyone else.
struct PriceImprovementView: View {
    @Environment(CinemaStore.self) private var store
    let listingID: UUID

    @State private var newPrice = ""
    @State private var applied = false
    @State private var oldPrice = 0
    @State private var copied: String?

    private var listing: Listing? { store.listing(listingID) }

    private var priceValue: Int? {
        let digits = newPrice.filter(\.isNumber)
        guard let value = Int(digits), value > 1000 else { return nil }
        return value
    }

    var body: some View {
        ScrollView {
            if let listing {
                content(listing)
            }
        }
        .cinemaScreen()
        .navigationTitle("Price improvement")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            if oldPrice == 0, let listing { oldPrice = listing.price }
        }
    }

    @ViewBuilder
    private func content(_ listing: Listing) -> some View {
        let street = listing.address.split(separator: ",").first.map(String.init) ?? listing.address
        let price = applied ? listing.price : (priceValue ?? listing.price)
        let drop = max(0, oldPrice - price)
        let percent = oldPrice > 0 ? Double(drop) / Double(oldPrice) * 100 : 0
        let priceLabel = price.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        let dropLabel = drop.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        let first = store.profile.name.split(separator: " ").first.map(String.init) ?? store.profile.name
        let hotAgents = listing.feedback.filter { $0.interest != .pass }
        let visitors = listing.openHouses.flatMap(\.visitors).filter { !$0.workingWithAgent && !$0.phone.isEmpty }

        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Price improvement")
                    .font(.cinema(26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("A new price is a second launch. Tell the people who already liked \(street) first, then everyone else.")
                    .font(.cinema(14))
                    .foregroundStyle(Theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Was").font(.cinema(12, weight: .semibold)).foregroundStyle(Theme.textTertiary)
                        Text(oldPrice.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                            .font(.cinema(17, weight: .bold))
                            .strikethrough(drop > 0)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right").foregroundStyle(Theme.textTertiary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Now").font(.cinema(12, weight: .semibold)).foregroundStyle(Theme.textTertiary)
                        Text(priceLabel)
                            .font(.cinema(20, weight: .heavy))
                            .foregroundStyle(Theme.red)
                    }
                }
                if !applied {
                    TextField("New price, like \(max(oldPrice - 15_000, 0))", text: $newPrice)
                        .keyboardType(.numberPad)
                        .inputStyle()
                }
                if drop > 0 {
                    Text("\(dropLabel) less (\(percent.formatted(.number.precision(.fractionLength(1))))%). \(listing.daysOnMarket) days on market.")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                if applied {
                    Label("Listing updated to \(priceLabel)", systemImage: "checkmark.circle.fill")
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(Theme.success)
                } else {
                    Button {
                        guard let value = priceValue, var updated = store.listing(listingID) else { return }
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        updated.price = value
                        store.updateListing(updated)
                        applied = true
                        store.showToast("Price updated")
                    } label: {
                        Label("Update the listing", systemImage: "arrow.down.circle.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(priceValue == nil || (priceValue ?? 0) >= oldPrice)
                    Text("Update the MLS first. This changes the price in CloseUp so posters, flyers and reels use it.")
                        .font(.cinema(11))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .cardStyle()

            if drop > 0 {
                message(
                    title: "1. Buyer's agents who showed it",
                    subtitle: hotAgents.isEmpty ? "No showing feedback logged yet. Send to agents who toured it." : "\(hotAgents.count) said they were interested: \(hotAgents.map(\.agentName).prefix(3).joined(separator: ", "))",
                    text: "Hi! Thanks again for showing \(street). Wanted you to hear it first: the sellers just improved the price to \(priceLabel). If your buyers are still looking, now's a great time for a second look. Happy to set it up. \(first)"
                )
                message(
                    title: "2. Open house visitors",
                    subtitle: visitors.isEmpty ? "No unrepresented visitors with a phone number yet." : "\(visitors.count) visitor\(visitors.count == 1 ? "" : "s") without an agent",
                    text: "Hi! It's \(first). You came by the open house at \(street). The price just dropped to \(priceLabel), and I thought you'd want to know before it goes out everywhere. Want to see it again this week?"
                )
                message(
                    title: "3. Your post",
                    subtitle: "Pair it with a Price improved poster",
                    text: "\u{1F6A8} Price improved: \(street) is now \(priceLabel). \(listing.specsLine)\(listing.features.first.map { " with \($0.phrase)" } ?? ""). Comment TOUR and I'll send you the details and times. #priceimproved #\(listing.city?.name.filter(\.isLetter).lowercased() ?? "florida")realestate"
                )
                message(
                    title: "4. Seller update",
                    subtitle: "So they know the plan",
                    text: "The new price of \(priceLabel) is live. Today I'm sending it to every agent who showed the home and every open house visitor, posting it, and refreshing the listing photos at the top of the feed. I'll send you the showing activity at the end of the week."
                )

                NavigationLink(value: Route.listingPoster(listingID)) {
                    IconRow(icon: "rectangle.portrait.on.rectangle.portrait.fill", title: "Make the Price improved poster", subtitle: "Pick Price improved in the poster maker")
                        .cardStyle(padding: 14)
                }
                .buttonStyle(.plain)
                NavigationLink(value: Route.storyPack(listingID)) {
                    IconRow(icon: "rectangle.stack.fill", title: "Post the story pack again", subtitle: "Guess the price works even better after a drop")
                        .cardStyle(padding: 14)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.gutter)
    }

    private func message(title: String, subtitle: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.cinema(15, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(subtitle)
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
            Text(text)
                .font(.cinema(14))
                .foregroundStyle(Theme.textPrimary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            HStack(spacing: 16) {
                Button {
                    UIPasteboard.general.string = text
                    copied = title
                } label: {
                    Label(copied == title ? "Copied" : "Copy", systemImage: copied == title ? "checkmark" : "doc.on.doc")
                        .font(.cinema(14, weight: .semibold))
                }
                ShareLink(item: text) {
                    Label("Send", systemImage: "paperplane.fill")
                        .font(.cinema(14, weight: .semibold))
                }
            }
            .tint(Theme.red)
        }
        .cardStyle()
    }
}
