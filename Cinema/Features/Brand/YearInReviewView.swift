import SwiftUI
import UIKit

/// A "my year in real estate" recap post and story, filled from what's in
/// CloseUp and editable before sharing.
struct YearInReviewView: View {
    @Environment(CinemaStore.self) private var store
    @State private var stats: [RecapStat] = []
    @State private var headline = ""
    @State private var thanks = ""
    @State private var story = false
    @State private var share: PosterMakerView.ShareBundle?
    @State private var didLoad = false

    private var year: Int { Calendar.current.component(.year, from: Date()) }
    private var yearToDate: Bool { Calendar.current.component(.month, from: Date()) < 12 }

    private var canvas: YearInReviewCanvas {
        YearInReviewCanvas(year: year, headline: headline, stats: stats.filter { $0.isOn && !$0.value.isEmpty }, thanks: thanks, story: story, agentName: store.profile.name, kit: store.brandKit)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Year in review")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("A thank you post with your numbers for \(String(year)). We filled in what CloseUp knows. Change anything before you share it.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                Picker("Size", selection: $story) {
                    Text("Post 4:5").tag(false)
                    Text("Story 9:16").tag(true)
                }
                .pickerStyle(.segmented)

                let width: CGFloat = story ? 200 : 280
                canvas
                    .scaleEffect(width / YearInReviewCanvas.width, anchor: .topLeading)
                    .frame(width: width, height: width * canvas.height / YearInReviewCanvas.width, alignment: .topLeading)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 5)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Headline")
                        .font(.cinema(15, weight: .bold))
                    TextField("Headline", text: $headline)
                        .inputStyle()
                    TextField("Thank you line", text: $thanks, axis: .vertical)
                        .lineLimit(2...3)
                        .inputStyle()
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Your numbers")
                        .font(.cinema(15, weight: .bold))
                    ForEach($stats) { $stat in
                        HStack(spacing: 10) {
                            Button { stat.isOn.toggle() } label: {
                                Image(systemName: stat.isOn ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(stat.isOn ? Theme.red : Theme.textTertiary)
                            }
                            .buttonStyle(.plain)
                            TextField("0", text: $stat.value)
                                .font(.cinema(15, weight: .bold))
                                .frame(width: 90)
                                .inputStyle()
                            TextField("Label", text: $stat.label)
                                .font(.cinema(14))
                                .inputStyle()
                        }
                    }
                    Text("Up to 6 show. Only share numbers you're allowed to share, and keep client names private.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
                .cardStyle()

                Button { export() } label: {
                    Label("Share it", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Year in review")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            load()
        }
        .sheet(item: $share) { bundle in
            ActivityView(items: [bundle.image, bundle.caption])
                .presentationDetents([.medium, .large])
        }
    }

    private func load() {
        let calendar = Calendar.current
        let thisYear = { (date: Date) in calendar.component(.year, from: date) == year }
        let closed = store.deals.filter { $0.isClosed && thisYear($0.closingDate) }
        let volume = closed.reduce(0) { $0 + $1.price }
        let buyers = closed.filter { $0.side == .buyer }.count
        let sellers = closed.filter { $0.side == .seller }.count
        let listings = store.listings.filter { thisYear($0.listedAt) }.count
        let videos = store.posts.filter { thisYear($0.date) }.count
        let reviews = store.testimonials.filter { thisYear($0.date) }.count
        let views = store.posts.filter { thisYear($0.date) }.reduce(0) { $0 + $1.views }

        func money(_ value: Int) -> String {
            if value >= 1_000_000 { return "$\((Double(value) / 1_000_000).formatted(.number.precision(.fractionLength(0...1))))M" }
            if value >= 1_000 { return "$\(value / 1_000)K" }
            return "$\(value)"
        }

        stats = [
            RecapStat(value: closed.isEmpty ? "" : "\(closed.count)", label: closed.count == 1 ? "family helped home" : "families helped home", isOn: !closed.isEmpty),
            RecapStat(value: volume > 0 ? money(volume) : "", label: "in homes sold", isOn: volume > 0),
            RecapStat(value: buyers > 0 ? "\(buyers)" : "", label: buyers == 1 ? "buyer got the keys" : "buyers got the keys", isOn: buyers > 0),
            RecapStat(value: sellers > 0 ? "\(sellers)" : "", label: sellers == 1 ? "home sold" : "homes sold", isOn: sellers > 0),
            RecapStat(value: listings > 0 ? "\(listings)" : "", label: listings == 1 ? "new listing" : "new listings", isOn: listings > 0 && sellers == 0),
            RecapStat(value: videos > 0 ? "\(videos)" : "", label: "videos posted", isOn: videos > 0),
            RecapStat(value: views > 0 ? views.formatted(.number.notation(.compactName)) : "", label: "video views", isOn: views > 0),
            RecapStat(value: reviews > 0 ? "\(reviews)" : "", label: reviews == 1 ? "five star review" : "five star reviews", isOn: reviews > 0),
            RecapStat(value: "", label: "open houses", isOn: false),
            RecapStat(value: "", label: "cups of coffee", isOn: false)
        ]
        headline = yearToDate ? "\(String(year)) so far" : "My \(String(year)) in real estate"
        thanks = "Thank you to every client, partner and friend who trusted me this year."
    }

    @MainActor
    private func export() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = 1080 / YearInReviewCanvas.width
        guard let image = renderer.uiImage else { return }
        let city = store.homeCity.name
        let lines = stats.filter { $0.isOn && !$0.value.isEmpty }.prefix(6).map { "\($0.value) \($0.label)" }
        let caption = "\(headline)! \(lines.joined(separator: ", ")). \(thanks) Thinking about a move in \(String(year + 1))? Send me a message and let's make a plan.\n\n#\(city.filter(\.isLetter).lowercased())realestate #yearinreview #thankyou"
        UIPasteboard.general.string = caption
        share = PosterMakerView.ShareBundle(image: image, caption: caption)
    }
}

struct RecapStat: Identifiable, Hashable {
    var id = UUID()
    var value: String
    var label: String
    var isOn: Bool
}

struct YearInReviewCanvas: View {
    static let width: CGFloat = 360

