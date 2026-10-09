import SwiftUI
import UIKit

/// Holiday and seasonal greeting posts with your brand, ready to share.
struct GreetingsView: View {
    @Environment(CinemaStore.self) private var store
    @State private var selected: Greeting?
    @State private var share: PosterMakerView.ShareBundle?

    struct Greeting: Identifiable, Hashable {
        var id: String
        var month: Int
        var headline: String
        var subline: String
        var icon: String
        var caption: String
    }

    private var greetings: [Greeting] {
        let city = store.homeCity.name
        let all = [
            Greeting(id: "new-year", month: 1, headline: "Happy New Year", subline: "Here's to new keys and new chapters", icon: "sparkles", caption: "Happy New Year from my family to yours! If a new home is on your list this year, I'd love to help."),
            Greeting(id: "valentines", month: 2, headline: "Love where you live", subline: "Happy Valentine's Day", icon: "heart.fill", caption: "Happy Valentine's Day! Tell me what you love most about your home or your neighborhood."),
            Greeting(id: "st-patricks", month: 3, headline: "Feeling lucky?", subline: "Happy St. Patrick's Day", icon: "leaf.fill", caption: "Happy St. Patrick's Day! The luckiest thing I know is helping families find home."),
            Greeting(id: "easter", month: 4, headline: "Happy Easter", subline: "Wishing you a sunny spring", icon: "sun.max.fill", caption: "Happy Easter from me to you. Enjoy the sunshine, \(city)!"),
            Greeting(id: "mothers-day", month: 5, headline: "Happy Mother's Day", subline: "To the women who make a house a home", icon: "heart.circle.fill", caption: "Happy Mother's Day to every mom who makes a house a home."),
            Greeting(id: "hurricane", month: 6, headline: "Hurricane season starts", subline: "Make your plan, check your supplies", icon: "hurricane", caption: "Hurricane season starts June 1. Comment READY and I'll send you my homeowner checklist."),
            Greeting(id: "fathers-day", month: 6, headline: "Happy Father's Day", subline: "Thanks for building more than houses", icon: "hammer.fill", caption: "Happy Father's Day to all the dads out there!"),
            Greeting(id: "july-4", month: 7, headline: "Happy 4th of July", subline: "Home of the free", icon: "star.fill", caption: "Happy Independence Day! Wishing you a safe and fun 4th, \(city)."),
            Greeting(id: "back-to-school", month: 8, headline: "Back to school", subline: "Have a great year, \(city)!", icon: "backpack.fill", caption: "Good luck to every student heading back to school this month!"),
            Greeting(id: "labor-day", month: 9, headline: "Happy Labor Day", subline: "Enjoy a well earned rest", icon: "sun.horizon.fill", caption: "Happy Labor Day! Thank you to everyone who keeps \(city) running."),
            Greeting(id: "halloween", month: 10, headline: "Happy Halloween", subline: "The only scary house is an overpriced one", icon: "moon.stars.fill", caption: "Happy Halloween! Stay safe out there tonight."),
            Greeting(id: "veterans", month: 11, headline: "Thank you, veterans", subline: "Honoring all who served", icon: "flag.fill", caption: "Thank you to every veteran and military family. We're grateful for your service."),
            Greeting(id: "thanksgiving", month: 11, headline: "Happy Thanksgiving", subline: "Grateful for every client and friend", icon: "leaf.circle.fill", caption: "Happy Thanksgiving! I'm grateful for every family I've helped this year."),
            Greeting(id: "holidays", month: 12, headline: "Happy Holidays", subline: "Peace, joy and home sweet home", icon: "gift.fill", caption: "Happy holidays from my home to yours!")
        ]
        let now = store.currentMonth
        return all.sorted { (($0.month - now + 12) % 12) < (($1.month - now + 12) % 12) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Holiday posts")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Easy posts that keep you in your sphere's feed, with your headshot and brand. Coming up first.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(greetings) { greeting in
                        Button {
                            makeShare(greeting)
                        } label: {
                            VStack(spacing: 8) {
                                GreetingCanvas(greeting: greeting, agentName: store.profile.name, brokerage: store.myMarketCenter?.name ?? store.profile.brokerage, kit: store.brandKit)
                                    .scaleEffect(150 / 360, anchor: .topLeading)
                                    .frame(width: 150, height: 150, alignment: .topLeading)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                Text(greeting.headline)
                                    .font(.cinema(13, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                    .lineLimit(1)
                                Text(Calendar.current.monthSymbols[greeting.month - 1])
                                    .font(.cinema(11))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .cardStyle(padding: 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text("Tap one to share. Set your headshot and color in Me > Brand kit.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Holiday posts")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $share) { bundle in
            ActivityView(items: [bundle.image, bundle.caption])
                .presentationDetents([.medium, .large])
        }
    }

    @MainActor
    private func makeShare(_ greeting: Greeting) {
        let renderer = ImageRenderer(content: GreetingCanvas(greeting: greeting, agentName: store.profile.name, brokerage: store.myMarketCenter?.name ?? store.profile.brokerage, kit: store.brandKit))
        renderer.scale = 3
        guard let image = renderer.uiImage else { return }
        share = PosterMakerView.ShareBundle(image: image, caption: greeting.caption)
    }
}

struct GreetingCanvas: View {
    let greeting: GreetingsView.Greeting
    let agentName: String
    let brokerage: String
    let kit: BrandKit

    var body: some View {
        ZStack {
            LinearGradient(colors: [kit.accent, kit.accent.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: greeting.icon)
                .font(.system(size: 220, weight: .bold))
                .foregroundStyle(.white.opacity(0.12))
                .offset(x: 110, y: -70)
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: greeting.icon)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                Text(greeting.headline)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Text(greeting.subline)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                HStack(spacing: 10) {
                    if let headshot = kit.headshotImage {
                        Image(uiImage: headshot)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 38, height: 38)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(agentName)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Text(brokerage)
                            .font(.system(size: 11, design: .rounded))
                            .opacity(0.85)
                    }
                    .foregroundStyle(.white)
                    Spacer()
                    if let logo = kit.logoImage {
                        Image(uiImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 60, maxHeight: 26)
                    }
                }
                .padding(.top, 8)
            }
            .padding(26)
        }
        .frame(width: 360, height: 360)
        .clipped()
    }
}
