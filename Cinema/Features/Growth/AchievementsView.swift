import SwiftUI

/// Creator level, badges and the city leaderboard.
struct AchievementsView: View {
    @Environment(CinemaStore.self) private var store

    private var unlocked: Int { store.achievements.filter(\.isUnlocked).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                levelCard
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Badges · \(unlocked) of \(store.achievements.count)")
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(store.achievements) { badge in
                            badgeCard(badge)
                        }
                    }
                }
                leaderboard
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var levelCard: some View {
        let level = store.creatorLevel
        let points = store.profile.points
        let next = level.next
        let progress: Double = {
            guard let next else { return 1 }
            let span = Double(next.minPoints - level.minPoints)
            return span > 0 ? min(1, Double(points - level.minPoints) / span) : 1
        }()
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: level.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Theme.red, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.title)
                        .font(.cinema(22, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(points.formatted()) points")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceRaised)
                    Capsule().fill(Theme.red).frame(width: max(8, geo.size.width * progress))
                }
            }
            .frame(height: 8)
            Text(next.map { "\(($0.minPoints - points).formatted()) points to \($0.title)" } ?? "Top level. You're a market icon.")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
            Text("Earn points by filming, posting, checking in on challenges, finishing lessons and planned videos.")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
        }
        .cardStyle()
    }

    private func badgeCard(_ badge: Achievement) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: badge.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(badge.isUnlocked ? .white : Theme.textTertiary)
                .frame(width: 40, height: 40)
                .background(badge.isUnlocked ? Theme.red : Theme.surfaceRaised, in: Circle())
            Text(badge.title)
                .font(.cinema(15, weight: .bold))
                .foregroundStyle(badge.isUnlocked ? Theme.textPrimary : Theme.textSecondary)
            Text(badge.detail)
                .font(.cinema(12))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if badge.isUnlocked {
                Label("+\(badge.points) points", systemImage: "checkmark.seal.fill")
                    .font(.cinema(11, weight: .semibold))
                    .foregroundStyle(Theme.success)
            } else {
                ProgressView(value: badge.fraction)
                    .tint(Theme.red)
                Text("\(min(badge.progress, badge.goal)) of \(badge.goal)")
                    .font(.cinema(11, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 12)
        .opacity(badge.isUnlocked ? 1 : 0.85)
    }

    private var leaderboard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Top creators in \(store.homeCity.name)")
            VStack(spacing: 0) {
                ForEach(Array(store.cityLeaderboard.prefix(8).enumerated()), id: \.element.id) { index, entry in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.cinema(14, weight: .bold))
                            .foregroundStyle(index < 3 ? Theme.red : Theme.textTertiary)
                            .frame(width: 22)
                        Text(entry.isMe ? "\(entry.name) (you)" : entry.name)
                            .font(.cinema(15, weight: entry.isMe ? .bold : .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("\(entry.points.formatted()) pts")
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(entry.isMe ? Theme.redSoft : Color.clear)
                    if index < min(store.cityLeaderboard.count, 8) - 1 { Divider() }
                }
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).stroke(Theme.stroke, lineWidth: 1))
            Text("Sample leaderboard until the live backend is connected.")
                .font(.cinema(11))
                .foregroundStyle(Theme.textTertiary)
        }
    }
}
