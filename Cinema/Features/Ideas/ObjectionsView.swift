import SwiftUI
import UIKit

/// Honest answers to the things clients say most, ready to say or film.
struct Objection: Identifiable, Hashable {
    enum Group: String, CaseIterable, Identifiable {
        case sellers = "Sellers"
        case buyers = "Buyers"
        case fees = "Fees"
        case market = "Market"
        var id: String { rawValue }
    }

    var id: String { said }
    var group: Group
    var said: String
    var answer: String
    var videoTopic: String

    static let all: [Objection] = [
        Objection(group: .sellers, said: "We'll wait until spring to list.", answer: "That can work. Here's the trade off: in many Florida markets winter brings snowbirds and relocation buyers, and there are often fewer homes to compete with. Let's look at what sold near you in the last 90 days, then you decide with real numbers.", videoTopic: "you should always wait until spring to sell in Florida"),
        Objection(group: .sellers, said: "Zillow says my home is worth more.", answer: "Online estimates can't see your updates, your view or your street. Let me pull the actual sales near you and walk you through them. If the numbers support a higher price, I'll be the first to say so.", videoTopic: "the Zillow estimate is what your home is worth"),
        Objection(group: .sellers, said: "We want to try selling it ourselves first.", answer: "Totally fair. If you do, get a pre-listing inspection, price it from recent sales, and have a title company ready. If it doesn't move in a few weeks, I'd love to show you how we'd market it differently.", videoTopic: "you save money selling your home without an agent"),
        Objection(group: .sellers, said: "Another agent said they could list it higher.", answer: "Pricing high feels good on day one, but buyers compare every home online. Homes that sit get price cuts and lower offers. I'll show you the sales that set your price so you can judge for yourself.", videoTopic: "listing your home high leaves room to negotiate"),
        Objection(group: .buyers, said: "We'll wait for rates to drop.", answer: "Rates might drop, but if they do, more buyers come back and prices often climb. You can refinance a rate later, you can't renegotiate the price. Let's see what payment you're comfortable with today.", videoTopic: "you should wait for rates to drop before you buy"),
        Objection(group: .buyers, said: "We don't need to get pre-approved yet.", answer: "A pre-approval tells you your real budget and makes sellers take your offer seriously. It's free with most lenders and doesn't lock you in. I can connect you with someone great.", videoTopic: "you only need a pre-approval once you find a home"),
        Objection(group: .buyers, said: "Insurance in Florida is too expensive.", answer: "It can be, so let's plan for it. Newer roofs, impact windows and a wind mitigation report can lower premiums a lot. I'll flag those features in every home we see and get you quotes before you commit.", videoTopic: "every home in Florida has the same insurance cost"),
        Objection(group: .buyers, said: "We'll just call the listing agent.", answer: "You can, but the listing agent works for the seller. I work for you, from negotiating price and repairs to catching issues in the inspection. Let's put our agreement in writing so you know exactly what I do and what it costs.", videoTopic: "calling the listing agent gets you a better deal"),
        Objection(group: .fees, said: "Why do I have to sign a buyer agreement?", answer: "Since August 2024, agents need a written agreement with buyers before touring homes. It spells out what I'll do for you and how I'm paid, so there are no surprises. We can keep it short and specific to the homes you want to see.", videoTopic: "buyer agreements lock you in forever"),
        Objection(group: .fees, said: "Can you cut your commission?", answer: "Here's what my fee pays for: pro photos and video, ads on every platform, open houses and negotiating every dollar. Let me show you the full marketing plan, then let's talk about what makes sense for you.", videoTopic: "every agent markets a home the same way"),
        Objection(group: .market, said: "Is the market about to crash?", answer: "Nobody can promise what's next, but I can show you what's happening right now in your neighborhood: prices, days on market and how many homes are for sale. Real local numbers beat headlines.", videoTopic: "the housing market is about to crash"),
        Objection(group: .market, said: "Hurricanes make Florida a bad investment.", answer: "Storms are real, so smart buyers plan for them: check the flood zone, roof age and elevation, and get insurance quotes early. Plenty of people buy here every year with eyes open, and I'll help you do the same.", videoTopic: "you can't buy safely in Florida because of hurricanes")
    ]
}

struct ObjectionsView: View {
    @Environment(CinemaStore.self) private var store
    @State private var group: Objection.Group = .sellers
    @State private var openID: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("What to say when...")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Honest answers to what clients say most. Use them on the phone, or turn one into a myth buster video.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                Picker("Group", selection: $group) {
                    ForEach(Objection.Group.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                ForEach(Objection.all.filter { $0.group == group }) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            withAnimation(.snappy) { openID = openID == item.id ? nil : item.id }
                        } label: {
                            HStack(alignment: .top) {
                                Text("\u{201C}\(item.said)\u{201D}")
                                    .font(.cinema(16, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: openID == item.id ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                        .buttonStyle(.plain)

                        if openID == item.id {
                            Text(item.answer)
                                .font(.cinema(14))
                                .foregroundStyle(Theme.textSecondary)
                                .textSelection(.enabled)
                            HStack(spacing: 16) {
                                Button {
                                    UIPasteboard.general.string = item.answer
                                    store.showToast("Copied")
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                Button {
                                    let idea = ScriptWriter.write(type: .mythBuster, topic: item.videoTopic, seconds: 30, city: store.homeCity, agentName: store.profile.name)
                                    store.saveScript(idea)
                                    store.showToast("Video script saved to your ideas")
                                } label: {
                                    Label("Make it a video", systemImage: "video.fill")
                                }
                            }
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(Theme.red)
                            .buttonStyle(.plain)
                        }
                    }
                    .cardStyle()
                }

                Text("General guidance, not legal advice. Follow your brokerage's policies and Florida law.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Objections")
        .navigationBarTitleDisplayMode(.inline)
    }
}
