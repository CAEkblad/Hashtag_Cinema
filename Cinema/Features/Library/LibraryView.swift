import SwiftUI

struct LibraryView: View {
    @Environment(CinemaStore.self) private var store
    @State private var filter: LibraryFilter = .all
    @State private var search = ""

    enum LibraryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case review = "To review"
        case pro = "Pro shoots"
        case phone = "Phone edits"
        case favorites = "Favorites"

        var id: String { rawValue }
    }

    private var filtered: [Clip] {
        let base: [Clip]
        switch filter {
        case .all: base = store.clips
        case .review: base = store.clips.filter { $0.status.needsAgent }
        case .pro: base = store.clips.filter { $0.source == .proShoot }
        case .phone: base = store.clips.filter { $0.source == .phoneEdit }
        case .favorites: base = store.clips.filter { $0.isFavorite }
        }
        guard !search.isEmpty else { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(search) ||
            ($0.listing ?? "").localizedCaseInsensitiveContains(search)
        }
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    filterChips
                    if filtered.isEmpty {
                        EmptyStateView(title: "Nothing here yet", message: "Film an idea or book a shoot and your clips land here.", icon: "film.stack")
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filtered) { clip in
                                NavigationLink(value: Route.clip(clip.id)) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ClipThumbnail(clip: clip, height: 250)
                                        Text(clip.title)
                                            .font(.cinema(14, weight: .semibold))
                                            .foregroundStyle(Theme.textPrimary)
                                            .lineLimit(1)
                                        HStack(spacing: 6) {
                                            Text(clip.source.title)
                                            if let views = clip.views {
                                                Text("· \(views.compact) views")
                                            }
                                        }
                                        .font(.cinema(12))
                                        .foregroundStyle(Theme.textSecondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        store.toggleFavorite(clip.id)
                                    } label: {
                                        Label(clip.isFavorite ? "Remove favorite" : "Favorite", systemImage: "star")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(Theme.gutter)
            }
            .cinemaScreen()
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search clips or addresses")
            .cinemaDestinations()
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibraryFilter.allCases) { option in
                    Button {
                        filter = option
                    } label: {
                        Text(option.rawValue)
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(filter == option ? Color.white : Theme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(filter == option ? Theme.red : Theme.surface, in: Capsule())
                            .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
