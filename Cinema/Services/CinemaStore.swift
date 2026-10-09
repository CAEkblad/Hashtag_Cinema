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

    // #Cinema Crew
    var shooters = MockData.shooters
    var favoriteShooterIDs: Set<UUID> = []
    var crewApplication: CrewApplication?
    var crewJobOffers = MockData.crewJobOffers

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

    /// Saves who is signed in and their setup so the app opens where they left off.
    func persist() {
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
    }

    // MARK: Leads

    func setLeadStatus(_ status: LeadStatus, for leadID: UUID) {
        guard let index = leads.firstIndex(where: { $0.id == leadID }) else { return }
        leads[index].status = status
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
