import Foundation

// MARK: - Accounts

enum UserRole: String, CaseIterable, Identifiable, Codable {
    case agent
    case teamLead
    case marketCenter
    case brokerageAdmin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .agent: return "Agent"
        case .teamLead: return "Team lead"
        case .marketCenter: return "Market center leader (MCA)"
        case .brokerageAdmin: return "Brokerage admin"
        }
    }

    var subtitle: String {
        switch self {
        case .agent: return "I market myself and my listings"
        case .teamLead: return "I run a team. Free to promote my team"
        case .marketCenter: return "I lead an office. Free to promote it"
        case .brokerageAdmin: return "I manage agents and seats. Free"
        }
    }

    var icon: String {
        switch self {
        case .agent: return "person.fill"
        case .teamLead: return "person.3.fill"
        case .marketCenter: return "building.columns.fill"
        case .brokerageAdmin: return "building.2.fill"
        }
    }

    /// Team leads, market center leaders and admins use #Cinema free.
    var isLeader: Bool { self != .agent }

    var orgWord: String {
        switch self {
        case .teamLead: return "team"
        case .marketCenter: return "office"
        default: return "brokerage"
        }
    }
}

enum Plan: String, CaseIterable, Identifiable, Codable {
    case starter
    case creator
    case pro
    case brokerage
    case leader

    var id: String { rawValue }

    var name: String {
        switch self {
        case .starter: return "Starter"
        case .creator: return "Creator"
        case .pro: return "Pro"
        case .brokerage: return "Brokerage"
        case .leader: return "Leader"
        }
    }

    var price: String {
        switch self {
        case .starter: return "Free"
        case .creator: return "$99/mo"
        case .pro: return "$249/mo"
        case .brokerage: return "$49/seat/mo"
        case .leader: return "Free"
        }
    }

    /// Monthly price in dollars. Nil for per-seat plans billed to the broker.
    var monthlyDollars: Double? {
        switch self {
        case .starter, .leader: return 0
        case .creator: return 99
        case .pro: return 249
        case .brokerage: return nil
        }
    }

    /// Price label with a partner discount applied, for example "$89.10/mo".
    func price(discountPercent: Int) -> String {
        guard discountPercent > 0, let dollars = monthlyDollars, dollars > 0 else { return price }
        let discounted = dollars * Double(100 - discountPercent) / 100
        return discounted.formatted(.currency(code: "USD")) + "/mo"
    }

    var monthlyCredits: Int {
        switch self {
        case .starter: return 0
        case .creator: return 4
        case .pro: return 10
        case .brokerage: return 4
        case .leader: return 2
        }
    }

    var perks: [String] {
        switch self {
        case .starter:
            return ["Book pro shoots", "Library for paid shoots", "3 ideas a week", "Public challenges and community"]
        case .creator:
            return ["Full daily idea feed", "4 edit credits a month", "Post and schedule to 4 platforms", "AI content coach"]
        case .pro:
            return ["10 edit credits a month", "24 hour turnaround", "10% off pro shoots", "Monthly live group coaching", "1 course included"]
        case .brokerage:
            return ["Creator features per seat", "Admin dashboard", "Brokerage brand kit", "Shared credit pool"]
        case .leader:
            return ["Free for team leads, MCAs and admins", "Promote your brokerage, office and team", "Spotlight your agents and recruit", "Team dashboard and reports", "2 edit credits a month for office content"]
        }
    }
}

struct AgentProfile: Codable, Equatable {
    var name: String
    var email: String
    var brokerage: String
    var market: String
    var niche: String
    var role: UserRole
    var plan: Plan
    var credits: Int
    var streakDays: Int
    var points: Int
    /// Home city id from `FloridaMarkets` (for example "tampa-hillsborough").
    var cityID: String? = nil
    /// Other cities the agent works in. Ideas rotate across all of them.
    var serviceAreaIDs: [String] = []
    var goals: [ContentGoal] = []
    /// Videos to post each week.
    var weeklyGoal: Int = 3
    /// Team name for team leads and agents on a team.
    var teamName: String = ""
    /// Leaders who still sell their own listings get every agent tool too.
    var alsoSells: Bool = true
    /// Partner office (KW market center) and whether it is verified.
    var marketCenterID: String? = nil
    var membership: MembershipStatus = .none
    /// Listing videos, photos and posters go to the office pool for remixing.
    var sharesWithOffice: Bool = true

    var partner: Partner? { Partner.forEmail(email) }

    var homeCity: FloridaCity? { FloridaMarkets.city(cityID) }
    var serviceAreas: [FloridaCity] { serviceAreaIDs.compactMap { FloridaMarkets.city($0) } }

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}

// MARK: - Social

