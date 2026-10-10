import SwiftUI

/// Film a week of videos in one sitting.
struct FilmDayView: View {
    @Environment(CinemaStore.self) private var store

    var body: some View {
        Group {
            if let session = store.filmDay {
                FilmDayRunView(session: session)
            } else {
                FilmDayPlanView()
            }
        }
        .cinemaScreen()
        .navigationTitle("Film day")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Plan

private struct FilmDayPlanView: View {
    @Environment(CinemaStore.self) private var store
    @State private var picked: [UUID] = []
    @State private var didPreselect = false
    @State private var prepDone: Set<Int> = []

    private var pickedIdeas: [Idea] { picked.compactMap { store.idea($0) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Film your week in one sitting")
                        .font(.cinema(24, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Pick your videos. We'll put them in an order that keeps you in one spot as long as possible and tell you when to change your top, so the week's posts don't look like one afternoon.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack(spacing: 10) {
                    StatTile(value: "\(picked.count)", label: "videos", icon: "video.fill")
                    StatTile(value: "\(FilmDayPlanner.minutes(for: pickedIdeas))", label: "minutes, about", icon: "clock.fill")
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Pick 3 to 7")
                    if store.ideas.isEmpty {
                        EmptyStateView(title: "No ideas yet", message: "Open Create and tap New ideas, or make one from Trends.", icon: "lightbulb")
                    }
                    ForEach(store.ideas.prefix(20)) { idea in
                        Button { toggle(idea.id) } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: picked.contains(idea.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(picked.contains(idea.id) ? Theme.red : Theme.textTertiary)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(idea.title)
                                        .font(.cinema(15, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                        .multilineTextAlignment(.leading)
                                    Label(FilmSpot(idea.category).title, systemImage: FilmSpot(idea.category).icon)
                                        .font(.cinema(12))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer(minLength: 0)
                                Text("\(idea.targetSeconds)s")
                                    .font(.cinema(12, weight: .semibold))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            .cardStyle(padding: 12)
                        }
                        .buttonStyle(.plain)
                        .disabled(!picked.contains(idea.id) && picked.count >= 7)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Before you start")
                    ForEach(Array(FilmDayPlanner.prep.enumerated()), id: \.offset) { index, item in
                        Button {
                            if prepDone.contains(index) { prepDone.remove(index) } else { prepDone.insert(index) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: prepDone.contains(index) ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(prepDone.contains(index) ? Theme.success : Theme.textTertiary)
                                Text(item)
                                    .font(.cinema(14))
                                    .foregroundStyle(Theme.textPrimary)
                                    .strikethrough(prepDone.contains(index), color: Theme.textTertiary)
                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .cardStyle()
            }
            .padding(Theme.gutter)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                store.startFilmDay(FilmDayPlanner.ordered(pickedIdeas))
            } label: {
                Label(picked.count < 3 ? "Pick at least 3" : "Start film day", systemImage: "video.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(picked.count < 3)
            .padding(Theme.gutter)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            guard !didPreselect else { return }
            didPreselect = true
            let goal = min(max(store.profile.weeklyGoal, 3), 7)
            picked = Array(store.ideas.prefix(goal).map(\.id))
        }
    }

    private func toggle(_ id: UUID) {
        if let index = picked.firstIndex(of: id) {
            picked.remove(at: index)
        } else if picked.count < 7 {
            picked.append(id)
        }
    }
}

// MARK: - Run

private struct FilmDayRunView: View {
    @Environment(CinemaStore.self) private var store
    let session: FilmDaySession
    @State private var filming: Idea?
    @State private var askAbout: Idea?
    @State private var confirmEnd = false
    @State private var openIdea: Idea?
    @State private var repurposeIdea: Idea?

    private var ideas: [Idea] { session.ideas }
    private var next: Idea? { ideas.first { !session.isDone($0.id) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 16) {
                    ProgressRing(progress: session.progress, size: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(session.filmed.count) of \(session.ideaIDs.count) filmed")
                            .font(.cinema(20, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(session.isComplete ? "That's a wrap." : "About \(FilmDayPlanner.minutes(for: ideas.filter { !session.isDone($0.id) })) minutes to go")
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .cardStyle()

                if let next {
                    upNext(next)
                } else {
                    wrapUp
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Today's lineup")
                    ForEach(Array(ideas.enumerated()), id: \.element.id) { index, idea in
                        if index == 0 || FilmSpot(ideas[index - 1].category) != FilmSpot(idea.category) {
                            Label(FilmSpot(idea.category).title, systemImage: FilmSpot(idea.category).icon)
                                .font(.cinema(12, weight: .bold))
                                .foregroundStyle(Theme.red)
                                .padding(.top, index == 0 ? 0 : 6)
                        }
                        if FilmDayPlanner.outfitChange(before: index) {
                            Label("Change your top", systemImage: "tshirt.fill")
                                .font(.cinema(12, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        lineupRow(idea)
                    }
                }

                Button(role: .destructive) { confirmEnd = true } label: {
                    Text(session.isComplete ? "Finish film day" : "End film day")
                        .font(.cinema(14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 6)
            }
            .padding(Theme.gutter)
        }
        .fullScreenCover(item: $filming, onDismiss: {
            if let idea = filmingDone { askAbout = idea }
        }) { idea in
            CameraView(idea: idea, practiceMode: false)
        }
        .confirmationDialog("Did you get \u{201C}\(askAbout?.title ?? "")\u{201D}?", isPresented: Binding(get: { askAbout != nil }, set: { if !$0 { askAbout = nil } }), titleVisibility: .visible) {
            if let idea = askAbout {
                Button("Got it") { store.markFilmDay(idea.id, filmed: true) }
                Button("Film it again") { reopen(idea) }
                Button("Skip this one") { store.markFilmDay(idea.id, filmed: false) }
                Button("Not yet", role: .cancel) {}
            }
        }
        .navigationDestination(item: $openIdea) { idea in
            IdeaDetailView(idea: idea)
        }
        .navigationDestination(item: $repurposeIdea) { idea in
            RepurposeView(idea: idea)
        }
        .confirmationDialog(session.isComplete ? "Finish film day?" : "End film day? Unfilmed videos stay in your ideas.", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button(session.isComplete ? "Finish" : "End film day", role: .destructive) { store.endFilmDay() }
        }
    }

    /// Kept separately so onDismiss knows which idea the camera was open for.
    @State private var filmingDone: Idea?

    private func film(_ idea: Idea) {
        filmingDone = idea
        filming = idea
    }

    private func reopen(_ idea: Idea) {
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            film(idea)
        }
    }

    private func upNext(_ idea: Idea) -> some View {
        let index = session.ideaIDs.firstIndex(of: idea.id) ?? 0
        let spot = FilmSpot(idea.category)
        return VStack(alignment: .leading, spacing: 12) {
            Text("UP NEXT")
                .font(.cinema(12, weight: .bold))
                .foregroundStyle(Theme.red)
                .tracking(1)
            Text(idea.title)
                .font(.cinema(20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("\u{201C}\(idea.hook)\u{201D}")
                .font(.cinema(15, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Label(spot.tip, systemImage: spot.icon)
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)
            if FilmDayPlanner.outfitChange(before: index) && !session.filmed.isEmpty {
                Label("New top before this one", systemImage: "tshirt.fill")
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(Theme.red)
            }
            Button { film(idea) } label: {
                Label("Film it", systemImage: "video.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            Button { openIdea = idea } label: {
                Text("See the shot list and script")
                    .font(.cinema(14, weight: .semibold))
                    .foregroundStyle(Theme.red)
                    .frame(maxWidth: .infinity)
            }
        }
        .cardStyle()
    }

    private var wrapUp: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You filmed \(session.filmed.count) \(session.filmed.count == 1 ? "video" : "videos")")
                .font(.cinema(20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Clips you sent for editing show up in Library. Space the posts out across the week so you show up every few days.")
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)
            NavigationLink(value: Route.weekPlan) {
                Label("Plan when they post", systemImage: "calendar.badge.plus")
            }
            .buttonStyle(PrimaryButtonStyle())
            if let first = session.ideas.first(where: { session.filmed.contains($0.id) }) {
                Button { repurposeIdea = first } label: {
                    Text("Turn them into posts for every platform")
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(Theme.red)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }

    private func lineupRow(_ idea: Idea) -> some View {
        let filmed = session.filmed.contains(idea.id)
        let skipped = session.skipped.contains(idea.id)
        return Button {
            if !filmed { film(idea) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: filmed ? "checkmark.circle.fill" : (skipped ? "forward.circle.fill" : "circle"))
                    .font(.system(size: 20))
                    .foregroundStyle(filmed ? Theme.success : Theme.textTertiary)
                Text(idea.title)
                    .font(.cinema(14, weight: .semibold))
                    .foregroundStyle(filmed || skipped ? Theme.textTertiary : Theme.textPrimary)
                    .strikethrough(filmed, color: Theme.textTertiary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if skipped {
                    Text("Skipped")
                        .font(.cinema(12, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .cardStyle(padding: 12)
        }
        .buttonStyle(.plain)
    }
}
