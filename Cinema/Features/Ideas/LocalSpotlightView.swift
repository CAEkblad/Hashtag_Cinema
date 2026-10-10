import SwiftUI
import UIKit

/// A local business spotlight series: the ask, the questions, the shots and
/// the caption, so featuring a neighborhood favorite takes one visit.
struct LocalSpotlightView: View {
    @Environment(CinemaStore.self) private var store
    @State private var business = ""
    @State private var owner = ""
    @State private var area = ""
    @State private var kind: SpotlightKind = .coffee
    @State private var openIdea: Idea?
    @State private var copied: String?

    private var plan: SpotlightPlan {
        SpotlightPlan(
            kind: kind,
            business: business.trimmingCharacters(in: .whitespaces),
            owner: owner.trimmingCharacters(in: .whitespaces),
            area: area.trimmingCharacters(in: .whitespaces).isEmpty ? store.homeCity.name : area.trimmingCharacters(in: .whitespaces),
            agentName: store.profile.name
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Local spotlight")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Feature a local business every week. Owners share the video with their followers, you become the person who knows the neighborhood, and buyers moving in see it first.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SpotlightKind.allCases) { option in
                            Button { kind = option } label: {
                                Label(option.title, systemImage: option.icon)
                                    .font(.cinema(13, weight: .semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(kind == option ? Theme.red : Theme.surfaceRaised, in: Capsule())
                                    .foregroundStyle(kind == option ? .white : Theme.textPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Business name, like \(kind.example)", text: $business)
                        .inputStyle()
                    TextField("Owner's first name (optional)", text: $owner)
                        .textContentType(.givenName)
                        .inputStyle()
                    TextField("Neighborhood, like \(store.homeCity.neighborhoods.first ?? store.homeCity.name)", text: $area)
                        .inputStyle()
                }
                .cardStyle()

                section("1. Ask them", icon: "paperplane.fill") {
                    Text(plan.outreach)
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    copyButton(plan.outreach, label: "Copy the message")
                }

                section("2. Ask these on camera", icon: "mic.fill") {
                    ForEach(Array(plan.questions.enumerated()), id: \.offset) { index, question in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.cinema(12, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Theme.red, in: Circle())
                            Text(question)
                                .font(.cinema(14))
                                .foregroundStyle(Theme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                section("3. Get these shots", icon: "camera.fill") {
                    ForEach(plan.shots, id: \.self) { shot in
                        Label(shot, systemImage: "checkmark.circle")
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }

                section("4. Post it", icon: "text.bubble.fill") {
                    Text(plan.caption)
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    copyButton(plan.caption, label: "Copy the caption")
                    Text("Tag the business and use Instagram's Collab invite so the video shows on both profiles.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }

                Button {
                    openIdea = store.addIdea(plan.idea(city: store.homeCity.name))
                } label: {
                    Label("Save as an idea and film it", systemImage: "video.badge.plus")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(business.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Local spotlight")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .navigationDestination(item: $openIdea) { idea in
            IdeaDetailView(idea: idea)
        }
    }

    private func section<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.cinema(15, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func copyButton(_ text: String, label: String) -> some View {
        Button {
            UIPasteboard.general.string = text
            copied = label
            store.showToast("Copied")
        } label: {
            Label(copied == label ? "Copied" : label, systemImage: copied == label ? "checkmark" : "doc.on.doc")
                .font(.cinema(14, weight: .semibold))
        }
        .tint(Theme.red)
    }
}

enum SpotlightKind: String, CaseIterable, Identifiable {
    case coffee, restaurant, bakery, brewery, boutique, gym, salon, pets, nonprofit, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .coffee: return "Coffee shop"
        case .restaurant: return "Restaurant"
        case .bakery: return "Bakery"
        case .brewery: return "Brewery"
        case .boutique: return "Boutique"
        case .gym: return "Gym or studio"
        case .salon: return "Salon"
        case .pets: return "Pet shop"
        case .nonprofit: return "Nonprofit"
        case .other: return "Other"
        }
    }
    var icon: String {
        switch self {
        case .coffee: return "cup.and.saucer.fill"
        case .restaurant: return "fork.knife"
        case .bakery: return "birthday.cake.fill"
        case .brewery: return "mug.fill"
        case .boutique: return "bag.fill"
        case .gym: return "figure.run"
        case .salon: return "scissors"
        case .pets: return "pawprint.fill"
        case .nonprofit: return "heart.fill"
        case .other: return "storefront.fill"
        }
    }
    var example: String {
        switch self {
        case .coffee: return "Sunrise Coffee"
        case .restaurant: return "Harbor Grill"
        case .bakery: return "the corner bakery"
        case .brewery: return "the local brewery"
        case .boutique: return "a shop on the main street"
        case .gym: return "a yoga studio"
        case .salon: return "a local salon"
        case .pets: return "the neighborhood pet shop"
        case .nonprofit: return "a local food bank"
        case .other: return "a local favorite"
        }
    }
    /// What to order, try or see, for the hook and the questions.
    var thing: String {
        switch self {
        case .coffee: return "drink"
        case .restaurant, .bakery: return "dish"
        case .brewery: return "beer"
        case .boutique: return "find"
        case .gym: return "class"
        case .salon: return "service"
        case .pets: return "product"
        case .nonprofit: return "way to help"
        case .other: return "thing to try"
        }
    }
}

struct SpotlightPlan {
    let kind: SpotlightKind
    let business: String
    let owner: String
    let area: String
    let agentName: String

    private var name: String { business.isEmpty ? "your business" : business }
    private var first: String { agentName.split(separator: " ").first.map(String.init) ?? agentName }

    var outreach: String {
        "Hi\(owner.isEmpty ? "" : " \(owner)")! I'm \(first), a local real estate agent. I make short videos about my favorite spots in \(area), and I'd love to feature \(name). It takes about 15 minutes, there's no cost, and I'll tag you so your followers see it too. Would a weekday morning work?"
    }

    var questions: [String] {
        var list = [
            "How did \(name) start?",
            "What's the one \(kind.thing) everyone should try first?",
            "What do you love most about being in \(area)?"
        ]
        switch kind {
        case .coffee, .bakery, .restaurant, .brewery:
            list.append("What's the busiest time, and when should people come for a quiet visit?")
        case .boutique, .pets, .other:
            list.append("What's new right now that people don't know about yet?")
        case .gym, .salon:
            list.append("What should someone know before their first visit?")
        case .nonprofit:
            list.append("What does a volunteer's first day look like?")
        }
        list.append("What's something about this neighborhood only locals know?")
        return list
    }

    var shots: [String] {
        [
            "Outside sign and street, with people walking by",
            "The owner saying hi to the camera",
            "Close up of the \(kind.thing) being made or shown",
            "You trying it (the reaction is the hook)",
            "Wide shot of the space with customers",
            "Ending: you and the owner waving together"
        ]
    }

    var hook: String {
        business.isEmpty ? "The best \(kind.thing) in \(area)? Let's find out." : "The \(kind.thing) everyone in \(area) is talking about, at \(business)."
    }

    var caption: String {
        let tag = business.isEmpty ? "" : " @\(business.filter { $0.isLetter || $0.isNumber }.lowercased())"
        let areaTag = area.filter(\.isLetter).lowercased()
        return "Local spotlight: \(name)\(tag) \u{2728}\n\nOne of my favorite reasons to live in \(area). Go try the \(kind.thing) they recommend and tell them \(first) sent you!\n\nWhat local spot should I feature next? Drop it below \u{1F447}\n\n#\(areaTag) #\(areaTag)local #shoplocal #supportlocal #\(areaTag)realestate"
    }

    func idea(city: String) -> Idea {
        Idea(
            title: "Local spotlight: \(name)",
            hook: hook,
            category: .neighborhood,
            shots: shots,
            script: "\(hook) I'm here with \(owner.isEmpty ? "the owner" : owner) at \(name) in \(area). [Ask: how did it start?] [Ask: what should everyone try first?] [Try it on camera.] This is why I love \(area). Tell them \(first) sent you, and comment the next spot I should feature.",
            targetSeconds: 45,
            whyItWorks: "Local businesses share videos about themselves, so you reach their followers too. Neighborhood content also shows buyers you know the area.",
            cityName: city
        )
    }
}
