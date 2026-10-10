import SwiftUI

/// The agent's partner office (a KW market center): connection status, join
/// code, office sharing and, for leaders, approvals and the revenue share.
struct MarketCenterView: View {
    @Environment(CinemaStore.self) private var store
    @State private var code = ""
    @State private var showPicker = false

    private var partner: Partner { store.partner ?? .kellerWilliams }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if store.partner != nil { partnerCard }
                connectionCard
                sharingCard
                if store.isLeader {
                    revenueCard
                    requestsSection
                    NavigationLink(value: Route.officeContent) {
                        IconRow(icon: "square.stack.3d.up.fill", title: "Office content pool", subtitle: "\(store.officeAssets.count) videos, photos and posters from your agents")
                            .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle(partner.officeTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPicker) {
            MarketCenterPickerView(partner: partner)
        }
    }

    private var partnerCard: some View {
        HStack(spacing: 14) {
            Text(partner.shortName)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Theme.red, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("\(partner.name) agent")
                    .font(.cinema(17, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(store.profile.email)
                    .font(.cinema(14, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Text("\(partner.signupDiscountPercent)% off every plan and credit pack")
                    .font(.cinema(12, weight: .semibold))
                    .foregroundStyle(Theme.red)
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your \(partner.officeWord)")
                    .font(.cinema(12, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Pill(text: store.profile.membership.title, icon: store.profile.membership.icon,
                     color: store.profile.membership == .approved ? Theme.success.opacity(0.15) : Theme.redSoft,
                     textColor: store.profile.membership == .approved ? Theme.success : Theme.red)
            }
            if let center = store.myMarketCenter {
                Text(center.name)
                    .font(.cinema(20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text([center.city?.displayName, center.group, "\(center.agentCount) agents"].compactMap { $0 }.joined(separator: " · "))
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)
                if store.profile.membership == .pending {
                    Text("Your \(partner.officeWord) leader will approve you. Have a join code? Enter it below to connect now.")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                }
            } else {
                Text("Connect to your \(partner.officeWord) so your office gets credit for your work and you see office challenges.")
                    .font(.cinema(14))
                    .foregroundStyle(Theme.textSecondary)
            }

            if store.profile.membership != .approved {
                HStack(spacing: 10) {
                    TextField("Join code from your \(store.lex.officeLeader)", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .inputStyle()
                    Button("Join") {
                        if store.joinMarketCenter(code: code) { code = "" }
                    }
                    .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                    .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Button(store.myMarketCenter == nil ? "Find my \(partner.officeWord)" : "Change \(partner.officeWord)") {
                showPicker = true
            }
            .buttonStyle(SecondaryButtonStyle())

            if store.marketCenters.contains(where: \.isSample) {
                Text("Demo: these are sample \(store.lex.offices). Try code TAMPA1. Your real list loads from the #Cinema admin.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .cardStyle()
    }

    private var sharingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(get: { store.profile.sharesWithOffice }, set: { store.setSharesWithOffice($0) })) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Share my listing content with my office")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Listing videos, photos and posters go to the office pool. Leaders can feature them, always crediting you.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .tint(Theme.red)
        }
        .cardStyle()
    }

    private var revenueCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Revenue share this month")
                .font(.cinema(12, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
            Text(store.revenueShareThisMonth.formatted(.currency(code: "USD")))
                .font(.cinema(34, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("\(partner.revenueSharePercent)% of \(store.officeRevenueThisMonth.formatted(.currency(code: "USD"))) spent by \(store.brokerageMembers.filter { $0.monthlySpend > 0 }.count) connected agents. Paid to the \(partner.officeWord) monthly.")
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)
            NavigationLink(value: Route.brokerage) {
                Text("See agents")
                    .font(.cinema(14, weight: .semibold))
                    .foregroundStyle(Theme.red)
            }
        }
        .cardStyle()
    }

    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Join requests")
            if store.joinRequests.isEmpty {
                Text("No one is waiting. Share your join code at your next team meeting.")
                    .font(.cinema(14))
                    .foregroundStyle(Theme.textSecondary)
                    .cardStyle()
            }
            ForEach(store.joinRequests) { request in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Avatar(initials: String(request.agentName.split(separator: " ").compactMap(\.first)).uppercased(), size: 40, paletteIndex: request.agentName.count)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(request.agentName)
                                .font(.cinema(15, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text([request.email, request.team].compactMap { $0 }.joined(separator: " · "))
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                    }
                    HStack(spacing: 10) {
                        Button("Approve") { store.approve(request) }
                            .buttonStyle(PrimaryButtonStyle())
                        Button("Not ours") { store.decline(request) }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .cardStyle()
            }
        }
    }
}

/// Search the partner's offices, nearest to the agent's city first.
struct MarketCenterPickerView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let partner: Partner
    @State private var query = ""
    @State private var customName = ""

    private var results: [MarketCenter] {
        let near = store.marketCenters(near: store.homeCity, partner: partner)
        guard !query.isEmpty else { return near }
        return near.filter { $0.name.localizedCaseInsensitiveContains(query) || ($0.city?.name.localizedCaseInsensitiveContains(query) ?? false) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(results) { center in
                        Button {
                            store.requestMarketCenter(center)
                            dismiss()
                        } label: {
                            MarketCenterRow(center: center, isSelected: center.id == store.profile.marketCenterID)
                        }
                    }
                } footer: {
                    Text("Picking one sends a request to its leader. A join code connects you instantly.")
                }
                .listRowBackground(Theme.surface)

                Section("Not listed?") {
                    TextField("\(partner.officeTitle) name", text: $customName)
                    Button("Ask #Cinema to add it") {
                        store.showToast("Thanks. We will add \(customName) and connect you.")
                        dismiss()
                    }
                    .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .listRowBackground(Theme.surface)
            }
            .cinemaScreen()
            .searchable(text: $query, prompt: "Search \(partner.officeWord)s")
            .navigationTitle("Find your \(partner.officeWord)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct MarketCenterRow: View {
    let center: MarketCenter
    var isSelected = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2.fill")
                .foregroundStyle(Theme.red)
                .frame(width: 32, height: 32)
                .background(Theme.redSoft, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(center.name)
                    .font(.cinema(15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text([center.city?.displayName, "\(center.agentCount) agents"].compactMap { $0 }.joined(separator: " · "))
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.red)
            }
        }
        .contentShape(Rectangle())
    }
}