enum SocialPlatform: String, CaseIterable, Identifiable, Codable, Hashable {
    case facebook
    case instagram
    case tiktok
    case youtube

    var id: String { rawValue }

    var name: String {
        switch self {
        case .facebook: return "Facebook"
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .youtube: return "YouTube"
        }
    }

    var icon: String {
        switch self {
        case .facebook: return "f.circle.fill"
        case .instagram: return "camera.circle.fill"
        case .tiktok: return "music.note"
        case .youtube: return "play.rectangle.fill"
        }
    }

    /// Comment-to-DM lead capture works through Meta's private reply API only.
    var supportsLeadCapture: Bool {
        self == .facebook || self == .instagram
    }
}

// MARK: - Ideas

enum IdeaCategory: String, CaseIterable, Identifiable, Codable {
    case listingTour
    case marketUpdate
    case neighborhood
    case mythBuster
    case clientStory
    case dayInLife
    case openHouse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .listingTour: return "Listing tours"
        case .marketUpdate: return "Market updates"
        case .neighborhood: return "Neighborhoods"
        case .mythBuster: return "Myth busters"
        case .clientStory: return "Client stories"
        case .dayInLife: return "Day in the life"
        case .openHouse: return "Open houses"
        }
    }

    var icon: String {
        switch self {
        case .listingTour: return "house.fill"
        case .marketUpdate: return "chart.line.uptrend.xyaxis"
        case .neighborhood: return "map.fill"
        case .mythBuster: return "lightbulb.fill"
        case .clientStory: return "heart.fill"
        case .dayInLife: return "sun.max.fill"
        case .openHouse: return "door.left.hand.open"
        }
    }
}

struct Idea: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var hook: String
    var category: IdeaCategory
    var shots: [String]
    var script: String
    var targetSeconds: Int
    var whyItWorks: String
    var isForYou: Bool = true
    var remixedFrom: String? = nil
    /// The Florida city this idea was written for.
    var cityName: String? = nil
}

// MARK: - Clips and editing

enum EditStyle: String, CaseIterable, Identifiable, Codable {
    case clean
    case bold
    case luxury
    case fastPaced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clean: return "Clean"
        case .bold: return "Bold captions"
        case .luxury: return "Luxury"
        case .fastPaced: return "Fast paced"
        }
    }

    var detail: String {
        switch self {
        case .clean: return "Simple cuts, subtle captions"
        case .bold: return "Big word-by-word captions"
        case .luxury: return "Slow moves, elegant type, soft music"
        case .fastPaced: return "Quick cuts, zooms, trending audio"
        }
    }
}

enum EditStatus: String, CaseIterable, Codable {
    case submitted
    case aiFirstCut
    case editorPolish
    case readyForReview
    case revisions
    case approved

    var title: String {
        switch self {
        case .submitted: return "Submitted"
        case .aiFirstCut: return "AI first cut"
        case .editorPolish: return "Editor polish"
        case .readyForReview: return "Ready for review"
        case .revisions: return "Revisions"
        case .approved: return "Approved"
        }
    }

    var icon: String {
        switch self {
        case .submitted: return "tray.and.arrow.up.fill"
        case .aiFirstCut: return "wand.and.stars"
        case .editorPolish: return "scissors"
        case .readyForReview: return "eye.fill"
        case .revisions: return "arrow.uturn.backward"
        case .approved: return "checkmark.seal.fill"
        }
    }

    var needsAgent: Bool { self == .readyForReview }
}

enum ClipSource: String, Codable {
    case phoneEdit
    case proShoot

    var title: String {
        switch self {
        case .phoneEdit: return "Phone edit"
        case .proShoot: return "Pro shoot"
        }
    }
}

enum AspectFormat: String, CaseIterable, Codable, Identifiable {
    case vertical = "9:16"
    case square = "1:1"
    case wide = "16:9"

    var id: String { rawValue }
}

struct ClipComment: Identifiable, Hashable, Codable {
    var id = UUID()
    var timestamp: Double
    var author: String
    var text: String
    var date: Date = Date()

    var timestampLabel: String {
        let total = Int(timestamp)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

struct Clip: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var source: ClipSource
    var listing: String?
    var createdAt: Date
    var durationSeconds: Int
    var status: EditStatus
    var style: EditStyle
    var formats: [AspectFormat] = AspectFormat.allCases
    var comments: [ClipComment] = []
    var symbol: String
    var paletteIndex: Int
    var views: Int? = nil
    var isFavorite: Bool = false
    var videoURL: URL? = nil

    var durationLabel: String {
        String(format: "%d:%02d", durationSeconds / 60, durationSeconds % 60)
    }
}

// MARK: - Booking

enum ServiceType: String, CaseIterable, Identifiable, Codable {
    case listing
    case drone
    case brandVideo
    case headshots
    case podcast
    case studio

