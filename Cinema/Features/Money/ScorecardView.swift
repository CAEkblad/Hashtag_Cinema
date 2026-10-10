import SwiftUI

/// Weekly targets, 4-1-1 style: a few numbers that, hit every week, add up to the year.
struct WeeklyTargets: Codable, Equatable {
    var videos = 3
    var touches = 100
    var appointments = 2
    var newLeads = 5
    var priority = ""
}

struct ScorecardView: View {
    @Environment(CinemaStore.self) private var store
    @State private var targets = WeeklyTargets()
    @State private var didLoad = false

    private struct Line: Identifiable {
        var id: String { title }
        var title: String
        var icon: String
        var actual: Int
        var target: Int
    }

    private var lines: [Line] {
        let week = store.thisWeek
        return [
            Line(title: "Videos posted", icon: "video.fill", actual: week.videos, target: targets.videos),
            Line(title: "Prospecting touches", icon: "hand.tap.fill", actual: week.touches, target: targets.touches),
            Line(title: "Appointments set", icon: "calendar.badge.checkmark", actual: week.appointments, target: targets.appointments),
            Line(title: "New leads", icon: "person.badge.plus", actual: week.newLeads, target: targets.newLeads)
        ]
    }

    private var score: Int {
        let parts = lines.map { $0.target > 0 ? min(1, Double($0.actual) / Double($0.target)) : 1 }
        return Int((parts.reduce(0, +) / Double(max(parts.count, 1)) * 100).rounded())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(score)%")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                    Text("of this week's targets hit · week of \(store.thisWeek.start.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.cinema(13, weight: .semibold))
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(score >= 80 ? Theme.success : Theme.red, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                ForEach(lines) { line in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label(line.title, systemImage: line.icon)
                                .font(.cinema(14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("\(line.actual) of \(line.target)")
                                .font(.cinema(14, weight: .bold))
                                .foregroundStyle(line.actual >= line.target ? Theme.success : Theme.red)
                        }
                        ProgressView(value: Double(min(line.actual, line.target)), total: Double(max(line.target, 1)))
                            .tint(line.actual >= line.target ? Theme.success : Theme.red)
                    }
                    .cardStyle(padding: 14)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly targets")
                        .font(.cinema(15, weight: .bold))
                    Stepper("\(targets.videos) videos", value: $targets.videos, in: 0...21)
                    Stepper("\(targets.touches) touches", value: $targets.touches, in: 0...500, step: 10)
                    Stepper("\(targets.appointments) appointments", value: $targets.appointments, in: 0...20)
                    Stepper("\(targets.newLeads) new leads", value: $targets.newLeads, in: 0...50)
                    TextField("This week's one big priority", text: $targets.priority, axis: .vertical)
                        .lineLimit(1...3)
                        .inputStyle()
                }
                .font(.cinema(14))
                .foregroundStyle(Theme.textPrimary)
                .cardStyle()

                ShareLink(item: shareText) {
                    Label(store.lex.isKW ? "Send my 4-1-1 to my Productivity Coach" : "Send to my accountability partner", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("Videos come from your posts, touches and appointments from Power hour, and leads from Leads. The week starts on your calendar's first day.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle(store.lex.weeklyPlanTitle)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            targets = store.weeklyTargets
        }
        .onChange(of: targets) { _, newValue in store.saveWeeklyTargets(newValue) }
    }

    private var shareText: String {
        var text = ["My week (\(score)% of targets):"]
        text += lines.map { "\($0.actual >= $0.target ? "✓" : "•") \($0.title): \($0.actual) of \($0.target)" }
        let priority = targets.priority.trimmingCharacters(in: .whitespacesAndNewlines)
        if !priority.isEmpty { text += ["", "Big priority: \(priority)"] }
        let miles = store.milesThisWeek
        if miles > 0 { text.append("Miles logged: \(Int(miles))") }
        return text.joined(separator: "\n")
    }
}
