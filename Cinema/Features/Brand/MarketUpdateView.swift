import SwiftUI
import UIKit

/// Enter this month's numbers, get a branded market graphic and a 30 second script.
struct MarketUpdateView: View {
    @Environment(CinemaStore.self) private var store
    @State private var cityID: String?
    @State private var medianPrice = 425_000.0
    @State private var change = 0.0
    @State private var daysOnMarket = 42.0
    @State private var active = 1_250.0
    @State private var newListings = 380.0
    @State private var share: PosterMakerView.ShareBundle?
    @State private var filming: Idea?

    private var city: FloridaCity { FloridaMarkets.city(cityID) ?? store.homeCity }

    private var snapshot: MarketSnapshot {
        MarketSnapshot(
            cityName: city.name,
            periodLabel: Date().formatted(.dateTime.month(.wide).year()),
            medianPrice: Int(medianPrice),
            priceChangePercent: (change * 10).rounded() / 10,
            daysOnMarket: Int(daysOnMarket),
            activeListings: Int(active),
            newListings: Int(newListings)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Market update")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Plug in this month's numbers from your MLS. We make the graphic and the script.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack {
                    Spacer()
                    MarketCanvas(snapshot: snapshot, agentName: store.profile.name, kit: store.brandKit)
                        .scaleEffect(300 / 360, anchor: .topLeading)
                        .frame(width: 300, height: 300, alignment: .topLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
                    Spacer()
                }

                if store.allMarkets.count > 1 {
                    Picker("City", selection: Binding(get: { cityID ?? store.homeCity.id }, set: { cityID = $0 })) {
                        ForEach(store.allMarkets) { market in
                            Text(market.name).tag(market.id)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(spacing: 14) {
                    slider("Median sale price", value: $medianPrice, range: 100_000...3_000_000, step: 5_000, label: snapshot.priceLabel)
                    slider("Price change vs last year", value: $change, range: -15...15, step: 0.1, label: snapshot.changeLabel)
                    slider("Median days on market", value: $daysOnMarket, range: 5...180, step: 1, label: "\(Int(daysOnMarket)) days")
                    slider("Homes for sale", value: $active, range: 10...20_000, step: 10, label: Int(active).formatted())
                    slider("New listings this month", value: $newListings, range: 1...5_000, step: 5, label: Int(newListings).formatted())
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your 30 second script")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(snapshot.script(agentFirstName: store.profile.firstName))
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                        .textSelection(.enabled)
                }
                .cardStyle()

                HStack(spacing: 10) {
                    Button {
                        makeShare()
                    } label: {
                        Label("Share graphic", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Button {
                        filming = store.addIdea(store.marketScriptIdea(snapshot), announce: false)
                    } label: {
                        Label("Film it", systemImage: "video.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                Text("Use numbers from your MLS or local Realtor association report for the period you name. Double check before posting.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Market update")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $share) { bundle in
            ActivityView(items: [bundle.image, bundle.caption])
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(item: $filming) { idea in
            CameraView(idea: idea, practiceMode: false)
        }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.cinema(14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(label)
                    .font(.cinema(14, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Slider(value: value, in: range, step: step)
                .tint(Theme.red)
        }
    }

    @MainActor
    private func makeShare() {
        let renderer = ImageRenderer(content: MarketCanvas(snapshot: snapshot, agentName: store.profile.name, kit: store.brandKit))
        renderer.scale = 3
        guard let image = renderer.uiImage else { return }
        let tag = snapshot.cityName.filter(\.isLetter).lowercased()
        let caption = "\(snapshot.cityName) real estate, \(snapshot.periodLabel): median price \(snapshot.priceLabel) (\(snapshot.changeLabel)), about \(snapshot.daysOnMarket) days on market. \(snapshot.takeaway) Comment MARKET for what it means for your home. #\(tag)realestate #floridarealestate #marketupdate"
        share = PosterMakerView.ShareBundle(image: image, caption: caption)
    }
}

/// Square market graphic with four stat tiles.
struct MarketCanvas: View {
    let snapshot: MarketSnapshot
    let agentName: String
    let kit: BrandKit

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MARKET UPDATE")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.85))
                Text(snapshot.cityName)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(snapshot.periodLabel)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                tile("Median price", snapshot.priceLabel)
                tile("vs last year", snapshot.changeLabel)
                tile("Days on market", "\(snapshot.daysOnMarket)")
                tile("Homes for sale", snapshot.activeListings.formatted())
            }
            Text(snapshot.takeaway)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                if let headshot = kit.headshotImage {
                    Image(uiImage: headshot)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                }
                Text([agentName, kit.phone].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if let logo = kit.logoImage {
                    Image(uiImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 60, maxHeight: 24)
                }
            }
        }
        .padding(22)
        .frame(width: 360, height: 360)
        .background(
            LinearGradient(colors: [kit.accent, kit.accent.opacity(0.75), Theme.ink], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private func tile(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