    var id: String { rawValue }

    var name: String {
        switch self {
        case .listing: return "Listing photo and video"
        case .drone: return "Drone"
        case .brandVideo: return "Agent brand video"
        case .headshots: return "Headshots"
        case .podcast: return "Podcast package"
        case .studio: return "Studio session"
        }
    }

    var detail: String {
        switch self {
        case .listing: return "Photos, walkthrough video and vertical cuts for every platform"
        case .drone: return "Aerial photos and video of the property and neighborhood"
        case .brandVideo: return "Your story, your why, filmed to build trust"
        case .headshots: return "Studio or on location headshots"
        case .podcast: return "1 hour produced podcast with clips"
        case .studio: return "Film in the #Cinema studio with crew and lights"
        }
    }

    var icon: String {
        switch self {
        case .listing: return "house.and.flag.fill"
        case .drone: return "airplane"
        case .brandVideo: return "person.crop.rectangle.fill"
        case .headshots: return "camera.aperture"
        case .podcast: return "mic.fill"
        case .studio: return "lightbulb.2.fill"
        }
    }

    var hours: Int {
        switch self {
        case .listing: return 2
        case .drone: return 1
        case .brandVideo: return 3
        case .headshots: return 1
        case .podcast: return 1
        case .studio: return 2
        }
    }

    var needsAddress: Bool {
        self == .listing || self == .drone
    }
}

enum BookingStatus: String, Codable {
    case depositPending
    case depositPaid
    case confirmed
    case completed

    var title: String {
        switch self {
        case .depositPending: return "Deposit pending"
        case .depositPaid: return "Deposit paid"
        case .confirmed: return "Confirmed"
        case .completed: return "Delivered"
        }
    }
}

struct Booking: Identifiable, Hashable, Codable {
    var id = UUID()
    var service: ServiceType
    var date: Date
    var address: String
    var notes: String
    var status: BookingStatus
    var depositAmount: Int = 500
    /// The shooter the agent asked for. #Cinema confirms who is assigned.
    var shooterID: UUID? = nil
    var packageName: String? = nil
    var addOns: [String] = []
    var estimatedTotal: Int? = nil
    /// Star rating the agent gave after delivery.
    var rating: Int? = nil
}

// MARK: - Posting and leads

enum PostStatus: String, Codable {
    case scheduled
    case posted
}

struct ScheduledPost: Identifiable, Hashable, Codable {
    var id = UUID()
    var clipID: UUID
    var clipTitle: String
    var platforms: [SocialPlatform]
    var caption: String
    var date: Date
    var status: PostStatus
    var leadKeyword: String?
    var views: Int = 0
    var likes: Int = 0
    var comments: Int = 0
}

enum LeadStatus: String, CaseIterable, Identifiable, Codable {
    case new
    case contacted
    case booked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new: return "New"
        case .contacted: return "Contacted"
        case .booked: return "Showing booked"
        }
    }
}

struct Lead: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var handle: String
    var platform: SocialPlatform
    var keyword: String
    var sourceClip: String
    var message: String
    var date: Date
    var status: LeadStatus
    /// Set when the lead signed in at an open house instead of commenting.
    var openHouseAddress: String? = nil
    var notes: String = ""
    var followUpDate: Date? = nil
    var lastContacted: Date? = nil
}

// MARK: - Challenges

enum ChallengeScope: String, Codable {
    case national
    case brokerage
}

struct LeaderboardEntry: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var market: String
    var points: Int
    var isMe: Bool = false
}

struct Challenge: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var subtitle: String
    var totalDays: Int
    var completedDays: Int
    var prize: String
    var participants: Int
    var isJoined: Bool
    var scope: ChallengeScope
    var checkedInToday: Bool = false
    var leaderboard: [LeaderboardEntry]

    var progress: Double {
        guard totalDays > 0 else { return 0 }
        return Double(completedDays) / Double(totalDays)
    }
}

// MARK: - Coach

enum CoachArea: String, CaseIterable, Codable {
    case hook
    case framing
    case lighting
    case audio
    case pacing
    case energy

    var title: String {
        switch self {
        case .hook: return "Hook"
        case .framing: return "Framing"
        case .lighting: return "Lighting"
        case .audio: return "Audio"
        case .pacing: return "Pacing"
        case .energy: return "Energy"
        }
    }

    var icon: String {
        switch self {
        case .hook: return "bolt.fill"
        case .framing: return "viewfinder"
        case .lighting: return "sun.max.fill"
        case .audio: return "waveform"
        case .pacing: return "metronome.fill"
        case .energy: return "flame.fill"
        }
    }
}

