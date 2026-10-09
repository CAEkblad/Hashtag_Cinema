import SwiftUI

/// Get the home camera ready: a checklist agents send to sellers before the shoot.
struct SellerPrepView: View {
    @Environment(CinemaStore.self) private var store
    @State private var done: Set<String> = []

    private let sections: [(title: String, icon: String, items: [String])] = [
        ("Outside", "house.fill", [
            "Mow, edge and blow off walkways the day before",
            "Move cars out of the driveway and off the street in front",
            "Put trash cans, hoses and toys out of sight",
            "Open hurricane shutters and clean the front door",
            "Turn sprinklers off the night before so everything is dry"
        ]),
        ("Pool and lanai", "drop.fill", [
            "Clean the pool and run the pump so the water is clear and blue",
            "Remove pool covers, floats and cleaning equipment",
            "Arrange patio furniture and open the umbrellas",
            "Sweep the lanai and wipe the screens"
        ]),
        ("Inside", "sofa.fill", [
            "Turn on every light and open every blind",
            "Clear counters, fridge doors and bathroom vanities",
            "Hide personal photos, mail and medications",
            "Make the beds and fluff the pillows",
            "Set ceiling fans off so they're sharp in photos"
        ]),
        ("Kitchen and baths", "fork.knife", [
            "Leave one plant or bowl of fruit, nothing else on the counters",
            "Put toilet seats down and remove bath mats",
            "Hang fresh, matching towels"
        ]),
        ("Day of the shoot", "camera.fill", [
            "Pets out of the house or in a crate",
            "Plan to step out for 1 to 2 hours",
            "Leave a key or lockbox code with your agent",
            "Tell your agent your favorite feature so we feature it"
        ])
    ]

    private var allItems: [String] { sections.flatMap(\.items) }

    private var message: String {
        var lines = ["Getting your home camera ready! Here's the checklist for our \(store.homeCity.name) shoot:", ""]
        for section in sections {
            lines.append(section.title.uppercased())
            lines += section.items.map { "- \($0)" }
            lines.append("")
        }
        lines.append("Questions? Text me anytime. \(store.profile.firstName)")
        return lines.joined(separator: "\n")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Seller prep checklist")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Send it to your seller a few days before the shoot. Great prep makes great photos.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                ShareLink(item: message) {
                    Label("Send to my seller", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("\(done.count) of \(allItems.count) ready")
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)

                ForEach(sections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: 4) {
                        Label(section.title, systemImage: section.icon)
                            .font(.cinema(16, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.bottom, 4)
                        ForEach(section.items, id: \.self) { item in
                            Button {
                                if done.contains(item) { done.remove(item) } else { done.insert(item) }
                            } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: done.contains(item) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(done.contains(item) ? Theme.success : Theme.textTertiary)
                                    Text(item)
                                        .font(.cinema(14))
                                        .foregroundStyle(done.contains(item) ? Theme.textSecondary : Theme.textPrimary)
                                        .multilineTextAlignment(.leading)
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 5)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .cardStyle()
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Seller prep")
        .navigationBarTitleDisplayMode(.inline)
    }
}
