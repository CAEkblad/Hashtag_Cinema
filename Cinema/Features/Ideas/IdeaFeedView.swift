import SwiftUI
import PhotosUI
import TipKit

struct IdeaFeedView: View {
    @Environment(CinemaStore.self) private var store
    @State private var category: IdeaCategory?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showUploadRequest = false
    @State private var showPractice = false

    private var filtered: [Idea] {
        guard let category else { return store.ideas }
        return store.ideas.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TipView(NewIdeasTip())
                        .tint(Theme.red)
                    createRow
                    scriptLink
                    hookLink
                    NavigationLink(value: Route.teleprompter) {
                        IconRow(icon: "text.viewfinder", title: "Teleprompter for your own script", subtitle: "Paste anything and film it")
                            .cardStyle(padding: 14)
                    }
                    .buttonStyle(.plain)
                    posterLink
                    marketLink
                    categoryChips
                    HStack {
                        SectionHeader(title: "Shoot this today")
                        Button {
                            Task { await store.refreshIdeas() }
                        } label: {
                            if store.isRefreshingIdeas {
                                ProgressView().tint(Theme.red)
                            } else {
                                Label("New ideas", systemImage: "sparkles")
                                    .font(.cinema(14, weight: .semibold))
                            }
                        }
                        .disabled(store.isRefreshingIdeas)
                    }

                    if filtered.isEmpty {
                        EmptyStateView(title: "No ideas here yet", message: "Tap New ideas and the idea engine will write some for your market.", icon: "lightbulb")
                    } else {
                        ForEach(filtered) { idea in
                            NavigationLink(value: Route.idea(idea.id)) {
                                IdeaCard(idea: idea)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(Theme.gutter)
            }
            .cinemaScreen()
            .navigationTitle("Create")
            .cinemaDestinations()
            .onChange(of: pickerItem) { _, newValue in
                if newValue != nil { showUploadRequest = true }
            }
            .sheet(isPresented: $showUploadRequest, onDismiss: { pickerItem = nil }) {
                EditRequestView(idea: nil, recordedURL: nil, sourceLabel: "Video from your camera roll")
            }
            .fullScreenCover(isPresented: $showPractice) {
                CameraView(idea: store.ideaOfTheDay, practiceMode: true)
            }
        }
    }

    private var createRow: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $pickerItem, matching: .videos) {
                createTile("Upload a clip", subtitle: "From camera roll", icon: "square.and.arrow.up.fill")
            }
            .buttonStyle(.plain)

            Button {
                showPractice = true
            } label: {
                createTile("Practice", subtitle: "Coach notes, no credits", icon: "figure.mind.and.body")
            }
            .buttonStyle(.plain)
        }
    }

    private var hookLink: some View {
        NavigationLink(value: Route.hooks) {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Theme.red)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Hook library")
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("36 proven first lines for your city")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .cardStyle(padding: 14)
        }
        .buttonStyle(.plain)
    }

    private var scriptLink: some View {
        NavigationLink(value: Route.scriptWriter) {
            HStack(spacing: 10) {
                Image(systemName: "text.quote")
                    .foregroundStyle(Theme.red)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Write a script from any topic")
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Hook, script and shots in one tap")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .cardStyle(padding: 14)
        }
        .buttonStyle(.plain)
    }

    private var posterLink: some View {
        NavigationLink(value: Route.posterMaker) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.on.rectangle.portrait.fill")
                    .foregroundStyle(Theme.red)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Make a listing poster")
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Just listed, just sold, coming soon, open house")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .cardStyle(padding: 14)
        }
        .buttonStyle(.plain)
    }

    private var marketLink: some View {
        NavigationLink(value: Route.market) {
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Theme.red)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Ideas for \(store.allMarkets.map(\.name).joined(separator: ", "))")
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text("This month's local topics and neighborhood spotlights")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .cardStyle(padding: 14)
        }
        .buttonStyle(.plain)
    }

    private func createTile(_ title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.red)
            Text(title)
                .font(.cinema(16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(subtitle)
                .font(.cinema(12))
                .foregroundStyle(Theme.textSecondary)
        }
        .cardStyle(padding: 14)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "For you", icon: "star.fill", isOn: category == nil) { category = nil }
                ForEach(IdeaCategory.allCases) { option in
                    chip(title: option.title, icon: option.icon, isOn: category == option) { category = option }
                }
            }
        }
    }

    private func chip(title: String, icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
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

struct IdeaCard: View {
    let idea: Idea

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Pill(text: idea.category.title, icon: idea.category.icon)
                Pill(text: "\(idea.targetSeconds)s", icon: "timer")
                if let city = idea.cityName {
                    Pill(text: city, icon: "mappin", color: Theme.redSoft, textColor: Theme.red)
                }
                if let author = idea.remixedFrom {
                    Pill(text: "Remix of \(author)", icon: "arrow.triangle.2.circlepath", color: Theme.red.opacity(0.25))
                }
                Spacer(minLength: 0)
            }
            Text(idea.title)
                .font(.cinema(18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.leading)
            Text("\u{201C}\(idea.hook)\u{201D}")
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
            HStack {
                Label("\(idea.shots.count) shots", systemImage: "list.bullet.rectangle")
                Spacer()
                Text("Open")
                    .foregroundStyle(Theme.red)
            }
            .font(.cinema(13, weight: .semibold))
            .foregroundStyle(Theme.textTertiary)
        }
        .cardStyle()
    }
}
