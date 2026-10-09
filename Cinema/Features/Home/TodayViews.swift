import SwiftUI

/// Four simple steps for today, so agents always know what to do next.
struct TodayPlanCard: View {
    @Environment(CinemaStore.self) private var store
    let onFilm: () -> Void
    let onReview: () -> Void
    let onPost: () -> Void
    let onLeads: () -> Void

    private struct Step: Identifiable {
        var id: String
        var title: String
        var detail: String
        var icon: String
        var done: Bool
        var action: () -> Void
    }

    private var steps: [Step] {
        let review = store.clipsNeedingReview.count
        let leads = store.newLeadCount
        return [
            Step(id: "film", title: "Film today's idea", detail: store.ideaOfTheDay.map { "\($0.title) · \($0.targetSeconds)s" } ?? "Pick any idea in Create", icon: "video.fill", done: store.filmedToday, action: onFilm),
            Step(id: "review", title: review == 0 ? "No edits to review" : "Review \(review) edited \(review == 1 ? "video" : "videos")", detail: "Approve or leave a note for your editor", icon: "eye.fill", done: review == 0, action: onReview),
            Step(id: "post", title: "Post one video", detail: "Instagram, Facebook, TikTok and YouTube at once", icon: "paperplane.fill", done: store.postedToday, action: onPost),
            Step(id: "leads", title: leads == 0 ? "No new leads" : "Reply to \(leads) new \(leads == 1 ? "lead" : "leads")", detail: "People who commented your keyword", icon: "person.badge.plus", done: leads == 0, action: onLeads)
        ]
    }

    var body: some View {
        let list = steps
        let doneCount = list.filter(\.done).count
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ProgressRing(progress: Double(doneCount) / Double(list.count), lineWidth: 5, size: 50)
                VStack(alignment: .leading, spacing: 2) {
                    Text(doneCount == list.count ? "Today is done. Nice work." : "Today's plan")
                        .font(.cinema(18, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(doneCount) of \(list.count) done · about 15 minutes")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            VStack(spacing: 0) {
                ForEach(list) { step in
                    Button(action: step.action) {
                        HStack(spacing: 12) {
                            Image(systemName: step.done ? "checkmark.circle.fill" : step.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(step.done ? Theme.success : Theme.red)
                                .frame(width: 34, height: 34)
                                .background(step.done ? Theme.success.opacity(0.12) : Theme.redSoft, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.title)
                                    .font(.cinema(15, weight: .semibold))
                                    .foregroundStyle(step.done ? Theme.textSecondary : Theme.textPrimary)
                                    .strikethrough(step.done && step.id != "review" && step.id != "leads", color: Theme.textTertiary)
                                Text(step.detail)
                                    .font(.cinema(12))
                                    .foregroundStyle(Theme.textTertiary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                            if !step.done {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(step.done)
                }
            }
        }
        .cardStyle()
    }
}

/// Posts this week against the agent's weekly goal.
struct WeeklyGoalCard: View {
    @Environment(CinemaStore.self) private var store

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("This week")
                    .font(.cinema(12, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                Text("\(store.postsThisWeek) of \(store.profile.weeklyGoal) videos posted")
                    .font(.cinema(16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.surfaceRaised)
                        Capsule().fill(Theme.red)
                            .frame(width: max(8, geo.size.width * store.weeklyProgress))
                    }
                }
                .frame(height: 8)
            }
            VStack(alignment: .trailing, spacing: 8) {
                Stepper("Weekly goal", value: Binding(get: { store.profile.weeklyGoal }, set: { store.setWeeklyGoal($0) }), in: 1...14)
                    .labelsHidden()
                NavigationLink(value: Route.weekPlan) {
                    Label(store.weekPlan.isEmpty ? "Plan my week" : "My plan", systemImage: "calendar")
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(Theme.red)
                }
            }
        }
        .cardStyle()
    }
}

/// Checklist for new accounts. Hides itself when done or dismissed.
struct GettingStartedCard: View {
    @Environment(CinemaStore.self) private var store
    let onStep: (String) -> Void

    var body: some View {
        let steps = store.starterSteps
        let done = steps.filter(\.isDone).count
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Get set up")
                        .font(.cinema(18, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(done) of \(steps.count) done. Each one takes a minute.")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button {
                    store.dismissGettingStarted()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(8)
                        .background(Theme.surfaceRaised, in: Circle())
                }
                .accessibilityLabel("Hide setup checklist")
            }
            ForEach(steps) { step in
                Button {
                    onStep(step.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: step.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(step.isDone ? Theme.success : Theme.textTertiary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(step.title)
                                .font(.cinema(15, weight: .semibold))
                                .foregroundStyle(step.isDone ? Theme.textSecondary : Theme.textPrimary)
                            Text(step.detail)
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: step.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.red.opacity(step.isDone ? 0.35 : 1))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(step.isDone)
            }
        }
        .cardStyle()
        .overlay(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).stroke(Theme.red.opacity(0.25), lineWidth: 1))
    }
}

/// Home teaser for the market screen with the top topic this month.
struct MarketTeaserCard: View {
    @Environment(CinemaStore.self) private var store

    var body: some View {
        let city = store.homeCity
        HStack(spacing: 14) {
            Image(systemName: city.region.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Theme.red, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("My market: \(city.name)")
                    .font(.cinema(16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(store.marketMoments.first.map { "This month: \($0.title)" } ?? "Local ideas, neighborhoods and nearby cities")
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.textTertiary)
        }
        .cardStyle()
    }
}
