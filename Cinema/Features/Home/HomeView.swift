import SwiftUI

struct HomeView: View {
    @Environment(CinemaStore.self) private var store
    @Binding var selectedTab: AppTab
    @State private var path = NavigationPath()
    @State private var showCamera = false
    @State private var showBooking = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greeting
                    statsRow
                    if let idea = store.ideaOfTheDay {
                        ideaOfTheDayCard(idea)
                    }
                    quickActions
                    if !store.clipsNeedingReview.isEmpty {
                        reviewSection
                    }
                    challengeSection
                    if let course = store.courseInProgress, let lesson = course.nextLesson {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Keep learning", actionTitle: "Courses") { path.append(Route.courses) }
                            NavigationLink(value: Route.lesson(course: course.id, lesson: lesson.id)) {
                                ContinueLearningCard(course: course, lesson: lesson)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    coachSection
                    if let booking = store.upcomingBookings.first {
                        bookingSection(booking)
                    }
                }
                .padding(Theme.gutter)
            }
            .cinemaScreen()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CinemaLogo(size: 20)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: Route.leads) {
                        Image(systemName: "bell.fill")
                            .overlay(alignment: .topTrailing) {
                                if store.newLeadCount > 0 {
                                    Circle().fill(Theme.red).frame(width: 8, height: 8).offset(x: 3, y: -3)
                                }
                            }
                    }
                }
            }
            .cinemaDestinations()
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(idea: store.ideaOfTheDay, practiceMode: false)
            }
        }
    }

    // MARK: Sections

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hey \(store.profile.firstName)")
                .font(.cinema(30, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Here's your content plan for today.")
                .font(.cinema(16))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(store.profile.streakDays)", label: "Day streak", icon: "flame.fill")
            StatTile(value: "\(store.profile.credits)", label: "Edit credits", icon: "ticket.fill")
            StatTile(value: "\(store.weeklyReport.leadsThisWeek)", label: "Leads this week", icon: "person.badge.plus")
        }
    }

    private func ideaOfTheDayCard(_ idea: Idea) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Pill(text: "Shoot this today", icon: "sparkles", color: Theme.red, textColor: .white)
                Spacer()
                Pill(text: "\(idea.targetSeconds)s", icon: "timer")
            }
            Text(idea.title)
                .font(.cinema(22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("\u{201C}\(idea.hook)\u{201D}")
                .font(.cinema(16, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 10) {
                Button {
                    showCamera = true
                } label: {
                    Label("Film it", systemImage: "video.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                NavigationLink(value: Route.idea(idea.id)) {
                    Text("See shot list")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(18)
        .background(
            LinearGradient(colors: [Theme.redDeep.opacity(0.5), Theme.surface], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: Theme.corner + 4, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: Theme.corner + 4, style: .continuous).stroke(Theme.red.opacity(0.35), lineWidth: 1))
    }

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            quickAction("Get ideas", icon: "lightbulb.fill") { selectedTab = .create }
            NavigationLink(value: Route.bookings) {
                quickActionLabel("Book a shoot", icon: "calendar.badge.plus")
            }
            .buttonStyle(.plain)
            NavigationLink(value: Route.calendar) {
                quickActionLabel("Content calendar", icon: "calendar")
            }
            .buttonStyle(.plain)
            quickAction("My library", icon: "film.stack") { selectedTab = .library }
        }
    }

    private func quickAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            quickActionLabel(title, icon: icon)
        }
        .buttonStyle(.plain)
    }

    private func quickActionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.red)
            Text(title)
                .font(.cinema(15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 0)
        }
        .cardStyle(padding: 14)
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Needs your review", actionTitle: "Library") { selectedTab = .library }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.clipsNeedingReview) { clip in
                        NavigationLink(value: Route.clip(clip.id)) {
                            VStack(alignment: .leading, spacing: 8) {
                                ClipThumbnail(clip: clip, height: 220)
                                Text(clip.title)
                                    .font(.cinema(14, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                    .lineLimit(1)
                            }
                            .frame(width: 150)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var challengeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your challenges", actionTitle: "All") { path.append(Route.challenges) }
            ForEach(store.joinedChallenges) { challenge in
                NavigationLink(value: Route.challenge(challenge.id)) {
                    HStack(spacing: 14) {
                        ProgressRing(progress: challenge.progress, size: 52)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(challenge.title)
                                .font(.cinema(16, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("Day \(challenge.completedDays) of \(challenge.totalDays) · Prize: \(challenge.prize)")
                                .font(.cinema(13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        if challenge.checkedInToday {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.success)
                        } else {
                            Text("Today")
                                .font(.cinema(12, weight: .bold))
                                .foregroundStyle(Theme.red)
                        }
                    }
                    .cardStyle()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var coachSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Coach's note", actionTitle: "Coach") { path.append(Route.coach) }
            if let tip = store.coachTips.first {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: tip.area.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.red)
                        .frame(width: 40, height: 40)
                        .background(Theme.surfaceRaised, in: Circle())
                    VStack(alignment: .leading, spacing: 6) {
                        Text(tip.area.title.uppercased())
                            .font(.cinema(11, weight: .bold))
                            .foregroundStyle(Theme.textTertiary)
                        Text(tip.text)
                            .font(.cinema(15))
                            .foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .cardStyle()
            }
        }
    }

    private func bookingSection(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Next shoot", actionTitle: "Bookings") { path.append(Route.bookings) }
            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text(booking.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                        .font(.cinema(12, weight: .bold))
                        .foregroundStyle(Theme.red)
                    Text(booking.date.formatted(.dateTime.day()))
                        .font(.cinema(24, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(width: 56, height: 56)
                .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.service.name)
                        .font(.cinema(16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(booking.date.timeOnly) · \(booking.address.isEmpty ? "#Cinema studio" : booking.address)")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Pill(text: booking.status.title)
            }
            .cardStyle()
        }
    }
}
