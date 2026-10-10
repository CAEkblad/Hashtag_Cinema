import Foundation

// MARK: - Platforms

enum TrendPlatform: String, Codable, CaseIterable, Identifiable, Hashable {
    case tiktok, instagram, facebook

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tiktok: return "TikTok"
        case .instagram: return "Instagram"
        case .facebook: return "Facebook"
        }
    }

    var short: String {
        switch self {
        case .tiktok: return "TT"
        case .instagram: return "IG"
        case .facebook: return "FB"
        }
    }

    var icon: String {
        switch self {
        case .tiktok: return "music.note"
        case .instagram: return "camera.circle.fill"
        case .facebook: return "f.circle.fill"
        }
    }

    /// Opens the platform's own search so agents watch real, current examples there.
    func searchURL(phrase: String, hashtag: String) -> URL? {
        let q = phrase.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? phrase
        let tag = hashtag.replacingOccurrences(of: "#", with: "").addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? hashtag
        switch self {
        case .tiktok: return URL(string: "https://www.tiktok.com/search/video?q=\(q)")
        case .instagram: return URL(string: "https://www.instagram.com/explore/tags/\(tag)/")
        case .facebook: return URL(string: "https://www.facebook.com/search/videos/?q=\(q)")
        }
    }

    /// Works out the platform from a pasted share link.
    static func detect(_ url: URL) -> TrendPlatform? {
        guard let host = url.host?.lowercased() else { return nil }
        if host.contains("tiktok.com") { return .tiktok }
        if host.contains("instagram.com") || host == "instagr.am" { return .instagram }
        if host.contains("facebook.com") || host == "fb.watch" || host == "fb.com" { return .facebook }
        return nil
    }
}

// MARK: - Trends

enum TrendHeat: Int, Codable, Comparable, Hashable {
    case steady = 1, rising = 2, hot = 3

    static func < (a: TrendHeat, b: TrendHeat) -> Bool { a.rawValue < b.rawValue }

    var title: String {
        switch self {
        case .hot: return "Hot"
        case .rising: return "Rising"
        case .steady: return "Evergreen"
        }
    }

    var icon: String {
        switch self {
        case .hot: return "flame.fill"
        case .rising: return "arrow.up.right"
        case .steady: return "leaf.fill"
        }
    }
}

/// A real video someone posted that shows the format. Comes from the trends backend.
struct TrendExample: Codable, Hashable, Identifiable {
    var id: String { url.absoluteString }
    var platform: TrendPlatform
    var url: URL
    var caption: String?
    var creator: String?
    var views: Int?
    var likes: Int?
    var comments: Int?
    var thumbnailUrl: URL?
    var postedAt: Date?

