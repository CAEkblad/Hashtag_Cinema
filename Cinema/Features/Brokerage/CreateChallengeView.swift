import SwiftUI

/// Leaders launch a challenge for their office or team. Agents see it in Challenges and on Home.
struct CreateChallengeView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    struct Template: Identifiable {
        var id: String { title }
        var title: String
        var subtitle: String
        var days: Int
        var prize: String
    }

    private let templates = [
        Template(title: "Market Monday", subtitle: "A market update video every Monday", days: 4, prize: "Feature on the office socials"),
        Template(title: "Listing Launch Sprint", subtitle: "5 videos for one listing in 7 days", days: 7, prize: "Free twilight photos"),
        Template(title: "30 Days on Camera", subtitle: "One video a day for 30 days", days: 30, prize: "Free pro shoot"),
        Template(title: "Neighborhood Week", subtitle: "Spotlight a different neighborhood every day", days: 7, prize: "Lunch on the team lead")
    ]

    @State private var title = "Market Monday"
    @State private var subtitle = "A market update video every Monday"
    @State private var days = 4
    @State private var prize = "Feature on the office socials"

    var body: some View {
        NavigationStack {
            Form {
                Section("Start from a template") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(templates) { template in
                                Button {
                                    title = template.title
                                    subtitle = template.subtitle
                                    days = template.days
                                    prize = template.prize
                                } label: {
                                    Text(template.title)
                                        .font(.cinema(13, weight: .semibold))
                                        .foregroundStyle(title == template.title ? Color.white : Theme.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(title == template.title ? Theme.red : Theme.surfaceRaised, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Section("Challenge") {
                    TextField("Name", text: $title)
                    TextField("What agents do", text: $subtitle)
                    Stepper("\(days) check ins", value: $days, in: 3...60)
                    TextField("Prize", text: $prize)
                }
                Section {
                    Text("Every agent in your \(store.officeWord) gets it in Challenges and on Home. Check ins happen when they post.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("Office challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Launch") {
                        store.launchOfficeChallenge(title: title, subtitle: subtitle, days: days, prize: prize)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
