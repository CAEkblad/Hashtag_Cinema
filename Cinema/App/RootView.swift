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
        case .market:
            MarketView()
        case .city(let id):
            MarketView(cityID: id)
        case .reminders:
            ReminderSettingsView()
        case .help:
            HowItWorksView()
        case .marketCenter:
            MarketCenterView()
        case .officeContent:
            OfficeContentView()
        case .posterMaker:
            PosterMakerView()
        case .findShooter:
            FindPhotographerView()
        case .shooter(let id):
            ShooterProfileView(shooterID: id)
        case .joinCrew:
            JoinCrewView()
        case .crewDashboard:
            CrewDashboardView()
        case .listings:
            ListingsView()
        case .listing(let id):
            ListingDetailView(listingID: id)
        case .paymentCalculator:
            PaymentCalculatorView()
        case .activity:
            ActivityInboxView()
        case .referrals:
            ReferralsView()
        case .scriptWriter:
            ScriptWriterView()
        case .brandKit:
            BrandKitView()
        case .testimonials:
            TestimonialsView()
        case .marketUpdate:
            MarketUpdateView()
        case .weekPlan:
            WeekPlanView()
        case .achievements:
            AchievementsView()
        case .lead(let id):
            LeadDetailView(leadID: id)
        case .hooks:
            HookLibraryView()
        case .greetings:
            GreetingsView()
        case .insights:
            InsightsView()
        case .linkInBio:
            LinkInBioView()
        case .teleprompter:
            TeleprompterScriptView()
        case .captionWriter:
            CaptionWriterView()
        case .listingPitch:
            ListingPitchView()
        case .sellerPrep:
            SellerPrepView()
        case .search:
            SearchView()
        case .referralNetwork:
            ReferralNetworkScreen()
        case .pastClients:
            PastClientsView()
        case .vendors:
            VendorsView()
        case .sellerReport(let id):
            SellerReportView(listingID: id)
        case .netSheet:
            NetSheetView()
        case .tours:
            ToursView()
        case .tour(let id):
            TourDetailView(tourID: id)
        case .buyerCosts:
            BuyerCostsView()
        case .tools:
            ToolsView()
        case .packageAdvisor:
            PackageAdvisorView()
        case .relocationGuide:
            RelocationGuideView()
        case .newsletter:
            NewsletterView()
        case .deals:
            DealsView()
        case .photoReel:
            PhotoReelView()
        case .buyers:
            BuyersView()
        case .businessPlan:
            BusinessPlanView()
        case .keywords:
            KeywordsView()
        case .homeValue:
            HomeValueView()
        case .whatsNew:
            WhatsNewList()
        case .launchPlan(let id):
            LaunchPlanView(listingID: id)
        case .expenses:
            ExpensesView()
        case .listingPoster(let id):
            if let listing = store.listing(id) { PosterMakerView(listing: listing) }
        case .shotList(let id):
            if let listing = store.listing(id) { ShotListView(listing: listing) }
        case .listingReel(let id):
            if let listing = store.listing(id) { PhotoReelView(listing: listing) }
        case .listingNetSheet(let id):
            if let listing = store.listing(id) { NetSheetView(startingPrice: Double(listing.price), address: listing.address) }
        case .objections:
            ObjectionsView()
        case .farm:
            FarmView()
        case .brandShootPrep:
            BrandShootPrepView()
        case .money:
            MoneyView()
        case .splitTracker:
            SplitTrackerView()
        case .taxes:
            TaxSetAsideView()
        case .license:
            LicenseView()
        case .businessCard:
            BusinessCardView()
        case .powerHour:
            PowerHourView()
        case .timeBlocks:
            TimeBlocksView()
        case .scorecard:
            ScorecardView()
        case .team:
            TeamView()
        case .recruit:
            RecruitView()
        case .agentNetwork:
            AgentNetworkView()
        case .gems(let id):
            HiddenGemsView(buyerID: id)
        case .partners:
            PartnersView()
        case .launchpad:
            LaunchpadView()
        case .listingCalculator(let id):
            if let listing = store.listing(id) { PaymentCalculatorView(startingPrice: Double(listing.price)) }
        case .buyer(let id):
            BuyerDetailView(buyerID: id)
        case .deal(let id):
            DealDetailView(dealID: id)
        case .bookingChat(let id):
            BookingChatView(bookingID: id)
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
