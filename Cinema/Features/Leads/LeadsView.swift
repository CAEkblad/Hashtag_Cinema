import SwiftUI

struct LeadsView: View {
    @Environment(CinemaStore.self) private var store

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    StatTile(value: "\(store.leads.count)", label: "Leads from video", icon: "person.badge.plus")
                    StatTile(value: "\(store.leads.filter { $0.status == .booked }.count)", label: "Showings booked", icon: "calendar.badge.checkmark")
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                ForEach(store.leads.sorted { $0.date > $1.date }) { lead in
                    LeadRow(lead: lead)
                }
            } header: {
                Text("Comment-to-DM leads")
            } footer: {
                Text("When someone comments your keyword on Instagram or Facebook, they get an instant DM and land here. Turn it on when you post.")
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
                Image(systemName: lead.platform.icon)
                    .foregroundStyle(Theme.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text(lead.name)
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(lead.handle) · commented \(lead.keyword) · \(lead.date.relative)")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
                Menu {
                    ForEach(LeadStatus.allCases) { status in
                        Button(status.title) { store.setLeadStatus(status, for: lead.id) }
                    }
                } label: {
                    Pill(text: lead.status.title, color: lead.status == .new ? Theme.red : Theme.surfaceRaised, textColor: .white)
                }
            }
            Text("\u{201C}\(lead.message)\u{201D}")
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)
            Text("From: \(lead.sourceClip)")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.vertical, 4)
    }
}
