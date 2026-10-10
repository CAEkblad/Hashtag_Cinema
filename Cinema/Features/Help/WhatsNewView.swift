import SwiftUI

/// Shown once after an update, with a tap-through to each new tool.
struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    var onOpen: (Route) -> Void = { _ in }

    struct Item: Identifiable {
        var id: String { title }
        var icon: String
        var title: String
        var detail: String
        var route: Route
    }

    static let items: [Item] = [
        Item(icon: "person.3.fill", title: "Team pages", detail: "Join or start a team. Videos, posters, listings, closings and reviews post to the team page on their own. Roster, leaderboard, lead hand offs and a recruiting page.", route: .team),
        Item(icon: "checklist.checked", title: "Weekly scorecard", detail: "4-1-1 style weekly targets for videos, touches, appointments and leads, filled in for you. Share it with your accountability partner.", route: .scorecard),
        Item(icon: "clock.fill", title: "Time blocks", detail: "Set your daily focus blocks and get a reminder when each one starts.", route: .timeBlocks),
        Item(icon: "timer", title: "Power hour", detail: "A prospecting timer with one tap tallies for calls, texts, talks and appointments, plus a daily streak.", route: .powerHour),
        Item(icon: "person.text.rectangle.fill", title: "Digital business card", detail: "A QR code people scan to save your contact, or send it as a contact card.", route: .businessCard),
        Item(icon: "checkmark.seal.fill", title: "License and CE", detail: "Florida renewal date, hours by category and reminders 90, 30 and 7 days out.", route: .license),
        Item(icon: "map.fill", title: "Mileage that does the math", detail: "Apple Maps works out the miles, including round trips and whole showing tours. Save frequent trips and log them in one tap.", route: .expenses),
        Item(icon: "chart.pie.fill", title: "Split and cap tracker", detail: "See how close you are to capping, with company split and royalty worked out from your closings.", route: .splitTracker),
        Item(icon: "building.columns.fill", title: "Tax set aside", detail: "How much to save from every closing, and reminders before each quarterly payment.", route: .taxes),
        Item(icon: "calendar.badge.clock", title: "Listing launch plan", detail: "Open any active listing for a dated countdown with every tool one tap away.", route: .listings),
        Item(icon: "film.stack.fill", title: "Photo reel", detail: "Listing photos in, a branded vertical video out, made on your phone.", route: .photoReel),
        Item(icon: "person.crop.rectangle.stack.fill", title: "Find a photographer, now with a map", detail: "See Crew near you, pick a package with Help me choose, and chat with your shooter.", route: .findShooter),
        Item(icon: "doc.text.fill", title: "Under contract", detail: "Every Florida contract deadline, with reminders and a timeline for your client.", route: .deals),
        Item(icon: "car.fill", title: "Showing tours", detail: "Plan the route, send the schedule, then send a recap of what they loved.", route: .tours),
        Item(icon: "heart.text.square", title: "Buyer wishlists", detail: "Match buyers to your listings and build a tour in one tap.", route: .buyers),
        Item(icon: "house.and.flag.fill", title: "Past clients", detail: "Home anniversary reminders, value check-ins and a monthly newsletter.", route: .pastClients),
        Item(icon: "dollarsign.circle.fill", title: "Seller net sheet", detail: "Florida doc stamps and title, worked out for your seller.", route: .netSheet),
        Item(icon: "chart.line.uptrend.xyaxis", title: "Home value report", detail: "A branded PDF from 3 to 5 comps for every VALUE lead.", route: .homeValue),
        Item(icon: "bubble.left.and.text.bubble.right.fill", title: "Auto DM keywords", detail: "Save your comment keywords and DMs once, use them on every post.", route: .keywords),
        Item(icon: "arrow.triangle.branch", title: "Agent referrals", detail: "Send clients to trusted agents across Florida and track the fee.", route: .referralNetwork),
        Item(icon: "target", title: "Business plan", detail: "Your income goal, worked back to videos a week.", route: .businessPlan),
        Item(icon: "quote.bubble.fill", title: "What to say when", detail: "Honest answers to the 12 objections you hear most, each one a video in a tap.", route: .objections),
        Item(icon: "map.fill", title: "My farm", detail: "Own a neighborhood: log monthly touches and get video ideas for it.", route: .farm),
        Item(icon: "person.crop.square.filled.and.at.rectangle", title: "Brand shoot prep", detail: "Your story, locations and wardrobe, sent to the #Cinema producer before shoot day.", route: .brandShootPrep),
        Item(icon: "chart.bar.fill", title: "Where your leads come from", detail: "A new chart in Insights shows which keywords and open houses bring in leads.", route: .insights),
        Item(icon: "waveform", title: "Siri and Shortcuts", detail: "Say \"Log mileage in #Cinema\", \"What's my video idea in #Cinema\" or \"Check my leads in #Cinema\".", route: .expenses),
        Item(icon: "square.grid.2x2.fill", title: "All tools", detail: "Everything in one place, grouped by what you're doing.", route: .tools)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("What's new in #Cinema")
                        .font(.cinema(28, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Tap anything to try it.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.bottom, 4)
                    ForEach(Self.items) { item in
                        Button {
                            dismiss()
                            onOpen(item.route)
                        } label: {
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Theme.red)
                                    .frame(width: 40, height: 40)
                                    .background(Theme.redSoft, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.cinema(16, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(item.detail)
                                        .font(.cinema(13))
                                        .foregroundStyle(Theme.textSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Theme.textTertiary)
                                    .padding(.top, 12)
                            }
                            .cardStyle(padding: 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Theme.gutter)
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    /// The build number this screen was last shown for.
    static let seenKey = "cinema.whatsnew.build"
    static var currentBuild: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0" }

    static var shouldShow: Bool {
        (UserDefaults.standard.string(forKey: seenKey) ?? "") != currentBuild
    }

    static func markSeen() {
        UserDefaults.standard.set(currentBuild, forKey: seenKey)
    }
}

/// The same list as a pushed screen, for the Me tab.
struct WhatsNewList: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(WhatsNewView.items) { item in
                    NavigationLink(value: item.route) {
                        IconRow(icon: item.icon, title: item.title, subtitle: item.detail)
                            .cardStyle(padding: 14)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("What's new")
        .navigationBarTitleDisplayMode(.inline)
    }
}