    let year: Int
    let headline: String
    let stats: [RecapStat]
    let thanks: String
    let story: Bool
    let agentName: String
    let kit: BrandKit

    var height: CGFloat { story ? 640 : 450 }
    private var shown: [RecapStat] { Array(stats.prefix(6)) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.ink, Theme.ink.opacity(0.92), kit.accent.opacity(0.85)], startPoint: .top, endPoint: .bottomTrailing)
            Text(String(year))
                .font(.system(size: story ? 170 : 150, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.06))
                .offset(y: story ? -190 : -120)
            VStack(alignment: .leading, spacing: story ? 18 : 12) {
                if story { Spacer(minLength: 0) }
                Text(headline.isEmpty ? "My year in real estate" : headline)
                    .font(.system(size: story ? 34 : 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                Rectangle().fill(kit.accent).frame(width: 56, height: 5)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], alignment: .leading, spacing: story ? 18 : 12) {
                    ForEach(shown) { stat in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.value)
                                .font(.system(size: story ? 38 : 32, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            Text(stat.label)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.75))
                                .lineLimit(2)
                        }
                    }
                }
                if shown.isEmpty {
                    Text("Add your numbers below.")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer(minLength: 0)
                Text(thanks)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    if let headshot = kit.headshotImage {
                        Image(uiImage: headshot).resizable().scaledToFill().frame(width: 30, height: 30).clipShape(Circle())
                    }
                    Text(agentName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    if let logo = kit.logoImage {
                        Image(uiImage: logo).resizable().scaledToFit().frame(maxWidth: 70, maxHeight: 26)
                    }
                }
            }
            .padding(.horizontal, 26)
            .padding(.vertical, story ? 60 : 26)
        }
        .frame(width: Self.width, height: height)
        .clipped()
    }
}
