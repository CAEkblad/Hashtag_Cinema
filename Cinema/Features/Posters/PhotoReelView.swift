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
    @State private var shareFile: ShareFile?
    @State private var errorText: String?
    @State private var didLoad = false
    @State private var voiceOn = false
    @State private var voiceScript = ""
    @State private var previewSynth = AVSpeechSynthesizer()

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
                            shareFile = videoURL.map { ShareFile(url: $0) }
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
                    if let errorText {
                        Text(errorText)
                            .font(.cinema(13))
                            .foregroundStyle(Theme.red)
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

                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(isOn: $voiceOn) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add a voiceover")
                                    .font(.cinema(15, weight: .semibold))
                                Text("A natural AI voice reads your script over the video.")
                                    .font(.cinema(12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .tint(Theme.red)
                        if voiceOn {
                            TextField("What should it say?", text: $voiceScript, axis: .vertical)
                                .lineLimit(3...7)
                                .font(.cinema(14))
                                .padding(10)
                                .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            let talk = VoiceoverWriter.estimatedSeconds(voiceScript)
                            let length = Double(photos.count) * seconds + 2
                            HStack {
                                Text(talk > length - 0.5 && !photos.isEmpty ? "About \(Int(talk.rounded())) seconds of talking, but the reel is \(Int(length)). Shorten it or add time per photo." : "About \(Int(talk.rounded())) seconds of talking.")
                                    .font(.cinema(12))
                                    .foregroundStyle(talk > length - 0.5 && !photos.isEmpty ? Theme.red : Theme.textTertiary)
                                Spacer()
                                Button {
                                    if previewSynth.isSpeaking {
                                        previewSynth.stopSpeaking(at: .immediate)
                                    } else {
                                        let utterance = AVSpeechUtterance(string: voiceScript)
                                        utterance.voice = VoiceoverWriter.bestVoice()
                                        utterance.rate = 0.5
                                        previewSynth.speak(utterance)
                                    }
                                } label: {
                                    Label("Hear it", systemImage: "speaker.wave.2.fill")
                                        .font(.cinema(13, weight: .semibold))
                                }
                                .tint(Theme.red)
                                .disabled(voiceScript.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                    }
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
                if photos.isEmpty { photos = ListingPhotoStore.load(listing.id, limit: 10) }
                voiceScript = ReelMixer.listingScript(listing, agentName: store.profile.name, seconds: Double(max(photos.count, 4)) * seconds + 2)
            }
        }
        .sheet(item: $shareFile) { file in
            ActivityView(items: [file.url])
                .presentationDetents([.medium, .large])
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
            var finalURL = url
            var usedVoice = false
            let script = voiceScript.trimmingCharacters(in: .whitespacesAndNewlines)
            if voiceOn && !script.isEmpty {
                previewSynth.stopSpeaking(at: .immediate)
                do {
                    let audioURL = FileManager.default.temporaryDirectory.appendingPathComponent("closeup-vo-\(UUID().uuidString.prefix(6)).caf")
                    try await VoiceoverWriter().write(script, to: audioURL)
                    finalURL = try await ReelMixer.addVoiceover(video: url, audio: audioURL)
                    usedVoice = true
                } catch {
                    errorText = "The reel is ready, but the voiceover didn't work on this phone. Try again or post it without one."
                }
            }
            videoURL = finalURL
            player = AVPlayer(url: finalURL)
            player?.play()
            store.showToast(usedVoice ? "Your reel is ready, voiceover included" : "Your reel is ready")
        } catch {
            errorText = "Couldn't make the reel. Try fewer photos."
        }
        isRendering = false
    }
}
