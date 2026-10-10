import SwiftUI
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers
import UIKit

/// Branded 9:16 covers for reels and TikToks, built so the title still reads
/// when Instagram crops it to 3:4 on your profile grid.
struct ReelCoverView: View {
    @Environment(CinemaStore.self) private var store
    @State private var title: String
    @State private var kicker = ""
    @State private var style: CoverStyle = .block
    @State private var position: CoverPosition = .middle
    @State private var episodeOn = false
    @State private var episode = 1
    @State private var image: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var videoURL: URL?
    @State private var videoSeconds: Double = 0
    @State private var frameTime: Double = 0
    @State private var showGrid = true
    @State private var isLoading = false
    @State private var message: String?
    @State private var share: PosterMakerView.ShareBundle?

    init(title: String = "") {
        _title = State(initialValue: title)
    }

    private var canvas: ReelCoverCanvas {
        ReelCoverCanvas(
            image: image,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            kicker: kicker.trimmingCharacters(in: .whitespacesAndNewlines),
            style: style,
            position: position,
            episode: episodeOn ? episode : nil,
            agentName: store.profile.name,
            kit: store.brandKit
        )
    }

    private var suggestions: [String] {
        var seen = Set<String>()
        return store.ideas.prefix(12).map(\.title).filter { seen.insert($0).inserted }.prefix(6).map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reel covers")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("A matching cover on every reel makes your profile look like a show people want to binge. The title stays inside the part Instagram shows on your grid.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        canvas
                            .scaleEffect(170 / ReelCoverCanvas.size.width, anchor: .topLeading)
                            .frame(width: 170, height: 170 * ReelCoverCanvas.size.height / ReelCoverCanvas.size.width, alignment: .topLeading)
                        if showGrid { GridCropGuide() }
                    }
                    .frame(width: 170, height: 170 * ReelCoverCanvas.size.height / ReelCoverCanvas.size.width)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 4)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("On your grid")
                            .font(.cinema(13, weight: .bold))
                            .foregroundStyle(Theme.textSecondary)
                        GridPreview(cover: canvas)
                        Toggle(isOn: $showGrid) {
                            Text("Show grid crop")
                                .font(.cinema(12, weight: .semibold))
                        }
                        .tint(Theme.red)
                        Text("Inside the lines shows on your profile. Outside only shows in the reel.")
                            .font(.cinema(11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Background")
                        .font(.cinema(15, weight: .bold))
                    PhotosPicker(selection: $pickerItem, matching: .any(of: [.images, .videos])) {
                        Label(image == nil ? "Pick a photo or video" : "Pick a different one", systemImage: "photo.on.rectangle.angled")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Loading...").font(.cinema(13)).foregroundStyle(Theme.textSecondary)
                        }
                    }
                    if videoURL != nil, videoSeconds > 0.5 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pick the frame: \(frameTime.formatted(.number.precision(.fractionLength(1))))s")
                                .font(.cinema(13, weight: .semibold))
                            Slider(value: $frameTime, in: 0...videoSeconds) { editing in
                                if !editing { Task { await grabFrame() } }
                            }
                            .tint(Theme.red)
                        }
                    }
                    if image == nil {
                        Text("No photo? You'll get a clean cover in your brand color.")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    if let message {
                        Text(message).font(.cinema(12)).foregroundStyle(Theme.warning)
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Title")
                        .font(.cinema(15, weight: .bold))
                    TextField("Like: 3 things I'd never do as a buyer", text: $title, axis: .vertical)
                        .lineLimit(1...3)
                        .inputStyle()
                    if !suggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button { title = suggestion } label: {
                                        Text(suggestion)
                                            .font(.cinema(12, weight: .semibold))
                                            .lineLimit(1)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Theme.surfaceRaised, in: Capsule())
                                            .foregroundStyle(Theme.textPrimary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    TextField("Small line above, like \(store.homeCity.name) real estate", text: $kicker)
                        .inputStyle()
                    Toggle(isOn: $episodeOn) {
                        Text("It's a series")
                            .font(.cinema(14, weight: .semibold))
                    }
                    .tint(Theme.red)
                    if episodeOn {
                        Stepper("Episode \(episode)", value: $episode, in: 1...999)
                            .font(.cinema(14))
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Look")
                        .font(.cinema(15, weight: .bold))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CoverStyle.allCases) { option in
                                Button { style = option } label: {
                                    Text(option.title)
                                        .font(.cinema(13, weight: .semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(style == option ? Theme.red : Theme.surfaceRaised, in: Capsule())
                                        .foregroundStyle(style == option ? .white : Theme.textPrimary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    Picker("Text position", selection: $position) {
                        ForEach(CoverPosition.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                .cardStyle()

                Button { export() } label: {
                    Label("Share cover", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)

                Text("Upload the cover when you post: on Instagram tap Edit cover, then Add from camera roll. On TikTok tap Select cover, then Add photo.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Reel covers")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
        .sheet(item: $share) { bundle in
            ActivityView(items: [bundle.image])
                .presentationDetents([.medium, .large])
        }
    }

    private func load(_ item: PhotosPickerItem) async {
        isLoading = true
        message = nil
        defer { isLoading = false; pickerItem = nil }
        if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
            guard let movie = try? await item.loadTransferable(type: CoverMovie.self) else {
                message = "Couldn't open that video. Try another."
                return
            }
            videoURL = movie.url
            let duration = (try? await AVURLAsset(url: movie.url).load(.duration).seconds) ?? 0
            videoSeconds = duration.isFinite ? duration : 0
            frameTime = min(1, videoSeconds / 2)
            await grabFrame()
        } else if let data = try? await item.loadTransferable(type: Data.self), let picked = UIImage(data: data) {
            videoURL = nil
            videoSeconds = 0
            image = picked.downscaled(maxSide: 2000)
        } else {
            message = "Couldn't open that photo. Try another."
        }
    }

    private func grabFrame() async {
        guard let videoURL else { return }
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: videoURL))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 2000, height: 2000)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
        if let frame = try? await generator.image(at: CMTime(seconds: frameTime, preferredTimescale: 600)).image {
            image = UIImage(cgImage: frame)
        } else {
            message = "Couldn't grab that frame. Try another spot."
        }
    }

    @MainActor
    private func export() {
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = 3
        guard let rendered = renderer.uiImage else { return }
        share = PosterMakerView.ShareBundle(image: rendered, caption: "")
    }
}

/// A picked video copied somewhere we can read it.
struct CoverMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory.appendingPathComponent("closeup-cover-\(UUID().uuidString.prefix(6)).\(received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension)")
            try? FileManager.default.removeItem(at: copy)
            try FileManager.default.copyItem(at: received.file, to: copy)
            return CoverMovie(url: copy)
        }
    }
}

enum CoverStyle: String, CaseIterable, Identifiable {
    case block, clean, magazine, outline, split
    var id: String { rawValue }
    var title: String {
        switch self {
        case .block: return "Color block"
        case .clean: return "Clean"
        case .magazine: return "Magazine"
        case .outline: return "Outline"
        case .split: return "Split"
        }
    }
}

enum CoverPosition: String, CaseIterable, Identifiable {
    case top, middle, bottom
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

/// The 3:4 window Instagram shows on the profile grid, drawn over a 9:16 preview.
private struct GridCropGuide: View {
    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.width * 4 / 3
            let top = (proxy.size.height - height) / 2
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.35).frame(height: top)
                Color.black.opacity(0.35).frame(height: top).offset(y: top + height)
                Rectangle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: proxy.size.width, height: height)
                    .offset(y: top)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Three grid tiles: this cover cropped like Instagram does, beside two blanks.
private struct GridPreview: View {
    let cover: ReelCoverCanvas

    var body: some View {
        let tile: CGFloat = 56
        let tall = tile * 4 / 3
        let scale = tile / ReelCoverCanvas.size.width
        HStack(spacing: 2) {
            cover
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: tile, height: tile * 16 / 9, alignment: .topLeading)
                .frame(width: tile, height: tall)
                .clipped()
            ForEach(0..<2, id: \.self) { _ in
                Rectangle().fill(Theme.surfaceRaised).frame(width: tile, height: tall)
            }
        }
    }
}

struct ReelCoverCanvas: View {
    static let size = CGSize(width: 360, height: 640)

    let image: UIImage?
    let title: String
    let kicker: String
    let style: CoverStyle
    let position: CoverPosition
    let episode: Int?
    let agentName: String
    let kit: BrandKit

    /// The 3:4 grid window inside the 9:16 frame.
    private var safeHeight: CGFloat { Self.size.width * 4 / 3 }
    private var safeTop: CGFloat { (Self.size.height - safeHeight) / 2 }
    private var shownTitle: String { title.isEmpty ? "Your title here" : title }

    private var alignment: Alignment {
        switch position {
        case .top: return .top
        case .middle: return .center
        case .bottom: return .bottom
        }
    }

    private var titleSize: CGFloat {
        let length = shownTitle.count
        if length <= 18 { return 46 }
        if length <= 32 { return 38 }
        if length <= 50 { return 31 }
        return 26
    }

    var body: some View {
        ZStack {
            background
            shade
            textBlock
                .padding(.horizontal, 26)
                .padding(.vertical, 30)
                .frame(width: Self.size.width, height: safeHeight, alignment: alignment)
            if let headshot = kit.headshotImage, style != .split {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(uiImage: headshot)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 1.5))
                        Text(agentName)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3)
                        Spacer()
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 26)
                }
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipped()
    }

    @ViewBuilder
    private var background: some View {
        if let image {
            if style == .split {
                VStack(spacing: 0) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: Self.size.width, height: Self.size.height * 0.56)
                        .clipped()
                    kit.accent
                }
            } else {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.size.width, height: Self.size.height)
                    .clipped()
            }
        } else {
            LinearGradient(colors: [kit.accent, kit.accent.opacity(0.75), Theme.ink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    @ViewBuilder
    private var shade: some View {
        if image != nil && style != .split {
            switch position {
            case .top:
                LinearGradient(colors: [.black.opacity(0.65), .clear, .black.opacity(0.25)], startPoint: .top, endPoint: .bottom)
            case .middle:
                Color.black.opacity(style == .block ? 0.15 : 0.35)
            case .bottom:
                LinearGradient(colors: [.black.opacity(0.1), .clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
            }
        }
    }

    private var episodeBadge: some View {
        Group {
            if let episode {
                Text("EP \(episode)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .kerning(1.5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(style == .block ? Color.white : kit.accent, in: Capsule())
                    .foregroundStyle(style == .block ? kit.accent : .white)
            }
        }
    }

    private var kickerText: some View {
        Group {
            if !kicker.isEmpty {
                Text(kicker.uppercased())
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .kerning(2.2)
                    .foregroundStyle(.white.opacity(0.92))
                    .shadow(color: .black.opacity(0.4), radius: 3)
            }
        }
    }

    @ViewBuilder
    private var textBlock: some View {
        switch style {
        case .block:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) { episodeBadge; kickerText }
                Text(shownTitle.uppercased())
                    .font(.system(size: titleSize * 0.9, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineSpacing(-2)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(kit.accent, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .clean:
            VStack(spacing: 10) {
                episodeBadge
                kickerText
                Text(shownTitle)
                    .font(.system(size: titleSize, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .shadow(color: .black.opacity(0.55), radius: 8, y: 2)
            }
            .frame(maxWidth: .infinity)
        case .magazine:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    kickerText
                    Spacer()
                    episodeBadge
                }
                Rectangle().fill(kit.accent).frame(width: 54, height: 5)
                Text(shownTitle)
                    .font(.system(size: titleSize * 1.05, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .shadow(color: .black.opacity(0.45), radius: 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .outline:
            VStack(spacing: 12) {
                episodeBadge
                Text(shownTitle.uppercased())
                    .font(.system(size: titleSize * 0.85, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .padding(18)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.45), radius: 6)
                kickerText
            }
            .frame(maxWidth: .infinity)
        case .split:
            VStack(alignment: .leading, spacing: 10) {
                Spacer(minLength: 0)
                HStack(spacing: 8) { episodeBadge; kickerText }
                Text(shownTitle)
                    .font(.system(size: titleSize * 0.85, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                Text(agentName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }
}