    var statLine: String? {
        var parts: [String] = []
        if let views, views > 0 { parts.append("\(views.compact) views") }
        if let likes, likes > 0 { parts.append("\(likes.compact) likes") }
        if let comments, comments > 0 { parts.append("\(comments.compact) comments") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

/// A video format that is working for agents right now, written as a template
/// the app can fill in with the agent's city and listing.
struct Trend: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    /// One line on how it is shot.
    var format: String
    var platforms: [TrendPlatform]
    var hashtags: [String]
    /// What to type into TikTok or Facebook search to watch examples.
    var searchPhrase: String
    var hook: String
    var whyItWorks: String
    var beats: [String]
    var script: String
    var seconds: Int
    var category: IdeaCategory
    var heat: TrendHeat
    /// True when the format works best with one of the agent's listings.
    var usesListing: Bool
    /// Words that show up in captions of videos in this format. Used to match pasted links.
    var keywords: [String]
    var audioTip: String?
    var examples: [TrendExample]?
    var updatedAt: Date?

    var exampleList: [TrendExample] { examples ?? [] }
    var primaryHashtag: String { hashtags.first ?? "realestate" }
}

// MARK: - Making the agent's version

struct TrendContext {
    var city: FloridaCity
    var listing: Listing?
    var agentName: String

    var cityName: String { listing?.placeName?.components(separatedBy: ",").first ?? city.name }
    var hood: String { city.neighborhoods.first ?? city.name }
    var hood2: String { city.neighborhoods.dropFirst().first ?? "the next town over" }
    var price: String { listing?.priceLabel ?? "[your price]" }
    var specs: String { listing?.specsLine ?? "[beds and baths]" }
    var street: String {
        guard let address = listing?.address, !address.isEmpty else { return "[the street]" }
        return address.split(separator: ",").first.map(String.init) ?? address
    }
    var firstName: String { agentName.split(separator: " ").first.map(String.init) ?? agentName }
}

extension Trend {
    func fill(_ text: String, _ context: TrendContext) -> String {
        text
            .replacingOccurrences(of: "{city}", with: context.cityName)
            .replacingOccurrences(of: "{county}", with: context.city.county)
            .replacingOccurrences(of: "{hood}", with: context.hood)
            .replacingOccurrences(of: "{hood2}", with: context.hood2)
            .replacingOccurrences(of: "{price}", with: context.price)
            .replacingOccurrences(of: "{specs}", with: context.specs)
            .replacingOccurrences(of: "{street}", with: context.street)
            .replacingOccurrences(of: "{name}", with: context.firstName)
    }

    /// The agent's own version of this trend, ready for the teleprompter and shot list.
    func idea(_ context: TrendContext, inspiredBy: String? = nil) -> Idea {
        Idea(
            title: fill(title, context) + (context.listing != nil && usesListing ? " at \(context.street)" : " in \(context.cityName)"),
            hook: fill(hook, context),
            category: category,
            shots: beats.map { fill($0, context) },
            script: fill(script, context),
            targetSeconds: seconds,
            whyItWorks: whyItWorks,
            remixedFrom: inspiredBy ?? title,
            cityName: context.cityName
        )
    }

    /// How closely a pasted caption matches this format, for picking a starting point.
    func matchScore(_ caption: String) -> Int {
        let text = caption.lowercased()
        var score = keywords.reduce(0) { $0 + (text.contains($1.lowercased()) ? 2 : 0) }
        score += hashtags.reduce(0) { $0 + (text.contains("#" + $1.lowercased()) ? 1 : 0) }
        return score
    }
}

// MARK: - Built in formats

/// The formats our team sees working for US agents. The trends backend updates heat,
/// adds new formats and attaches real example videos; this list keeps the feed useful offline.
enum TrendLibrary {
    static let all: [Trend] = [
        Trend(
            id: "reverse-tour",
            title: "The reverse tour",
            format: "Show the best rooms first and hold the price until the very end.",
            platforms: [.tiktok, .instagram, .facebook],
            hashtags: ["housetour", "hometour", "realestate"],
            searchPhrase: "guess the price house tour",
            hook: "Guess the price of this {city} home before I tell you.",
            whyItWorks: "People stay to the end to see if they guessed right, and the comments fill up with guesses. Watch time and comments are what push a video out.",
            beats: [
                "Open on the single best shot: the view, the kitchen or the pool",
                "Walk 4 to 6 rooms in quick 2 second clips",
                "One close up of a detail people miss",
                "Face the camera and reveal the price on screen",
                "End on the front of the house with your comment keyword"
            ],
            script: "Guess the price of this {city} home before I tell you. {specs}. Look at this kitchen. This is the primary suite. And the backyard. Okay. Drop your guess in the comments. It's listed at {price}. Did you get it? Comment TOUR and I'll send you the full video.",
            seconds: 30,
            category: .listingTour,
            heat: .hot,
            usesListing: true,
            keywords: ["guess the price", "guess", "price reveal", "how much", "tour"],
            audioTip: "Any upbeat trending sound under your voice. Keep it low so the reveal lands."
        ),
        Trend(
            id: "what-price-gets",
            title: "What this price gets you",
            format: "Same budget, two or three neighborhoods, side by side.",
            platforms: [.tiktok, .instagram, .facebook],
            hashtags: ["whatcanyouget", "realestate", "househunting"],
            searchPhrase: "what you get for the price house",
            hook: "Here's what {price} gets you in {hood} versus {hood2}.",
            whyItWorks: "Buyers search by budget, so a number in the first second stops the scroll. Comparing places gets people tagging friends who live there.",
            beats: [
                "Price on screen in the first second",
                "3 quick clips of the first home with the neighborhood name",
                "3 quick clips of the second home",
                "Face the camera: which one would you pick?",
                "End card with your comment keyword"
            ],
            script: "Here's what {price} gets you in {hood} versus {hood2}. In {hood} you get this. [specs and one standout feature]. In {hood2}, same budget, you get this. [specs and one standout feature]. Which one are you picking? Comment LIST and I'll send you what's out there right now.",
            seconds: 35,
            category: .marketUpdate,
            heat: .hot,
            usesListing: false,
            keywords: ["what", "gets you", "budget", "versus", "vs", "for the price"],
            audioTip: nil
        ),
        Trend(
            id: "pov-keys",
            title: "POV: you just got the keys",
            format: "A closing day moment from your buyer's point of view.",
            platforms: [.instagram, .tiktok, .facebook],
            hashtags: ["closingday", "newhomeowner", "firsttimehomebuyer"],
            searchPhrase: "closing day keys first time home buyer",
            hook: "POV: you were renting a year ago and now you're holding keys in {city}.",
            whyItWorks: "Big feelings get shared. Friends and family of the buyer repost it, which puts you in front of their whole circle.",
            beats: [
                "Close up of the keys handed over",
                "Buyer walking through the front door (ask first)",
                "The sold sign or the closing table",
                "Quick selfie video of you and the buyer",
                "Text on screen: how long it took and one hurdle you beat"
            ],
            script: "A year ago they were renting. Today they got the keys to their first home in {city}. We lost two offers before this one, and they never gave up. If you think owning is out of reach, comment KEYS and I'll show you how they did it.",
            seconds: 20,
            category: .clientStory,
            heat: .hot,
            usesListing: false,
            keywords: ["pov", "keys", "closing day", "first home", "homeowner", "closed"],
            audioTip: "An emotional trending sound works here. Pick one with no lyrics over the talking part."
        ),
        Trend(
            id: "buyer-red-flags",
            title: "Things I'd never do as a buyer",
            format: "A fast countdown of mistakes, one per clip.",
            platforms: [.tiktok, .instagram],
            hashtags: ["homebuyingtips", "firsttimehomebuyer", "realtortips"],
            searchPhrase: "things I would never do as a home buyer realtor",
            hook: "As a {city} agent, here are 3 things I'd never do when buying a home.",
            whyItWorks: "Lists are easy to follow and people save them for later. Saves tell the app your video is worth showing to more buyers.",
            beats: [
                "Hook to camera with 3 on screen",
                "Number 1 with a quick B roll clip",
                "Number 2 with a quick B roll clip",
                "Number 3 with a quick B roll clip",
                "Ask them to save it and comment your keyword"
            ],
            script: "As a {city} agent, here are 3 things I'd never do when buying a home. One: skip the inspection to win the deal. Two: open a new credit card before closing. Three: buy here without checking the flood zone and insurance quote first. Save this for later, and comment TIPS for my full buyer checklist.",
            seconds: 30,
            category: .mythBuster,
            heat: .rising,
            usesListing: false,
            keywords: ["never", "mistakes", "don't", "things i", "red flags"],
            audioTip: nil
        ),
        Trend(
            id: "green-screen-react",
            title: "Green screen listing breakdown",
            format: "Stand in front of your listing photos and point out what makes it special.",
            platforms: [.tiktok, .facebook],
            hashtags: ["greenscreen", "realestate", "justlisted"],
            searchPhrase: "realtor green screen listing review",
            hook: "Let's break down this {price} listing on {street}.",
            whyItWorks: "It's the fastest way to make a video without going to the house, and pointing at details keeps eyes on the screen.",
            beats: [
                "Turn on the green screen effect with your first listing photo",
                "Swipe through 4 or 5 photos while you talk",
                "Point to one detail per photo",
                "Finish on the price and your keyword"
            ],
            script: "Let's break down this {price} listing on {street}. {specs}. First thing I noticed is this. [detail]. Then look at this. [detail]. And this is the part buyers will love. [detail]. Comment INFO and I'll send you the details before it's gone.",
            seconds: 40,
            category: .listingTour,
            heat: .steady,
            usesListing: true,
            keywords: ["green screen", "breakdown", "let's look", "review", "zillow"],
            audioTip: "Your voice only. No music under the talking."
        ),
        Trend(
            id: "hidden-feature",
            title: "This house has a secret",
            format: "Tease one surprising feature, then reveal it.",
            platforms: [.tiktok, .instagram, .facebook],
            hashtags: ["hiddenroom", "dreamhome", "housetour"],
            searchPhrase: "house has a secret hidden feature",
            hook: "This {city} home has a feature you'll never guess.",
            whyItWorks: "Curiosity holds people until the reveal. It works even for normal homes if you pick the one thing that's unusual.",
            beats: [
                "Start at a normal looking spot",
                "Slow walk toward the feature",
                "The reveal in one clean shot",
                "A second angle of the feature",
                "End with price and keyword"
            ],
            script: "This {city} home has a feature you'll never guess. It looks like a normal hallway, right? But open this. [reveal]. That's the kind of thing you don't see in the photos. {specs}, {price}. Comment SECRET and I'll send you the full tour.",
            seconds: 25,
            category: .listingTour,
            heat: .rising,
            usesListing: true,
            keywords: ["secret", "hidden", "never guess", "wait for it", "surprise"],
            audioTip: "A suspense sound that builds to the reveal."
        ),
        Trend(
            id: "moving-here",
            title: "Moving to your city? Watch this",
            format: "A quick welcome tour with 4 or 5 things people should know.",
            platforms: [.facebook, .instagram, .tiktok],
            hashtags: ["movingto", "relocation", "realestate"],
            searchPhrase: "moving to florida what to know realtor",
            hook: "Moving to {city}? Here's what nobody tells you.",
            whyItWorks: "People research a city for months before they move. This video gets found by search for a long time, not just this week.",
            beats: [
                "You in front of a spot everyone in town knows",
                "One clip for each thing people should know",
                "A quick shot of a neighborhood like {hood}",
                "Face the camera with your offer to help"
            ],
            script: "Moving to {city}? Here's what nobody tells you. One: {county} County traffic peaks earlier than you think. Two: get your insurance quote before you fall in love with a house. Three: {hood} is the area people ask me about most. Comment MOVING and I'll send you my relocation guide.",
            seconds: 45,
            category: .neighborhood,
            heat: .steady,
            usesListing: false,
            keywords: ["moving to", "relocat", "what to know", "nobody tells you", "living in"],
            audioTip: nil
        ),
        Trend(
            id: "day-in-life",
            title: "A day in the life of an agent",
            format: "Fast clips from your real day, start to finish.",
            platforms: [.tiktok, .instagram],
            hashtags: ["dayinthelife", "realtorlife", "realestateagent"],
            searchPhrase: "day in the life realtor",
            hook: "A real day in the life of a {city} real estate agent.",
            whyItWorks: "People like working with someone they feel they know. Behind the scenes clips build trust before they ever call you.",
            beats: [
                "Morning coffee or the drive in",
                "Showing or listing appointment (no client faces without permission)",
                "Paperwork or calls",
                "Something fun in {city}",
                "End of day thought to camera"
            ],
            script: "A real day in the life of a {city} real estate agent. Coffee first. Then a listing appointment in {hood}. Two showings this afternoon. A quick lunch break. And contracts tonight. Want to see what buying here looks like? Comment DAY and I'll walk you through it.",
            seconds: 30,
            category: .dayInLife,
            heat: .steady,
            usesListing: false,
            keywords: ["day in the life", "ditl", "realtor life", "come with me", "a day"],
            audioTip: "A chill trending sound with voice over or text only."
        ),
        Trend(
            id: "myth-fact",
            title: "Myth or fact",
            format: "Say a myth, slap a big MYTH on screen, then the truth.",
            platforms: [.tiktok, .instagram, .facebook],
            hashtags: ["realestatemyths", "homebuyingtips", "firsttimehomebuyer"],
            searchPhrase: "real estate myth vs fact",
            hook: "You need 20% down to buy a home. Myth.",
            whyItWorks: "People love being told something they believed is wrong, and they share it with friends who believe it too.",
            beats: [
                "Say the myth to camera",
                "Big MYTH text with a sound effect",
                "The truth in one or two sentences",
                "One real example with a number",
                "Keyword ask"
            ],
            script: "You need 20% down to buy a home. Myth. Plenty of loans let you put down 3 to 5%, and some programs in {county} County help with the rest. A lot of my buyers in {city} put down way less than they thought. Comment DOWN and I'll send you the options.",
            seconds: 25,
            category: .mythBuster,
            heat: .rising,
            usesListing: false,
            keywords: ["myth", "fact", "true or false", "you don't need", "misconception"],
            audioTip: nil
        ),
        Trend(
            id: "reply-comment",
            title: "Replying to a comment",
            format: "Pin a real comment or question on screen and answer it.",
            platforms: [.tiktok, .instagram],
            hashtags: ["realtortips", "realestate", "askarealtor"],
            searchPhrase: "realtor replying to comment",
            hook: "Someone asked me if now is a bad time to buy in {city}. Here's my honest answer.",
            whyItWorks: "Answering one real question feels personal and gets more questions in the comments, which gives you your next video.",
            beats: [
                "Put the comment or question on screen",
                "Your honest answer to camera",
                "One fact or number that backs it up",
                "Invite the next question"
            ],
            script: "Someone asked me if now is a bad time to buy in {city}. Honest answer? It depends on how long you'll stay. If it's 5 years or more, waiting for the perfect time usually costs more than it saves. Here's what I'm seeing in {hood} right now. [one real number]. Got a question? Drop it below and I'll answer it next.",
            seconds: 40,
            category: .mythBuster,
            heat: .hot,
            usesListing: false,
            keywords: ["replying to", "reply", "someone asked", "you asked", "question"],
            audioTip: "No music. Just you."
        ),
        Trend(
            id: "almost-fell-apart",
            title: "The deal that almost fell apart",
            format: "A short story with one turning point and a happy ending.",
            platforms: [.facebook, .instagram, .tiktok],
            hashtags: ["realestatestory", "realtorlife", "closingday"],
            searchPhrase: "deal almost fell apart realtor story",
            hook: "This deal almost fell apart 3 days before closing.",
            whyItWorks: "Stories keep people watching, and it shows sellers and buyers what you do behind the scenes without bragging.",
            beats: [
                "Hook to camera, serious face",
                "B roll of the house or neighborhood (no address)",
                "The problem in one sentence",
                "What you did to save it",
                "The happy ending and keyword"
            ],
            script: "This deal almost fell apart 3 days before closing. The appraisal came in low. My buyers couldn't cover the gap, and the sellers had already bought their next home. So I pulled 3 better comps, we challenged it, and we met in the middle. They closed on time. That's the stuff nobody sees. Comment STORY if you want more like this.",
            seconds: 45,
            category: .clientStory,
            heat: .rising,
            usesListing: false,
            keywords: ["almost fell apart", "fell through", "story time", "storytime", "almost lost"],
            audioTip: nil
        ),
        Trend(
            id: "open-house-setup",
            title: "Set up my open house with me",
            format: "Time lapse of signs, lights and snacks, ending with the door opening.",
            platforms: [.instagram, .tiktok, .facebook],
            hashtags: ["openhouse", "realtorlife", "justlisted"],
            searchPhrase: "set up open house with me realtor",
            hook: "Come set up my open house on {street} with me.",
            whyItWorks: "It's a fun watch and an invite in one. Locals see it the morning of and show up.",
            beats: [
                "Signs going in the yard",
                "Lights on, blinds open, room by room",
                "Snacks and sign in table",
                "The best room looking perfect",
                "Text on screen: time, address and come say hi"
            ],
            script: "Come set up my open house on {street} with me. Signs out. Lights on in every room. Snacks ready. And this is the room everybody's going to love. {specs}, {price}. Open today, come say hi.",
            seconds: 20,
            category: .openHouse,
            heat: .steady,
            usesListing: true,
            keywords: ["open house", "set up with me", "setup", "come with me"],
            audioTip: "A trending upbeat sound with text on screen works best."
        ),
        Trend(
            id: "tier-list",
            title: "Ranking neighborhoods",
            format: "A tier list of local areas from S to C with one reason each.",
            platforms: [.tiktok, .instagram],
            hashtags: ["tierlist", "neighborhoods", "realestate"],
            searchPhrase: "ranking neighborhoods realtor tier list",
            hook: "Ranking {city} neighborhoods as an agent. Don't come for me.",
            whyItWorks: "Local pride gets people commenting and arguing, and every comment pushes the video to more locals.",
            beats: [
                "Hook with the tier list template on screen",
                "Drop each neighborhood in with one reason",
                "Quick B roll of each spot",
                "Ask where they'd put their neighborhood"
            ],
            script: "Ranking {city} neighborhoods as an agent. Don't come for me. {hood}: top tier for the parks and the restaurants. {hood2}: great value if you want more space. [add 2 or 3 more]. Where would you put yours? Tell me in the comments.",
            seconds: 45,
            category: .neighborhood,
            heat: .rising,
            usesListing: false,
            keywords: ["ranking", "tier list", "rating", "best neighborhoods", "ranked"],
            audioTip: nil
        ),
        Trend(
            id: "staging-before-after",
            title: "Before and after",
            format: "Same angle, before and after the clean up, staging or photos.",
            platforms: [.instagram, .facebook, .tiktok],
            hashtags: ["beforeandafter", "homestaging", "listingphotos"],
            searchPhrase: "before and after home staging listing",
            hook: "Same house. Same room. Watch what a little prep did.",
            whyItWorks: "Transformations are satisfying to watch, and they show sellers exactly why they should hire you.",
            beats: [
                "Before shot of a room, phone at chest height",
                "Hard cut to the same angle after",
                "Repeat for 2 or 3 rooms",
                "The result: days on market or offers"
            ],
            script: "Same house. Same room. Watch what a little prep did. [before] [after]. We decluttered, swapped the bulbs and brought in pro photos. It went under contract in [days] days. Selling in {city}? Comment PREP and I'll send you my seller checklist.",
            seconds: 20,
            category: .listingTour,
            heat: .steady,
            usesListing: true,
            keywords: ["before and after", "before", "after", "transformation", "staging"],
            audioTip: "A trending transition sound timed to the hard cut."
        )
    ]

    static func trend(_ id: String) -> Trend? { all.first { $0.id == id } }

    /// Puts fresh server data on top of the built in list: new formats are added,
    /// existing ones take the server's heat and example videos.
    static func merge(_ remote: [Trend]) -> [Trend] {
        var byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        var order = all.map(\.id)
        for trend in remote {
            if byID[trend.id] == nil { order.insert(trend.id, at: 0) }
            byID[trend.id] = trend
        }
        return order.compactMap { byID[$0] }
    }
}
