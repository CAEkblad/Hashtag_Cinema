import SwiftUI

/// Weekly seller update plus a log of showing feedback from buyer's agents.
struct SellerReportView: View {
    @Environment(CinemaStore.self) private var store
    let listingID: UUID

    @State private var sellerName = ""
    @State private var viewsText = ""
    @State private var showLog = false

    var body: some View {
        if let listing = store.listing(listingID) {
            content(listing)
        } else {
            EmptyStateView(title: "Listing not found", message: "It may have been removed.", icon: "house")
                .cinemaScreen()
        }
    }

    private func content(_ listing: Listing) -> some View {
        let report = ListingCopywriter.sellerReport(for: listing, sellerName: sellerName, agentName: store.profile.name, videoViews: Int(viewsText.filter(\.isNumber)))
        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Seller report")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Sellers who hear from you every week stay happy, even when the market is slow.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack(spacing: 12) {
                    StatTile(value: "\(listing.daysOnMarket)", label: "Days listed", icon: "calendar")
                    StatTile(value: "\(listing.openHouses.reduce(0) { $0 + $1.visitors.count })", label: "OH visitors", icon: "door.left.hand.open")
                    StatTile(value: "\(listing.feedback.count)", label: "Feedback", icon: "text.bubble.fill")
                }

                SectionHeader(title: "Showing feedback", actionTitle: "Log") { showLog = true }
                ShareLink(item: ListingCopywriter.feedbackRequest(for: listing, agentName: store.profile.name)) {
                    Label("Ask a buyer's agent for feedback", systemImage: "paperplane.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
                if listing.feedback.isEmpty {
                    Text("After each showing, text the buyer's agent, then log what they said here. It goes straight into your seller report.")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                        .cardStyle()
                }
                ForEach(listing.feedback) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label(item.interest.title, systemImage: item.interest.icon)
                                .font(.cinema(13, weight: .semibold))
                                .foregroundStyle(item.interest == .hot ? Theme.red : Theme.textPrimary)
                            Spacer()
                            Text(item.date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Text(item.agentName)
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                        if !item.priceOpinion.isEmpty {
                            Text("Price: \(item.priceOpinion)")
                                .font(.cinema(13))
                                .foregroundStyle(Theme.textPrimary)
                        }
                        if !item.comment.isEmpty {
                            Text(item.comment)
                                .font(.cinema(13))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                    .cardStyle()
                }

                SectionHeader(title: "This week's report")
                TextField("Seller's first name", text: $sellerName)
                    .inputStyle()
                TextField("Video views this week (optional)", text: $viewsText)
                    .keyboardType(.numberPad)
                    .inputStyle()
                Text(report)
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                ShareLink(item: report) {
                    Label("Send to my seller", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Seller report")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showLog) {
            LogFeedbackView(listingID: listing.id)
        }
    }
}

struct LogFeedbackView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let listingID: UUID

    @State private var agentName = ""
    @State private var interest: ShowingFeedback.Interest = .maybe
    @State private var priceOpinion = ""
    @State private var comment = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Showing") {
                    TextField("Buyer's agent name", text: $agentName)
                        .textContentType(.name)
                    Picker("Interest", selection: $interest) {
                        ForEach(ShowingFeedback.Interest.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                }
                Section("What they said") {
                    TextField("Price, like \"about right\" or \"a little high\"", text: $priceOpinion)
                    TextField("Comments", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addFeedback(ShowingFeedback(agentName: agentName.trimmingCharacters(in: .whitespaces).isEmpty ? "Buyer's agent" : agentName, date: Date(), interest: interest, priceOpinion: priceOpinion, comment: comment), to: listingID)
                        dismiss()
                    }
                }
            }
        }
    }
}
