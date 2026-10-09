import SwiftUI

struct ContentCalendarView: View {
    @Environment(CinemaStore.self) private var store

    private var upcoming: [ScheduledPost] {
        store.posts.filter { $0.status == .scheduled }.sorted { $0.date < $1.date }
    }

    private var posted: [ScheduledPost] {
        store.posts.filter { $0.status == .posted }.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section("Scheduled") {
                if upcoming.isEmpty {
                    Text("Nothing scheduled. Approve a clip, then tap Post or schedule.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }
                ForEach(upcoming) { post in
                    PostRow(post: post)
                }
            }
            .listRowBackground(Theme.surface)

            Section("Posted") {
                ForEach(posted) { post in
                    PostRow(post: post)
                }
            }
            .listRowBackground(Theme.surface)
        }
        .cinemaScreen()
        .navigationTitle("Content calendar")
    }
}

struct PostRow: View {
    let post: ScheduledPost

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(post.clipTitle)
                    .font(.cinema(15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(post.date.shortDay + " · " + post.date.timeOnly)
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            HStack(spacing: 10) {
                ForEach(post.platforms) { platform in
                    Image(systemName: platform.icon)
                        .foregroundStyle(Theme.red)
                }
                if let keyword = post.leadKeyword {
                    Pill(text: "Keyword: \(keyword)", icon: "bubble.left.and.text.bubble.right.fill")
                }
                Spacer()
            }
            .font(.system(size: 14))
            if post.status == .posted {
                HStack(spacing: 16) {
                    Label(post.views.compact, systemImage: "eye")
                    Label(post.likes.compact, systemImage: "heart")
                    Label(post.comments.compact, systemImage: "bubble.left")
                }
                .font(.cinema(12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}
