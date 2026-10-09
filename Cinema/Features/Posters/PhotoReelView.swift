import SwiftUI
import PhotosUI
import AVKit

/// Listing photos in, a vertical reel out. Made on the phone in seconds.
struct PhotoReelView: View {
    @Environment(CinemaStore.self) private var store
    var listing: Listing? = nil

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var photos: [UIImage] = []
    @State private var isLoading = false
    @State private var tag = "Just listed"
    @State private var title = ""
    @State private var subtitle = ""
    @State private var seconds: Double = 2.5
    @State private var progress: Double = 0
    @State private var isRendering = false
    @State private var videoURL: URL?
    @State private var player: AVPlayer?
    @State private var showShare = false
    @State private var errorText: String?
    @State private var didLoad = false

    private let tags = ["Just listed", "Coming soon", "Open house", "Price improved", "Under contract", "Just sold"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Photo reel")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Pick up to 10 listing photos. We'll turn them into a vertical video with a slow zoom on each photo and your branding.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                if let player {
                    VideoPlayer(player: player)
                        .aspectRatio(9 / 16, contentMode: .fit)
                        .frame(maxHeight: 460)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    HStack(spacing: 10) {
                        Button {
                            showShare = true
                        } label: {
                            Label("Share or save", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        Button {
                            self.player = nil
                            videoURL = nil
                        } label: {
                            Label("Edit", systemImage: "slider.horizontal.3")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    Text("Add a trending sound when you post on Instagram or TikTok. Their music is licensed for posts.")
                        .font(.cinema(11))
                        .foregroundStyle(Theme.textTertiary)
                } else {
                    PhotosPicker(selection: $pickerItems, maxSelectionCount: 10, matching: .images) {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.stack.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.red)
                            Text(photos.isEmpty ? "Choose photos" : "\(photos.count) photo\(photos.count == 1 ? "" : "s") picked. Change")
                                .font(.cinema(15, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if isLoading { ProgressView() }
                        }
                        .cardStyle()
                    }

                    if !photos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(photos.enumerated()), id: \.offset) { _, photo in
                                    Image(uiImage: photo)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 110)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Tag", selection: $tag) {
                            ForEach(tags, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.red)
                        TextField("Headline, like 123 Bayshore Blvd", text: $title)
                        TextField("Details, like $650,000 · 3 bed · 2 bath", text: $subtitle)
                        Stepper("\(String(format: "%.1f", seconds)) seconds per photo", value: $seconds, in: 1.5...4, step: 0.5)
                    }
                    .font(.cinema(14))
                    .cardStyle()

                    if isRendering {
                        VStack(alignment: .leading, spacing: 6) {
                            ProgressView(value: progress)
                                .tint(Theme.red)
                            Text("Making your reel... \(Int(progress * 100))%")
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    if let errorText {
                        Text(errorText)
                            .font(.cinema(13))
                            .foregroundStyle(Theme.red)
                    }

                    Button {
                        Task { await render() }
                    } label: {
                        Label("Make my reel", systemImage: "film.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(photos.isEmpty || isRendering)

                    Text("About \(Int(Double(photos.count) * seconds + 2)) seconds long. Under 30 seconds works best on Reels and TikTok.")
                        .font(.cinema(11))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Photo reel")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: pickerItems) { _, items in
            Task { await load(items) }
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            if let listing {
                title = listing.address
                subtitle = "\(listing.priceLabel) · \(listing.specsLine)"
                switch listing.status {
                case .comingSoon: tag = "Coming soon"
                case .active: tag = "Just listed"
                case .underContract: tag = "Under contract"
                case .sold: tag = "Just sold"
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let videoURL {
                ActivityView(items: [videoURL])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func load(_ items: [PhotosPickerItem]) async {
        isLoading = true
        var loaded: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                loaded.append(image.downscaled(maxSide: 2000))
            }
        }
        photos = loaded
        isLoading = false
    }

    private func render() async {
        isRendering = true
        progress = 0
        errorText = nil
        let options = ReelRenderer.Options(
            tag: tag,
            title: title.isEmpty ? store.homeCity.name : title,
            subtitle: subtitle,
            agentName: store.profile.name,
            agentLine: [store.brandKit.phone, store.myMarketCenter?.name ?? store.profile.brokerage].filter { !$0.isEmpty }.joined(separator: "\n"),
            accent: UIColor(store.brandKit.accent),
            secondsPerPhoto: seconds
        )
        let images = photos
        do {
            let url = try await Task.detached(priority: .userInitiated) {
                try await ReelRenderer.render(photos: images, options: options) { value in
                    Task { @MainActor in progress = value }
                }
            }.value
            videoURL = url
            player = AVPlayer(url: url)
            player?.play()
            store.showToast("Your reel is ready")
        } catch {
            errorText = "Couldn't make the reel. Try fewer photos."
        }
        isRendering = false
    }
}
