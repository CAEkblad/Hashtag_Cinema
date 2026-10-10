import SwiftUI
import UIKit

/// A weekly team meeting agenda built from the team page: wins, the leaderboard,
/// a shout out, this week's video challenge and a role play.
struct TeamHuddleView: View {
    @Environment(CinemaStore.self) private var store
    @State private var didPost = false

    private var week: Int { Calendar.current.component(.weekOfYear, from: Date()) }
    private var weekAgo: Date { Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date() }

    private var wins: [TeamFeedItem] {
        let kinds: [TeamFeedItem.Kind] = [.sold, .listing, .testimonial, .milestone]
        return store.teamFeed.filter { $0.date >= weekAgo && kinds.contains($0.kind) && $0.title != "This week's huddle" }
    }

    private var ranked: [TeamMember] {
        (store.team?.members ?? []).sorted { score($0) > score($1) }
    }

    private var shoutOut: TeamMember? {
        store.team?.members.max { $0.videosThisMonth < $1.videosThisMonth }.flatMap { $0.videosThisMonth > 0 ? $0 : nil }
    }

    private var rolePlay: Objection { Objection.all[week % Objection.all.count] }
    private var challenge: Trend? { store.trendOfTheWeek }

    private func score(_ member: TeamMember) -> Int { member.videosThisMonth * 2 + member.leads + member.closings * 10 }

    var body: some View {
        Group {
            if let team = store.team {
                content(team)
            } else {
                VStack(spacing: 14) {
                    EmptyStateView(title: "Start or join a team first", message: "The huddle is built from your team page.", icon: "person.3")
                    NavigationLink(value: Route.team) {
                        Label("Go to My team", systemImage: "person.3.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(Theme.gutter)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .cinemaScreen()
        .navigationTitle("Team huddle")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ team: Team) -> some View {
        let agenda = agendaText(team)
        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(team.name) huddle")
                        .font(.cinema(24, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Week of \(weekStart.formatted(.dateTime.month(.abbreviated).day())). A 20 minute agenda built from your team page. Share it before the meeting or run it from here.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                section("1. Wins", icon: "trophy.fill", minutes: 5) {
                    if wins.isEmpty {
                        Text("No new listings, closings or reviews on the team page this week. Go around the room: one win each, big or small.")
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        ForEach(wins.prefix(6)) { item in
                            Label("\(item.authorName): \(item.title)", systemImage: item.kind.icon)
                                .font(.cinema(14))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                }

                section("2. Leaderboard", icon: "chart.bar.fill", minutes: 3) {
                    ForEach(Array(ranked.prefix(3).enumerated()), id: \.element.id) { index, member in
                        HStack {
                            Text("\(index + 1). \(member.name)")
                                .font(.cinema(14, weight: .semibold))
                            Spacer()
                            Text("\(member.videosThisMonth) videos · \(member.leads) leads · \(member.closings) closings")
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    if let shoutOut {
                        Label("Shout out: \(shoutOut.name) with \(shoutOut.videosThisMonth) videos this month", systemImage: "hands.clap.fill")
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(Theme.red)
                    }
                }

                section("3. This week's video challenge", icon: "flame.fill", minutes: 4) {
                    if let challenge {
                        Text(challenge.title)
                            .font(.cinema(16, weight: .bold))
                        Text(challenge.format)
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textSecondary)
                        NavigationLink(value: Route.trend(challenge.id)) {
                            Text("Make my version")
                                .font(.cinema(14, weight: .semibold))
                                .foregroundStyle(Theme.red)
                        }
                        Text("Everyone films one by Friday. It posts to the team page on its own.")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                section("4. Role play", icon: "bubble.left.and.bubble.right.fill", minutes: 6) {
                    Text("\u{201C}\(rolePlay.said)\u{201D}")
                        .font(.cinema(15, weight: .semibold))
                    Text(rolePlay.answer)
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Pair up. One person is the client, one is the agent, then switch.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }

                section("5. Commitments", icon: "checkmark.circle.fill", minutes: 2) {
                    Text("Each person says their number for the week: videos, appointments and touches. Check them on next week's scorecard.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                    NavigationLink(value: Route.scorecard) {
                        Text("Open the weekly scorecard")
                            .font(.cinema(14, weight: .semibold))
                            .foregroundStyle(Theme.red)
                    }
                }

                HStack(spacing: 10) {
                    ShareLink(item: agenda) {
                        Label("Share agenda", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Button {
                        store.postToTeam(.milestone, "This week's huddle", detail: huddleSummary, force: true)
                        store.showToast("Posted to the team page")
                        didPost = true
                    } label: {
                        Label(didPost ? "Posted" : "Post to team", systemImage: didPost ? "checkmark" : "person.3.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(didPost)
                }
            }
            .padding(Theme.gutter)
        }
    }

    private var weekStart: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    }

    private var huddleSummary: String {
        var parts: [String] = []
        if !wins.isEmpty { parts.append("\(wins.count) win\(wins.count == 1 ? "" : "s") this week") }
        if let challenge { parts.append("video challenge: \(challenge.title)") }
        parts.append("role play: \(rolePlay.said)")
        return parts.joined(separator: " · ")
    }

    private func agendaText(_ team: Team) -> String {
        var lines = ["\(team.name) huddle, week of \(weekStart.formatted(.dateTime.month(.abbreviated).day()))", ""]
        lines.append("1. Wins (5 min)")
        if wins.isEmpty {
            lines.append("   One win each, big or small.")
        } else {
            lines += wins.prefix(6).map { "   \($0.authorName): \($0.title)" }
        }
        lines.append("2. Leaderboard (3 min)")
        lines += ranked.prefix(3).enumerated().map { "   \($0.offset + 1). \($0.element.name): \($0.element.videosThisMonth) videos, \($0.element.leads) leads, \($0.element.closings) closings" }
        if let shoutOut { lines.append("   Shout out to \(shoutOut.name)!") }
        if let challenge {
            lines.append("3. Video challenge (4 min): \(challenge.title)")
            lines.append("   \(challenge.format) Everyone films one by Friday.")
        }
        lines.append("4. Role play (6 min): \"\(rolePlay.said)\"")
        lines.append("5. Commitments (2 min): your videos, appointments and touches for the week.")
        return lines.joined(separator: "\n")
    }

    private func section<Content: View>(_ title: String, icon: String, minutes: Int, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.cinema(16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(minutes) min")
                    .font(.cinema(12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
