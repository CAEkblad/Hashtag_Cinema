import SwiftUI

struct CoachView: View {
    @Environment(CinemaStore.self) private var store
    @State private var showPractice = false
    @State private var expandedLevel: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                weeklyReport
                practiceCard
                tipsSection
                skillPath
                liveCoaching
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Coach")
        .fullScreenCover(isPresented: $showPractice) {
            CameraView(idea: store.ideaOfTheDay, practiceMode: true)
        }
    }

    private var weeklyReport: some View {
        let report = store.weeklyReport
        return VStack(alignment: .leading, spacing: 14) {
            Text("This week")
                .font(.cinema(22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: 10) {
                StatTile(value: "\(report.postsThisWeek)", label: "Posts", icon: "paperplane.fill")
                StatTile(value: "\(report.avgWatchSeconds)s", label: "Avg watch", icon: "eye.fill")
                StatTile(value: "\(report.leadsThisWeek)", label: "Leads", icon: "person.badge.plus")
            }
            reportLine("What worked", report.whatWorked, icon: "checkmark.circle.fill", color: Theme.success)
            reportLine("Try next", report.tryNext, icon: "arrow.forward.circle.fill", color: Theme.red)
            reportLine("Focus skill", report.focusSkill, icon: "scope", color: Theme.warning)
            Text("Based on how real viewers watched your posts.")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func reportLine(_ title: String, _ text: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.cinema(11, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                Text(text)
                    .font(.cinema(15))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cardStyle(padding: 14)
    }

    private var practiceCard: some View {
        Button {
            showPractice = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Theme.red, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice mode")
                        .font(.cinema(17, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Rehearse with the teleprompter. Get notes on pace, filler words and eye contact.")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Notes on your clips")
            ForEach(store.coachTips.prefix(6)) { tip in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: tip.area.icon)
                        .foregroundStyle(Theme.red)
                        .frame(width: 34, height: 34)
                        .background(Theme.surfaceRaised, in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(tip.area.title)
                                .font(.cinema(14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            if let clip = tip.clipTitle {
                                Text("· \(clip)")
                                    .font(.cinema(12))
                                    .foregroundStyle(Theme.textTertiary)
                                    .lineLimit(1)
                            }
                        }
                        Text(tip.text)
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .cardStyle(padding: 14)
            }
        }
    }

    private var skillPath: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your skill path")
            ForEach(store.skillPath) { level in
                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        withAnimation { expandedLevel = expandedLevel == level.id ? nil : level.id }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(level.isComplete ? Theme.success : (level.isCurrent ? Theme.red : Theme.surfaceRaised))
                                    .frame(width: 36, height: 36)
                                if level.isComplete {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                } else {
                                    Text("\(level.level)")
                                        .font(.cinema(15, weight: .bold))
                                        .foregroundStyle(level.isCurrent ? Color.white : Theme.textTertiary)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.title)
                                    .font(.cinema(16, weight: .semibold))
                                    .foregroundStyle(level.isComplete || level.isCurrent ? Theme.textPrimary : Theme.textSecondary)
                                Text(level.isCurrent ? "You are here" : "\(level.lessons.count) lessons")
                                    .font(.cinema(12))
                                    .foregroundStyle(level.isCurrent ? Theme.red : Theme.textTertiary)
                            }
                            Spacer()
                            Image(systemName: expandedLevel == level.id ? "chevron.up" : "chevron.down")
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    if expandedLevel == level.id {
                        ForEach(level.lessons, id: \.self) { lesson in
                            Label(lesson, systemImage: "play.circle")
                                .font(.cinema(14))
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.leading, 48)
                        }
                        if let course = store.courses.first(where: { $0.skillLevel == level.level }) {
                            NavigationLink(value: Route.course(course.id)) {
                                Label("Course: \(course.title)", systemImage: "play.rectangle.on.rectangle.fill")
                                    .font(.cinema(14, weight: .semibold))
                                    .foregroundStyle(Theme.red)
                                    .padding(.leading, 48)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .cardStyle(padding: 14)
            }
        }
    }

    private var liveCoaching: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "video.bubble.fill")
                    .foregroundStyle(Theme.red)
                Text("Live group coaching")
                    .font(.cinema(17, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Pill(text: "Pro", color: Theme.red, textColor: .white)
            }
            Text("Monthly session with Adam: bring a clip, get it reviewed live with agents from across the country.")
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)
            if store.profile.plan == .pro {
                Button("Save my seat") { store.showToast("Seat saved. We'll send the link.") }
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                NavigationLink(value: Route.plans) {
                    Text("Upgrade to Pro")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .cardStyle()
    }
}
