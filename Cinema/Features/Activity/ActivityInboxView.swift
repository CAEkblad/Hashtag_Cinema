import SwiftUI

/// Everything that happened: edits ready, new leads, bookings, ratings, office news, referral rewards.
struct ActivityInboxView: View {
    @Environment(CinemaStore.self) private var store

    private var today: [ActivityItem] { store.activity.filter { Calendar.current.isDateInToday($0.date) } }
    private var earlier: [ActivityItem] { store.activity.filter { !Calendar.current.isDateInToday($0.date) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if store.activity.isEmpty {
                    EmptyStateView(title: "All caught up", message: "Edits, leads, bookings and rewards show up here.", icon: "tray")
                }
                if !today.isEmpty { section("Today", items: today) }
                if !earlier.isEmpty { section("Earlier", items: earlier) }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if store.unreadActivityCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Mark all read") { store.markAllRead() }
                        .font(.cinema(14, weight: .semibold))
                }
            }
        }
    }

    private func section(_ title: String, items: [ActivityItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.cinema(12, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
            ForEach(items) { item in
                if let route = item.route {
                    NavigationLink(value: route) {
                        row(item)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded { store.markRead(item) })
                } else {
                    Button {
                        store.markRead(item)
                    } label: {
                        row(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func row(_ item: ActivityItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.kind.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(item.isRead ? Theme.textSecondary : Theme.red)
                .frame(width: 36, height: 36)
                .background(item.isRead ? Theme.surfaceRaised : Theme.redSoft, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.title)
                        .font(.cinema(15, weight: item.isRead ? .medium : .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer(minLength: 6)
                    Text(item.date.relative)
                        .font(.cinema(11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Text(item.detail)
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !item.isRead {
                Circle().fill(Theme.red).frame(width: 8, height: 8).padding(.top, 6)
            }
        }
        .cardStyle(padding: 14)
    }
}