struct CoachTip: Identifiable, Hashable, Codable {
    var id = UUID()
    var area: CoachArea
    var text: String
    var clipTitle: String?
}

struct SkillLevel: Identifiable, Hashable, Codable {
    var id = UUID()
    var level: Int
    var title: String
    var lessons: [String]
    var isComplete: Bool
    var isCurrent: Bool
}

struct WeeklyReport: Codable, Equatable {
    var postsThisWeek: Int
    var avgWatchSeconds: Int
    var leadsThisWeek: Int
    var bestClip: String
    var whatWorked: String
    var tryNext: String
    var focusSkill: String
}

// MARK: - Community

enum CommunityPostKind: String, CaseIterable, Identifiable, Codable {
    case win
    case idea
    case question
    case lesson

    var id: String { rawValue }

    var title: String {
        switch self {
        case .win: return "Win"
        case .idea: return "Idea"
        case .question: return "Question"
        case .lesson: return "Lesson"
        }
    }

    var icon: String {
        switch self {
        case .win: return "trophy.fill"
        case .idea: return "lightbulb.fill"
        case .question: return "questionmark.bubble.fill"
        case .lesson: return "graduationcap.fill"
        }
    }
}

struct CommunityPost: Identifiable, Hashable, Codable {
    var id = UUID()
    var author: String
    var market: String
    var niche: String
    var kind: CommunityPostKind
    var body: String
    var stat: String?
    var likes: Int
    var replies: Int
    var isLiked: Bool = false
    var createdAt: Date
    var template: Idea?
    /// Set when a leader posts on behalf of their brokerage, office or team.
    var postedAs: String? = nil
    var isFeatured: Bool = false
}

struct CommunityGroup: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var detail: String
    var members: Int
    var icon: String
    var isJoined: Bool
    var isPrivate: Bool = false
}

struct SuccessStory: Identifiable, Hashable, Codable {
    var id = UUID()
    var agent: String
    var market: String
    var headline: String
    var summary: String
    var milestones: [String]
    var paletteIndex: Int
}

// MARK: - Courses

struct Lesson: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var minutes: Int
    var summary: String
    var takeaways: [String]
    var assignment: String
    var assignmentScript: String
    var isComplete: Bool = false
    var videoURL: URL? = nil
}

struct Course: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var subtitle: String
    var instructor: String
    var level: String
    /// Matches a level on the coach skill path.
    var skillLevel: Int
    var price: String
    var isOwned: Bool
    var paletteIndex: Int
    var symbol: String
    var lessons: [Lesson]

    var completedCount: Int { lessons.filter { $0.isComplete }.count }

    var progress: Double {
        guard !lessons.isEmpty else { return 0 }
        return Double(completedCount) / Double(lessons.count)
    }

    var totalMinutes: Int { lessons.reduce(0) { $0 + $1.minutes } }
    var isComplete: Bool { !lessons.isEmpty && completedCount == lessons.count }
    var nextLesson: Lesson? { lessons.first { !$0.isComplete } }
    var isStarted: Bool { completedCount > 0 }
}

// MARK: - Brokerage

struct BrokerageMember: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var postsThisMonth: Int
    var challengeDays: Int
    var creditsUsed: Int
    var leads: Int
    /// What this agent spent with #Cinema this month, in dollars.
    var monthlySpend: Double = 0
}

// MARK: - Navigation

enum Route: Hashable {
    case idea(UUID)
    case clip(UUID)
    case challenge(UUID)
    case story(UUID)
    case bookings
    case calendar
    case leads
    case coach
    case challenges
    case brokerage
    case plans
    case promote
    case courses
    case course(UUID)
    case lesson(course: UUID, lesson: UUID)
    case market
    case city(String)
    case reminders
    case help
    case marketCenter
    case officeContent
    case posterMaker
    case findShooter
    case shooter(UUID)
    case joinCrew
    case crewDashboard
    case listings
    case listing(UUID)
    case paymentCalculator
    case activity
    case referrals
    case scriptWriter
    case brandKit
    case testimonials
    case marketUpdate
    case weekPlan
    case achievements
    case lead(UUID)
    case hooks
    case greetings
    case insights
    case linkInBio
    case teleprompter
    case captionWriter
    case listingPitch
    case sellerPrep
    case search
    case referralNetwork
    case pastClients
    case vendors
    case sellerReport(UUID)
    case netSheet
    case tours
    case tour(UUID)
    case buyerCosts
    case tools
    case packageAdvisor
    case relocationGuide
    case newsletter
    case deals
    case photoReel
    case buyers
    case businessPlan
    case keywords
    case buyer(UUID)
    case deal(UUID)
    case bookingChat(UUID)
}
