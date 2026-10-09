import Foundation
import Observation

/// Single source of truth for the app. Views read from it and call its actions.
@MainActor
@Observable
final class CinemaStore {
    // Session
    var isSignedIn = false
    var hasOnboarded = false
    var profile = MockData.profile
    var connectedPlatforms: Set<SocialPlatform> = [.instagram, .facebook]

    // Content
    var ideas = MockData.ideas
    var clips = MockData.clips
    var bookings = MockData.bookings
    var posts = MockData.posts
    var leads = MockData.leads
    var challenges = MockData.challenges

    // Coaching
    var coachTips = MockData.coachTips
    var weeklyReport = MockData.weeklyReport
    var skillPath = MockData.skillPath

    // Courses
    var courses = MockData.courses

    // Community
    var communityPosts = MockData.communityPosts
    var groups = MockData.groups
    var stories = MockData.stories

    // Brokerage and partners
    var brokerageMembers = MockData.brokerageMembers
    var marketCenters = MockData.marketCenters
    var joinRequests = MockData.joinRequests
    var officeAssets = MockData.officeAssets
    var posters: [PosterItem] = []

    // Listings
    var listings = MockData.listings

    // #Cinema Crew
    var shooters = MockData.shooters
    var favoriteShooterIDs: Set<UUID> = []
    var crewApplication: CrewApplication?
    var crewJobOffers = MockData.crewJobOffers

    // Inbox and referrals
    var activity: [ActivityItem] = CinemaStore.sampleActivity()
    var referrals: [Referral] = [
        Referral(name: "Alex Morgan", date: MockData.day(-6), status: .rewarded),
        Referral(name: "Priya Shah", date: MockData.day(-2), status: .invited)
    ]
    var savedScripts: [Idea] = []

    // Agent referral network
    var networkAgents: [NetworkAgent] = NetworkDirectory.sample()
    var agentReferrals: [AgentReferral] = CinemaStore.sampleAgentReferrals()

    // Past clients and trusted pros
    var pastClients: [PastClient] = CinemaStore.samplePastClients()
    var vendors: [Vendor] = CinemaStore.sampleVendors()

    // Showing tours
    var tours: [ShowingTour] = CinemaStore.sampleTours()

    // Shoot chat with the shooter, per booking
    var shootMessages: [ShootMessage] = []

    // Deals under contract
    var deals: [Deal] = CinemaStore.sampleDeals()

    // Comment to DM keywords
    var keywordRules: [KeywordRule] = []

    // Buyer wishlists
    var buyers: [BuyerWish] = [
        BuyerWish(name: "Dana and Chris Wolfe", cityNames: ["Tampa"], maxPrice: 1_400_000, minBeds: 3, mustHaves: [.pool], notes: "Moving from Chicago by spring. Want to be near South Tampa schools.")
    ]

    // Weekly plan
    var weekPlan: [PlannedVideo] = []

    // Link in bio
    var bioPage = BioPage()

    // Brand kit and social proof
    var brandKit = BrandKit()
    var testimonials: [Testimonial] = [
        Testimonial(clientName: "Maria and Luis G.", quote: "Jordan made our first home feel easy. We beat five other offers and closed in 30 days.", stars: 5, side: .buyer, cityName: "Tampa", date: MockData.day(-12)),
        Testimonial(clientName: "Dan R.", quote: "The video tour brought in buyers from out of state. Under contract in one weekend.", stars: 5, side: .seller, cityName: "St. Petersburg", date: MockData.day(-30))
    ]

    // UI state
    var isRefreshingIdeas = false
    var toast: String?
    var gettingStartedDismissed = false

    // Reminders
    var reminderEnabled = false
    var reminderHour = 9
    var reminderMinute = 0

    private let ideaEngine: any IdeaEngine
    private let editing: any AIEditingService
    private let payments: any PaymentsService
    private let posting: any SocialPostingService
    private let coach: any CoachService

    private let localEngine = LocalIdeaEngine()

    init(
        ideaEngine: any IdeaEngine = LocalIdeaEngine(),
        editing: any AIEditingService = MockAIEditingService(),
        payments: any PaymentsService = MockPaymentsService(),
        posting: any SocialPostingService = MockSocialPostingService(),
        coach: any CoachService = MockCoachService()
    ) {
        self.ideaEngine = ideaEngine
        self.editing = editing
        self.payments = payments
        self.posting = posting
        self.coach = coach
        restore()
        restoreBrandKit()
        restoreSphere()
        restoreWork()
        if let data = UserDefaults.standard.data(forKey: Self.keywordsKey), let saved = try? JSONDecoder().decode([KeywordRule].self, from: data) {
            keywordRules = saved
        } else {
            keywordRules = KeywordRule.defaults(city: homeCity.name)
        }
        if shootMessages.isEmpty, let upcoming = bookings.first(where: { $0.date > Date() }) {
            shootMessages = [ShootMessage(bookingID: upcoming.id, fromAgent: false, text: "Hi! I'm confirmed for your shoot. Anything special about the home I should know?", date: Date().addingTimeInterval(-3_600), isRead: false)]
        }
        if let data = UserDefaults.standard.data(forKey: Self.bioKey), let page = try? JSONDecoder().decode(BioPage.self, from: data) {
            bioPage = page
        }
        ideas = localEngine.ideas(for: profile, count: 8, seed: Self.daySeed) + MockData.ideas
    }

    /// Same seed all day, so the idea of the day does not change on every launch.
    static var daySeed: UInt64 {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return UInt64((parts.year ?? 2026) * 10_000 + (parts.month ?? 1) * 100 + (parts.day ?? 1))
    }

    // MARK: Saved session

    private struct SavedSession: Codable {
        var isSignedIn: Bool
        var hasOnboarded: Bool
        var profile: AgentProfile
        var connectedPlatforms: [SocialPlatform]
        var gettingStartedDismissed: Bool
        var reminderEnabled: Bool
        var reminderHour: Int
        var reminderMinute: Int
    }

    private static let sessionKey = "cinema.session.v2"

    /// Listings, deals, tours, leads and bookings, saved on the phone until the backend syncs them.
    private struct WorkData: Codable {
        var listings: [Listing]
        var deals: [Deal]
        var tours: [ShowingTour]
        var leads: [Lead]
        var bookings: [Booking]
        var agentReferrals: [AgentReferral]
        var shootMessages: [ShootMessage]
        var buyers: [BuyerWish]?
    }

    private static let workKey = "cinema.work.v1"

    private func persistWork() {
        let work = WorkData(listings: listings, deals: deals, tours: tours, leads: leads, bookings: bookings, agentReferrals: agentReferrals, shootMessages: shootMessages, buyers: buyers)
        if let data = try? JSONEncoder().encode(work) {
            UserDefaults.standard.set(data, forKey: Self.workKey)
        }
    }

    private func restoreWork() {
        guard let data = UserDefaults.standard.data(forKey: Self.workKey),
              let work = try? JSONDecoder().decode(WorkData.self, from: data) else { return }
        listings = work.listings
        deals = work.deals
        tours = work.tours
        leads = work.leads
        bookings = work.bookings
        agentReferrals = work.agentReferrals
        shootMessages = work.shootMessages
        if let saved = work.buyers { buyers = saved }
    }

