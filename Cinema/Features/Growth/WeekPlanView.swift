import SwiftUI

/// Your weekly goal turned into a day by day plan of videos to film.
struct WeekPlanView: View {
    @Environment(CinemaStore.self) private var store
    @State private var filming: Idea?
    @State private var openIdea: Idea?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if store.weekPlan.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.red)
                        Text("Plan \(store.profile.weeklyGoal) videos for this week")
                            .font(.cinema(18, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("We spread them across the week and mix ideas from every city you serve.")
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                        Button {
                            withAnimation { store.buildWeekPlan() }
                        } label: {
                            Label("Plan my week", systemImage: "sparkles")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .frame(maxWidth: .infinity)
                    .cardStyle(padding: 22)
                } else {
                    ForEach(store.weekPlan) { item in
                        dayCard(item)
                    }
                    Button {
                        withAnimation { store.buildWeekPlan() }
                    } label: {
                        Label("Rebuild my plan", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Plan my week")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $filming) { idea in
            CameraView(idea: idea, practiceMode: false)
        }
        .navigationDestination(item: $openIdea) { idea in
            IdeaDetailView(idea: idea)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ProgressRing(progress: store.weekPlan.isEmpty ? 0 : Double(store.weekPlanDone) / Double(store.weekPlan.count), lineWidth: 5, size: 54)
            VStack(alignment: .leading, spacing: 3) {
                Text(store.weekPlan.isEmpty ? "No plan yet" : "\(store.weekPlanDone) of \(store.weekPlan.count) filmed")
                    .font(.cinema(18, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Goal: \(store.profile.weeklyGoal) videos a week. Change it on Home.")
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    private func dayCard(_ item: PlannedVideo) -> some View {
        let isToday = Calendar.current.isDateInToday(item.day)
        return HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 2) {
                Text(item.day.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(.cinema(11, weight: .bold))
                    .foregroundStyle(isToday ? .white : Theme.red)
                Text(item.day.formatted(.dateTime.day()))
                    .font(.cinema(22, weight: .bold))
                    .foregroundStyle(isToday ? .white : Theme.textPrimary)
            }
            .frame(width: 54, height: 58)
            .background(isToday ? Theme.red : Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Pill(text: item.idea.category.title, icon: item.idea.category.icon)
                    if let city = item.idea.cityName {
                        Pill(text: city, icon: "mappin", color: Theme.redSoft, textColor: Theme.red)
                    }
                }
                Button {
                    openIdea = item.idea
                } label: {
                    Text(item.idea.title)
                        .font(.cinema(16, weight: .semibold))
                        .foregroundStyle(item.isDone ? Theme.textSecondary : Theme.textPrimary)
                        .strikethrough(item.isDone, color: Theme.textTertiary)
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)
                HStack(spacing: 16) {
                    Button {
                        filming = item.idea
                    } label: {
                        Label("Film", systemImage: "video.fill")
                    }
                    Button {
                        withAnimation { store.swapPlanned(item) }
                    } label: {
                        Label("Swap", systemImage: "shuffle")
                    }
                    Spacer()
                    Button {
                        withAnimation { store.togglePlanned(item) }
                    } label: {
                        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(item.isDone ? Theme.success : Theme.textTertiary)
                    }
                    .accessibilityLabel(item.isDone ? "Mark not filmed" : "Mark filmed")
                }
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(Theme.red)
                .buttonStyle(.plain)
            }
        }
        .cardStyle(padding: 14)
    }
}
