import SwiftUI

/// Every home in reach, ranked for one buyer by what a portal filter misses:
/// value, motivated sellers, price cuts and homes that aren't public yet.
struct HiddenGemsView: View {
    @Environment(CinemaStore.self) private var store
    let buyerID: UUID
    @State private var picked: Set<UUID> = []
    @State private var showAll = false

    var body: some View {
        if let buyer = store.buyers.first(where: { $0.id == buyerID }) {
            content(buyer)
        } else {
            EmptyStateView(title: "Buyer not found", message: "They may have been removed.", icon: "person")
                .cinemaScreen()
        }
    }

    private func content(_ buyer: BuyerWish) -> some View {
        let ranked = store.gemMatches(for: buyer)
        let shown = showAll ? ranked : ranked.filter { $0.gem.score >= 40 }
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hidden gems for \(buyer.firstName)")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("We checked every home on the agent network and your own listings for value, motivated sellers, price cuts and homes that aren't on the portals yet. Then we ranked them for \(buyer.firstName): \(buyer.summary).")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack(spacing: 12) {
                    StatTile(value: "\(ranked.count)", label: "Homes checked", icon: "magnifyingglass")
                    StatTile(value: "\(ranked.filter { $0.gem.isGem }.count)", label: "Hidden gems", icon: "sparkles")
                    StatTile(value: "\(ranked.filter { $0.listing.status != .active }.count)", label: "Not public yet", icon: "eye.slash.fill")
                }

                if shown.isEmpty {
                    Text("Nothing strong yet. Widen the budget or cities on the wishlist, or check back as agents share new homes.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                        .cardStyle()
                }

                ForEach(shown, id: \.listing.id) { match in
                    NetworkListingCard(listing: match.listing, gem: match.gem, selectable: true, isSelected: picked.contains(match.listing.id)) {
                        if picked.contains(match.listing.id) { picked.remove(match.listing.id) } else { picked.insert(match.listing.id) }
                    }
                }

                if showAll || ranked.count > shown.count {
                    Button(showAll ? "Show the best only" : "Show all \(ranked.count) homes") { showAll.toggle() }
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(Theme.red)
                }

                ShareLink(item: picks(buyer, ranked: ranked)) {
                    Label(picked.isEmpty ? "Pick homes to send" : "Send \(picked.count) pick\(picked.count == 1 ? "" : "s") to \(buyer.firstName)", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(picked.isEmpty)

                Text("Scores look at price per square foot against the area, days on market, price cuts, words in the remarks and whether a home is public yet. Always check the details with the listing agent.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Hidden gems")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func picks(_ buyer: BuyerWish, ranked: [(listing: NetworkListing, gem: GemScore)]) -> String {
        var lines = ["Hi \(buyer.firstName)! I went through everything I could find and pulled the ones worth your time:", ""]
        for match in ranked where picked.contains(match.listing.id) {
            lines.append("\(match.listing.address), \(match.listing.place): \(match.listing.priceLabel), \(match.listing.specs)")
            lines += match.gem.reasons.filter { !$0.hasPrefix("In-house") && !$0.hasPrefix("KW to KW") }.prefix(3).map { "  - \($0)" }
            lines.append("")
        }
        lines.append("Some of these aren't on Zillow yet. Want to see any of them this week? \(store.profile.firstName)")
        return lines.joined(separator: "\n")
    }
}
