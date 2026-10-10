import SwiftUI

/// What's working on TikTok, Instagram and Facebook for agents right now,
/// with one tap to make your own version.
struct TrendsView: View {
    @Environment(CinemaStore.self) private var store
    @State private var platform: TrendPlatform?
    @State private var savedOnly = false
    @State private var showPaste = false
    @State private var openIdea: Idea?

    private var shown: [Trend] {
        store.trends
            .filter { platform == nil || $0.platforms.contains(platform!) }
            .filter { !savedOnly || store.isSaved($0) }
            .enumerated()
            .sorted { a, b in a.element.heat == b.element.heat ? a.offset < b.offset : a.element.heat > b.element.heat }
            .map(\.element)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Formats getting views for agents on TikTok, Instagram and Facebook. Watch real examples, then make your own version for \(store.homeCity.name) in one tap.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                    Text(statusLine)
                        .font(.cinema(12, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }

                Button { showPaste = true } label: {
                    IconRow(icon: "link.badge.plus", title: "Saw a video you liked?", subtitle: "Paste the link and we'll make your version")
                        .cardStyle(padding: 14)
                }
                .buttonStyle(.plain)

                filters

                if shown.isEmpty {
                    EmptyStateView(title: savedOnly ? "No saved trends yet" : "Nothing here yet", message: savedOnly ? "Tap the bookmark on any trend to keep it here." : "Try another platform.", icon: "flame")
                } else {
                    ForEach(shown) { trend in
                        NavigationLink(value: Route.trend(trend.id)) {
                            TrendCard(trend: trend, city: store.homeCity, saved: store.isSaved(trend))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("CloseUp links out to each platform to watch examples. We never repost other creators' videos.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.top, 4)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Trends")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await store.refreshTrends(force: true) }
        .task { await store.refreshTrends() }
        .sheet(isPresented: $showPaste) {
            PasteVideoSheet { idea in
                showPaste = false
                Task {
                    try? await Task.sleep(nanoseconds: 450_000_000)
                    openIdea = idea
                }
            }
        }
        .navigationDestination(item: $openIdea) { idea in
            IdeaDetailView(idea: idea)
        }
    }

    private var statusLine: String {
        if store.trendsAreLive, let updated = store.trendsUpdatedAt {
            return "Updated \(updated.formatted(.relative(presentation: .named)))"
        }
        return "Picked by the CloseUp team · \(store.trends.count) formats"
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", icon: "square.grid.2x2.fill", isOn: platform == nil && !savedOnly) {
                    platform = nil
                    savedOnly = false
                }
                ForEach(TrendPlatform.allCases) { option in
                    chip(option.title, icon: option.icon, isOn: platform == option && !savedOnly) {
                        platform = option
                        savedOnly = false
                    }
                }
                chip("Saved", icon: "bookmark.fill", isOn: savedOnly) {
                    savedOnly = true
                    platform = nil
                }
            }
        }
    }

    private func chip(_ title: String, icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(isOn ? Color.white : Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isOn ? Theme.red : Theme.surface, in: Capsule())
                .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card

struct TrendCard: View {
    let trend: Trend
    let city: FloridaCity
    var saved = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                HeatPill(heat: trend.heat)
                ForEach(trend.platforms) { platform in
                    PlatformBadge(platform: platform)
                }
                Spacer(minLength: 0)
                if saved {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.red)
                }
            }
            Text(trend.title)
                .font(.cinema(18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.leading)
            Text(trend.format)
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.leading)
            Text("\u{201C}\(trend.fill(trend.hook, TrendContext(city: city, listing: nil, agentName: "")))\u{201D}")
                .font(.cinema(14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            HStack(spacing: 12) {
                Label("\(trend.seconds)s", systemImage: "timer")
                if trend.usesListing {
                    Label("Uses a listing", systemImage: "house.fill")
                }
                if !trend.exampleList.isEmpty {
                    Label("\(trend.exampleList.count) examples", systemImage: "play.rectangle.fill")
                }
                Spacer()
                Text("Make mine")
                    .foregroundStyle(Theme.red)
            }
            .font(.cinema(12, weight: .semibold))
            .foregroundStyle(Theme.textTertiary)
        }
        .cardStyle()
    }
}

struct HeatPill: View {
    let heat: TrendHeat

    var body: some View {
        Pill(
            text: heat.title,
            icon: heat.icon,
            color: heat == .hot ? Theme.red : (heat == .rising ? Theme.redSoft : Theme.surfaceRaised),
            textColor: heat == .hot ? .white : (heat == .rising ? Theme.red : Theme.textSecondary)
        )
    }
}

struct PlatformBadge: View {
    let platform: TrendPlatform

    var body: some View {
        Text(platform.short)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Theme.surfaceRaised, in: Capsule())
            .accessibilityLabel(platform.title)
    }
}

