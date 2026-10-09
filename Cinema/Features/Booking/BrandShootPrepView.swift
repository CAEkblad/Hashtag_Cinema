import SwiftUI

/// Get ready for an agent brand video: story questions, wardrobe and locations,
/// sent to the #Cinema producer before shoot day.
struct BrandShootPrepView: View {
    @Environment(CinemaStore.self) private var store
    @State private var answers: [String: String] = [:]
    @State private var locations: Set<String> = []
    @State private var bookService: ServiceType?

    private let questions: [(id: String, prompt: String, hint: String)] = [
        ("why", "Why did you get into real estate?", "The moment or person that started it"),
        ("love", "What do you love most about your city?", "A place, a feeling, a Saturday morning"),
        ("client", "Tell us about a client you'll never forget", "What happened and how it felt"),
        ("different", "What do you do that other agents don't?", "Be specific, that's what sells"),
        ("life", "What do you do when you're not working?", "Boat, kids, coffee, fishing, church")
    ]

    private let wardrobe = [
        "Solid colors in your brand color or neutrals. Skip small patterns and logos.",
        "Bring 2 to 3 outfits: one polished, one relaxed, one for outdoors.",
        "Florida heat is real. Choose breathable fabrics and bring a towel.",
        "Fresh haircut 3 to 5 days before, not the day before.",
        "Matte makeup or powder for shine. Lip balm and water nearby."
    ]

    private var locationOptions: [String] {
        let city = store.homeCity
        var list = city.highlights.prefix(4).map { $0 }
        list += city.neighborhoods.prefix(3).map { "\($0) streets and storefronts" }
        list += ["Your office or team space", "A listing you love", "Your favorite coffee shop"]
        return list
    }

    private var brief: String {
        var lines = ["Brand shoot brief for \(store.profile.name) (\(store.homeCity.name))", ""]
        for question in questions {
            let answer = answers[question.id, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
            if !answer.isEmpty { lines += [question.prompt, answer, ""] }
        }
        if !locations.isEmpty {
            lines.append("Locations I'd love:")
            lines += locationOptions.filter { locations.contains($0) }.map { "- \($0)" }
            lines.append("")
        }
        lines.append("Brand color and logo are in my #Cinema brand kit.")
        return lines.joined(separator: "\n")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Brand shoot prep")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Your brand video is your story. Answer a few questions so our producer can write it, then pick the places that feel like you.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                SectionHeader(title: "Your story")
                ForEach(questions, id: \.id) { question in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(question.prompt)
                            .font(.cinema(15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        TextField(question.hint, text: Binding(get: { answers[question.id, default: ""] }, set: { answers[question.id] = $0 }), axis: .vertical)
                            .lineLimit(2...5)
                            .inputStyle()
                    }
                }

                SectionHeader(title: "Where to film")
                FlowLayout(spacing: 8) {
                    ForEach(locationOptions, id: \.self) { option in
                        Button {
                            if locations.contains(option) { locations.remove(option) } else { locations.insert(option) }
                        } label: {
                            Text(option)
                                .font(.cinema(13, weight: .semibold))
                                .foregroundStyle(locations.contains(option) ? .white : Theme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(locations.contains(option) ? Theme.red : Theme.surface, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                SectionHeader(title: "What to wear")
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(wardrobe, id: \.self) { tip in
                        Label(tip, systemImage: "checkmark.circle.fill")
                            .font(.cinema(13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .cardStyle()

                ShareLink(item: brief) {
                    Label("Send to my #Cinema producer", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    bookService = .brandVideo
                } label: {
                    Label("Book the brand shoot", systemImage: "calendar.badge.plus")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Brand shoot")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .sheet(item: $bookService) { service in
            BookingFormView(service: service)
        }
    }
}
