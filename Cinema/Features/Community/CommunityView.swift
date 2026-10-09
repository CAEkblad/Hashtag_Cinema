import SwiftUI

struct CommunityView: View {
    @Environment(CinemaStore.self) private var store
    @State private var section: CommunitySection = .feed
    @State private var showNewPost = false
    @State private var kindFilter: CommunityPostKind?

    enum CommunitySection: String, CaseIterable, Identifiable {
        case feed = "Feed"
        case stories = "Success stories"
        case groups = "Groups"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Section", selection: $section) {
                        ForEach(CommunitySection.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch section {
                    case .feed: feed
                    case .stories: storiesList
                    case .groups: groupsList
                    }
                }
                .padding(Theme.gutter)
            }
            .cinemaScreen()
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewPost = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New post")
                }
            }
            .sheet(isPresented: $showNewPost) {
                NewCommunityPostView()
            }
            .cinemaDestinations()
        }
    }

    // MARK: Feed

    private var filteredPosts: [CommunityPost] {
        guard let kindFilter else { return store.communityPosts }
        return store.communityPosts.filter { $0.kind == kindFilter }
    }

    private var feed: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip("All", icon: "square.grid.2x2", isOn: kindFilter == nil) { kindFilter = nil }
                    ForEach(CommunityPostKind.allCases) { kind in
                        filterChip(kind.title + "s", icon: kind.icon, isOn: kindFilter == kind) { kindFilter = kind }
                    }
                }
            }
            ForEach(filteredPosts) { post in
                CommunityPostCard(post: post)
            }
        }
    }

    private func filterChip(_ title: String, icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(isOn ? Color.white : Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isOn ? Theme.red : Theme.surface, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Stories

    private var storiesList: some View {
        VStack(spacing: 14) {
            ForEach(store.stories) { story in
                NavigationLink(value: Route.story(story.id)) {
                    VStack(alignment: .leading, spacing: 10) {
                        ZStack(alignment: .bottomLeading) {
                            Theme.gradient(story.paletteIndex)
                                .frame(height: 140)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(story.agent)
                                    .font(.cinema(13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.85))
                                Text(story.headline)
                                    .font(.cinema(20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(14)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        Text(story.summary)
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    .cardStyle(padding: 10)
                }
                .buttonStyle(.plain)
            }
            Text("Want to be featured? Share your path in the feed with the Win tag.")
                .font(.cinema(13))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    // MARK: Groups

    private var groupsList: some View {
        VStack(spacing: 12) {
            ForEach(store.groups) { group in
                HStack(spacing: 14) {
                    Image(systemName: group.icon)
                        .foregroundStyle(Theme.red)
                        .frame(width: 42, height: 42)
                        .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(group.name)
                                .font(.cinema(16, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            if group.isPrivate {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                        Text("\(group.detail) · \(group.members.compact) members")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    if !group.isPrivate {
                        Button(group.isJoined ? "Joined" : "Join") {
                            store.toggleGroup(group.id)
                        }
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(group.isJoined ? Theme.textSecondary : Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(group.isJoined ? Theme.surfaceRaised : Theme.red, in: Capsule())
                        .buttonStyle(.plain)
                    }
                }
                .cardStyle(padding: 14)
            }
        }
    }
}

// MARK: - Post card

struct CommunityPostCard: View {
    let post: CommunityPost
    @Environment(CinemaStore.self) private var store
    @State private var remixedIdeaID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Avatar(initials: initials, size: 38, paletteIndex: post.author.count % Theme.palettes.count)
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author)
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(post.market) · \(post.niche) · \(post.createdAt.relative)")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
                Pill(text: post.kind.title, icon: post.kind.icon)
            }

            Text(post.body)
                .font(.cinema(15))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let stat = post.stat {
                Label(stat, systemImage: "chart.bar.fill")
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(Theme.red)
            }

            if post.template != nil {
                if let remixedIdeaID {
                    NavigationLink(value: Route.idea(remixedIdeaID)) {
                        Label("Open your remix", systemImage: "arrow.right.circle.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button {
                        remixedIdeaID = store.remix(post)?.id
                    } label: {
                        Label("Remix this idea for my market", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }

            HStack(spacing: 20) {
                Button {
                    store.toggleLike(post.id)
                } label: {
                    Label("\(post.likes)", systemImage: post.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .foregroundStyle(post.isLiked ? Theme.red : Theme.textSecondary)
                }
                Label("\(post.replies)", systemImage: "bubble.left")
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Menu {
                    Button("Report post", systemImage: "flag") {
                        store.showToast("Thanks. Our team will review it.")
                    }
                    Button("Block \(post.author)", systemImage: "hand.raised") {
                        store.showToast("\(post.author) is blocked.")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 30, height: 24)
                }
            }
            .font(.cinema(14, weight: .semibold))
            .buttonStyle(.plain)
        }
        .cardStyle()
    }

    private var initials: String {
        String(post.author.split(separator: " ").prefix(2).compactMap { $0.first }).uppercased()
    }
}

// MARK: - Success story

struct SuccessStoryView: View {
    let story: SuccessStory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ZStack(alignment: .bottomLeading) {
                    Theme.gradient(story.paletteIndex)
                        .frame(height: 200)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(story.agent) · \(story.market)")
                            .font(.cinema(14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                        Text(story.headline)
                            .font(.cinema(26, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(18)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text(story.summary)
                    .font(.cinema(16))
                    .foregroundStyle(Theme.textPrimary)

                Text("Their path")
                    .font(.cinema(20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(story.milestones.enumerated()), id: \.offset) { index, milestone in
                        HStack(alignment: .top, spacing: 14) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(index == story.milestones.count - 1 ? Theme.red : Theme.surfaceRaised)
                                    .overlay(Circle().stroke(Theme.red, lineWidth: 2))
                                    .frame(width: 16, height: 16)
                                if index < story.milestones.count - 1 {
                                    Rectangle()
                                        .fill(Theme.red.opacity(0.4))
                                        .frame(width: 2, height: 34)
                                }
                            }
                            Text(milestone)
                                .font(.cinema(15))
                                .foregroundStyle(Theme.textPrimary)
                                .padding(.top, -2)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .cardStyle()
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationBarTitleDisplayMode(.inline)
    }
}