// MARK: - Detail

struct TrendDetailView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.openURL) private var openURL
    let trendID: String
    @State private var listingID: UUID?
    @State private var didPickDefault = false
    @State private var isMaking = false
    @State private var openIdea: Idea?

    private var trend: Trend? { store.trend(trendID) }
    private var listing: Listing? { listingID.flatMap { store.listing($0) } }

    var body: some View {
        if let trend {
            content(trend)
        } else {
            EmptyStateView(title: "This trend is gone", message: "Pull to refresh the Trends feed.", icon: "flame")
                .cinemaScreen()
        }
    }

    private func content(_ trend: Trend) -> some View {
        let context = TrendContext(city: listing?.city ?? store.homeCity, listing: listing, agentName: store.profile.name)
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        HeatPill(heat: trend.heat)
                        Pill(text: trend.category.title, icon: trend.category.icon)
                        Pill(text: "\(trend.seconds)s", icon: "timer")
                    }
                    Text(trend.title)
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(trend.format)
                        .font(.cinema(16))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    label("WHY IT WORKS")
                    Text(trend.whyItWorks)
                        .font(.cinema(15))
                        .foregroundStyle(Theme.textPrimary)
                    if let audio = trend.audioTip {
                        Label(audio, systemImage: "music.note")
                            .font(.cinema(13))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.top, 4)
                    }
                }
                .cardStyle()

                watchSection(trend)

                if !store.listings.isEmpty {
                    listingPicker(trend)
                }

                VStack(alignment: .leading, spacing: 10) {
                    label("YOUR VERSION")
                    Text("\u{201C}\(trend.fill(trend.hook, context))\u{201D}")
                        .font(.cinema(19, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    ForEach(Array(trend.beats.enumerated()), id: \.offset) { index, beat in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "\(index + 1).circle.fill")
                                .foregroundStyle(Theme.red)
                            Text(trend.fill(beat, context))
                                .font(.cinema(14))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer(minLength: 0)
                        }
                    }
                    if trend.usesListing && listing == nil {
                        Text("Pick a listing above and we'll drop in the price, specs and street.")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .cardStyle()

                hashtags(trend)
            }
            .padding(Theme.gutter)
            .padding(.bottom, 110)
        }
        .cinemaScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleSaved(trend)
                } label: {
                    Image(systemName: store.isSaved(trend) ? "bookmark.fill" : "bookmark")
                }
                .tint(Theme.red)
                .accessibilityLabel(store.isSaved(trend) ? "Remove from saved" : "Save trend")
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                make(trend)
            } label: {
                if isMaking {
                    ProgressView().tint(.white)
                } else {
                    Label("Make my version", systemImage: "wand.and.stars")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isMaking)
            .padding(Theme.gutter)
            .background(.ultraThinMaterial)
        }
        .navigationDestination(item: $openIdea) { idea in
            IdeaDetailView(idea: idea)
        }
        .onAppear {
            guard !didPickDefault else { return }
            didPickDefault = true
            if trend.usesListing {
                listingID = store.listings.first { $0.status != .sold }?.id ?? store.listings.first?.id
            }
        }
    }

    private func make(_ trend: Trend) {
        isMaking = true
        Task {
            let idea = await store.makeIdea(from: trend, listing: listing)
            isMaking = false
            openIdea = idea
        }
    }

    private func watchSection(_ trend: Trend) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            label("WATCH IT WORK")
            if !trend.exampleList.isEmpty {
                ForEach(trend.exampleList.prefix(6)) { example in
                    Button { openURL(example.url) } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: example.platform.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.red)
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(example.creator ?? example.platform.title)
                                    .font(.cinema(14, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                if let caption = example.caption, !caption.isEmpty {
                                    Text(caption)
                                        .font(.cinema(13))
                                        .foregroundStyle(Theme.textSecondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                if let stats = example.statLine {
                                    Text(stats)
                                        .font(.cinema(12, weight: .semibold))
                                        .foregroundStyle(Theme.textTertiary)
                                }
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Divider()
            }
            Text("See the newest ones on")
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 8) {
                ForEach(trend.platforms) { platform in
                    if let url = platform.searchURL(phrase: trend.searchPhrase, hashtag: trend.primaryHashtag) {
                        Button { openURL(url) } label: {
                            Label(platform.title, systemImage: platform.icon)
                                .font(.cinema(13, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundStyle(Theme.textPrimary)
                                .background(Theme.surfaceRaised, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func listingPicker(_ trend: Trend) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            label(trend.usesListing ? "FILM IT AT" : "TIE IT TO A LISTING (OPTIONAL)")
            Picker("Listing", selection: $listingID) {
                Text("No listing").tag(UUID?.none)
                ForEach(store.listings) { listing in
                    Text(listing.address).tag(UUID?.some(listing.id))
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.red)
        }
        .cardStyle(padding: 14)
    }

    private func hashtags(_ trend: Trend) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            label("HASHTAGS")
            FlowLayout(spacing: 8) {
                ForEach(trend.hashtags, id: \.self) { tag in
                    Button {
                        UIPasteboard.general.string = trend.hashtags.map { "#\($0)" }.joined(separator: " ")
                        store.showToast("Hashtags copied")
                    } label: {
                        Text("#\(tag)")
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(Theme.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.redSoft, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Tap to copy them all.")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
        }
        .cardStyle()
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.cinema(12, weight: .bold))
            .foregroundStyle(Theme.red)
            .tracking(1)
    }
}

// MARK: - Paste a link

/// The agent pastes a TikTok, Reel or Facebook video link. We read what we can,
/// suggest the closest format and write their version.
struct PasteVideoSheet: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var onMade: (Idea) -> Void

    @State private var text = ""
    @State private var video: PastedVideo?
    @State private var trendID: String?
    @State private var listingID: UUID?
    @State private var isLooking = false
    @State private var isMaking = false
    @State private var error: String?

    private var trend: Trend? { trendID.flatMap { store.trend($0) } }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Paste a TikTok, Instagram or Facebook link", text: $text)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit { Task { await lookUp() } }
                    PasteButton(payloadType: String.self) { strings in
                        if let first = strings.first {
                            text = first
                            Task { await lookUp() }
                        }
                    }
                    .tint(Theme.red)
                    Button {
                        Task { await lookUp() }
                    } label: {
                        if isLooking {
                            ProgressView()
                        } else {
                            Text("Look it up")
                        }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || isLooking)
                } header: {
                    Text("Video link")
                } footer: {
                    if let error {
                        Text(error).foregroundStyle(Theme.red)
                    } else {
                        Text("In TikTok, Instagram or Facebook tap Share, then Copy link.")
                    }
                }

                if let video {
                    Section("What we found") {
                        HStack(alignment: .top, spacing: 12) {
                            if let thumb = video.thumbnailURL {
                                AsyncImage(url: thumb) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Theme.surfaceRaised
                                }
                                .frame(width: 60, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            } else {
                                Image(systemName: video.platform?.icon ?? "play.rectangle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(Theme.red)
                                    .frame(width: 60, height: 60)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(video.creator ?? video.platform?.title ?? "Video")
                                    .font(.cinema(15, weight: .semibold))
                                Text(video.caption?.isEmpty == false ? video.caption! : "We can't read the caption from \(video.platform?.title ?? "this site"). Pick the format below.")
                                    .font(.cinema(13))
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(4)
                            }
                        }
                        Button("Watch it again") { UIApplication.shared.open(video.url) }
                            .tint(Theme.red)
                    }

                    Section {
                        Picker("Format", selection: $trendID) {
                            ForEach(store.trends) { trend in
                                Text(trend.title).tag(String?.some(trend.id))
                            }
                        }
                        .tint(Theme.red)
                        if !store.listings.isEmpty {
                            Picker("Listing", selection: $listingID) {
                                Text("No listing").tag(UUID?.none)
                                ForEach(store.listings) { listing in
                                    Text(listing.address).tag(UUID?.some(listing.id))
                                }
                            }
                            .tint(Theme.red)
                        }
                    } header: {
                        Text("Your version")
                    } footer: {
                        if let trend {
                            Text(trend.format)
                        }
                    }
                }
            }
            .navigationTitle("Copy a video idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if video != nil {
                    Button {
                        make()
                    } label: {
                        if isMaking {
                            ProgressView().tint(.white)
                        } else {
                            Label("Make my version", systemImage: "wand.and.stars")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(trend == nil || isMaking)
                    .padding(Theme.gutter)
                    .background(.ultraThinMaterial)
                }
            }
        }
    }

    private func lookUp() async {
        error = nil
        guard let url = VideoLinkInspector.firstURL(in: text) else {
            error = "That doesn't look like a link. Copy it from the Share button and paste it here."
            return
        }
        guard TrendPlatform.detect(url) != nil else {
            error = "Paste a TikTok, Instagram or Facebook video link."
            return
        }
        isLooking = true
        let found = await VideoLinkInspector.inspect(url)
        isLooking = false
        video = found
        let match = VideoLinkInspector.bestMatch(for: found.caption, in: store.trends)
        trendID = match?.id ?? trendID ?? store.trends.first?.id
        if let match, match.usesListing, listingID == nil {
            listingID = store.listings.first { $0.status != .sold }?.id
        }
    }

    private func make() {
        guard let trend, let video else { return }
        isMaking = true
        Task {
            let listing = listingID.flatMap { store.listing($0) }
            let idea = await store.makeIdea(from: trend, listing: listing, pasted: video)
            isMaking = false
            onMade(idea)
        }
    }
}
