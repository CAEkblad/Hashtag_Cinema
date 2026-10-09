import SwiftUI

struct RootView: View {
    @Environment(CinemaStore.self) private var store

    var body: some View {
        ZStack(alignment: .top) {
            if !store.isSignedIn {
                SignInView()
                    .transition(.opacity)
            } else if !store.hasOnboarded {
                OnboardingView()
                    .transition(.move(edge: .trailing))
            } else {
                MainTabView()
                    .transition(.opacity)
            }

            if let toast = store.toast {
                ToastView(message: toast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.isSignedIn)
        .animation(.easeInOut(duration: 0.3), value: store.hasOnboarded)
        .animation(.spring(duration: 0.35), value: store.toast)
    }
}

enum AppTab: Hashable {
    case home
    case create
    case library
    case community
    case me
}

struct MainTabView: View {
    @Environment(CinemaStore.self) private var store
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView(selectedTab: $selection)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            IdeaFeedView()
                .tabItem { Label("Create", systemImage: "video.badge.plus") }
                .tag(AppTab.create)

            LibraryView()
                .tabItem { Label("Library", systemImage: "film.stack") }
                .badge(store.clipsNeedingReview.count)
                .tag(AppTab.library)

            CommunityView()
                .tabItem { Label("Community", systemImage: "person.3.fill") }
                .tag(AppTab.community)

            ProfileView()
                .tabItem { Label("Me", systemImage: "person.crop.circle") }
                .badge(store.newLeadCount)
                .tag(AppTab.me)
        }
    }
}

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.cinema(14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.ink, in: Capsule())
            .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
            .padding(.horizontal, Theme.gutter)
    }
}

/// One place that maps every Route to its screen, shared by all tabs.
struct RouteDestination: View {
    @Environment(CinemaStore.self) private var store
    let route: Route

    var body: some View {
        switch route {
        case .idea(let id):
            if let idea = store.idea(id) {
                IdeaDetailView(idea: idea)
            } else {
                missing
            }
        case .clip(let id):
            ClipDetailView(clipID: id)
        case .challenge(let id):
            ChallengeDetailView(challengeID: id)
        case .story(let id):
            if let story = store.story(id) {
                SuccessStoryView(story: story)
            } else {
                missing
            }
        case .bookings:
            BookingView()
        case .calendar:
            ContentCalendarView()
        case .leads:
            LeadsView()
        case .coach:
            CoachView()
        case .challenges:
            ChallengesView()
        case .brokerage:
            BrokerageDashboardView()
        case .plans:
            PlansView()
        case .promote:
            PromoteView()
        case .courses:
            CoursesView()
        case .course(let id):
            CourseDetailView(courseID: id)
        case .lesson(let course, let lesson):
            LessonView(courseID: course, lessonID: lesson)
        }
    }

    private var missing: some View {
        EmptyStateView(title: "Not found", message: "This item was removed.", icon: "questionmark.folder")
            .cinemaScreen()
    }
}

extension View {
    func cinemaDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            RouteDestination(route: route)
        }
    }
}
