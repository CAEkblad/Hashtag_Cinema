import SwiftUI
import UIKit

/// Listing check up: how it's doing, what buyers are saying, what to do next
/// and what to tell the seller.
struct ListingHealthView: View {
    @Environment(CinemaStore.self) private var store
    let listingID: UUID
    @State private var sellerName = ""

    var body: some View {
        Group {
            if let listing = store.listing(listingID) {
                content(ListingHealth(listing: listing, openHouseVisitors: listing.openHouses.reduce(0) { $0 + $1.visitors.count }))
            } else {
                EmptyStateView(title: "Listing not found", message: "It may have been removed.", icon: "house")
            }
        }
        .cinemaScreen()
        .navigationTitle("Listing check up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ health: ListingHealth) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Label(health.verdict.title, systemImage: health.verdict.icon)
                        .font(.cinema(20, weight: .bold))
                        .foregroundStyle(color(health.verdict))
                    Text(health.summary)
                        .font(.cinema(15))
                        .foregroundStyle(Theme.textPrimary)
                }
                .cardStyle()

                HStack(spacing: 10) {
                    StatTile(value: "\(health.days)", label: "days on market", icon: "calendar")
                    StatTile(value: "\(health.showings)", label: "showings logged", icon: "key.fill")
                    StatTile(value: "\(health.openHouseVisitors)", label: "open house visitors", icon: "house.fill")
                }

                if health.showings > 0 {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "What buyers are saying")
                        HStack(spacing: 8) {
                            interestBar("Very interested", count: health.hot, total: health.showings, color: Theme.success)
                            interestBar("Maybe", count: health.maybe, total: health.showings, color: Theme.warning)
                            interestBar("Passed", count: health.pass, total: health.showings, color: Theme.red)
                        }
                        if health.priceObjections > 0 {
                            Label("\(health.priceObjections) of \(health.showings) mentioned price", systemImage: "tag.fill")
                                .font(.cinema(13, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        ForEach(health.listing.feedback.sorted { $0.date > $1.date }.prefix(3)) { item in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.comment.isEmpty ? item.interest.title : "\u{201C}\(item.comment)\u{201D}")
                                    .font(.cinema(14))
                                    .foregroundStyle(Theme.textPrimary)
                                Text([item.agentName, item.priceOpinion.isEmpty ? nil : "Price: \(item.priceOpinion)", item.date.formatted(date: .abbreviated, time: .omitted)].compactMap { $0 }.joined(separator: " · "))
                                    .font(.cinema(12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .cardStyle(padding: 12)
                        }
                    }
                } else {
                    NavigationLink(value: Route.sellerReport(health.listing.id)) {
                        IconRow(icon: "plus.bubble.fill", title: "Log showing feedback", subtitle: "The check up gets smarter with every showing you log")
                            .cardStyle(padding: 14)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Do this next")
                    ForEach(Array(health.nextSteps.enumerated()), id: \.offset) { _, step in
                        if let route = step.route {
                            NavigationLink(value: route) {
                                IconRow(icon: step.icon, title: step.title, subtitle: step.detail)
                                    .cardStyle(padding: 14)
                            }
                            .buttonStyle(.plain)
                        } else {
                            IconRow(icon: step.icon, title: step.title, subtitle: step.detail)
                                .cardStyle(padding: 14)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Tell your seller")
                    TextField("Seller's first name", text: $sellerName)
                        .textInputAutocapitalization(.words)
                        .padding(12)
                        .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    let script = health.sellerScript(sellerName: sellerName.trimmingCharacters(in: .whitespaces).isEmpty ? "[name]" : sellerName.trimmingCharacters(in: .whitespaces), agentName: store.profile.name)
                    Text(script)
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                        .textSelection(.enabled)
                    HStack(spacing: 10) {
                        ShareLink(item: script) {
                            Label("Send", systemImage: "paperplane.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        Button {
                            UIPasteboard.general.string = script
                            store.showToast("Copied")
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .cardStyle()

                Text("The check up only uses what you've logged in CloseUp. Your local market and your seller's goals matter more than any rule of thumb.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
    }

    private func interestBar(_ title: String, count: Int, total: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(count)")
                .font(.cinema(20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceRaised)
                    Capsule().fill(color).frame(width: proxy.size.width * (total == 0 ? 0 : CGFloat(count) / CGFloat(total)))
                }
            }
            .frame(height: 6)
            Text(title)
                .font(.cinema(11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 12)
    }

    private func color(_ verdict: ListingHealth.Verdict) -> Color {
        switch verdict {
        case .tooEarly: return Theme.textSecondary
        case .onTrack, .offerReady: return Theme.success
        case .needsExposure: return Theme.warning
        case .priceConversation: return Theme.red
        }
    }
}
