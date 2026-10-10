import SwiftUI
import PhotosUI
import UIKit

/// Six Instagram and Facebook story frames for one listing, made to post as a
/// sequence over a day, each with the sticker to add when you post it.
struct StoryPackView: View {
    @Environment(CinemaStore.self) private var store
    let listing: Listing

    @State private var photos: [UIImage] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var selected = 0
    @State private var share: StoryShare?
    @State private var didLoad = false

    struct StoryShare: Identifiable {
        let id = UUID()
        let images: [UIImage]
    }

    private var frames: [StoryFrame] { StoryFrame.Kind.allCases.map { StoryFrame(kind: $0) } }

    private func canvas(_ frame: StoryFrame) -> StoryFrameCanvas {
        StoryFrameCanvas(frame: frame, listing: listing, photos: photos, agentName: store.profile.name, kit: store.brandKit)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Story pack")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Six stories for \(listing.address.split(separator: ",").first.map(String.init) ?? listing.address). Post one every couple of hours. Stickers like polls and questions get people tapping, and every tap tells you who's interested.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(frames.enumerated()), id: \.offset) { index, frame in
                            Button { selected = index } label: {
                                canvas(frame)
                                    .scaleEffect(84 / StoryFrameCanvas.size.width, anchor: .topLeading)
                                    .frame(width: 84, height: 84 * 16 / 9, alignment: .topLeading)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(selected == index ? Theme.red : .clear, lineWidth: 3)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                let frame = frames[min(selected, frames.count - 1)]
                HStack(alignment: .top, spacing: 14) {
                    canvas(frame)
                        .scaleEffect(170 / StoryFrameCanvas.size.width, anchor: .topLeading)
                        .frame(width: 170, height: 170 * 16 / 9, alignment: .topLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Story \(selected + 1) of \(frames.count)")
                            .font(.cinema(12, weight: .bold))
                            .foregroundStyle(Theme.textTertiary)
                        Text(frame.kind.title)
                            .font(.cinema(17, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Label(frame.kind.sticker, systemImage: frame.kind.stickerIcon)
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(Theme.red)
                        Text(frame.kind.tip)
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(frame.kind.when)
                            .font(.cinema(12, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                PhotosPicker(selection: $pickerItems, maxSelectionCount: 4, matching: .images) {
                    Label(photos.isEmpty ? "Add listing photos" : "Change photos (\(photos.count))", systemImage: "photo.on.rectangle.angled")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button { exportAll() } label: {
                    Label("Save all 6 stories", systemImage: "square.and.arrow.down.on.square")
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("Tip: save them all, then post from Instagram. Add the sticker in the empty space on each one.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Story pack")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            photos = ListingPhotoStore.load(listing.id, limit: 4).map { $0.downscaled(maxSide: 1600) }
        }
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task {
                var loaded: [UIImage] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        loaded.append(image.downscaled(maxSide: 1600))
                    }
                }
                if !loaded.isEmpty { photos = loaded }
                pickerItems = []
            }
        }
        .sheet(item: $share) { bundle in
            ActivityView(items: bundle.images)
                .presentationDetents([.medium, .large])
        }
    }

    @MainActor
    private func exportAll() {
        let images = frames.compactMap { frame -> UIImage? in
            let renderer = ImageRenderer(content: canvas(frame))
            renderer.scale = 3
            return renderer.uiImage
        }
        guard !images.isEmpty else { return }
        share = StoryShare(images: images)
    }
}

struct StoryFrame: Hashable {
    enum Kind: String, CaseIterable {
        case teaser, reveal, favorite, thisOrThat, tour, ask

        var title: String {
            switch self {
            case .teaser: return "Guess the price"
            case .reveal: return "The reveal"
            case .favorite: return "Favorite part"
            case .thisOrThat: return "This or that"
            case .tour: return "Come see it"
            case .ask: return "DM me"
            }
        }
        var sticker: String {
            switch self {
            case .teaser: return "Add a poll or quiz sticker"
            case .reveal: return "Add a link sticker to the listing"
            case .favorite: return "Add an emoji slider"
            case .thisOrThat: return "Add a poll sticker"
            case .tour: return "Add a countdown sticker"
            case .ask: return "Add a question sticker"
            }
        }
        var stickerIcon: String {
            switch self {
            case .teaser, .thisOrThat: return "chart.bar.fill"
            case .reveal: return "link"
            case .favorite: return "slider.horizontal.3"
            case .tour: return "timer"
            case .ask: return "questionmark.bubble.fill"
            }
        }
        var tip: String {
            switch self {
            case .teaser: return "Give three price options. Everyone who votes gets a DM from you later: \"Want to see it?\""
            case .reveal: return "Post an hour after the teaser so voters come back to see if they were right."
            case .favorite: return "Ask how much they love it. Sliders are the easiest tap there is."
            case .thisOrThat: return "Two photos, one vote. It's fun and tells you what buyers care about."
            case .tour: return "Set the countdown to your open house or first showing day. Followers get a reminder."
            case .ask: return "Question stickers turn into DMs. Reply to every one within the hour."
            }
        }
        var when: String {
            switch self {
            case .teaser: return "Morning"
            case .reveal: return "An hour later"
            case .favorite: return "Midday"
            case .thisOrThat: return "Afternoon"
            case .tour: return "Early evening"
            case .ask: return "Night"
            }
        }
    }

    let kind: Kind
}

struct StoryFrameCanvas: View {
    static let size = CGSize(width: 360, height: 640)

    let frame: StoryFrame
    let listing: Listing
    let photos: [UIImage]
    let agentName: String
    let kit: BrandKit

    private var street: String { listing.address.split(separator: ",").first.map(String.init) ?? listing.address }

    private func photo(_ index: Int) -> UIImage? {
        guard !photos.isEmpty else { return nil }
        return photos[index % photos.count]
    }

    private var priceOptions: [String] {
        let price = Double(listing.price)
        let step = price >= 1_000_000 ? 100_000.0 : (price >= 400_000 ? 50_000.0 : 25_000.0)
        let options = [price - step, price, price + step].map { value -> String in
            let rounded = (value / 5_000).rounded() * 5_000
            if rounded >= 1_000_000 { return "$\((rounded / 1_000_000).formatted(.number.precision(.fractionLength(0...2))))M" }
            return "$\(Int(rounded / 1_000))K"
        }
        return options
    }

    var body: some View {
        ZStack {
            switch frame.kind {
            case .teaser: teaser
            case .reveal: reveal
            case .favorite: favorite
            case .thisOrThat: thisOrThat
            case .tour: tour
            case .ask: ask
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipped()
    }

    // MARK: Pieces

    @ViewBuilder
    private func photoBackground(_ index: Int, dim: Double = 0.35) -> some View {
        if let image = photo(index) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: Self.size.width, height: Self.size.height)
                .clipped()
                .overlay(Color.black.opacity(dim))
        } else {
            LinearGradient(colors: [kit.accent, Theme.ink], startPoint: .top, endPoint: .bottom)
        }
    }

    private func pill(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 13, weight: .black, design: .rounded))
            .kerning(1.6)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(kit.accent, in: Capsule())
            .foregroundStyle(.white)
    }

    private func big(_ text: String, size: CGFloat = 40, lines: Int? = nil) -> some View {
        Text(text)
            .font(.system(size: size, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(lines)
            .minimumScaleFactor(0.4)
            .shadow(color: .black.opacity(0.45), radius: 8, y: 2)
    }

    private var stickerSpace: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
            .foregroundStyle(.white.opacity(0.0))
            .frame(height: 120)
    }

    private var signature: some View {
        HStack(spacing: 8) {
            if let headshot = kit.headshotImage {
                Image(uiImage: headshot).resizable().scaledToFill().frame(width: 30, height: 30).clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
            }
            Text(agentName)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 3)
            Spacer()
        }
    }

    // MARK: Frames

    private var teaser: some View {
        ZStack {
            photoBackground(0, dim: 0.4)
            VStack(alignment: .leading, spacing: 14) {
                pill(listing.status == .comingSoon ? "Coming soon" : "New listing")
                big("Guess the price?", size: 44)
                Text("\(listing.specsLine) in \(listing.city?.name ?? listing.cityLine)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                stickerSpace
                HStack(spacing: 8) {
                    ForEach(priceOptions, id: \.self) { option in
                        Text(option)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(Theme.ink)
                    }
                }
                Spacer()
                signature
            }
            .padding(.horizontal, 26)
            .padding(.top, 110)
            .padding(.bottom, 40)
        }
    }

    private var reveal: some View {
        ZStack {
            photoBackground(1, dim: 0.3)
            VStack(alignment: .leading, spacing: 10) {
                pill(listing.status == .sold ? "Sold" : "Just listed")
                Spacer()
                Text("The answer:")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                big(listing.priceLabel, size: 52, lines: 1)
                big(street, size: 24, lines: 2)
                Text(listing.specsLine)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                stickerSpace.frame(height: 70)
                signature
            }
            .padding(.horizontal, 26)
            .padding(.top, 110)
            .padding(.bottom, 40)
        }
    }

    private var favorite: some View {
        ZStack {
            photoBackground(2, dim: 0.35)
            VStack(alignment: .leading, spacing: 12) {
                pill("My favorite part")
                big(listing.features.first.map { $0.phrase.prefix(1).uppercased() + $0.phrase.dropFirst() } ?? "The light in this one", size: 34)
                if listing.features.count > 1 {
                    Text("Plus " + listing.features.dropFirst().prefix(3).map(\.title).joined(separator: ", ").lowercased())
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                }
                Spacer()
                stickerSpace
                signature
            }
            .padding(.horizontal, 26)
            .padding(.top, 110)
            .padding(.bottom, 40)
        }
    }

    private var thisOrThat: some View {
        VStack(spacing: 0) {
            ZStack {
                if let image = photo(1) {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: Self.size.width, height: Self.size.height / 2).clipped()
                } else {
                    kit.accent
                }
                Text("THIS")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 6)
            }
            .frame(width: Self.size.width, height: Self.size.height / 2)
            ZStack {
                if let image = photo(3) {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: Self.size.width, height: Self.size.height / 2).clipped()
                } else {
                    Theme.ink
                }
                Text("OR THAT")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 6)
            }
            .frame(width: Self.size.width, height: Self.size.height / 2)
        }
        .overlay(alignment: .top) {
            pill("Which room wins?").padding(.top, 70)
        }
    }

    private var tour: some View {
        ZStack {
            photoBackground(3, dim: 0.45)
            VStack(alignment: .leading, spacing: 12) {
                pill(listing.openHouses.isEmpty ? "Private showings" : "Open house")
                big("Come see it in person", size: 40)
                Text(listing.openHouses.sorted { $0.start < $1.start }.first(where: { $0.end > Date() })?.label ?? "Showings this week. DM me for a time.")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(street)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                stickerSpace
                Spacer()
                signature
            }
            .padding(.horizontal, 26)
            .padding(.top, 110)
            .padding(.bottom, 40)
        }
    }

    private var ask: some View {
        ZStack {
            LinearGradient(colors: [kit.accent, Theme.ink], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 16) {
                Spacer()
                if let headshot = kit.headshotImage {
                    Image(uiImage: headshot).resizable().scaledToFill().frame(width: 110, height: 110).clipShape(Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                }
                big("Questions about \(street)?", size: 32)
                    .multilineTextAlignment(.center)
                Text("Ask me anything. Or DM me TOUR and I'll send times.")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                stickerSpace
                Spacer()
                Text([agentName, kit.phone].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 50)
        }
    }
}
