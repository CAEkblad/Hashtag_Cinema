import SwiftUI

/// Plain English guide to the app. Opens from the ? on Home and from Me.
struct FAQ: Identifiable {
    var question: String
    var answer: String
    var id: String { question }
}

struct HowItWorksView: View {
    @Environment(CinemaStore.self) private var store

    private let steps: [(icon: String, title: String, detail: String)] = [
        ("lightbulb.fill", "Get an idea", "Every day you get a video idea written for your city, with a hook, shot list and script. Tap New ideas anytime for more."),
        ("video.fill", "Film it on your phone", "Open the camera, read the teleprompter and film. Practice mode gives coach notes without using a credit."),
        ("wand.and.stars", "We edit it", "AI makes the first cut in minutes. Pro edits go to a #Cinema editor for polish. You approve or leave notes on the exact second."),
        ("paperplane.fill", "Post and get leads", "Post to Instagram, Facebook, TikTok and YouTube at once. Add a comment keyword and we DM everyone who comments it, then save them as leads.")
    ]

    private let faqs: [FAQ] = [
        FAQ(question: "What is an edit credit?", answer: "One credit is an Instant edit by AI. A Pro edit with a human editor is 2 credits. Rush delivery adds 1. Your plan includes credits every month and you can add a pack anytime in Me > Plan and credits."),
        FAQ(question: "How fast do I get my video back?", answer: "Instant edits are usually ready in minutes. Pro edits are ready within 48 hours, or 24 hours on Pro and Rush."),
        FAQ(question: "How do comment keywords work?", answer: "When you post, pick a word like HOME. Anyone who comments that word on Instagram or Facebook gets your message by DM and shows up in Leads."),
        FAQ(question: "Can I change my city?", answer: "Yes. Go to Me > My market. You can also add up to 6 more cities you serve, and your ideas rotate across all of them."),
        FAQ(question: "When should I book a pro shoot?", answer: "For listings, your brand video, headshots and podcasts. A $500 deposit holds your date and goes toward the shoot."),
        FAQ(question: "I'm a team lead or MCA. Is it free?", answer: "Yes. Leaders use #Cinema free to promote their brokerage, office or team, spotlight agents and recruit.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("How #Cinema works")
                        .font(.cinema(28, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Your content team in your pocket. Four steps, about 15 minutes a day.")
                        .font(.cinema(15))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 14) {
                            VStack(spacing: 0) {
                                Image(systemName: step.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Theme.red, in: Circle())
                                if index < steps.count - 1 {
                                    Rectangle()
                                        .fill(Theme.red.opacity(0.25))
                                        .frame(width: 2)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(index + 1). \(step.title)")
                                    .font(.cinema(17, weight: .bold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(step.detail)
                                    .font(.cinema(14))
                                    .foregroundStyle(Theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.bottom, 18)
                        }
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Your setup")
                    IconRow(icon: "mappin.and.ellipse", title: store.homeCity.displayName, subtitle: store.serviceAreas.isEmpty ? "Home market" : "Plus \(store.serviceAreas.count) more cities")
                    IconRow(icon: "crown.fill", title: "\(store.profile.plan.name) plan", subtitle: "\(store.profile.credits) edit credits left")
                    IconRow(icon: "target", title: "\(store.profile.weeklyGoal) videos a week", subtitle: "Change it on Home")
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Questions")
                    ForEach(faqs) { faq in
                        DisclosureGroup {
                            Text(faq.answer)
                                .font(.cinema(14))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 6)
                        } label: {
                            Text(faq.question)
                                .font(.cinema(15, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .tint(Theme.red)
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
                .cardStyle()

                Text("Need a hand? Email hello@hashtagcinema.com and a real person will help.")
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}
