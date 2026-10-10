import SwiftUI

/// Agents helping agents: homes shared before they hit the portals, and buyers
/// looking for homes. Not a referral board: you keep your client and find them the house.
struct AgentNetworkView: View {
    @Environment(CinemaStore.self) private var store
    @State private var tab: Tab = .homes
    @State private var query = ""
    @State private var status: NetworkListing.Status?
    @State private var showShare = false
    @State private var showNeed = false

    enum Tab: String, CaseIterable, Identifiable {
        case homes = "Homes"
        case buyers = "Buyers looking"
        var id: String { rawValue }
    }

    private var homes: [NetworkListing] {
        store.networkListings.filter { listing in
            let q = query.trimmingCharacters(in: .whitespaces).lowercased()
            let matchesQuery = q.isEmpty || listing.place.lowercased().contains(q) || listing.address.lowercased().contains(q) || listing.state.lowercased() == q
            return matchesQuery && (status == nil || listing.status == status)
        }
        .sorted { lhs, rhs in
            let l = GemScore.score(lhs, for: nil, myOffice: store.myOfficeName, kwMode: store.lex.isKW).score
            let r = GemScore.score(rhs, for: nil, myOffice: store.myOfficeName, kwMode: store.lex.isKW).score
            return l > r
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Agent network")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Coming soon and off market homes from agents across the country, plus buyers other agents are working with. Find your client the house, or find your listing a buyer.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                if store.lex.isKW {
                    let kwHomes = store.networkListings.filter { $0.isKW && !$0.isMine }.count
                    let kwBuyers = store.buyerNeeds.filter(\.isKW).count
                    IconRow(icon: "arrow.left.arrow.right.circle.fill", title: "KW to KW: \(kwHomes) homes, \(kwBuyers) buyers", subtitle: "When both sides are KW associates, the whole deal stays in the KW family. We rank those matches higher.")
                        .cardStyle()
                }

                Picker("Show", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                if tab == .homes {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundStyle(Theme.textTertiary)
                        TextField("City or state, like Orlando or GA", text: $query)
                            .autocorrectionDisabled()
                    }
                    .inputStyle()

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chip("All", isOn: status == nil) { status = nil }
                            ForEach(NetworkListing.Status.allCases) { option in
                                chip(option.title, isOn: status == option) { status = option }
                            }
                        }
                    }

