import SwiftUI
import UIKit

/// Proven first lines, sorted by style. Tap to copy or turn one into a video.
struct HookLibraryView: View {
    @Environment(CinemaStore.self) private var store
    @State private var style: HookStyle = .curiosity
    @State private var openIdea: Idea?

    enum HookStyle: String, CaseIterable, Identifiable {
        case curiosity, warning, numbers, local, story, question
        var id: String { rawValue }

        var title: String {
            switch self {
            case .curiosity: return "Curiosity"
            case .warning: return "Warning"
            case .numbers: return "Numbers"
            case .local: return "Local"
            case .story: return "Story"
            case .question: return "Question"
            }
        }

        var icon: String {
            switch self {
            case .curiosity: return "eye.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .numbers: return "number"
            case .local: return "mappin.and.ellipse"
            case .story: return "book.fill"
            case .question: return "questionmark.bubble.fill"
            }
        }

        var category: IdeaCategory {
            switch self {
            case .curiosity, .numbers: return .marketUpdate
            case .warning: return .mythBuster
            case .local: return .neighborhood
            case .story: return .clientStory
            case .question: return .mythBuster
            }
        }

        var hooks: [String] {
            switch self {
            case .curiosity:
                return [
                    "Nobody is talking about what just happened in {city} real estate.",
                    "This is the {city} home everyone keeps asking me about.",
                    "I wasn't supposed to show you this house yet.",
                    "Here's what $500K actually gets you in {city} right now.",
                    "The one street in {city} I'd buy on today.",
                    "Watch this before you list your home in {city}."
                ]
            case .warning:
                return [
                    "Stop. Don't buy a home in Florida until you check this.",
                    "This mistake costs {city} sellers thousands every year.",
                    "If your agent hasn't told you this, run.",
                    "Never skip this step on a Florida home inspection.",
                    "Buying a condo in {city}? Read this first.",
                    "Three red flags I spotted on a showing today."
                ]
            case .numbers:
                return [
                    "3 things every {city} buyer should know this month.",
                    "I sold 5 homes in {city} this year. Here's what they had in common.",
                    "It took 7 days to sell this home. Here's how.",
                    "5 neighborhoods in {county} County under the radar.",
                    "2 minutes, 3 tips, and you'll price your home right.",
                    "1 number tells you if it's a good time to buy in {city}."
                ]
            case .local:
                return [
                    "If you move to {city}, this is your Saturday.",
                    "The best kept secret in {county} County.",
                    "Locals in {city}, where's the best coffee? I'll start.",
                    "What it's really like to live in {city}.",
                    "Moving to {city}? These are the 3 areas I'd look at first.",
                    "Things only {city} people understand."
                ]
            case .story:
                return [
                    "They almost gave up on buying. Then this happened.",
                    "Six offers, one house, and a letter that changed everything.",
                    "My client cried when she saw this kitchen.",
                    "This family waited 8 months for this moment.",
                    "The day I almost quit real estate.",
                    "What a first time buyer taught me this week."
                ]
            case .question:
                return [
                    "Should you rent or buy in {city} right now?",
                    "Is it a buyer's market in {city}? Let's look.",
                    "Would you live here for this price?",
                    "Pool or no pool in Florida? Tell me in the comments.",
                    "How much do you really need to buy a home in {city}?",
                    "What would you change about this living room?"
                ]
            }
        }
    }

    private func fill(_ hook: String) -> String {
        hook.replacingOccurrences(of: "{city}", with: store.homeCity.name)
            .replacingOccurrences(of: "{county}", with: store.homeCity.county)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hook library")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Your first 2 seconds decide if people keep watching. Start with one of these.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(HookStyle.allCases) { option in
                            Button {
                                style = option
                            } label: {
                                Label(option.title, systemImage: option.icon)
                                    .font(.cinema(13, weight: .semibold))
                                    .foregroundStyle(style == option ? Color.white : Theme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(style == option ? Theme.red : Theme.surface, in: Capsule())
                                    .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                ForEach(style.hooks, id: \.self) { raw in
                    let hook = fill(raw)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\u{201C}\(hook)\u{201D}")
                            .font(.cinema(16, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 18) {
                            Button {
                                UIPasteboard.general.string = hook
                                store.showToast("Hook copied")
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            Button {
                                openIdea = store.addIdea(idea(from: hook), announce: false)
                            } label: {
                                Label("Make it a video", systemImage: "video.badge.plus")
                            }
                        }
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(Theme.red)
                        .buttonStyle(.plain)
                    }
                    .cardStyle()
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Hooks")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $openIdea) { idea in
            IdeaDetailView(idea: idea)
        }
    }

    private func idea(from hook: String) -> Idea {
        Idea(
            title: hook,
            hook: hook,
            category: style.category,
            shots: ["Say the hook close to camera, no intro", "Show the proof: the home, the street or the number", "Close on you with the keyword"],
            script: "\(hook) Here's the one thing to know: say your main point in one sentence. Then give one example or number that proves it. Want more like this? Comment MORE and I'll send it to you.",
            targetSeconds: 30,
            whyItWorks: "A strong first line stops the scroll. Keep the rest to one idea and one proof.",
            cityName: store.homeCity.name
        )
    }
}
