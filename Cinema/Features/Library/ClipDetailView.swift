import SwiftUI
import AVKit

struct ClipDetailView: View {
    let clipID: UUID

    @Environment(CinemaStore.self) private var store
    @State private var player: AVPlayer?
    @State private var commentText = ""
    @State private var format: AspectFormat = .vertical
    @State private var showCompose = false

    var body: some View {
        Group {
            if let clip = store.clip(clipID) {
                content(clip)
            } else {
                EmptyStateView(title: "Clip not found", message: "It may have been removed.", icon: "film")
            }
        }
        .cinemaScreen()
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { player?.pause() }
    }

    @ViewBuilder
    private func content(_ clip: Clip) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                videoArea(clip)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        StatusBadge(status: clip.status)
                        Pill(text: clip.source.title)
                        Spacer()
                        Button {
                            store.toggleFavorite(clip.id)
                        } label: {
                            Image(systemName: clip.isFavorite ? "star.fill" : "star")
                                .foregroundStyle(clip.isFavorite ? Theme.warning : Theme.textSecondary)
                        }
                    }
                    Text(clip.title)
                        .font(.cinema(24, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    if let listing = clip.listing {
                        Label(listing, systemImage: "mappin.and.ellipse")
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                if clip.status != .approved {
                    progressCard(clip)
                }

                formatPicker(clip)

                if clip.status == .readyForReview || clip.status == .revisions {
                    reviewActions(clip)
                }

                commentsCard(clip)

                if clip.status == .approved {
                    shareActions(clip)
                }
            }
            .padding(Theme.gutter)
        }
        .sheet(isPresented: $showCompose) {
            ComposePostView(clip: clip)
        }
    }

    // MARK: Video

    private func videoArea(_ clip: Clip) -> some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
            } else {
                Theme.gradient(clip.paletteIndex)
                Button {
                    if let url = clip.videoURL {
                        let newPlayer = AVPlayer(url: url)
                        player = newPlayer
                        newPlayer.play()
                    }
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .aspectRatio(aspect(for: format), contentMode: .fit)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 460)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.easeInOut, value: format)
    }

    private func aspect(for format: AspectFormat) -> CGFloat {
        switch format {
        case .vertical: return 9.0 / 16.0
        case .square: return 1
        case .wide: return 16.0 / 9.0
        }
    }

    private func formatPicker(_ clip: Clip) -> some View {
        Picker("Format", selection: $format) {
            ForEach(clip.formats) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: Progress

    private func progressCard(_ clip: Clip) -> some View {
        let steps: [EditStatus] = clip.source == .proShoot
            ? [.submitted, .editorPolish, .readyForReview, .approved]
            : [.submitted, .aiFirstCut, .readyForReview, .approved]
        let currentIndex = steps.firstIndex(of: clip.status) ?? (clip.status == .revisions ? 1 : 0)

        return VStack(alignment: .leading, spacing: 12) {
            Text(clip.status == .revisions ? "Your editor is making changes" : "Where your clip is")
                .font(.cinema(15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: 6) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    VStack(spacing: 6) {
                        Image(systemName: step.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(index <= currentIndex ? .white : Theme.textTertiary)
                            .frame(width: 32, height: 32)
                            .background(index <= currentIndex ? Theme.red : Theme.surfaceRaised, in: Circle())
                        Text(step.title)
                            .font(.cinema(10, weight: .semibold))
                            .foregroundStyle(index <= currentIndex ? Theme.textPrimary : Theme.textTertiary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }

    // MARK: Review

    private func reviewActions(_ clip: Clip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Review your edit")
                .font(.cinema(17, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Add time-stamped notes below, then approve or send back for changes.")
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 10) {
                Button {
                    store.approve(clip.id)
                } label: {
                    Label("Approve", systemImage: "checkmark")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    store.requestRevision(clip.id)
                } label: {
                    Label("Request changes", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(clip.status == .revisions)
            }
        }
        .cardStyle()
    }

    private func commentsCard(_ clip: Clip) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.cinema(17, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            if clip.comments.isEmpty {
                Text("No notes yet. Pause the video and add one at that moment.")
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)
            }

            ForEach(clip.comments) { comment in
                HStack(alignment: .top, spacing: 10) {
                    Button {
                        player?.seek(to: CMTime(seconds: comment.timestamp, preferredTimescale: 600))
                    } label: {
                        Text(comment.timestampLabel)
                            .font(.cinema(12, weight: .bold).monospacedDigit())
                            .foregroundStyle(Theme.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.red.opacity(0.15), in: Capsule())
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(comment.author)
                            .font(.cinema(12, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Text(comment.text)
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Add a note at \(currentTimeLabel)", text: $commentText)
                    .inputStyle()
                Button {
                    let time = player?.currentTime().seconds ?? 0
                    store.addComment(commentText, at: time.isFinite ? time : 0, to: clip.id)
                    commentText = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(commentText.isEmpty ? Theme.textTertiary : Theme.red)
                }
                .disabled(commentText.isEmpty)
            }
        }
        .cardStyle()
    }

    private var currentTimeLabel: String {
        let seconds = player?.currentTime().seconds ?? 0
        let total = seconds.isFinite ? Int(seconds) : 0
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: Share

    private func shareActions(_ clip: Clip) -> some View {
        VStack(spacing: 10) {
            Button {
                showCompose = true
            } label: {
                Label("Post or schedule", systemImage: "paperplane.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            if let url = clip.videoURL {
                ShareLink(item: url, subject: Text(clip.title)) {
                    Label("Share with the iOS share sheet", systemImage: "square.and.arrow.up")
                        .font(.cinema(16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Theme.surfaceRaised, in: Capsule())
                }
            }
        }
    }
}
