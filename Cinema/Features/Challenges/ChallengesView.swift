import SwiftUI

struct ChallengesView: View {
    @Environment(CinemaStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    StatTile(value: "\(store.profile.streakDays)", label: "Day streak", icon: "flame.fill")
                    StatTile(value: "\(store.profile.points)", label: "Points", icon: "star.fill")
                }

                SectionHeader(title: "Your challenges")
                ForEach(store.challenges.filter { $0.isJoined }) { challenge in
                    NavigationLink(value: Route.challenge(challenge.id)) {
                        ChallengeCard(challenge: challenge)
                    }
                    .buttonStyle(.plain)
                }

                let open = store.challenges.filter { !$0.isJoined }
                if !open.isEmpty {
                    SectionHeader(title: "Join a challenge")
                    ForEach(open) { challenge in
                        NavigationLink(value: Route.challenge(challenge.id)) {
                            ChallengeCard(challenge: challenge)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Challenges")
    }
}

struct ChallengeCard: View {
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 14) {
            ProgressRing(progress: challenge.progress, size: 58)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(challenge.title)
                        .font(.cinema(16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    if challenge.scope == .brokerage {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                Text(challenge.subtitle)
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 8) {
                    Pill(text: challenge.prize, icon: "gift.fill")
                    Text("\(challenge.participants.compact) in")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }
}

struct ChallengeDetailView: View {
    let challengeID: UUID
    @Environment(CinemaStore.self) private var store
    @State private var showCamera = false

    var body: some View {
        Group {
            if let challenge = store.challenge(challengeID) {
                content(challenge)
            } else {
                EmptyStateView(title: "Challenge ended", message: "Check out the other challenges.", icon: "flag.checkered")
            }
        }
        .cinemaScreen()
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(idea: store.ideaOfTheDay, practiceMode: false)
        }
    }

    private func content(_ challenge: Challenge) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    ProgressRing(progress: challenge.progress, lineWidth: 8, size: 86)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(challenge.title)
                            .font(.cinema(24, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(challenge.subtitle)
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textSecondary)
                        Pill(text: "Prize: \(challenge.prize)", icon: "gift.fill", color: Theme.red, textColor: .white)
                    }
                }

                dayGrid(challenge)

                if challenge.isJoined {
                    if challenge.checkedInToday {
                        Label("Today is done. See you tomorrow.", systemImage: "checkmark.circle.fill")
                            .font(.cinema(15, weight: .semibold))
                            .foregroundStyle(Theme.success)
                            .cardStyle()
                    } else {
                        VStack(spacing: 10) {
                            Button {
                                showCamera = true
                            } label: {
                                Label("Film today's video", systemImage: "video.fill")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            Button("I posted today") { store.checkIn(challenge.id) }
                                .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                } else {
                    Button("Join challenge") { store.join(challenge.id) }
                        .buttonStyle(PrimaryButtonStyle())
                }

                SectionHeader(title: challenge.scope == .brokerage ? "Office leaderboard" : "National leaderboard")
                VStack(spacing: 0) {
                    ForEach(Array(challenge.leaderboard.sorted { $0.points > $1.points }.enumerated()), id: \.element.id) { index, entry in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.cinema(15, weight: .bold).monospacedDigit())
                                .foregroundStyle(index < 3 ? Theme.red : Theme.textSecondary)
                                .frame(width: 24)
                            Avatar(initials: initials(entry.name), size: 34, paletteIndex: index)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.isMe ? "\(entry.name) (you)" : entry.name)
                                    .font(.cinema(15, weight: entry.isMe ? .bold : .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(entry.market)
                                    .font(.cinema(12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text("\(entry.points) pts")
                                .font(.cinema(14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(entry.isMe ? Theme.red.opacity(0.12) : Color.clear)
                    }
                }
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))

                Text("Challenge chat lives in Community, so you can cheer each other on and share entries.")
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
    }

    private func dayGrid(_ challenge: Challenge) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(1...challenge.totalDays, id: \.self) { day in
                Text("\(day)")
                    .font(.cinema(12, weight: .semibold))
                    .foregroundStyle(day <= challenge.completedDays ? Color.white : Theme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(day <= challenge.completedDays ? Theme.red : Theme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private func initials(_ name: String) -> String {
        String(name.split(separator: " ").prefix(2).compactMap { $0.first }).uppercased()
    }
}
