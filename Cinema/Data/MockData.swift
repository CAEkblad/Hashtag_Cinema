import Foundation

/// Sample content so every screen works before the backend is connected.
/// Replace with Supabase queries in `SupabaseBackend` when ready.
enum MockData {
    static let sampleVideoURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")

    static func day(_ offset: Int, hour: Int = 10, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let shifted = calendar.date(byAdding: .day, value: offset, to: start) ?? start
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: shifted) ?? shifted
    }

    // MARK: Profile

    static let profile = AgentProfile(
        name: "Jordan Rivera",
        email: "jordan@example.com",
        brokerage: "Keller Williams Tampa",
        market: "Tampa Bay, FL",
        niche: "Waterfront homes",
        role: .agent,
        plan: .creator,
        credits: 3,
        streakDays: 6,
        points: 420,
        cityID: "tampa-hillsborough",
        serviceAreaIDs: ["st-petersburg-pinellas", "brandon-hillsborough"],
        goals: [.moreListings, .personalBrand],
        weeklyGoal: 3
    )

    // MARK: Ideas

    static let ideas: [Idea] = [
        Idea(
            title: "3 things buyers miss on a waterfront tour",
            hook: "Stop. Before you buy on the water, check these 3 things.",
            category: .listingTour,
            shots: [
                "Open on you at the dock, phone at chest height",
                "Seawall close up while you explain condition",
                "Flood zone map on your laptop screen",
                "Wide shot of the view from the back porch",
                "End on you pointing at the water: 'Comment WATER for my checklist'"
            ],
            script: "Stop. Before you buy on the water in Tampa Bay, check these three things. One: the seawall. Ask how old it is and when it was last inspected. Two: the flood zone. It changes your insurance more than the price does. Three: the dock permits. Make sure they match what is actually built. Want my full waterfront checklist? Comment WATER and I will send it to you.",
            targetSeconds: 45,
            whyItWorks: "Number hooks with a warning hold attention in the first 2 seconds, and the comment keyword turns views into leads."
        ),
        Idea(
            title: "This week's Tampa market in 30 seconds",
            hook: "Prices did something this week nobody expected.",
            category: .marketUpdate,
            shots: [
                "Tight shot, you walking toward camera",
                "Screen recording of 3 numbers: median price, days on market, new listings",
                "Close on you: what it means for buyers and sellers"
            ],
            script: "Prices in Tampa did something this week nobody expected. Median price is holding, but days on market jumped. That means sellers, price it right the first time. Buyers, you have more room to negotiate than you did a month ago. Follow for your 30 second market update every Monday.",
            targetSeconds: 30,
            whyItWorks: "A weekly series builds a habit for your followers and makes you the local expert."
        ),
        Idea(
            title: "Hidden gem: Seminole Heights coffee walk",
            hook: "If you move to Seminole Heights, this is your Saturday.",
            category: .neighborhood,
            shots: [
                "Walking shot down the street, phone on a gimbal or held steady",
                "Coffee being made, slow motion",
                "You at an outdoor table telling viewers why you love it",
                "Quick cuts of 3 homes for sale nearby"
            ],
            script: "If you move to Seminole Heights, this is your Saturday. Start with coffee on Florida Avenue, walk the bungalow streets, and grab lunch by the river. Homes here start around the mid four hundreds. Want my list of the best streets? Comment HEIGHTS.",
            targetSeconds: 40,
            whyItWorks: "Lifestyle content reaches buyers before they are looking at listings."
        ),
        Idea(
            title: "Myth: you need 20% down",
            hook: "You do not need 20% down. Here is the truth.",
            category: .mythBuster,
            shots: [
                "Text on screen: 'You need 20% down'",
                "You shaking your head, direct to camera",
                "Simple whiteboard or notes app with 3 loan options"
            ],
            script: "You do not need twenty percent down to buy a home. FHA loans start at three and a half percent. Conventional loans can go as low as three percent. And there are down payment assistance programs right here in Florida. Talk to a lender before you rule yourself out.",
            targetSeconds: 35,
            whyItWorks: "Myth busters get saved and shared, which pushes them to more people."
        ),
        Idea(
            title: "Day in the life: closing day",
            hook: "Come with me to hand over the keys.",
            category: .dayInLife,
            shots: [
                "Morning coffee and checking the file",
                "Driving clip, phone mounted",
                "Title office lobby",
                "Keys hand off, with client permission",
                "Selfie wrap up: how you feel"
            ],
            script: "Come with me to hand over the keys. This family has been looking for eight months, and today it is finally theirs. This is my favorite part of the job.",
            targetSeconds: 50,
            whyItWorks: "Behind the scenes content builds trust and shows you get results."
        )
    ]

    // MARK: Clips

    static let clips: [Clip] = [
        Clip(
            title: "Bayshore listing tour",
            source: .proShoot,
            listing: "4821 W Bayshore Blvd",
            createdAt: day(-1, hour: 15),
            durationSeconds: 58,
            status: .readyForReview,
            style: .luxury,
            comments: [ClipComment(timestamp: 12, author: "#Cinema editor", text: "Swapped the opening shot for the drone reveal.")],
            symbol: "house.fill",
            paletteIndex: 2,
            videoURL: sampleVideoURL
        ),
        Clip(
            title: "Monday market update",
            source: .phoneEdit,
            listing: nil,
            createdAt: day(-3, hour: 9),
            durationSeconds: 31,
            status: .approved,
            style: .bold,
            symbol: "chart.line.uptrend.xyaxis",
            paletteIndex: 1,
            views: 12_400,
            isFavorite: true,
            videoURL: sampleVideoURL
        ),
        Clip(
            title: "Seminole Heights coffee walk",
            source: .phoneEdit,
            listing: nil,
            createdAt: day(-5, hour: 11),
            durationSeconds: 42,
            status: .approved,
            style: .fastPaced,
            symbol: "cup.and.saucer.fill",
            paletteIndex: 4,
            views: 8_150,
            videoURL: sampleVideoURL
        ),
        Clip(
            title: "Myth: 20% down",
            source: .phoneEdit,
            listing: nil,
            createdAt: Date(),
            durationSeconds: 36,
            status: .aiFirstCut,
            style: .bold,
            symbol: "lightbulb.fill",
            paletteIndex: 0,
            videoURL: sampleVideoURL
        ),
        Clip(
            title: "Agent brand story",
            source: .proShoot,
            listing: nil,
            createdAt: day(-12, hour: 14),
            durationSeconds: 94,
            status: .approved,
            style: .clean,
            symbol: "person.crop.rectangle.fill",
            paletteIndex: 3,
            views: 21_900,
            isFavorite: true,
            videoURL: sampleVideoURL
        )
    ]

    // MARK: Bookings

    static let bookings: [Booking] = [
        Booking(service: .listing, date: day(3, hour: 9), address: "211 Davis Blvd, Tampa", notes: "Lockbox on side gate. Twilight shots if possible.", status: .confirmed, packageName: "Full package", addOns: ["Sunset or twilight photos"], estimatedTotal: 498),
        Booking(service: .listing, date: day(-4, hour: 10), address: "4821 W Bayshore Blvd, Tampa", notes: "", status: .completed, packageName: "Video + Drone", estimatedTotal: 299)
    ]

    // MARK: Posts

    static let posts: [ScheduledPost] = [
        ScheduledPost(clipID: UUID(), clipTitle: "Monday market update", platforms: [.instagram, .tiktok, .facebook], caption: "Tampa market in 30 seconds. Follow for every Monday.", date: day(-3, hour: 12), status: .posted, leadKeyword: nil, views: 12_400, likes: 640, comments: 52),
        ScheduledPost(clipID: UUID(), clipTitle: "Seminole Heights coffee walk", platforms: [.instagram, .youtube], caption: "Your Saturday in Seminole Heights. Comment HEIGHTS for my best streets list.", date: day(-5, hour: 17), status: .posted, leadKeyword: "HEIGHTS", views: 8_150, likes: 402, comments: 77),
        ScheduledPost(clipID: UUID(), clipTitle: "Agent brand story", platforms: [.facebook, .instagram], caption: "Why I do this job.", date: day(2, hour: 18), status: .scheduled, leadKeyword: nil)
    ]

    // MARK: Leads

    static let leads: [Lead] = [
        Lead(name: "Maria Santos", handle: "@mariasantos", platform: .instagram, keyword: "HEIGHTS", sourceClip: "Seminole Heights coffee walk", message: "We are relocating from Chicago in spring. Love this area!", date: day(-1, hour: 20), status: .new),
        Lead(name: "Derek Owens", handle: "@dowens_fl", platform: .instagram, keyword: "HEIGHTS", sourceClip: "Seminole Heights coffee walk", message: "Send the list please", date: day(-2, hour: 8), status: .contacted),
        Lead(name: "Priya Patel", handle: "Priya Patel", platform: .facebook, keyword: "HEIGHTS", sourceClip: "Seminole Heights coffee walk", message: "Looking for a 3 bed under 550", date: day(-4, hour: 13), status: .booked)
    ]

    // MARK: Challenges

    static let leaderboard: [LeaderboardEntry] = [
        LeaderboardEntry(name: "Alyssa Chen", market: "Austin, TX", points: 980),
        LeaderboardEntry(name: "Marcus Bell", market: "Atlanta, GA", points: 910),
        LeaderboardEntry(name: "Dana Whitfield", market: "Denver, CO", points: 860),
        LeaderboardEntry(name: "Jordan Rivera", market: "Tampa Bay, FL", points: 420, isMe: true),
        LeaderboardEntry(name: "Sam Ortiz", market: "Phoenix, AZ", points: 390)
    ]

    static let challenges: [Challenge] = [
        Challenge(title: "Post Every Day", subtitle: "30 days, one video a day", totalDays: 30, completedDays: 6, prize: "Free pro shoot", participants: 1_284, isJoined: true, scope: .national, leaderboard: leaderboard),
        Challenge(title: "Listing Launch Sprint", subtitle: "5 videos for one listing in 7 days", totalDays: 7, completedDays: 0, prize: "Studio time", participants: 312, isJoined: false, scope: .national, leaderboard: leaderboard),
        Challenge(title: "KW Tampa: Market Monday", subtitle: "Office challenge, 4 weekly market updates", totalDays: 4, completedDays: 1, prize: "Feature on #Cinema socials", participants: 38, isJoined: true, scope: .brokerage, leaderboard: Array(leaderboard.suffix(3)))
    ]

    // MARK: Coach

    static let coachTips: [CoachTip] = [
        CoachTip(area: .hook, text: "Your first line starts at 1.8 seconds. Cut the 'Hey guys' and open on the warning.", clipTitle: "Myth: 20% down"),
        CoachTip(area: .lighting, text: "Face the window, not away from it. Your face is in shadow in the first 10 seconds.", clipTitle: "Myth: 20% down"),
        CoachTip(area: .pacing, text: "You said 'um' 7 times. Try practice mode once before you record the real take.", clipTitle: "Myth: 20% down")
    ]

    static let weeklyReport = WeeklyReport(
        postsThisWeek: 4,
        avgWatchSeconds: 14,
        leadsThisWeek: 3,
        bestClip: "Monday market update",
        whatWorked: "Videos that opened on a number held viewers 2x longer than videos that opened on a greeting.",
        tryNext: "Film one neighborhood video with a comment keyword. Your HEIGHTS post brought in 3 leads.",
        focusSkill: "Hooks in the first 2 seconds"
    )

    static let skillPath: [SkillLevel] = [
        SkillLevel(level: 1, title: "First video", lessons: ["Hold your phone right", "Find your light", "Record your first 30 seconds"], isComplete: true, isCurrent: false),
        SkillLevel(level: 2, title: "Consistent creator", lessons: ["Batch film 4 videos in an hour", "Build a weekly series", "Post every day for 7 days"], isComplete: false, isCurrent: true),
        SkillLevel(level: 3, title: "Hook master", lessons: ["The 2 second rule", "5 hook formulas for agents", "Open loops that keep people watching"], isComplete: false, isCurrent: false),
        SkillLevel(level: 4, title: "Lead machine", lessons: ["Comment keywords that convert", "From DM to showing", "Retargeting your viewers"], isComplete: false, isCurrent: false),
        SkillLevel(level: 5, title: "Market authority", lessons: ["Own your niche", "Collabs with local businesses", "Turn content into listings"], isComplete: false, isCurrent: false)
    ]

    // MARK: Community

    static let communityPosts: [CommunityPost] = [
        CommunityPost(
            author: "Alyssa Chen",
            market: "Austin, TX",
            niche: "First time buyers",
            kind: .win,
            body: "My 'rent vs buy in 30 seconds' video just passed 40k views and brought in 11 DMs. The hook was a single number on screen.",
            stat: "40k views, 11 leads",
            likes: 318,
            replies: 42,
            createdAt: day(0, hour: 7),
            template: Idea(
                title: "Rent vs buy in 30 seconds",
                hook: "You are paying this much to rent. Here is what it buys you instead.",
                category: .mythBuster,
                shots: ["Number on screen: average rent in your city", "You direct to camera explaining the monthly payment", "End on a comment keyword"],
                script: "The average rent here is two thousand one hundred dollars. That same monthly payment could buy a home around three hundred thousand with a low down payment. Comment RENT and I will run your numbers.",
                targetSeconds: 30,
                whyItWorks: "One local number makes the comparison instant and personal.",
                remixedFrom: "Alyssa Chen"
            )
        ),
        CommunityPost(
            author: "Marcus Bell",
            market: "Atlanta, GA",
            niche: "Luxury",
            kind: .lesson,
            body: "I stopped filming full house tours. Now I post one room a day for a week. Each listing gets 7 videos and the last one always does best.",
            stat: nil,
            likes: 204,
            replies: 19,
            createdAt: day(-1, hour: 16)
        ),
        CommunityPost(
            author: "Dana Whitfield",
            market: "Denver, CO",
            niche: "Teams",
            kind: .question,
            body: "How are you all getting clients to agree to be on camera at closing? Looking for scripts.",
            stat: nil,
            likes: 57,
            replies: 33,
            createdAt: day(-1, hour: 10)
        )
    ]

    static let groups: [CommunityGroup] = [
        CommunityGroup(name: "Luxury agents", detail: "High end listings and branding", members: 2_140, icon: "diamond.fill", isJoined: false),
        CommunityGroup(name: "New agents", detail: "Your first year on camera", members: 5_820, icon: "sparkles", isJoined: true),
        CommunityGroup(name: "Teams", detail: "Running content for a team", members: 1_310, icon: "person.3.fill", isJoined: false),
        CommunityGroup(name: "Tampa Bay agents", detail: "Local market, collabs and referrals", members: 486, icon: "mappin.and.ellipse", isJoined: true),
        CommunityGroup(name: "KW Tampa office", detail: "Private space for your brokerage", members: 38, icon: "lock.fill", isJoined: true, isPrivate: true)
    ]

    static let stories: [SuccessStory] = [
        SuccessStory(
            agent: "Alyssa Chen",
            market: "Austin, TX",
            headline: "From zero videos to 3 listings from Instagram",
            summary: "Alyssa had never filmed herself. She joined the Post Every Day challenge and used the idea feed every morning.",
            milestones: ["Day 1: first 20 second video", "Week 3: first 10k view video", "Month 2: first buyer lead from a DM", "Month 6: 3 listings that found her through video"],
            paletteIndex: 0
        ),
        SuccessStory(
            agent: "Marcus Bell",
            market: "Atlanta, GA",
            headline: "One room a day doubled his listing views",
            summary: "Marcus turned every luxury listing into a 7 day series and now pitches it in every listing appointment.",
            milestones: ["Started with pro shoots only", "Added daily phone clips edited by #Cinema", "Listing views up 2x", "Uses his video stats to win listings"],
            paletteIndex: 2
        )
    ]

    // MARK: Courses

    static let courses: [Course] = [
        Course(
            title: "Own Your Market With Your Phone",
            subtitle: "Build your personal brand and own your niche with phone video",
            instructor: "Adam Ekblad",
            level: "Beginner",
            skillLevel: 2,
            price: "$197",
            isOwned: true,
            paletteIndex: 0,
            symbol: "iphone.gen3",
            lessons: [
                Lesson(
                    title: "Why phone video wins listings",
                    minutes: 6,
                    summary: "Sellers hire the agent they already feel like they know. Video is the fastest way to get there.",
                    takeaways: ["Video builds trust before the first call", "Consistency beats production value", "Pick one niche to own"],
                    assignment: "Film a 20 second intro: who you help and where.",
                    assignmentScript: "Hi, I'm your local agent. I help families buy and sell homes right here in our neighborhood. Follow along for tips that save you time and money.",
                    isComplete: true,
                    videoURL: sampleVideoURL
                ),
                Lesson(
                    title: "Light, sound and framing",
                    minutes: 9,
                    summary: "Three fixes that make a phone video look pro: face the window, get close to the mic, and frame at eye level.",
                    takeaways: ["Face the light, never your back to a window", "Phone at eye level, a little above is better", "Film in a quiet room or use a clip mic"],
                    assignment: "Film the same 15 second line in 3 spots in your home and keep the best one.",
                    assignmentScript: "Here's one thing most buyers miss when they tour a home. Watch this.",
                    isComplete: true,
                    videoURL: sampleVideoURL
                ),
                Lesson(
                    title: "Hooks that stop the scroll",
                    minutes: 11,
                    summary: "You have 2 seconds. Open with a number, a warning or a question, never a greeting.",
                    takeaways: ["Cut 'Hey guys' from every video", "Put the payoff in the first line", "Show the hook on screen as text"],
                    assignment: "Rewrite your intro with a warning hook and film it.",
                    assignmentScript: "Stop. Before you list your home this spring, do these three things first.",
                    videoURL: sampleVideoURL
                ),
                Lesson(
                    title: "Batch a month of content in an hour",
                    minutes: 12,
                    summary: "Plan 8 ideas, change your shirt twice, and film them back to back.",
                    takeaways: ["Plan before you press record", "Film 3 to 4 in one outfit", "Send them all to editing at once"],
                    assignment: "Film 4 ideas from your feed in one session.",
                    assignmentScript: "This week in our market, here's what you need to know.",
                    videoURL: sampleVideoURL
                ),
                Lesson(
                    title: "Turn views into leads",
                    minutes: 10,
                    summary: "Every video needs one next step. Comment keywords make that step easy.",
                    takeaways: ["One call to action per video", "Use a comment keyword with an auto DM", "Follow up within an hour"],
                    assignment: "Post a video with a comment keyword turned on.",
                    assignmentScript: "Want my full checklist? Comment LIST and I'll send it straight to you.",
                    videoURL: sampleVideoURL
                )
            ]
        ),
        Course(
            title: "Listing Video Playbook",
            subtitle: "Shot lists and scripts that sell homes faster",
            instructor: "Adam Ekblad",
            level: "Intermediate",
            skillLevel: 3,
            price: "$147",
            isOwned: false,
            paletteIndex: 2,
            symbol: "house.and.flag.fill",
            lessons: [
                Lesson(title: "The 7 day listing launch", minutes: 8, summary: "One room a day builds anticipation before the open house.", takeaways: ["Tease before you list", "One room per day", "Finish with the full tour"], assignment: "Film a 15 second teaser for your next listing.", assignmentScript: "Coming soon to the market. Here's a first look.", videoURL: sampleVideoURL),
                Lesson(title: "Walkthrough shots on a phone", minutes: 10, summary: "Slow, steady moves and doorway reveals.", takeaways: ["Walk slower than feels right", "Lead with the best room", "Shoot horizontal and vertical"], assignment: "Film a 3 room walkthrough.", assignmentScript: "Let's walk through it together, starting with my favorite room.", videoURL: sampleVideoURL),
                Lesson(title: "When to book a pro shoot", minutes: 7, summary: "Luxury listings, drone and twilight need a crew.", takeaways: ["Price point sets the budget", "Drone sells waterfront", "Twilight sells luxury"], assignment: "Pick your next listing and book the right shoot.", assignmentScript: "This one deserved the full treatment. Here's why.", videoURL: sampleVideoURL)
            ]
        ),
        Course(
            title: "Podcast Your Way to Referrals",
            subtitle: "Launch a local real estate networking podcast",
            instructor: "Adam Ekblad",
            level: "Advanced",
            skillLevel: 5,
            price: "$247",
            isOwned: false,
            paletteIndex: 3,
            symbol: "mic.fill",
            lessons: [
                Lesson(title: "Why a podcast builds your referral network", minutes: 9, summary: "Every guest is a relationship and a referral source.", takeaways: ["Interview local business owners", "Clip every episode into shorts", "Guests share it with their audience"], assignment: "List 10 local guests you'd invite.", assignmentScript: "Today I'm sitting down with one of my favorite local business owners.", videoURL: sampleVideoURL),
                Lesson(title: "Your first episode", minutes: 14, summary: "Book the #Cinema studio and keep it to 30 minutes.", takeaways: ["3 questions is enough", "Let the guest shine", "End with how to reach them"], assignment: "Film a 30 second episode trailer.", assignmentScript: "New episode out now. You won't believe what we talked about.", videoURL: sampleVideoURL)
            ]
        )
    ]

    // MARK: Brokerage

    static let brokerageMembers: [BrokerageMember] = [
        BrokerageMember(name: "Jordan Rivera", postsThisMonth: 14, challengeDays: 6, creditsUsed: 3, leads: 9, monthlySpend: 89.10),
        BrokerageMember(name: "Taylor Brooks", postsThisMonth: 21, challengeDays: 12, creditsUsed: 4, leads: 15, monthlySpend: 359.10),
        BrokerageMember(name: "Chris Nguyen", postsThisMonth: 6, challengeDays: 2, creditsUsed: 1, leads: 2, monthlySpend: 89.10),
        BrokerageMember(name: "Morgan Lee", postsThisMonth: 0, challengeDays: 0, creditsUsed: 0, leads: 0)
    ]

    // MARK: Partners (sample data until the backend list loads)

    static let marketCenters: [MarketCenter] = [
        MarketCenter(id: "sample-kw-tampa", partnerID: "kw", name: "Sample KW Market Center, Tampa", cityID: "tampa-hillsborough", joinCode: "TAMPA1", group: "KW Impact", agentCount: 212, isSample: true),
        MarketCenter(id: "sample-kw-stpete", partnerID: "kw", name: "Sample KW Market Center, St. Petersburg", cityID: "st-petersburg-pinellas", joinCode: "STPETE1", group: "KW Impact", agentCount: 168, isSample: true),
        MarketCenter(id: "sample-kw-brandon", partnerID: "kw", name: "Sample KW Market Center, Brandon", cityID: "brandon-hillsborough", joinCode: "BRANDON1", group: "KW Impact", agentCount: 141, isSample: true),
        MarketCenter(id: "sample-kw-wesley", partnerID: "kw", name: "Sample KW Market Center, Wesley Chapel", cityID: "wesley-chapel-pasco", joinCode: "WESLEY1", group: "KW Impact", agentCount: 97, isSample: true),
        MarketCenter(id: "sample-kw-sarasota", partnerID: "kw", name: "Sample KW Market Center, Sarasota", cityID: "sarasota-sarasota", joinCode: "SRQ1", agentCount: 133, isSample: true),
        MarketCenter(id: "sample-kw-orlando", partnerID: "kw", name: "Sample KW Market Center, Orlando", cityID: "orlando-orange", joinCode: "ORL1", agentCount: 254, isSample: true)
    ]

    static let joinRequests: [JoinRequest] = [
        JoinRequest(agentName: "Avery Collins", email: "avery.collins@kw.com", team: "The Bay Group", requestedAt: day(0, hour: 8)),
        JoinRequest(agentName: "Sam Patel", email: "sam.patel@kw.com", team: nil, requestedAt: day(-1, hour: 16))
    ]

    static let officeAssets: [OfficeAsset] = [
        OfficeAsset(agentName: "Taylor Brooks", kind: .video, title: "Davis Islands waterfront tour", listingAddress: "48 Biscayne Ave", status: "Just listed", createdAt: day(-1, hour: 11), symbol: "house.fill", paletteIndex: 1),
        OfficeAsset(agentName: "Jordan Rivera", kind: .photos, title: "Bayshore listing photos", listingAddress: "4821 W Bayshore Blvd", status: "Coming soon", createdAt: day(-2, hour: 14), symbol: "photo.fill", paletteIndex: 2),
        OfficeAsset(agentName: "Chris Nguyen", kind: .poster, title: "Just sold in Westchase", listingAddress: "10230 Brentford Dr", status: "Just sold", createdAt: day(-3, hour: 9), symbol: "rectangle.portrait.fill", paletteIndex: 0),
        OfficeAsset(agentName: "Taylor Brooks", kind: .video, title: "Seminole Heights coffee walk", listingAddress: nil, status: nil, createdAt: day(-4, hour: 10), symbol: "cup.and.saucer.fill", paletteIndex: 4),
        OfficeAsset(agentName: "Jordan Rivera", kind: .poster, title: "Open house this Sunday", listingAddress: "211 Davis Blvd", status: "Open house", createdAt: day(-5, hour: 15), symbol: "door.left.hand.open", paletteIndex: 3)
    ]
}
