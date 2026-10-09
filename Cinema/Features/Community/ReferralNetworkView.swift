import SwiftUI

/// Agent to agent referrals across Florida. Find a trusted agent in any city,
/// send your client with the fee agreed up front, and track it to closing.
struct ReferralNetworkSection: View {
    @Environment(CinemaStore.self) private var store
    @State private var query = ""
    @State private var sendTo: NetworkAgent?

    private var cityMatches: [FloridaCity] {
        query.trimmingCharacters(in: .whitespaces).isEmpty ? [] : FloridaMarkets.search(query, limit: 4)
    }

    private var agents: [NetworkAgent] {
        guard let city = cityMatches.first else {
            return Array(store.networkAgents.filter { $0.cityID != store.homeCity.id }.prefix(6))
        }
        return store.networkAgents(near: city)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                StatTile(value: "\(store.agentReferrals.filter { !$0.isIncoming }.count)", label: "Sent", icon: "arrow.up.right")
                StatTile(value: "\(store.agentReferrals.filter(\.isIncoming).count)", label: "Received", icon: "arrow.down.left")
                StatTile(value: "\(store.agentReferrals.filter { $0.status == .closed }.count)", label: "Closed", icon: "checkmark.seal.fill")
            }

            if !store.agentReferrals.isEmpty {
                SectionHeader(title: "Your referrals")
                ForEach(store.agentReferrals) { referral in
                    referralCard(referral)
                }
            }

            SectionHeader(title: "Find an agent in another city")
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.textTertiary)
                TextField("City, like Orlando or Naples", text: $query)
                    .autocorrectionDisabled()
            }
            .inputStyle()

            if let city = cityMatches.first {
                Text("Agents in and near \(city.name)")
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }

            ForEach(agents) { agent in
                agentCard(agent)
            }

            Text("Sample network until the backend is live. Referral agreements are between agents and their brokers.")
                .font(.cinema(11))
                .foregroundStyle(Theme.textTertiary)
        }
        .sheet(item: $sendTo) { agent in
            SendReferralView(agent: agent)
        }
    }

    private func agentCard(_ agent: NetworkAgent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Avatar(initials: agent.initials, size: 44, paletteIndex: agent.name.count)
                VStack(alignment: .leading, spacing: 2) {
                    Text(agent.name)
                        .font(.cinema(16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(agent.city?.name ?? "") · \(agent.brokerage)")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Label(String(format: "%.1f", agent.rating), systemImage: "star.fill")
                        .font(.cinema(12, weight: .bold))
                        .foregroundStyle(Theme.warning)
                    Text("\(agent.closedReferrals) closed")
                        .font(.cinema(11))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            FlowLayout(spacing: 6) {
                ForEach(agent.specialties + (agent.languages.count > 1 ? ["Habla español"] : []), id: \.self) { tag in
                    Pill(text: tag)
                }
            }
            Button {
                sendTo = agent
            } label: {
                Label("Send a referral", systemImage: "arrow.up.right.circle.fill")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .cardStyle()
    }

    private func referralCard(_ referral: AgentReferral) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(referral.isIncoming ? "From \(referral.otherAgentName)" : "To \(referral.otherAgentName)", systemImage: referral.isIncoming ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(referral.isIncoming ? Theme.success : Theme.red)
                Spacer()
                Pill(text: referral.status.title)
            }
            Text("\(referral.clientName) · \(referral.side.title) in \(referral.city?.name ?? "") · \(referral.priceRange)")
                .font(.cinema(15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            if !referral.notes.isEmpty {
                Text(referral.notes)
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Text("\(referral.feePercent)% referral fee")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
            if referral.isIncoming && referral.status == .sent {
                HStack(spacing: 10) {
                    Button("Accept") { store.acceptReferral(referral.id) }
                        .buttonStyle(PrimaryButtonStyle())
                    Button("Pass") { store.declineReferral(referral.id) }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .cardStyle()
    }
}

/// Full screen version, reachable from search and notifications.
struct ReferralNetworkScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Agent referrals")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Client moving to another Florida city? Send them to a trusted agent and earn a referral fee.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }
                ReferralNetworkSection()
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Referrals")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }
}

struct SendReferralView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let agent: NetworkAgent

    @State private var clientName = ""
    @State private var side: AgentReferral.Side = .buyer
    @State private var priceRange = "$300K to $450K"
    @State private var notes = ""
    @State private var fee = 25

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Avatar(initials: agent.initials, size: 40, paletteIndex: agent.name.count)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(agent.name).font(.cinema(16, weight: .semibold))
                            Text("\(agent.city?.displayName ?? "") · \(agent.brokerage)")
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                Section("Client") {
                    TextField("Client's name", text: $clientName)
                    Picker("They're a", selection: $side) {
                        ForEach(AgentReferral.Side.allCases) { Text($0.title).tag($0) }
                    }
                    TextField("Price range", text: $priceRange)
                    TextField("Timeline, needs, how to reach them", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    Stepper("\(fee)% referral fee", value: $fee, in: 10...50, step: 5)
                } footer: {
                    Text("Ask your client first, and have both brokers sign the referral agreement before you share contact details.")
                }
            }
            .navigationTitle("Send a referral")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        store.sendReferral(to: agent, clientName: clientName, side: side, priceRange: priceRange, notes: notes, fee: fee)
                        dismiss()
                    }
                    .disabled(clientName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
