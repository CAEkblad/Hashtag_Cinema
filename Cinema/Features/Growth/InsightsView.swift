import SwiftUI
import Charts

/// How your content is doing: reach over time, best days to post, what topics win, and where views come from.
struct InsightsView: View {
    @Environment(CinemaStore.self) private var store

    private var data: ContentInsights { store.insights }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    StatTile(value: data.totalViews.compact, label: "Views, 8 weeks", icon: "eye.fill")
                    StatTile(value: "\(data.totalLeads)", label: "Leads from video", icon: "person.badge.plus")
                    StatTile(value: "\(store.weeklyReport.avgWatchSeconds)s", label: "Avg watch", icon: "timer")
                }

                chartCard("Views per week", subtitle: data.trendLine) {
                    Chart(data.weekly) { point in
                        AreaMark(x: .value("Week", point.weekStart, unit: .weekOfYear), y: .value("Views", point.views))
                            .foregroundStyle(LinearGradient(colors: [Theme.red.opacity(0.35), Theme.red.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)
                        LineMark(x: .value("Week", point.weekStart, unit: .weekOfYear), y: .value("Views", point.views))
                            .foregroundStyle(Theme.red)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                    .chartYAxis { AxisMarks(position: .leading) }
                    .frame(height: 180)
                }

                chartCard("Best days to post", subtitle: "Average views by the day you posted. Post on \(data.bestDay) when you can.") {
                    Chart(data.byWeekday) { item in
                        BarMark(x: .value("Day", item.label), y: .value("Views", item.value))
                            .foregroundStyle(item.label == data.bestDay ? Theme.red : Theme.red.opacity(0.3))
                            .cornerRadius(5)
                    }
                    .frame(height: 160)
                }

                chartCard("What your audience watches", subtitle: "Average views by video type") {
                    Chart(data.byCategory) { item in
                        BarMark(x: .value("Views", item.value), y: .value("Type", item.label))
                            .foregroundStyle(Theme.red.gradient)
                            .cornerRadius(5)
                            .annotation(position: .trailing) {
                                Text(item.value.compact)
                                    .font(.cinema(11, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                    }
                    .chartXAxis(.hidden)
                    .frame(height: CGFloat(data.byCategory.count) * 36)
                }

                chartCard("Where views come from", subtitle: nil) {
                    VStack(spacing: 10) {
                        ForEach(data.byPlatform) { item in
                            HStack(spacing: 10) {
                                Text(item.label)
                                    .font(.cinema(14, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                                    .frame(width: 84, alignment: .leading)
                                GeometryReader { geo in
                                    Capsule().fill(Theme.surfaceRaised)
                                        .overlay(alignment: .leading) {
                                            Capsule().fill(Theme.red)
                                                .frame(width: max(6, geo.size.width * item.share))
                                        }
                                }
                                .frame(height: 10)
                                Text("\(Int((item.share * 100).rounded()))%")
                                    .font(.cinema(13, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("What to try next", systemImage: "lightbulb.fill")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.red)
                    Text("Your \(data.byCategory.first?.label.lowercased() ?? "local") videos get the most views. Film two more this week and post one on \(data.bestDay).")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textPrimary)
                    NavigationLink(value: Route.weekPlan) {
                        Text("Plan my week")
                            .font(.cinema(14, weight: .semibold))
                    }
                    .foregroundStyle(Theme.red)
                }
                .cardStyle()

                Text("Sample numbers until your Instagram, Facebook, TikTok and YouTube accounts are connected to the live backend.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func chartCard<Content: View>(_ title: String, subtitle: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.cinema(17, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            content()
        }
        .cardStyle()
    }
}

struct ContentInsights {
    struct WeekPoint: Identifiable {
        var id: Date { weekStart }
        var weekStart: Date
        var views: Int
    }

    struct Bar: Identifiable {
        var id: String { label }
        var label: String
        var value: Int
    }

    struct Share: Identifiable {
        var id: String { label }
        var label: String
        var share: Double
    }

    var weekly: [WeekPoint]
    var byWeekday: [Bar]
    var byCategory: [Bar]
    var byPlatform: [Share]
    var totalLeads: Int

    var totalViews: Int { weekly.reduce(0) { $0 + $1.views } }
    var bestDay: String { byWeekday.max { $0.value < $1.value }?.label ?? "Tue" }

    var trendLine: String {
        guard weekly.count >= 4 else { return "" }
        let recent = weekly.suffix(4).reduce(0) { $0 + $1.views }
        let earlier = weekly.prefix(4).reduce(0) { $0 + $1.views }
        guard earlier > 0 else { return "" }
        let change = Double(recent - earlier) / Double(earlier) * 100
        return change >= 0 ? "Up \(Int(change.rounded()))% vs the 4 weeks before" : "Down \(Int(-change.rounded()))% vs the 4 weeks before"
    }
}