                    Button {
                        showShare = true
                    } label: {
                        Label("Share one of my listings", systemImage: "square.and.arrow.up.on.square")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    ForEach(homes) { listing in
                        NetworkListingCard(listing: listing, gem: GemScore.score(listing, for: nil, myOffice: store.myOfficeName, kwMode: store.lex.isKW))
                    }
                } else {
                    Button {
                        showNeed = true
                    } label: {
                        Label("Post a buyer I'm working with", systemImage: "person.fill.questionmark")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    ForEach(store.buyerNeeds) { need in
                        buyerNeedCard(need)
                    }
                }

                Text("Sample network until the backend is live. Share only what your seller has approved, and follow your MLS's rules for coming soon and off market listings.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Agent network")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShare) { ShareToNetworkView() }
        .sheet(isPresented: $showNeed) { PostBuyerNeedView() }
    }

    private func buyerNeedCard(_ need: BuyerNeedPost) -> some View {
        let isMine = store.myBuyerNeeds.contains { $0.id == need.id }
        let fits = isMine ? [] : store.listings.filter { listing in
            listing.status != .sold && listing.price <= need.maxPrice && listing.beds >= need.minBeds && need.mustHaves.allSatisfy { listing.features.contains($0) }
        }
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(need.cityName) · up to \(Double(need.maxPrice).compactMoney) · \(need.minBeds)+ beds")
                    .font(.cinema(15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if store.lex.isKW && need.isKW {
                    Pill(text: "KW", color: Theme.redSoft, textColor: Theme.red)
                }
            }
            if !need.mustHaves.isEmpty {
                Text("Must have: " + need.mustHaves.map(\.title).joined(separator: ", "))
                    .font(.cinema(12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            Text(need.note)
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)
            Text("\(need.agentName) · \(need.brokerage)")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
            if isMine {
                Label("Your post", systemImage: "person.crop.circle.fill")
                    .font(.cinema(12, weight: .semibold))
                    .foregroundStyle(Theme.red)
            } else if need.brokerage == store.myOfficeName {
                Label(store.lex.inHouse.prefix(1).uppercased() + store.lex.inHouse.dropFirst(), systemImage: "building.2.fill")
                    .font(.cinema(12, weight: .semibold))
                    .foregroundStyle(Theme.success)
            }
            if !fits.isEmpty {
                ShareLink(item: "Hi \(need.agentName.split(separator: " ").first.map(String.init) ?? need.agentName)! Saw your buyer on #Cinema. I have \(fits.map { "\($0.address) (\($0.priceLabel))" }.joined(separator: " and ")) that could fit. Want to set up a showing? \(store.profile.name)") {
                    Label("I have \(fits.count) that fit\(fits.count == 1 ? "s" : "")", systemImage: "house.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .cardStyle()
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(isOn ? .white : Theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isOn ? Theme.red : Theme.surface, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct NetworkListingCard: View {
    @Environment(CinemaStore.self) private var store
    let listing: NetworkListing
    let gem: GemScore
    var selectable = false
    var isSelected = false
    var onToggle: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Pill(text: listing.status.title, color: listing.status == .active ? Theme.surfaceRaised : Theme.redSoft, textColor: listing.status == .active ? Theme.textPrimary : Theme.red)
                        if gem.isGem {
                            Pill(text: "Hidden gem", icon: "sparkles", color: Theme.red, textColor: .white)
                        }
                    }
                    Text(listing.address)
                        .font(.cinema(16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(listing.place) · \(listing.specs)")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(listing.priceLabel)
                        .font(.cinema(16, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                    if selectable {
                        Button {
                            onToggle?()
                        } label: {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundStyle(isSelected ? Theme.red : Theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if !gem.reasons.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(gem.reasons.prefix(4), id: \.self) { reason in
                        Label(reason, systemImage: "checkmark.seal.fill")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            HStack {
                Text(listing.isMine ? "Your listing" : "\(listing.agentName) · \(listing.brokerage)")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                Spacer()
                if !listing.isMine {
                    ShareLink(item: "Hi \(listing.agentName.split(separator: " ").first.map(String.init) ?? listing.agentName)! I have a buyer who'd love to see \(listing.address). Is it still available, and when can we show it? \(store.profile.name)") {
                        Label("I have a buyer", systemImage: "paperplane.fill")
                            .font(.cinema(12, weight: .semibold))
                            .foregroundStyle(Theme.red)
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct ShareToNetworkView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var listingID: UUID?
    @State private var status: NetworkListing.Status = .comingSoon
    @State private var remarks = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Which listing") {
                    let mine = store.listings.filter { $0.status != .sold }
                    if mine.isEmpty {
                        Text("Add a listing first.")
                    }
                    ForEach(mine) { listing in
                        Button {
                            listingID = listing.id
                        } label: {
                            HStack {
                                Text(listing.address)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                if listingID == listing.id { Image(systemName: "checkmark").foregroundStyle(Theme.red) }
                            }
                        }
                    }
                }
                Section {
                    Picker("Share as", selection: $status) {
                        ForEach(NetworkListing.Status.allCases) { Text($0.title).tag($0) }
                    }
                    TextField("Note for agents, like 'seller wants a 45 day close'", text: $remarks, axis: .vertical)
                        .lineLimit(2...4)
                } footer: {
                    Text("Only agents on #Cinema see this. Get your seller's OK first, and follow your MLS rules.")
                }
            }
            .navigationTitle("Share with agents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        if let listingID { store.shareToNetwork(listingID, status: status, remarks: remarks) }
                        dismiss()
                    }
                    .disabled(listingID == nil)
                }
            }
        }
    }
}

struct PostBuyerNeedView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var buyerID: UUID?
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Which buyer") {
                    if store.buyers.isEmpty { Text("Add a buyer wishlist first.") }
                    ForEach(store.buyers) { buyer in
                        Button {
                            buyerID = buyer.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(buyer.name).foregroundStyle(Theme.textPrimary)
                                    Text(buyer.summary).font(.cinema(12)).foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                if buyerID == buyer.id { Image(systemName: "checkmark").foregroundStyle(Theme.red) }
                            }
                        }
                    }
                }
                Section {
                    TextField("Note, like 'preapproved, can close in 30 days'", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                } footer: {
                    Text("Agents see what your buyer wants, not their name or contact details.")
                }
            }
            .navigationTitle("Post a buyer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        if let buyerID { store.postBuyerNeed(buyerID, note: note) }
                        dismiss()
                    }
                    .disabled(buyerID == nil)
                }
            }
        }
    }
}
