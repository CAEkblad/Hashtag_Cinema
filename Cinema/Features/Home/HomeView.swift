import SwiftUI
import TipKit

struct HomeView: View {
    @Environment(CinemaStore.self) private var store
    @Binding var selectedTab: AppTab
    @State private var path = NavigationPath()
    @State private var showCamera = false
    @State private var showBooking = false
    @State private var showWhatsNew = false
    @State private var pendingRoute: Route?

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greeting
                    if let announcement = store.latestAnnouncement {
                        AnnouncementCard(announcement: announcement)
                    }
                    if store.showGettingStarted {
                        GettingStartedCard { stepID in
                            switch stepID {
                            case "market": path.append(Route.market)
                            case "connect": selectedTab = .me
                            case "film": showCamera = true
                            case "challenge": path.append(Route.challenges)
                            default: path.append(Route.reminders)
                            }
                        }
                    }
                    TodayPlanCard(
                        onFilm: { showCamera = true },
                        onReview: { selectedTab = .library },
                        onPost: { selectedTab = .library },
                        onLeads: { path.append(Route.leads) }
                    )
                    WeeklyGoalCard()
                    if !store.touchesDueToday.isEmpty {
                        NavigationLink(value: Route.touchPlans) {
                            IconRow(icon: "point.3.filled.connected.trianglepath.dotted", title: "\(store.touchesDueToday.count) touch\(store.touchesDueToday.count == 1 ? "" : "es") due today", subtitle: store.touchesDueToday.prefix(3).map(\.contact.firstName).joined(separator: ", "))
                                .cardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                    if store.isNewAgent {
                        NavigationLink(value: Route.launchpad) {
                            IconRow(icon: "airplane.departure", title: "Launchpad · day \(store.launchpad.dayNumber) of 90", subtitle: store.nextLaunchStepTitle.map { "Next: \($0)" } ?? "Every step done. Go get that closing.")
                                .cardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                    if let client = store.anniversariesThisMonth.first(where: { $0.daysUntilAnniversary() <= 7 }) {
                        NavigationLink(value: Route.pastClients) {
                            IconRow(icon: "house.and.flag.fill", title: "\(client.firstName)'s \(client.anniversaryLine.lowercased())", subtitle: "Tap to send a home anniversary text")
                                .cardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                    if let urgent = store.urgentDealDeadline {
                        NavigationLink(value: Route.deal(urgent.0.id)) {
                            IconRow(icon: urgent.1.isOverdue ? "exclamationmark.triangle.fill" : "clock.badge.exclamationmark.fill", title: "\(urgent.1.title) \(urgent.1.isOverdue ? "is overdue" : urgent.1.dueDate.relativeDayLabel)", subtitle: urgent.0.address)
                                .cardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                    VStack(spacing: 8) {
                        TipView(MarketTip())
                            .tint(Theme.red)
                        NavigationLink(value: Route.market) {
                            MarketTeaserCard()
                        }
                        .buttonStyle(.plain)
                    }
                    if store.isLeader {
                        NavigationLink(value: Route.promote) {
                            HStack(spacing: 14) {
                                Image(systemName: "megaphone.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Theme.red, in: Circle())
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Promote your \(store.profile.role.orgWord(store.lex))")
                                        .font(.cinema(16, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("Spotlight agents, share wins, recruit. Free for leaders.")
                                        .font(.cinema(13))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            .cardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                    if let idea = store.ideaOfTheDay {
                        ideaOfTheDayCard(idea)
                    }
                    statsRow
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
                    NavigationLink(value: Route.search) {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel("Search")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: Route.help) {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel("How #Cinema works")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: Route.activity) {
                        Image(systemName: "bell.fill")
                            .overlay(alignment: .topTrailing) {
                                if store.unreadActivityCount > 0 {
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
            .sheet(isPresented: $showWhatsNew, onDismiss: {
                if let route = pendingRoute {
                    path.append(route)
                    pendingRoute = nil
                }
            }) {
                WhatsNewView { route in pendingRoute = route }
            }
            .task {
                guard WhatsNewView.shouldShow else { return }
                WhatsNewView.markSeen()
                try? await Task.sleep(nanoseconds: 800_000_000)
                showWhatsNew = true
            }
        }
    }

    // MARK: Sections

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hey \(store.profile.firstName)")
                .font(.cinema(30, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Here's your plan for today in \(store.homeCity.name).")
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
            LinearGradient(colors: [Theme.red.opacity(0.12), Theme.surface], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: Theme.corner + 4, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: Theme.corner + 4, style: .continuous).stroke(Theme.red.opacity(0.25), lineWidth: 1))
        .shadow(color: Theme.red.opacity(0.10), radius: 16, x: 0, y: 6)
    }

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            quickAction("Get ideas", icon: "lightbulb.fill") { selectedTab = .create }
            quickLink("Find a photographer", icon: "person.crop.rectangle.stack.fill", route: .findShooter)
            quickLink("Make a poster", icon: "rectangle.portrait.on.rectangle.portrait.fill", route: .posterMaker)
            quickLink("My listings", icon: "house.and.flag.fill", route: .listings)
            quickLink("Showing tours", icon: "car.fill", route: .tours)
            quickLink("Past clients", icon: "house.and.flag.fill", route: .pastClients)
            quickLink("Photo reel", icon: "film.stack.fill", route: .photoReel)
            quickLink("Power hour", icon: "timer", route: .powerHour)
            quickLink("My money", icon: "banknote.fill", route: .money)
            quickLink("All tools", icon: "square.grid.2x2.fill", route: .tools)
        }
    }

    private func quickLink(_ title: String, icon: String, route: Route) -> some View {
        NavigationLink(value: route) {
            quickActionLabel(title, icon: icon)
        }
        .buttonStyle(.plain)
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
