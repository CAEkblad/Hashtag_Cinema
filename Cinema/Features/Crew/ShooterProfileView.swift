import SwiftUI

struct ShooterProfileView: View {
    @Environment(CinemaStore.self) private var store
    let shooterID: UUID
    @State private var requestService: ServiceType?

    var body: some View {
        if let shooter = store.shooter(shooterID) {
            content(shooter)
        } else {
            EmptyStateView(title: "Shooter not found", message: "This profile is no longer available.", icon: "person.crop.circle.badge.questionmark")
                .cinemaScreen()
        }
    }

    private func content(_ shooter: Shooter) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 10) {
                    Avatar(initials: shooter.initials, size: 84, paletteIndex: shooter.tier.paletteIndex)
                    Text(shooter.name)
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 8) {
                        TierBadge(tier: shooter.tier)
                        if let city = shooter.city {
                            Text(city.displayName)
                                .font(.cinema(13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Text(shooter.responseTime)
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 10) {
                    StatTile(value: shooter.ratingLabel, label: "Rating", icon: "star.fill")
                    StatTile(value: "\(shooter.jobsCompleted)", label: "Shoots", icon: "camera.fill")
                    StatTile(value: "\(shooter.fiveStarCount)", label: "5 star", icon: "hand.thumbsup.fill")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(shooter.bio)
                        .font(.cinema(15))
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    FlowLayout(spacing: 6) {
                        if shooter.backgroundChecked { Pill(text: "Background checked", icon: "checkmark.shield.fill", color: Theme.success.opacity(0.14), textColor: Theme.success) }
                        if shooter.insured { Pill(text: "Insured", icon: "umbrella.fill", color: Theme.success.opacity(0.14), textColor: Theme.success) }
                        if shooter.hasPart107 { Pill(text: "FAA Part 107 drone pilot", icon: "airplane", color: Theme.success.opacity(0.14), textColor: Theme.success) }
                        Pill(text: "\(shooter.yearsShooting) years shooting", icon: "clock.fill")
                    }
                    if !shooter.gear.isEmpty {
                        Label(shooter.gear, systemImage: "camera.metering.matrix")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .cardStyle()

                SectionHeader(title: "Portfolio")
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(shooter.portfolio) { item in
                        ZStack(alignment: .bottomLeading) {
                            Theme.gradient(item.paletteIndex)
                            Image(systemName: item.symbol)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            if item.isVideo {
                                Image(systemName: "play.circle.fill")
                                    .foregroundStyle(.white)
                                    .padding(6)
                            }
                        }
                        .frame(height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .accessibilityLabel(item.title)
                    }
                }

                SectionHeader(title: "Specialties")
                FlowLayout(spacing: 8) {
                    ForEach(shooter.skills) { skill in
                        Pill(text: skill.title, icon: skill.icon, color: Theme.redSoft, textColor: Theme.red)
                    }
                }

                SectionHeader(title: "Reviews")
                if shooter.reviews.isEmpty {
                    Text("New to #Cinema Crew. Be the first to review.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }
                ForEach(shooter.reviews) { review in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            StarRow(rating: review.rating)
                            Spacer()
                            Text(review.date.relative)
                                .font(.cinema(11))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Text(review.text)
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textPrimary)
                        Text(review.author)
                            .font(.cinema(12, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .cardStyle()
                }

                Text("Contact and scheduling go through #Cinema, so your shoot is insured and guaranteed.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
            .padding(.bottom, 80)
        }
        .cinemaScreen()
        .navigationTitle(shooter.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleFavorite(shooter: shooter)
                } label: {
                    Image(systemName: store.favoriteShooterIDs.contains(shooter.id) ? "heart.fill" : "heart")
                }
                .accessibilityLabel("Save to favorites")
            }
        }
        .safeAreaInset(edge: .bottom) {
            Menu {
                ForEach(ServiceType.allCases) { service in
                    Button {
                        requestService = service
                    } label: {
                        Label(service.name, systemImage: service.icon)
                    }
                }
            } label: {
                Label("Request \(shooter.name.split(separator: " ").first.map { String($0) } ?? shooter.name)", systemImage: "calendar.badge.plus")
                    .font(.cinema(16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.red, in: Capsule())
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 8)
        }
        .sheet(item: $requestService) { service in
            BookingFormView(service: service, preferredShooter: shooter)
        }
    }
}
