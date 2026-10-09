import SwiftUI

/// A note from the office leader that shows on every agent's Home screen.
struct OfficeAnnouncement: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var body: String
    var author: String
    var office: String
    var date: Date
}

/// The Home card agents see.
struct AnnouncementCard: View {
    @Environment(CinemaStore.self) private var store
    let announcement: OfficeAnnouncement

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(announcement.office, systemImage: "megaphone.fill")
                    .font(.cinema(12, weight: .bold))
                    .foregroundStyle(Theme.red)
                Spacer()
                Text(announcement.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Text(announcement.title)
                .font(.cinema(16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(announcement.body)
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)
            HStack {
                Text("From \(announcement.author)")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Button("Got it") {
                    withAnimation { store.dismissAnnouncement(announcement.id) }
                }
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(Theme.red)
            }
        }
        .cardStyle()
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.red)
                .frame(width: 4)
                .padding(.vertical, 12)
        }
    }
}

struct ComposeAnnouncementView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var message = ""

    private let starters: [(String, String)] = [
        ("Team meeting this week", "Join us Tuesday at 9:30 in the training room. We'll kick off the listing video challenge."),
        ("New office challenge", "Post 3 videos this week to win. Open #Cinema and tap Challenges to join."),
        ("Shout out", "Big congrats to our agents who closed this week. Keep the videos coming!")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Headline", text: $title)
                    TextField("Message", text: $message, axis: .vertical)
                        .lineLimit(3...8)
                } footer: {
                    Text("Shows on the Home screen of every agent in \(store.myMarketCenter?.name ?? store.profile.brokerage).")
                }
                Section("Start from") {
                    ForEach(starters, id: \.0) { starter in
                        Button(starter.0) {
                            title = starter.0
                            message = starter.1
                        }
                    }
                }
            }
            .navigationTitle("Announcement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        store.postAnnouncement(title: title.trimmingCharacters(in: .whitespaces), body: message.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