    /// Saves who is signed in and their setup so the app opens where they left off.
    func persist() {
        persistWork()
        let saved = SavedSession(
            isSignedIn: isSignedIn,
            hasOnboarded: hasOnboarded,
            profile: profile,
            connectedPlatforms: Array(connectedPlatforms),
            gettingStartedDismissed: gettingStartedDismissed,
            reminderEnabled: reminderEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute
        )
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: Self.sessionKey)
        }
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: Self.sessionKey),
              let saved = try? JSONDecoder().decode(SavedSession.self, from: data) else { return }
        isSignedIn = saved.isSignedIn
        hasOnboarded = saved.hasOnboarded
        profile = saved.profile
        connectedPlatforms = Set(saved.connectedPlatforms)
        gettingStartedDismissed = saved.gettingStartedDismissed
        reminderEnabled = saved.reminderEnabled
        reminderHour = saved.reminderHour
        reminderMinute = saved.reminderMinute
    }

    // MARK: Lookups

    func idea(_ id: UUID) -> Idea? { ideas.first { $0.id == id } }
    func clip(_ id: UUID) -> Clip? { clips.first { $0.id == id } }
    func challenge(_ id: UUID) -> Challenge? { challenges.first { $0.id == id } }
    func story(_ id: UUID) -> SuccessStory? { stories.first { $0.id == id } }
    func course(_ id: UUID) -> Course? { courses.first { $0.id == id } }
    var courseInProgress: Course? {
        if let started = courses.first(where: { $0.isOwned && $0.isStarted && !$0.isComplete }) { return started }
        return courses.first(where: { $0.isOwned && !$0.isComplete })
    }

    var ideaOfTheDay: Idea? { ideas.first }
    var clipsNeedingReview: [Clip] { clips.filter { $0.status.needsAgent } }
    var upcomingBookings: [Booking] {
        bookings.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }.sorted { $0.date < $1.date }
    }
    var joinedChallenges: [Challenge] { challenges.filter { $0.isJoined } }
    var newLeadCount: Int { leads.filter { $0.status == .new }.count }

    // MARK: Session

    func signIn(email: String) {
        if !email.isEmpty { profile.email = email }
        isSignedIn = true
        persist()
    }

    /// True when sign in runs through the real backend (email code) instead of demo mode.
    var usesRealSignIn: Bool { SupabaseClient.shared != nil }

    /// Emails a 6 digit sign in code. Returns false and shows why if it fails.
    func sendSignInCode(to email: String) async -> Bool {
        guard let client = SupabaseClient.shared else { return true }
        do {
            try await client.sendCode(email: email)
            return true
        } catch {
            showToast(error.localizedDescription)
            return false
        }
    }

    func verifySignInCode(_ code: String, email: String) async -> Bool {
        guard let client = SupabaseClient.shared else {
            signIn(email: email)
            return true
        }
        do {
            try await client.verify(email: email, code: code)
            signIn(email: email)
            return true
        } catch {
            showToast("That code did not work. Check your email and try again.")
            return false
        }
    }

    func completeOnboarding(
        name: String,
        brokerage: String,
        teamName: String,
        alsoSells: Bool,
        role: UserRole,
        city: FloridaCity,
        serviceAreas: [FloridaCity],
        niche: String,
        goals: [ContentGoal],
        weeklyGoal: Int,
        plan: Plan
    ) {
        if !name.isEmpty { profile.name = name }
        if !brokerage.isEmpty { profile.brokerage = brokerage }
        if let center = myMarketCenter, brokerage.isEmpty { profile.brokerage = center.name }
        profile.teamName = teamName
        profile.alsoSells = role.isLeader ? alsoSells : true
        profile.role = role
        profile.niche = niche
        profile.goals = goals
        profile.weeklyGoal = weeklyGoal
        profile.plan = role.isLeader ? .leader : plan
        profile.credits = max(profile.credits, profile.plan.monthlyCredits)
        applyCity(city, serviceAreas: serviceAreas)
        hasOnboarded = true
        persist()
    }

    func signOut() {
        SupabaseClient.shared?.signOut()
        isSignedIn = false
        hasOnboarded = false
        gettingStartedDismissed = false
        persist()
    }

    // MARK: Market

    var homeCity: FloridaCity { profile.homeCity ?? FloridaMarkets.fallback }
    var serviceAreas: [FloridaCity] { profile.serviceAreas }
    var allMarkets: [FloridaCity] { [homeCity] + serviceAreas }

    var currentMonth: Int { Calendar.current.component(.month, from: Date()) }

    var marketMoments: [SeasonalMoment] { FloridaCalendar.moments(month: currentMonth, city: homeCity) }

    func setHomeCity(_ city: FloridaCity) {
        applyCity(city, serviceAreas: serviceAreas.filter { $0.id != city.id })
        showToast("Your market is now \(city.name)")
        persist()
    }

    func toggleServiceArea(_ city: FloridaCity) {
        guard city.id != homeCity.id else { return }
        if let index = profile.serviceAreaIDs.firstIndex(of: city.id) {
            profile.serviceAreaIDs.remove(at: index)
        } else if profile.serviceAreaIDs.count < 6 {
            profile.serviceAreaIDs.append(city.id)
        } else {
            showToast("You can add up to 6 extra cities")
            return
        }
        persist()
    }

    func isServiceArea(_ city: FloridaCity) -> Bool { profile.serviceAreaIDs.contains(city.id) }

    private func applyCity(_ city: FloridaCity, serviceAreas: [FloridaCity]) {
        profile.cityID = city.id
        profile.market = city.displayName
        profile.serviceAreaIDs = serviceAreas.map(\.id).filter { $0 != city.id }
        ideas = localEngine.ideas(for: profile, count: 10, seed: Self.daySeed)
    }

    /// Ideas written for one city, used by the market screen.
    func localIdeas(for city: FloridaCity, count: Int = 6) -> [Idea] {
        localEngine.ideas(for: city, profile: profile, count: count, seed: Self.daySeed &+ city.id.unicodeScalars.reduce(UInt64(0)) { $0 &+ UInt64($1.value) })
    }

    /// Puts an idea at the top of the Create feed and returns it for navigation.
    @discardableResult
    func addIdea(_ idea: Idea, announce: Bool = true) -> Idea {
        if let existing = ideas.first(where: { $0.title == idea.title }) { return existing }
        ideas.insert(idea, at: 0)
        if announce { showToast("Added to your ideas") }
        return idea
    }

    // MARK: Today

    private var startOfToday: Date { Calendar.current.startOfDay(for: Date()) }
    private var startOfWeek: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? startOfToday
    }

    var filmedToday: Bool { clips.contains { $0.source == .phoneEdit && $0.createdAt >= startOfToday } }
    var postedToday: Bool { posts.contains { $0.status == .posted && $0.date >= startOfToday } }
    var postsThisWeek: Int { posts.filter { $0.status == .posted && $0.date >= startOfWeek }.count }
    var weeklyProgress: Double {
        guard profile.weeklyGoal > 0 else { return 0 }
        return min(1, Double(postsThisWeek) / Double(profile.weeklyGoal))
    }

    func setWeeklyGoal(_ goal: Int) {
        profile.weeklyGoal = max(1, min(14, goal))
        persist()
    }

    // MARK: Getting started

    struct StarterStep: Identifiable {
        var id: String
        var title: String
        var detail: String
        var icon: String
        var isDone: Bool
    }

    var starterSteps: [StarterStep] {
        [
            StarterStep(id: "market", title: "Pick your market", detail: "Ideas are written for your city", icon: "mappin.and.ellipse", isDone: profile.cityID != nil),
            StarterStep(id: "connect", title: "Connect Instagram or Facebook", detail: "Post and capture leads in one tap", icon: "link", isDone: !connectedPlatforms.isEmpty),
            StarterStep(id: "film", title: "Film your first video", detail: "Use the teleprompter, we edit it", icon: "video.fill", isDone: clips.contains { $0.source == .phoneEdit }),
            StarterStep(id: "challenge", title: "Join a challenge", detail: "The easiest way to stay consistent", icon: "flag.checkered", isDone: !joinedChallenges.isEmpty),
            StarterStep(id: "reminder", title: "Turn on your daily idea", detail: "A nudge at the time you choose", icon: "bell.badge.fill", isDone: reminderEnabled)
        ]
    }

    var showGettingStarted: Bool {
        !gettingStartedDismissed && starterSteps.contains { !$0.isDone }
    }

    func dismissGettingStarted() {
        gettingStartedDismissed = true
        persist()
    }

    // MARK: Reminders

    func setReminder(enabled: Bool, hour: Int, minute: Int) async {
        reminderHour = hour
        reminderMinute = minute
        if enabled {
            let allowed = await ReminderScheduler.requestPermission()
            guard allowed else {
                reminderEnabled = false
                showToast("Turn on notifications for #Cinema in Settings")
                persist()
                return
            }
            await ReminderScheduler.scheduleDaily(hour: hour, minute: minute, idea: ideaOfTheDay, city: homeCity)
            reminderEnabled = true
            showToast("Daily idea at \(ReminderScheduler.label(hour: hour, minute: minute))")
        } else {
            ReminderScheduler.cancel()
            reminderEnabled = false
        }
        persist()
    }

    func showToast(_ message: String) {
        toast = message
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if self.toast == message { self.toast = nil }
        }
    }

    // MARK: Ideas

    func refreshIdeas() async {
        isRefreshingIdeas = true
        defer { isRefreshingIdeas = false }
        if let fresh = try? await ideaEngine.generateIdeas(for: profile), !fresh.isEmpty {
            ideas = fresh
        } else {
            ideas = localEngine.ideas(for: profile, count: 10, seed: UInt64.random(in: 1...UInt64.max))
        }
    }

    /// Community "Remix" turns a post that worked into an idea card for this agent's market.
    @discardableResult
    func remix(_ post: CommunityPost) -> Idea? {
        guard var template = post.template else { return nil }
        template.id = UUID()
        template.remixedFrom = post.author
        template.cityName = homeCity.name
        template.title = "\(template.title) (\(homeCity.name) remix)"
        ideas.insert(template, at: 0)
        showToast("Added to your ideas")
        return template
    }

    // MARK: Editing

    @discardableResult
    func submitEditRequest(_ request: EditRequest) -> Clip? {
        guard profile.credits >= request.creditCost else {
            showToast("Not enough credits. Add a credit pack in Me > Plan.")
            return nil
        }
        profile.credits -= request.creditCost
        let category = request.ideaID.flatMap { idea($0)?.category }
        let clip = Clip(
            title: request.title,
            source: .phoneEdit,
            listing: nil,
            createdAt: Date(),
            durationSeconds: idea(request.ideaID ?? UUID())?.targetSeconds ?? 30,
            status: .submitted,
            style: request.style,
            symbol: category?.icon ?? "film.fill",
            paletteIndex: Int.random(in: 0..<Theme.palettes.count),
            videoURL: request.localVideoURL ?? MockData.sampleVideoURL
        )
        clips.insert(clip, at: 0)
        checkInToActiveChallenges()

        let clipID = clip.id
        let needsEditor = request.proEdit
        Task {
            _ = try? await editing.submit(request)
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            self.setStatus(.aiFirstCut, for: clipID)
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if needsEditor {
                self.setStatus(.editorPolish, for: clipID)
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
            self.setStatus(.readyForReview, for: clipID)
            if let tips = try? await self.coach.feedback(forClipTitled: request.title) {
                self.coachTips = tips + self.coachTips
            }
            self.showToast("\"\(request.title)\" is ready for review")
            self.notify(.edit, "Your edit is ready", detail: "\"\(request.title)\" is ready for you to review and approve.", route: .clip(clipID))
        }
        return clip
    }

    func setStatus(_ status: EditStatus, for clipID: UUID) {
        guard let index = clips.firstIndex(where: { $0.id == clipID }) else { return }
        clips[index].status = status
    }

    func addComment(_ text: String, at timestamp: Double, to clipID: UUID) {
        guard let index = clips.firstIndex(where: { $0.id == clipID }) else { return }
        let comment = ClipComment(timestamp: timestamp, author: profile.firstName, text: text)
        clips[index].comments.append(comment)
        clips[index].comments.sort { $0.timestamp < $1.timestamp }
    }

    func requestRevision(_ clipID: UUID) {
        setStatus(.revisions, for: clipID)
        showToast("Sent to your editor")
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self.setStatus(.readyForReview, for: clipID)
        }
    }

    func approve(_ clipID: UUID) {
        setStatus(.approved, for: clipID)
        showToast("Approved and saved to your library")
        // Listing content feeds the office pool so leaders can remix it.
        if let clip = clip(clipID), clip.listing != nil || clip.source == .proShoot {
            shareWithOffice(OfficeAsset(
                agentName: profile.name,
                kind: .video,
                title: clip.title,
                listingAddress: clip.listing,
                status: clip.listing == nil ? nil : "Just listed",
                createdAt: Date(),
                symbol: clip.symbol,
                paletteIndex: clip.paletteIndex
            ))
        }
    }

    func toggleFavorite(_ clipID: UUID) {
        guard let index = clips.firstIndex(where: { $0.id == clipID }) else { return }
        clips[index].isFavorite.toggle()
    }

    // MARK: Booking

    func payDepositAndBook(
        service: ServiceType,
        date: Date,
        address: String,
        notes: String,
        shooter: Shooter? = nil,
        package: ShootPackage? = nil,
        addOns: [ShootAddOn] = [],
        stagedPhotos: Int = 0
    ) async -> Booking? {
        let total = package.map { pkg in pkg.price + addOns.reduce(0) { $0 + $1.price * ($1.perPhoto ? max(stagedPhotos, 1) : 1) } }
        let deposit = min(500, total ?? 500)
        do {
            let result = try await payments.payDeposit(amount: deposit, description: package?.name ?? service.name)
            guard result.succeeded else { return nil }
            var booking = Booking(service: service, date: date, address: address, notes: notes, status: result.isPending ? .depositPending : .depositPaid, depositAmount: deposit)
            booking.shooterID = shooter?.id
            booking.packageName = package?.name
            booking.addOns = addOns.map(\.name)
            booking.estimatedTotal = total
            bookings.append(booking)
            notify(.booking, "Shoot booked", detail: "\(package?.name ?? service.name) on \(date.shortDay) at \(date.timeOnly)\(shooter.map { " with \($0.name)" } ?? "").", route: .bookings)
            return booking
        } catch {
            showToast("Payment failed. Try again.")
            return nil
        }
    }

    // MARK: Posting

    func connect(_ platform: SocialPlatform) {
        connectedPlatforms.insert(platform)
        showToast("\(platform.name) connected")
        persist()
    }

    func disconnect(_ platform: SocialPlatform) {
        connectedPlatforms.remove(platform)
        persist()
    }

    func schedulePost(clip: Clip, platforms: [SocialPlatform], caption: String, date: Date, postNow: Bool, leadKeyword: String?) async {
        let post = ScheduledPost(
            clipID: clip.id,
            clipTitle: clip.title,
            platforms: platforms,
            caption: caption,
            date: postNow ? Date() : date,
            status: postNow ? .posted : .scheduled,
            leadKeyword: leadKeyword
        )
        try? await posting.schedule(post)
        posts.append(post)
        if postNow { checkInToActiveChallenges() }
        showToast(postNow ? "Posted to \(platforms.count) platforms" : "Scheduled for \(date.shortDay)")
        notify(.system, postNow ? "Posted" : "Post scheduled", detail: "\"\(clip.title)\" \(postNow ? "went out" : "goes out \(date.shortDay)") on \(platforms.map(\.name).joined(separator: ", ")).", route: .calendar)
    }

    // MARK: Leads

    func setLeadStatus(_ status: LeadStatus, for leadID: UUID) {
        guard let index = leads.firstIndex(where: { $0.id == leadID }) else { return }
        leads[index].status = status
    }

    func lead(_ id: UUID) -> Lead? { leads.first { $0.id == id } }

    func updateLead(_ lead: Lead) {
        guard let index = leads.firstIndex(where: { $0.id == lead.id }) else { return }
        leads[index] = lead
    }

    func markContacted(_ leadID: UUID) {
        guard let index = leads.firstIndex(where: { $0.id == leadID }) else { return }
        leads[index].lastContacted = Date()
        if leads[index].status == .new { leads[index].status = .contacted }
    }

    var leadsDueForFollowUp: [Lead] {
        leads.filter { lead in
            guard let due = lead.followUpDate else { return false }
            return due <= Date() && lead.status != .booked
        }
    }

    func setFollowUp(_ leadID: UUID, on date: Date?) async {
        guard let index = leads.firstIndex(where: { $0.id == leadID }) else { return }
        leads[index].followUpDate = date
        if let date {
            let allowed = await ReminderScheduler.requestPermission()
            if allowed { await ReminderScheduler.scheduleFollowUp(for: leads[index], at: date) }
            showToast("Reminder set for \(date.shortDay)")
        } else {
            ReminderScheduler.cancelFollowUp(for: leadID)
        }
    }

    // MARK: Challenges

    func join(_ challengeID: UUID) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }
        challenges[index].isJoined = true
        challenges[index].participants += 1
        showToast("You're in. Day 1 starts now.")
    }

    func checkIn(_ challengeID: UUID) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }
        guard !challenges[index].checkedInToday else { return }
        challenges[index].checkedInToday = true
        challenges[index].completedDays = min(challenges[index].completedDays + 1, challenges[index].totalDays)
        profile.points += 20
        profile.streakDays += 1
    }

    private func checkInToActiveChallenges() {
        for challenge in challenges where challenge.isJoined && !challenge.checkedInToday {
            checkIn(challenge.id)
        }
    }

    // MARK: Community

    func toggleLike(_ postID: UUID) {
        guard let index = communityPosts.firstIndex(where: { $0.id == postID }) else { return }
        communityPosts[index].isLiked.toggle()
        communityPosts[index].likes += communityPosts[index].isLiked ? 1 : -1
    }

    func addCommunityPost(kind: CommunityPostKind, body: String) {
        let post = CommunityPost(
            author: profile.name,
            market: profile.market,
            niche: profile.niche,
            kind: kind,
            body: body,
            stat: nil,
            likes: 0,
            replies: 0,
            createdAt: Date()
        )
        communityPosts.insert(post, at: 0)
    }

    func toggleGroup(_ groupID: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        groups[index].isJoined.toggle()
        groups[index].members += groups[index].isJoined ? 1 : -1
    }

    // MARK: Courses

    func setLesson(_ lessonID: UUID, in courseID: UUID, complete: Bool) {
        guard let c = courses.firstIndex(where: { $0.id == courseID }),
              let l = courses[c].lessons.firstIndex(where: { $0.id == lessonID }) else { return }
        let wasComplete = courses[c].isComplete
        courses[c].lessons[l].isComplete = complete
        if complete { profile.points += 25 }
        if !wasComplete && courses[c].isComplete {
            profile.points += 100
            showToast("Course complete. Your certificate is ready.")
        }
    }

    func buyCourse(_ courseID: UUID) async {
        guard let index = courses.firstIndex(where: { $0.id == courseID }) else { return }
        do {
            let result = try await payments.purchase(productID: "course-\(courseID.uuidString)", description: courses[index].title)
            if result.succeeded {
                courses[index].isOwned = true
                showToast("You're enrolled")
            }
        } catch {
            showToast("Purchase failed. Try again.")
        }
    }

    // MARK: Partners (Keller Williams)

    var partner: Partner? { profile.partner }
    var discountPercent: Int { partner?.signupDiscountPercent ?? 0 }
    var myMarketCenter: MarketCenter? { marketCenters.first { $0.id == profile.marketCenterID } }
    var officeWord: String { partner?.officeWord ?? profile.role.orgWord }

    func marketCenters(near city: FloridaCity, partner: Partner) -> [MarketCenter] {
        marketCenters
            .filter { $0.partnerID == partner.id }
            .sorted { ($0.city?.distance(to: city) ?? 999) < ($1.city?.distance(to: city) ?? 999) }
    }

    /// The MCA's join code connects an agent to the right market center instantly.
    @discardableResult
    func joinMarketCenter(code: String) -> Bool {
        let cleaned = code.trimmingCharacters(in: .whitespaces).uppercased()
        guard let center = marketCenters.first(where: { $0.joinCode.uppercased() == cleaned }) else {
            showToast("That code did not match a market center")
            return false
        }
        profile.marketCenterID = center.id
        profile.membership = .approved
        showToast("Connected to \(center.name)")
        persist()
        return true
    }

    /// Without a code, the market center leader approves the request.
    func requestMarketCenter(_ center: MarketCenter) {
        profile.marketCenterID = center.id
        profile.membership = .pending
        showToast("Request sent to \(center.name)")
        persist()
    }

    func leaveMarketCenter() {
        profile.marketCenterID = nil
        profile.membership = .none
        persist()
    }

    func approve(_ request: JoinRequest) {
        joinRequests.removeAll { $0.id == request.id }
        brokerageMembers.append(BrokerageMember(name: request.agentName, postsThisMonth: 0, challengeDays: 0, creditsUsed: 0, leads: 0))
        showToast("\(request.agentName) is connected")
        notify(.office, "Agent connected", detail: "\(request.agentName) joined your \(officeWord).", route: .marketCenter)
    }

    func decline(_ request: JoinRequest) {
        joinRequests.removeAll { $0.id == request.id }
    }

    /// 10% of what connected agents spend goes to their market center.
    var officeRevenueThisMonth: Double { brokerageMembers.reduce(0) { $0 + $1.monthlySpend } }
    var revenueShareThisMonth: Double {
        officeRevenueThisMonth * Double(partner?.revenueSharePercent ?? Partner.kellerWilliams.revenueSharePercent) / 100
    }

    func setSharesWithOffice(_ on: Bool) {
        profile.sharesWithOffice = on
        persist()
    }

    // MARK: Office content pool

    /// Adds the agent's listing content to the office pool when sharing is on.
    func shareWithOffice(_ asset: OfficeAsset) {
        guard profile.sharesWithOffice else { return }
        officeAssets.insert(asset, at: 0)
    }

    /// Leader remix: a featured office post that credits the agent.
    func remixForOffice(_ asset: OfficeAsset) {
        if let index = officeAssets.firstIndex(where: { $0.id == asset.id }) {
            officeAssets[index].remixCount += 1
        }
        let what = asset.status.map { "\($0.lowercased()) " } ?? ""
        let place = asset.listingAddress.map { " at \($0)" } ?? ""
        let body = "Congrats to \(asset.agentName) on this \(what)\(asset.kind == .video ? "video" : "listing")\(place). This is what \(profile.brokerage) agents do every week."
        promote(kind: .win, body: body, alsoToSocials: true, as: .office)
    }

    // MARK: Posters

    func savePoster(_ poster: PosterItem) {
        posters.insert(poster, at: 0)
        shareWithOffice(OfficeAsset(
            agentName: profile.name,
            kind: .poster,
            title: "\(poster.kind.title.capitalized) \(poster.address)",
            listingAddress: poster.address,
            status: poster.kind.title.capitalized,
            createdAt: Date(),
            symbol: poster.kind.icon,
            paletteIndex: 0,
            imageData: poster.imageData
        ))
    }

    // MARK: Listings

    func listing(_ id: UUID) -> Listing? { listings.first { $0.id == id } }

    @discardableResult
    func addListing(_ listing: Listing) -> Listing {
        var new = listing
        new.paletteIndex = listings.count % Theme.palettes.count
        new.description = ListingCopywriter.description(for: new, tone: .warm)
        listings.insert(new, at: 0)
        showToast("Listing added with a marketing plan")
        let fans = buyers.filter { $0.matches(new) }
        if let first = fans.first {
            notify(.lead, fans.count == 1 ? "\(first.name) is a match" : "\(fans.count) buyers match", detail: "\(new.address) fits what \(fans.count == 1 ? "they're" : "they're each") looking for. Send it before it hits the portals.", route: .buyer(first.id))
        }
        return new
    }

    func updateListing(_ listing: Listing) {
        guard let index = listings.firstIndex(where: { $0.id == listing.id }) else { return }
        listings[index] = listing
    }

    func setStatus(_ status: ListingStatus, for listingID: UUID) {
        guard let index = listings.firstIndex(where: { $0.id == listingID }) else { return }
        listings[index].status = status
        showToast("\(status.title). Your \(status.posterKind.shortTitle.lowercased()) poster is ready to make.")
        if status == .sold {
            notify(.system, "Sold! Ask for a testimonial", detail: "\(listings[index].address) closed. Happy clients write the best reviews in the first week.", route: .testimonials)
        }
    }

    // MARK: Office challenges

    func launchOfficeChallenge(title: String, subtitle: String, days: Int, prize: String) {
        let me = LeaderboardEntry(name: profile.name, market: homeCity.name, points: 0, isMe: true)
        let others = brokerageMembers.prefix(5).map { LeaderboardEntry(name: $0.name, market: homeCity.name, points: 0) }
        let challenge = Challenge(
            title: "\(myMarketCenter?.name ?? profile.brokerage): \(title)",
            subtitle: subtitle,
            totalDays: days,
            completedDays: 0,
            prize: prize,
            participants: brokerageMembers.count + 1,
            isJoined: true,
            scope: .brokerage,
            leaderboard: [me] + others
        )
        challenges.insert(challenge, at: 0)
        notify(.office, "Office challenge launched", detail: "\(title) is live for \(brokerageMembers.count) agents.", route: .challenge(challenge.id))
        showToast("\(title) is live for your \(officeWord)")
    }

    // MARK: Insights

    /// Sample analytics until social accounts are connected. Stable per agent so the charts don't jump around.
    var insights: ContentInsights {
        var rng = SeededGenerator(seed: profile.email.unicodeScalars.reduce(UInt64(7)) { $0 &* 31 &+ UInt64($1.value) })
        let calendar = Calendar.current
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        var weekly: [ContentInsights.WeekPoint] = []
        var level = Double.random(in: 4_000...7_000, using: &rng)
        for offset in (0..<8).reversed() {
            level *= Double.random(in: 0.92...1.22, using: &rng)
            let start = calendar.date(byAdding: .weekOfYear, value: -offset, to: thisWeek) ?? thisWeek
            weekly.append(ContentInsights.WeekPoint(weekStart: start, views: Int(level)))
        }
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let weekdayBars = days.map { ContentInsights.Bar(label: $0, value: Int(Double.random(in: 900...4_200, using: &rng))) }
        let categories: [IdeaCategory] = [.neighborhood, .listingTour, .marketUpdate, .mythBuster, .clientStory]
        let categoryBars = categories.map { ContentInsights.Bar(label: $0.title, value: Int(Double.random(in: 1_200...9_500, using: &rng))) }
            .sorted { $0.value > $1.value }
        let raw = SocialPlatform.allCases.map { ($0.name, Double.random(in: 0.1...1, using: &rng)) }
        let total = raw.reduce(0) { $0 + $1.1 }
        let platforms = raw.map { ContentInsights.Share(label: $0.0, share: $0.1 / total) }.sorted { $0.share > $1.share }
        return ContentInsights(weekly: weekly, byWeekday: weekdayBars, byCategory: categoryBars, byPlatform: platforms, totalLeads: leads.count + 14)
    }


    func addFeedback(_ feedback: ShowingFeedback, to listingID: UUID) {
        guard let index = listings.firstIndex(where: { $0.id == listingID }) else { return }
        listings[index].feedback.insert(feedback, at: 0)
        showToast("Feedback saved")
    }

    func toggleTask(_ task: MarketingTask, for listingID: UUID) {
        guard let index = listings.firstIndex(where: { $0.id == listingID }) else { return }
        if listings[index].done.contains(task) {
            listings[index].done.remove(task)
        } else {
            listings[index].done.insert(task)
            profile.points += 10
        }
    }

    func markTask(_ task: MarketingTask, for listingID: UUID) {
        guard let index = listings.firstIndex(where: { $0.id == listingID }) else { return }
        listings[index].done.insert(task)
    }

    func scheduleOpenHouse(for listingID: UUID, start: Date, hours: Int) {
        guard let index = listings.firstIndex(where: { $0.id == listingID }) else { return }
        let end = Calendar.current.date(byAdding: .hour, value: hours, to: start) ?? start
        listings[index].openHouses.append(OpenHouse(start: start, end: end))
        listings[index].openHouses.sort { $0.start < $1.start }
        listings[index].done.insert(.openHouse)
        showToast("Open house scheduled. Make the poster next.")
    }

    /// Open house sign in. The visitor also becomes a lead.
    func signIn(_ visitor: OpenHouseVisitor, openHouseID: UUID, listingID: UUID) {
        guard let l = listings.firstIndex(where: { $0.id == listingID }),
              let o = listings[l].openHouses.firstIndex(where: { $0.id == openHouseID }) else { return }
        listings[l].openHouses[o].visitors.append(visitor)
        let detail = [visitor.preapproved ? "Pre-approved" : nil, visitor.workingWithAgent ? "Has an agent" : nil, visitor.timeline.isEmpty ? nil : "Timeline: \(visitor.timeline)"]
            .compactMap { $0 }.joined(separator: ". ")
        leads.insert(Lead(
            name: visitor.name,
            handle: visitor.phone.isEmpty ? visitor.email : visitor.phone,
            platform: .facebook,
            keyword: "OPEN",
            sourceClip: listings[l].address,
            message: detail.isEmpty ? "Signed in at the open house" : detail,
            date: Date(),
            status: .new,
            openHouseAddress: listings[l].address
        ), at: 0)
        notify(.lead, "Open house sign in", detail: "\(visitor.name) signed in at \(listings[l].address).", route: .leads)
    }

    // MARK: Find a photographer

    func shooter(_ id: UUID) -> Shooter? { shooters.first { $0.id == id } }

    /// Shooters for a city: same city first, then nearby, best tier and rating first.
    func shooters(near city: FloridaCity, skill: ShooterSkill? = nil, radiusMiles: Double = 60) -> [Shooter] {
        shooters
            .filter { skill == nil || $0.skills.contains(skill!) }
            .filter { ($0.city?.distance(to: city) ?? 999) <= radiusMiles }
            .sorted {
                let d0 = $0.city?.distance(to: city) ?? 999
                let d1 = $1.city?.distance(to: city) ?? 999
                if $0.tier != $1.tier { return CrewTier.allCases.firstIndex(of: $0.tier)! > CrewTier.allCases.firstIndex(of: $1.tier)! }
                if abs(d0 - d1) > 15 { return d0 < d1 }
                return $0.rating > $1.rating
            }
    }

    func toggleFavorite(shooter: Shooter) {
        if favoriteShooterIDs.contains(shooter.id) {
            favoriteShooterIDs.remove(shooter.id)
        } else {
            favoriteShooterIDs.insert(shooter.id)
            showToast("\(shooter.name) saved to your favorites")
        }
    }

    var bookingsToRate: [Booking] { bookings.filter { $0.status == .completed && $0.rating == nil } }

    /// Five star ratings feed the shooter's tier on the backend.
    func rate(_ bookingID: UUID, stars: Int, comment: String) {
        guard let index = bookings.firstIndex(where: { $0.id == bookingID }) else { return }
        bookings[index].rating = stars
        if let shooterID = bookings[index].shooterID ?? shooters.first?.id,
           let s = shooters.firstIndex(where: { $0.id == shooterID }) {
            let count = Double(shooters[s].jobsCompleted)
            shooters[s].rating = ((shooters[s].rating * count) + Double(stars)) / (count + 1)
            shooters[s].jobsCompleted += 1
            if stars == 5 { shooters[s].fiveStarCount += 1 }
            if !comment.trimmingCharacters(in: .whitespaces).isEmpty {
                let lastInitial = profile.name.split(separator: " ").dropFirst().last?.first.map { String($0) } ?? ""
                let author = lastInitial.isEmpty ? profile.firstName : "\(profile.firstName) \(lastInitial)."
                shooters[s].reviews.insert(ShootReview(author: author, rating: stars, text: comment, date: Date()), at: 0)
            }
        }
        showToast(stars == 5 ? "Thanks! Five stars helps your shooter level up." : "Thanks for the feedback")
        notify(.rating, "Thanks for rating your shoot", detail: "You gave \(stars) star\(stars == 1 ? "" : "s"). Ratings decide which shooters level up.", route: .bookings)
    }

    // MARK: #Cinema Crew

    func submitCrewApplication(_ application: CrewApplication) {
        crewApplication = application
        showToast("Application sent. We review new shooters within 3 business days.")
    }

    func acceptJob(_ offer: CrewJobOffer) {
        crewJobOffers.removeAll { $0.id == offer.id }
        showToast("Job accepted. It's on your schedule.")
    }

    // MARK: Activity inbox

    var unreadActivityCount: Int { activity.filter { !$0.isRead }.count }

    func notify(_ kind: ActivityItem.Kind, _ title: String, detail: String, route: Route? = nil) {
        activity.insert(ActivityItem(kind: kind, title: title, detail: detail, date: Date(), route: route), at: 0)
    }

    func markRead(_ item: ActivityItem) {
        guard let index = activity.firstIndex(where: { $0.id == item.id }) else { return }
        activity[index].isRead = true
    }

    func markAllRead() {
        for index in activity.indices { activity[index].isRead = true }
    }

    nonisolated static func sampleActivity() -> [ActivityItem] {
        [
            ActivityItem(kind: .edit, title: "Your edit is ready", detail: "\"Bayshore listing tour\" is ready for you to review and approve.", date: MockData.day(0, hour: 8, minute: 12), route: .bookings),
            ActivityItem(kind: .lead, title: "New lead from WATER", detail: "Someone commented WATER on your waterfront tour. We sent your DM.", date: MockData.day(0, hour: 7, minute: 40), route: .leads),
            ActivityItem(kind: .coach, title: "Your weekly coach report", detail: "Your hooks are getting stronger. Try ending on a question this week.", date: MockData.day(-1, hour: 18), route: .coach),
            ActivityItem(kind: .referral, title: "You earned 2 credits", detail: "Alex Morgan joined #Cinema with your invite.", date: MockData.day(-6, hour: 12), route: .referrals, isRead: true)
        ]
    }

    // MARK: Referrals

    /// Invite code agents share. Each friend who joins gives both of you 2 edit credits.
    var referralCode: String {
        let letters = profile.firstName.uppercased().filter { $0.isLetter }
        let number = abs(profile.email.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) % 9000 }) + 1000
        return "\(letters.prefix(6))\(number)"
    }

    var referralLink: String { "https://hashtagcinema.com/join?ref=\(referralCode)" }

    var referralMessage: String {
        "I make my real estate videos with #Cinema. Daily ideas for your city, they edit, and it posts everywhere. Use my code \(referralCode) and we both get 2 free edits: \(referralLink)"
    }

    var creditsEarnedFromReferrals: Int { referrals.filter { $0.status == .rewarded }.count * 2 }

    func invite(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let referral = Referral(name: trimmed, date: Date(), status: .invited)
        referrals.insert(referral, at: 0)
        showToast("Invite ready for \(trimmed)")
        // Demo: the friend joins a few seconds later so the reward flow can be tested.
        let id = referral.id
        Task {
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            guard let index = self.referrals.firstIndex(where: { $0.id == id }) else { return }
            self.referrals[index].status = .rewarded
            self.profile.credits += 2
            self.persist()
            self.notify(.referral, "You earned 2 credits", detail: "\(trimmed) joined #Cinema with your invite.", route: .referrals)
            self.showToast("\(trimmed) joined. You both got 2 credits.")
        }
    }

    // MARK: Agent referral network

    /// Agents in the city first, then the closest markets around it.
    func networkAgents(near city: FloridaCity) -> [NetworkAgent] {
        let sorted = networkAgents.sorted { lhs, rhs in
            let l = lhs.city?.distance(to: city) ?? .greatestFiniteMagnitude
            let r = rhs.city?.distance(to: city) ?? .greatestFiniteMagnitude
            return l < r
        }
        return Array(sorted.prefix(6))
    }

    func acceptReferral(_ id: UUID) {
        guard let index = agentReferrals.firstIndex(where: { $0.id == id }) else { return }
        agentReferrals[index].status = .accepted
        let referral = agentReferrals[index]
        let lead = Lead(name: referral.clientName, handle: "Agent referral", platform: .facebook, keyword: "REFERRAL", sourceClip: "From \(referral.otherAgentName)", message: "\(referral.side.title) in \(referral.city?.name ?? "Florida"), \(referral.priceRange). \(referral.notes)", date: Date(), status: .new, notes: "\(referral.feePercent)% referral fee to \(referral.otherAgentName) at closing.")
        leads.insert(lead, at: 0)
        notify(.referral, "Referral accepted", detail: "\(referral.clientName) is in your Leads. Reach out today.", route: .lead(lead.id))
        showToast("Accepted. \(referral.clientName) is in your Leads.")
    }

    func declineReferral(_ id: UUID) {
        guard let referral = agentReferrals.first(where: { $0.id == id }) else { return }
        agentReferrals.removeAll { $0.id == id }
        showToast("Passed. We'll let \(referral.otherAgentName) know.")
    }

    func sendReferral(to agent: NetworkAgent, clientName: String, side: AgentReferral.Side, priceRange: String, notes: String, fee: Int) {
        let name = clientName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let referral = AgentReferral(clientName: name, side: side, cityID: agent.cityID, priceRange: priceRange, notes: notes, otherAgentName: agent.name, feePercent: fee, status: .sent, isIncoming: false, date: Date())
        agentReferrals.insert(referral, at: 0)
        showToast("Referral sent to \(agent.name)")
        // Demo: the other agent accepts a few seconds later.
        let id = referral.id
        Task {
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            guard let index = self.agentReferrals.firstIndex(where: { $0.id == id }) else { return }
            self.agentReferrals[index].status = .accepted
            self.notify(.referral, "\(agent.name) accepted your referral", detail: "\(name) is in good hands in \(agent.city?.name ?? "their city"). \(fee)% fee at closing.", route: .referralNetwork)
        }
    }

    nonisolated static func sampleAgentReferrals() -> [AgentReferral] {
        [
            AgentReferral(clientName: "Marcus and Jen Reed", side: .buyer, cityID: FloridaMarkets.all.first?.id ?? "", priceRange: "$400K to $550K", notes: "Relocating from Atlanta in March. Two kids, want a good school zone and a pool.", otherAgentName: "Carla Mendez", feePercent: 25, status: .sent, isIncoming: true, date: MockData.day(0, hour: 9)),
            AgentReferral(clientName: "Diane Foster", side: .seller, cityID: FloridaMarkets.all.dropFirst(3).first?.id ?? "", priceRange: "$700K to $800K", notes: "Downsizing after retirement. Wants to list in spring.", otherAgentName: "Luis Ortiz", feePercent: 25, status: .underContract, isIncoming: false, date: MockData.day(-12))
        ]
    }

    // MARK: Past clients

    private static let pastClientsKey = "cinema.pastclients.v1"
    private static let vendorsKey = "cinema.vendors.v1"

    var anniversariesThisMonth: [PastClient] {
        pastClients.filter { $0.daysUntilAnniversary() <= 30 }.sorted { $0.daysUntilAnniversary() < $1.daysUntilAnniversary() }
    }

    func addPastClient(_ client: PastClient, remind: Bool) {
        pastClients.insert(client, at: 0)
        savePastClients()
        if remind { setAnniversaryReminder(client.id, on: true) }
        showToast("\(client.name) added")
    }

    func deletePastClient(_ id: UUID) {
        ReminderScheduler.cancelAnniversary(id)
        pastClients.removeAll { $0.id == id }
        savePastClients()
    }

    func setAnniversaryReminder(_ id: UUID, on: Bool) {
        guard let index = pastClients.firstIndex(where: { $0.id == id }) else { return }
        pastClients[index].reminderOn = on
        savePastClients()
        let client = pastClients[index]
        if on {
            Task {
                guard await ReminderScheduler.requestPermission() else {
                    self.showToast("Turn on notifications in Settings to get reminders")
                    return
                }
                await ReminderScheduler.scheduleAnniversary(for: client)
                self.showToast("We'll remind you every \(client.closeDate.formatted(.dateTime.month(.wide).day()))")
            }
        } else {
            ReminderScheduler.cancelAnniversary(id)
        }
    }

    private func savePastClients() {
        if let data = try? JSONEncoder().encode(pastClients) {
            UserDefaults.standard.set(data, forKey: Self.pastClientsKey)
        }
    }

    private func restoreSphere() {
        if let data = UserDefaults.standard.data(forKey: Self.pastClientsKey), let saved = try? JSONDecoder().decode([PastClient].self, from: data) {
            pastClients = saved
        }
        if let data = UserDefaults.standard.data(forKey: Self.vendorsKey), let saved = try? JSONDecoder().decode([Vendor].self, from: data) {
            vendors = saved
        }
    }

    nonisolated static func samplePastClients() -> [PastClient] {
        let calendar = Calendar.current
        func closed(yearsAgo: Int, anniversaryInDays days: Int) -> Date {
            calendar.date(byAdding: .year, value: -yearsAgo, to: MockData.day(days)) ?? Date()
        }
        return [
            PastClient(name: "Maria and Luis Gomez", address: "4120 W Bay Vista Ave", cityName: "Tampa", closeDate: closed(yearsAgo: 2, anniversaryInDays: 3), side: .buyer),
            PastClient(name: "Tom Becker", address: "88 Harbor Dr", cityName: "Clearwater", closeDate: closed(yearsAgo: 1, anniversaryInDays: 18), side: .seller),
            PastClient(name: "Angela Price", address: "1503 Palm Sparrow Ct", cityName: "Brandon", closeDate: closed(yearsAgo: 4, anniversaryInDays: 140), side: .buyer)
        ]
    }

    // MARK: Trusted pros

    func addVendor(_ vendor: Vendor) {
        vendors.append(vendor)
        saveVendors()
        showToast("\(vendor.name) added to your pros")
    }

    func deleteVendor(_ id: UUID) {
        vendors.removeAll { $0.id == id }
        saveVendors()
    }

    private func saveVendors() {
        if let data = try? JSONEncoder().encode(vendors) {
            UserDefaults.standard.set(data, forKey: Self.vendorsKey)
        }
    }

    func vendorMessage(_ vendor: Vendor) -> String {
        var lines = ["Here's my go-to for \(vendor.category.title.lowercased()): \(vendor.name), \(vendor.company)."]
        if !vendor.contactLine.isEmpty { lines.append(vendor.contactLine) }
        if !vendor.note.isEmpty { lines.append(vendor.note) }
        lines.append("Tell them \(profile.firstName) sent you!")
        return lines.joined(separator: "\n")
    }

    func vendorListMessage() -> String {
        var lines = ["My trusted pros, from \(profile.name):", ""]
        for category in Vendor.Category.allCases {
            let group = vendors.filter { $0.category == category }
            guard !group.isEmpty else { continue }
            lines.append(category.title.uppercased())
            for vendor in group {
                lines.append("- \(vendor.name), \(vendor.company)\(vendor.contactLine.isEmpty ? "" : ": \(vendor.contactLine)")")
            }
            lines.append("")
        }
        lines.append("Questions about any of them? Just text me.")
        return lines.joined(separator: "\n")
    }

    nonisolated static func sampleVendors() -> [Vendor] {
        [
            Vendor(name: "Rachel Kim", company: "Bayside Home Loans", category: .lender, phone: "(813) 555-0142", note: "Fast pre-approvals, great with first time buyers"),
            Vendor(name: "Mike Dawson", company: "Gulf Coast Inspections", category: .inspector, phone: "(813) 555-0187", note: "Includes wind mitigation and 4 point"),
            Vendor(name: "Sunshine Title", company: "Sunshine Title and Escrow", category: .title, phone: "(813) 555-0110"),
            Vendor(name: "Carlos Ramos", company: "Crystal Clear Pools", category: .pool, phone: "(813) 555-0163", note: "Can get a green pool blue before photos")
        ]
    }

    // MARK: Showing tours

    func tour(_ id: UUID) -> ShowingTour? { tours.first { $0.id == id } }

    @discardableResult
    func createTour(buyerName: String, start: Date, minutesPerStop: Int, stops: [TourStop] = []) -> UUID {
        let tour = ShowingTour(buyerName: buyerName, start: start, minutesPerStop: minutesPerStop, stops: stops)
        tours.append(tour)
        showToast(stops.isEmpty ? "Tour for \(buyerName) created. Add the homes next." : "Tour with \(stops.count) homes is in Showing tours")
        return tour.id
    }

    // MARK: Comment to DM keywords

    private static let keywordsKey = "cinema.keywords.v1"

    func saveKeywordRule(_ rule: KeywordRule) {
        // One rule per keyword: saving a duplicate replaces the older one.
        keywordRules.removeAll { $0.id != rule.id && $0.keyword.uppercased() == rule.keyword.uppercased() }
        if let index = keywordRules.firstIndex(where: { $0.id == rule.id }) {
            keywordRules[index] = rule
        } else {
            keywordRules.append(rule)
        }
        saveKeywordRules()
        showToast("\(rule.keyword) saved")
    }

    func deleteKeywordRule(_ id: UUID) {
        keywordRules.removeAll { $0.id == id }
        saveKeywordRules()
    }

    func setKeywordRule(_ id: UUID, on: Bool) {
        guard let index = keywordRules.firstIndex(where: { $0.id == id }) else { return }
        keywordRules[index].isOn = on
        saveKeywordRules()
    }

    private func saveKeywordRules() {
        if let data = try? JSONEncoder().encode(keywordRules) {
            UserDefaults.standard.set(data, forKey: Self.keywordsKey)
        }
    }

    // MARK: Business plan

    private static let planKey = "cinema.plan.v1"

    var businessPlan: BusinessPlan {
        guard let data = UserDefaults.standard.data(forKey: Self.planKey),
              let plan = try? JSONDecoder().decode(BusinessPlan.self, from: data) else {
            var plan = BusinessPlan()
            if let price = listings.first(where: { $0.status != .sold })?.price { plan.averagePrice = Double(min(price, 900_000)) }
            return plan
        }
        return plan
    }

    func saveBusinessPlan(_ plan: BusinessPlan) {
        if let data = try? JSONEncoder().encode(plan) {
            UserDefaults.standard.set(data, forKey: Self.planKey)
        }
    }

    // MARK: Buyer wishlists

    func addBuyer(_ buyer: BuyerWish) {
        buyers.insert(buyer, at: 0)
        let count = listings.filter { buyer.matches($0) }.count
        showToast(count > 0 ? "\(buyer.firstName) matches \(count) of your listings" : "\(buyer.firstName) saved. We'll watch for matches.")
    }

    func deleteBuyer(_ id: UUID) {
        buyers.removeAll { $0.id == id }
    }

    func addStop(_ stop: TourStop, to tourID: UUID) {
        guard let index = tours.firstIndex(where: { $0.id == tourID }), !stop.address.isEmpty else { return }
        tours[index].stops.append(stop)
    }

    func moveStops(in tourID: UUID, from offsets: IndexSet, to destination: Int) {
        guard let index = tours.firstIndex(where: { $0.id == tourID }) else { return }
        tours[index].stops.move(fromOffsets: offsets, toOffset: destination)
    }

    func deleteStops(in tourID: UUID, at offsets: IndexSet) {
        guard let index = tours.firstIndex(where: { $0.id == tourID }) else { return }
        tours[index].stops.remove(atOffsets: offsets)
    }

    func setReaction(_ reaction: TourStop.Reaction, stopID: UUID, tourID: UUID) {
        guard let t = tours.firstIndex(where: { $0.id == tourID }),
              let s = tours[t].stops.firstIndex(where: { $0.id == stopID }) else { return }
        tours[t].stops[s].reaction = reaction
    }

    func deleteTour(_ id: UUID) {
        tours.removeAll { $0.id == id }
    }

    nonisolated static func sampleTours() -> [ShowingTour] {
        let start = MockData.day(1, hour: 10)
        return [
            ShowingTour(buyerName: "Marcus Reed", start: start, minutesPerStop: 30, stops: [
                TourStop(address: "2911 W San Nicholas St, Tampa", price: "$489,000"),
                TourStop(address: "4407 W Euclid Ave, Tampa", price: "$515,000"),
                TourStop(address: "3606 W Wallcraft Ave, Tampa", price: "$535,000")
            ])
        ]
    }

    // MARK: Shoot chat

    func shootMessages(for bookingID: UUID) -> [ShootMessage] {
        shootMessages.filter { $0.bookingID == bookingID }.sorted { $0.date < $1.date }
    }

    func unreadShootMessages(_ bookingID: UUID) -> Int {
        shootMessages.filter { $0.bookingID == bookingID && !$0.isRead }.count
    }

    func markShootMessagesRead(_ bookingID: UUID) {
        for index in shootMessages.indices where shootMessages[index].bookingID == bookingID && !shootMessages[index].isRead {
            shootMessages[index].isRead = true
        }
    }

    func sendShootMessage(_ text: String, bookingID: UUID) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        shootMessages.append(ShootMessage(bookingID: bookingID, fromAgent: true, text: trimmed, date: Date()))
        // Demo: the shooter answers a few seconds later. Live replies come from the Crew app.
        let booking = bookings.first { $0.id == bookingID }
        let shooterName = booking?.shooterID.flatMap { shooter($0) }?.name.split(separator: " ").first.map(String.init) ?? "Your shooter"
        let reply = Self.demoReply(to: trimmed)
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            self.shootMessages.append(ShootMessage(bookingID: bookingID, fromAgent: false, text: reply, date: Date(), isRead: false))
            self.notify(.booking, "\(shooterName) replied", detail: reply, route: .bookingChat(bookingID))
        }
    }

    nonisolated static func demoReply(to text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("late") { return "No problem at all, I'll start on the exterior shots." }
        if lower.contains("sunset") || lower.contains("twilight") { return "Love it. I'll time the pool and lanai for golden hour." }
        if lower.contains("lockbox") || lower.contains("code") || lower.contains("gate") { return "Got it, thanks. I'll text through here when I'm on site." }
        if lower.contains("home") { return "Sounds good. I'll introduce myself and keep it quick and tidy." }
        if lower.contains("neighborhood") || lower.contains("area") { return "Absolutely. I'll grab the park, the water and a few street scenes." }
        return "Thanks! Noted for the shoot. See you there."
    }

    // MARK: Deals

    func deal(_ id: UUID) -> Deal? { deals.first { $0.id == id } }

    /// The soonest open deadline across every pending deal.
    var nextDealDeadline: (Deal, DealMilestone)? {
        deals.filter { !$0.isClosed }
            .compactMap { deal in deal.nextMilestone.map { (deal, $0) } }
            .min { $0.1.dueDate < $1.1.dueDate }
    }

    /// A deadline worth a Home card: overdue or due in the next 2 days.
    var urgentDealDeadline: (Deal, DealMilestone)? {
        guard let next = nextDealDeadline else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: next.1.dueDate)).day ?? 99
        return next.1.isOverdue || days <= 2 ? next : nil
    }

    func addDeal(_ deal: Deal) {
        deals.append(deal)
        notify(.system, "Under contract!", detail: "\(deal.address) is pending. \(deal.milestones.count) deadlines are on your timeline.", route: .deal(deal.id))
        showToast("Deal added with \(deal.milestones.count) deadlines")
    }

    func toggleMilestone(_ milestoneID: UUID, dealID: UUID) {
        guard let d = deals.firstIndex(where: { $0.id == dealID }),
              let m = deals[d].milestones.firstIndex(where: { $0.id == milestoneID }) else { return }
        deals[d].milestones[m].isDone.toggle()
        if deals[d].remindersOn { setDealReminders(dealID, on: true, quiet: true) }
    }

    func setMilestoneDate(_ date: Date, milestoneID: UUID, dealID: UUID) {
        guard let d = deals.firstIndex(where: { $0.id == dealID }),
              let m = deals[d].milestones.firstIndex(where: { $0.id == milestoneID }) else { return }
        deals[d].milestones[m].dueDate = date
        deals[d].milestones.sort { $0.dueDate < $1.dueDate }
        if deals[d].remindersOn { setDealReminders(dealID, on: true, quiet: true) }
    }

    func setDealReminders(_ dealID: UUID, on: Bool, quiet: Bool = false) {
        guard let d = deals.firstIndex(where: { $0.id == dealID }) else { return }
        deals[d].remindersOn = on
        let deal = deals[d]
        let ids = deal.milestones.map { "cinema.deal.\($0.id.uuidString)" }
        ReminderScheduler.cancel(ids: ids)
        guard on else { return }
        Task {
            guard await ReminderScheduler.requestPermission() else {
                self.showToast("Turn on notifications in Settings to get reminders")
                return
            }
            for milestone in deal.milestones where !milestone.isDone {
                await ReminderScheduler.scheduleOnce(id: "cinema.deal.\(milestone.id.uuidString)", title: "Today: \(milestone.title)", body: deal.address, on: milestone.dueDate)
            }
            if !quiet { self.showToast("Reminders set for every deadline") }
        }
    }

    func closeDeal(_ dealID: UUID) {
        guard let d = deals.firstIndex(where: { $0.id == dealID }) else { return }
        deals[d].isClosed = true
        deals[d].closingDate = min(deals[d].closingDate, Date())
        for m in deals[d].milestones.indices { deals[d].milestones[m].isDone = true }
        let deal = deals[d]
        ReminderScheduler.cancel(ids: deal.milestones.map { "cinema.deal.\($0.id.uuidString)" })
        let parts = deal.address.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        addPastClient(PastClient(name: deal.clientName, address: parts.first ?? deal.address, cityName: parts.count > 1 ? parts[1] : homeCity.name, closeDate: deal.closingDate, side: deal.side), remind: true)
        if let l = listings.firstIndex(where: { $0.address == deal.address }), listings[l].status != .sold {
            setStatus(.sold, for: listings[l].id)
        } else {
            notify(.system, "Closed! Ask for a testimonial", detail: "\(deal.clientName) just closed on \(deal.address). Happy clients write the best reviews in the first week.", route: .testimonials)
        }
        showToast("Congrats on closing \(deal.address)!")
    }

    nonisolated static func sampleDeals() -> [Deal] {
        let effective = MockData.day(-13)
        let closing = MockData.day(22)
        var milestones = Deal.defaultMilestones(effective: effective, closing: closing, financed: true)
        for index in milestones.indices where milestones[index].dueDate < MockData.day(0) && index < 2 {
            milestones[index].isDone = true
        }
        return [Deal(address: "4407 W Euclid Ave, Tampa", clientName: "Marcus Reed", side: .buyer, price: 505_000, effectiveDate: effective, closingDate: closing, commissionPercent: 2.5, milestones: milestones)]
    }

    // MARK: Script writer

    func saveScript(_ idea: Idea) {
        savedScripts.insert(idea, at: 0)
        addIdea(idea)
    }

    // MARK: Plan my week

    var weekPlanDone: Int { weekPlan.filter(\.isDone).count }

    /// Spreads the weekly goal across the next 7 days with a mix of ideas from every city served.
    func buildWeekPlan() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let count = max(1, min(profile.weeklyGoal, 7))
        let step = 7.0 / Double(count)
        let days = (0..<count).compactMap { calendar.date(byAdding: .day, value: Int((Double($0) * step).rounded(.down)), to: today) }
        let weekSeed = UInt64(calendar.component(.weekOfYear, from: today)) &* 7919 &+ UInt64(weekPlan.count)
        let pool = localEngine.ideas(for: profile, count: count + 4, seed: weekSeed &+ UInt64.random(in: 0...999))
        weekPlan = zip(days, pool).map { PlannedVideo(day: $0, idea: $1) }
        for item in weekPlan { addIdea(item.idea, announce: false) }
        showToast("Your week is planned: \(weekPlan.count) videos")
    }

    func swapPlanned(_ item: PlannedVideo) {
        guard let index = weekPlan.firstIndex(where: { $0.id == item.id }) else { return }
        let used = Set(weekPlan.map(\.idea.title))
        let fresh = localEngine.ideas(for: profile, count: 12, seed: UInt64.random(in: 1...UInt64.max))
        if let replacement = fresh.first(where: { !used.contains($0.title) }) {
            weekPlan[index].idea = replacement
            addIdea(replacement, announce: false)
        }
    }

    func togglePlanned(_ item: PlannedVideo) {
        guard let index = weekPlan.firstIndex(where: { $0.id == item.id }) else { return }
        weekPlan[index].isDone.toggle()
        if weekPlan[index].isDone { profile.points += 15 }
    }

    // MARK: Achievements

    var creatorLevel: CreatorLevel { CreatorLevel.forPoints(profile.points) }

    var achievements: [Achievement] {
        let filmed = clips.filter { $0.source == .phoneEdit }.count
        let posted = posts.filter { $0.status == .posted }.count
        let openHouseLeads = leads.filter { $0.openHouseAddress != nil }.count
        let fiveStars = testimonials.filter { $0.stars == 5 }.count
        let coursesDone = courses.filter(\.isComplete).count
        let challengeDone = challenges.filter { $0.isJoined && $0.completedDays >= $0.totalDays }.count
        let rewarded = referrals.filter { $0.status == .rewarded }.count
        return [
            Achievement(id: "first-video", title: "Lights, camera", detail: "Film your first video", icon: "video.fill", progress: filmed, goal: 1, points: 50),
            Achievement(id: "ten-videos", title: "On a roll", detail: "Film 10 videos", icon: "film.stack.fill", progress: filmed, goal: 10, points: 200),
            Achievement(id: "five-posts", title: "Everywhere at once", detail: "Post 5 videos", icon: "paperplane.fill", progress: posted, goal: 5, points: 100),
            Achievement(id: "streak", title: "Week strong", detail: "Keep a 7 day streak", icon: "flame.fill", progress: profile.streakDays, goal: 7, points: 150),
            Achievement(id: "first-lead", title: "Hello, lead", detail: "Get your first lead", icon: "person.badge.plus", progress: leads.count, goal: 1, points: 50),
            Achievement(id: "open-house", title: "Open house pro", detail: "Collect 5 open house sign ins", icon: "door.left.hand.open", progress: openHouseLeads, goal: 5, points: 100),
            Achievement(id: "poster", title: "Just listed", detail: "Make your first poster", icon: "rectangle.portrait.on.rectangle.portrait.fill", progress: posters.count, goal: 1, points: 30),
            Achievement(id: "brand", title: "On brand", detail: "Fill in 3 parts of your brand kit", icon: "paintpalette.fill", progress: brandKit.completion, goal: 3, points: 50),
            Achievement(id: "five-star", title: "Client love", detail: "Save 3 five star testimonials", icon: "heart.fill", progress: fiveStars, goal: 3, points: 100),
            Achievement(id: "recruiter", title: "Recruiter", detail: "Invite an agent who joins", icon: "gift.fill", progress: rewarded, goal: 1, points: 100),
            Achievement(id: "markets", title: "Market expert", detail: "Serve 2 or more cities", icon: "map.fill", progress: allMarkets.count, goal: 2, points: 50),
            Achievement(id: "course", title: "Graduate", detail: "Finish a course", icon: "graduationcap.fill", progress: coursesDone, goal: 1, points: 150),
            Achievement(id: "challenge", title: "Champion", detail: "Finish a challenge", icon: "trophy.fill", progress: challengeDone, goal: 1, points: 200)
        ]
    }

    /// Top creators in the agent's city this month. Sample names until the backend is live.
    var cityLeaderboard: [LeaderboardEntry] {
        let names = ["Taylor Brooks", "Chris Nguyen", "Morgan Lee", "Sam Patel", "Avery Collins", "Jamie Ortiz", "Riley Chen"]
        var rows = names.enumerated().map { index, name in
            LeaderboardEntry(name: name, market: homeCity.name, points: max(60, profile.points + 260 - index * 95))
        }
        rows.append(LeaderboardEntry(name: profile.name, market: homeCity.name, points: profile.points, isMe: true))
        return rows.sorted { $0.points > $1.points }
    }

    // MARK: Link in bio

    private static let bioKey = "cinema.bio.v1"

    func saveBioPage(_ page: BioPage) {
        bioPage = page
        if let data = try? JSONEncoder().encode(page) {
            UserDefaults.standard.set(data, forKey: Self.bioKey)
        }
    }

    // MARK: Account

    /// Deletes the account. App Store rules require this to be in the app.
    func deleteAccount() async {
        if let client = SupabaseClient.shared {
            struct Empty: Codable {}
            _ = try? await client.invoke("delete-account", body: Empty(), as: Empty.self)
        }
        ReminderScheduler.cancelAll()
        profile = MockData.profile
        brandKit = BrandKit()
        bioPage = BioPage()
        weekPlan = []
        listings = []
        deals = []
        tours = []
        leads = []
        bookings = []
        agentReferrals = []
        shootMessages = []
        buyers = []
        pastClients = []
        vendors = []
        keywordRules = KeywordRule.defaults(city: homeCity.name)
        signOut()
        // signOut saves the session, so clear storage after it.
        for key in [Self.sessionKey, Self.brandKey, Self.bioKey, Self.pastClientsKey, Self.vendorsKey, Self.workKey, Self.planKey, Self.keywordsKey] {
            UserDefaults.standard.removeObject(forKey: key)
        }
        showToast("Your account was deleted")
    }

    // MARK: Brand kit

    private static let brandKey = "cinema.brand.v1"

    func saveBrandKit(_ kit: BrandKit) {
        brandKit = kit
        if let data = try? JSONEncoder().encode(kit) {
            UserDefaults.standard.set(data, forKey: Self.brandKey)
        }
    }

    private func restoreBrandKit() {
        guard let data = UserDefaults.standard.data(forKey: Self.brandKey),
              let kit = try? JSONDecoder().decode(BrandKit.self, from: data) else { return }
        brandKit = kit
    }

    // MARK: Testimonials

    var reviewRequestMessage: String {
        "Hi! It was a joy helping you with your home. Would you share a sentence or two about working with me? It helps other families find the right agent. Thank you! \(profile.firstName)"
    }

    func addTestimonial(_ testimonial: Testimonial) {
        testimonials.insert(testimonial, at: 0)
        notify(.system, "New testimonial", detail: "\(testimonial.clientName): \"\(testimonial.quote.prefix(60))\"", route: .testimonials)
        showToast("Testimonial saved")
    }

    /// A client story video idea built from a real testimonial.
    func testimonialIdea(_ testimonial: Testimonial) -> Idea {
        let city = allMarkets.first { $0.name == testimonial.cityName } ?? homeCity
        var idea = ScriptWriter.write(type: .clientStory, topic: testimonial.quote, seconds: 30, city: city, agentName: profile.name)
        idea.title = "Client story: \(testimonial.clientName)"
        idea.shots.insert("Show the quote on screen while you read it", at: 1)
        return idea
    }

    // MARK: Market update

    func marketScriptIdea(_ snapshot: MarketSnapshot) -> Idea {
        Idea(
            title: "\(snapshot.cityName) market: \(snapshot.periodLabel)",
            hook: "Here's the \(snapshot.cityName) market for \(snapshot.periodLabel) in 30 seconds.",
            category: .marketUpdate,
            shots: ["Walk toward camera, tight framing", "Market graphic on screen, point at each number", "Close on you with the keyword"],
            script: snapshot.script(agentFirstName: profile.firstName),
            targetSeconds: 30,
            whyItWorks: "Real local numbers make you the go to source. A monthly series builds a habit.",
            cityName: snapshot.cityName
        )
    }

    // MARK: Leaders: free promotion

    var isLeader: Bool { profile.role.isLeader }
    var promotions: [CommunityPost] {
        let names = Set([identityName(.team), identityName(.office), profile.brokerage])
        return communityPosts.filter { post in post.postedAs.map { names.contains($0) } ?? false }
    }

    /// Name shown when a leader posts as their team or office.
    func identityName(_ identity: PostingIdentity) -> String {
        switch identity {
        case .me: return profile.name
        case .team: return profile.teamName.isEmpty ? "\(profile.firstName)'s team" : profile.teamName
        case .office: return myMarketCenter?.name ?? profile.brokerage
        }
    }

    /// Identities this person can post as. Leaders who sell can always post as themselves.
    var postingIdentities: [PostingIdentity] {
        switch profile.role {
        case .agent: return [.me]
        case .teamLead: return profile.alsoSells ? [.me, .team] : [.team]
        case .marketCenter, .brokerageAdmin: return profile.alsoSells ? [.me, .team, .office] : [.office, .team]
        }
    }

    /// Featured post on behalf of the brokerage, office or team. Free for leaders.
    /// Posting as yourself is a normal post that goes to your own socials.
    func promote(kind: CommunityPostKind, body: String, alsoToSocials: Bool, as identity: PostingIdentity = .office) {
        let isOrg = identity != .me
        let post = CommunityPost(
            author: profile.name,
            market: profile.market,
            niche: isOrg ? (identity == .team ? "Team" : officeWord.capitalized) : profile.niche,
            kind: kind,
            body: body,
            stat: nil,
            likes: 0,
            replies: 0,
            createdAt: Date(),
            postedAs: isOrg ? identityName(identity) : nil,
            isFeatured: isOrg
        )
        communityPosts.insert(post, at: 0)
        if isOrg {
            showToast(alsoToSocials ? "Featured in Community and posted to your socials" : "Featured in Community")
        } else {
            showToast(alsoToSocials ? "Posted to Community and your socials" : "Posted to Community")
        }
    }

    func spotlight(_ member: BrokerageMember) {
        let body = "Agent spotlight: \(member.name) posted \(member.postsThisMonth) videos this month and brought in \(member.leads) leads from video. Proud to have them at \(profile.brokerage)."
        promote(kind: .win, body: body, alsoToSocials: false)
    }

    // MARK: Plans

    func changePlan(to plan: Plan) {
        profile.plan = plan
        profile.credits = max(profile.credits, plan.monthlyCredits)
        showToast("You're on \(plan.name)")
    }

    func buyCreditPack(_ count: Int) {
        profile.credits += count
        showToast("\(count) credits added")
    }
}
