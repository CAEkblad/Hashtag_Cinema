import SwiftUI

struct LeadsView: View {
    @Environment(CinemaStore.self) private var store

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    StatTile(value: "\(store.leads.count)", label: "Leads", icon: "person.badge.plus")
                    StatTile(value: "\(store.leads.filter { $0.status == .booked }.count)", label: "Showings booked", icon: "calendar.badge.checkmark")
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                NavigationLink(value: Route.keywords) {
                    IconRow(icon: "bubble.left.and.text.bubble.right.fill", title: "Auto DM keywords", subtitle: "\(store.keywordRules.filter(\.isOn).count) keywords turning comments into leads")
                }
                NavigationLink(value: Route.buyers) {
                    IconRow(icon: "heart.text.square", title: "Buyer wishlists", subtitle: "Match buyers to your listings")
                }
            }
            .listRowBackground(Theme.surface)

            if !store.leadsDueForFollowUp.isEmpty {
                Section("Follow up today") {
                    ForEach(store.leadsDueForFollowUp) { lead in
                        NavigationLink(value: Route.lead(lead.id)) {
                            LeadRow(lead: lead)
                        }
                    }
                }
                .listRowBackground(Theme.redSoft)
            }

            Section {
                ForEach(store.leads.sorted { $0.date > $1.date }) { lead in
                    NavigationLink(value: Route.lead(lead.id)) {
                        LeadRow(lead: lead)
                    }
                }
            } header: {
                Text("Comment-to-DM and open house leads")
            } footer: {
                Text("When someone comments your keyword on Instagram or Facebook, they get an instant DM and land here. Open house sign-ins land here too.")
            }
            .listRowBackground(Theme.surface)
        }
        .cinemaScreen()
        .navigationTitle("Leads")
    }
}

struct LeadRow: View {
    let lead: Lead
    @Environment(CinemaStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: lead.openHouseAddress == nil ? lead.platform.icon : "door.left.hand.open")
                    .foregroundStyle(Theme.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text(lead.name)
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(lead.openHouseAddress == nil ? "\(lead.handle) · commented \(lead.keyword) · \(lead.date.relative)" : "\(lead.handle) · signed in at open house · \(lead.date.relative)")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
                Pill(text: lead.status.title, color: lead.status == .new ? Theme.red : Theme.surfaceRaised, textColor: lead.status == .new ? .white : Theme.textPrimary)
            }
            Text("\u{201C}\(lead.message)\u{201D}")
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)
            Text("From: \(lead.openHouseAddress ?? lead.sourceClip)")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.vertical, 4)
    }
}
