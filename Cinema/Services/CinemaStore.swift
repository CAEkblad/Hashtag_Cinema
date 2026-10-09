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

    // Brokerage
    var brokerageMembers = MockData.brokerageMembers

    // UI state
    var isRefreshingIdeas = false
    var toast: String?

    private let ideaEngine: any IdeaEngine
    private let editing: any AIEditingService
    private let payments: any PaymentsService
    private let posting: any SocialPostingService
    private let coach: any CoachService

    init(
        ideaEngine: any IdeaEngine = MockIdeaEngine(),
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
    }

    func completeOnboarding(name: String, role: UserRole, market: String, niche: String, plan: Plan) {
        if !name.isEmpty { profile.name = name }
        profile.role = role
        if !market.isEmpty { profile.market = market }
        profile.niche = niche
        profile.plan = plan
        profile.credits = max(profile.credits, plan.monthlyCredits)
        hasOnboarded = true
    }

    func signOut() {
        isSignedIn = false
        hasOnboarded = false
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
        if let fresh = try? await ideaEngine.generateIdeas(for: profile) {
            ideas = fresh
        }
    }

    /// Community "Remix" turns a post that worked into an idea card for this agent's market.
    @discardableResult
    func remix(_ post: CommunityPost) -> Idea? {
        guard var template = post.template else { return nil }
        template.id = UUID()
        template.remixedFrom = post.author
        template.title = "\(template.title) (\(profile.market) remix)"
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
    }

    func toggleFavorite(_ clipID: UUID) {
        guard let index = clips.firstIndex(where: { $0.id == clipID }) else { return }
        clips[index].isFavorite.toggle()
    }

    // MARK: Booking

    func payDepositAndBook(service: ServiceType, date: Date, address: String, notes: String) async -> Booking? {
        do {
            let result = try await payments.payDeposit(amount: 500, description: service.name)
            guard result.succeeded else { return nil }
            let booking = Booking(service: service, date: date, address: address, notes: notes, status: .depositPaid)
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
    }

    func disconnect(_ platform: SocialPlatform) {
        connectedPlatforms.remove(platform)
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
