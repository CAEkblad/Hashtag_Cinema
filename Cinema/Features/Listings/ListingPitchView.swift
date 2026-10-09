import SwiftUI
import UIKit

/// A one page "how I'll market your home" plan to send before a listing appointment.
struct ListingPitchView: View {
    @Environment(CinemaStore.self) private var store
    @State private var sellerName = ""
    @State private var address = ""
    @State private var items: Set<PitchItem> = Set(PitchItem.allCases)
    @State private var shareURL: URL?
    @State private var showShare = false

    enum PitchItem: String, CaseIterable, Identifiable {
        case photos, video, reels, posters, openHouse, leadCapture, report

        var id: String { rawValue }

        var title: String {
            switch self {
            case .photos: return "Professional photos and drone"
            case .video: return "Cinematic video tour"
            case .reels: return "Vertical reels on 4 platforms"
            case .posters: return "Coming soon and just listed posters"
            case .openHouse: return "Open house with QR sign in"
            case .leadCapture: return "Comment to DM buyer capture"
            case .report: return "Weekly seller report"
            }
        }

        var detail: String {
            switch self {
            case .photos: return "Shot by a vetted #Cinema Crew photographer, delivered in 24 to 48 hours."
            case .video: return "A walkthrough that sells the lifestyle, not just the rooms."
            case .reels: return "Instagram, Facebook, TikTok and YouTube Shorts, posted the day you list."
            case .posters: return "Branded graphics and a printable flyer with a QR code."
            case .openHouse: return "Every visitor signs in on a phone and gets a follow up."
            case .leadCapture: return "Anyone who comments the keyword gets details by DM, instantly."
            case .report: return "Views, showings and feedback every week, so you always know where we stand."
            }
        }

        var icon: String {
            switch self {
            case .photos: return "camera.fill"
            case .video: return "film.fill"
            case .reels: return "rectangle.portrait.fill"
            case .posters: return "rectangle.portrait.on.rectangle.portrait.fill"
            case .openHouse: return "door.left.hand.open"
            case .leadCapture: return "bubble.left.and.text.bubble.right.fill"
            case .report: return "chart.bar.doc.horizontal.fill"
            }
        }
    }

    private var canvas: PitchCanvas {
        PitchCanvas(
            sellerName: sellerName,
            address: address.isEmpty ? "Your home" : address,
            cityName: store.homeCity.name,
            items: PitchItem.allCases.filter { items.contains($0) },
            agentName: store.profile.name,
            brokerage: store.myMarketCenter?.name ?? store.profile.brokerage,
            kit: store.brandKit,
            stats: [
                ("\(store.insights.totalViews.compact)", "video views in 8 weeks"),
                ("\(store.posts.filter { $0.status == .posted }.count + store.clips.count)", "videos made"),
                ("\(store.testimonials.filter { $0.stars == 5 }.count)", "five star reviews")
            ]
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Listing presentation")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Send sellers your marketing plan before the appointment. Video agents win more listings.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack {
                    Spacer()
                    canvas
                        .scaleEffect(300 / FlyerCanvas.size.width, anchor: .topLeading)
                        .frame(width: 300, height: 300 * FlyerCanvas.size.height / FlyerCanvas.size.width, alignment: .topLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 5)
                    Spacer()
                }

                TextField("Seller's name", text: $sellerName)
                    .textContentType(.name)
                    .inputStyle()
                TextField("Property address", text: $address)
                    .textContentType(.fullStreetAddress)
                    .inputStyle()

                VStack(alignment: .leading, spacing: 4) {
                    Text("What's included")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    ForEach(PitchItem.allCases) { item in
                        Toggle(isOn: Binding(get: { items.contains(item) }, set: { on in if on { items.insert(item) } else { items.remove(item) } })) {
                            Label(item.title, systemImage: item.icon)
                                .font(.cinema(14))
                        }
                        .tint(Theme.red)
                    }
                }
                .cardStyle()

                Button {
                    makePDF()
                } label: {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Listing presentation")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showShare) {
            if let shareURL {
                ActivityView(items: [shareURL])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    @MainActor
    private func makePDF() {
        let renderer = ImageRenderer(content: canvas)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Marketing-Plan.pdf")
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            context.beginPDFPage(nil)
            draw(context)
            context.endPDFPage()
            context.closePDF()
        }
        shareURL = url
        showShare = true
    }
}

struct PitchCanvas: View {
    let sellerName: String
    let address: String
    let cityName: String
    let items: [ListingPitchView.PitchItem]
    let agentName: String
    let brokerage: String
    let kit: BrandKit
    let stats: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("MY MARKETING PLAN FOR")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.85))
                Text(address)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                if !sellerName.isEmpty {
                    Text("Prepared for \(sellerName)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(kit.accent)

            HStack(spacing: 12) {
                ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat.0)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Text(stat.1)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 22)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(kit.accent, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            Text(item.detail)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 22)

            Spacer(minLength: 0)

            Text("Buyers find homes on their phones. I make sure they find yours in \(cityName) first.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)

            HStack(spacing: 12) {
                if let headshot = kit.headshotImage {
                    Image(uiImage: headshot)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(agentName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text([kit.phone, kit.website].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                        .font(.system(size: 12, design: .rounded))
                    Text(brokerage)
                        .font(.system(size: 11, design: .rounded))
                        .opacity(0.75)
                }
                .foregroundStyle(.white)
                Spacer()
                if let logo = kit.logoImage {
                    Image(uiImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 110, maxHeight: 44)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 18)
            .background(Theme.ink)
        }
        .frame(width: FlyerCanvas.size.width, height: FlyerCanvas.size.height)
        .background(Color.white)
    }
}
