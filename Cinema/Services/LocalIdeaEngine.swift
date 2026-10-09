import Foundation

// The local idea engine writes ideas for any Florida city on the phone, with no
// network. It mixes the city's traits (beach, golf, military, new construction...),
// the month (hurricane season, snowbirds, spring training...), the agent's niche
// and goals. The AI engine on the backend uses the same inputs and these
// templates as examples, so ideas look the same online and offline.

struct IdeaTemplate {
    var key: String
    var category: IdeaCategory
    /// The city needs at least one of these. Empty means every city.
    var anyOf: Set<CityTrait> = []
    /// Only in these months (1 to 12). Empty means all year.
    var months: Set<Int> = []
    /// Niches that get this idea boosted to the top.
    var niches: Set<String> = []
    var goals: Set<ContentGoal> = []
    var title: String
    var hook: String
    var shots: [String]
    var script: String
    var seconds: Int
    var why: String
    var keyword: String
}

enum FloridaCalendar {
    static let monthNames = ["january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"]

    /// Timely topics for this month in this city, most specific first.
    static func moments(month: Int, city: FloridaCity) -> [SeasonalMoment] {
        var list: [SeasonalMoment] = []

        // City events from the highlights ("Gasparilla Pirate Festival in late January").
        for (index, highlight) in city.highlights.enumerated() where months(in: highlight).contains(month) {
            list.append(SeasonalMoment(
                id: "\(city.id)-event-\(index)",
                title: highlight,
                detail: "Locals and out of town buyers are searching for it this month. Be the agent who shows it.",
                icon: "party.popper.fill",
                hook: "If you live in \(city.name), you already know what this month means.",
                category: .neighborhood
            ))
        }
        if (2...3).contains(month), let spring = city.highlights.first(where: { $0.lowercased().contains("spring training") }) {
            list.append(SeasonalMoment(
                id: "\(city.id)-spring-training",
                title: spring,
                detail: "Baseball fans visit every spring and some of them buy. Film near the ballpark.",
                icon: "baseball.fill",
                hook: "Here for spring training? Here is what it is like to live here year round.",
                category: .neighborhood
            ))
        }

        if (1...2).contains(month) || month == 3 {
            list.append(SeasonalMoment(
                id: "homestead",
                title: "Homestead exemption deadline is March 1",
                detail: "New owners save on property taxes when they file with the \(city.county) County Property Appraiser. A helpful reminder that earns saves.",
                icon: "calendar.badge.exclamationmark",
                hook: "Bought a home in \(city.county) County last year? Do this before March 1.",
                category: .mythBuster
            ))
        }
        if city.has(.snowbird) && ([10, 11, 12, 1, 2, 3, 4] as Set).contains(month) {
            list.append(SeasonalMoment(
                id: "snowbirds",
                title: month >= 10 ? "Snowbirds are coming back" : "Snowbird season is in full swing",
                detail: "Seasonal residents tour homes while they are here. Speak to the buyer who rents every winter and wonders about owning.",
                icon: "bird.fill",
                hook: "If you spend every winter in \(city.name), you should hear this.",
                category: .marketUpdate
            ))
        }
        if city.has(.beach) && month == 3 {
            list.append(SeasonalMoment(
                id: "spring-break",
                title: "Spring break crowds",
                detail: "Show the side of \(city.name) locals love, away from the crowds.",
                icon: "sun.max.fill",
                hook: "Spring break is the busiest week in \(city.name). Here is where locals go instead.",
                category: .neighborhood
            ))
        }
        if (3...5).contains(month) {
            list.append(SeasonalMoment(
                id: "spring-market",
                title: "Spring selling season",
                detail: "More listings hit the market. Sellers want to know how to stand out.",
                icon: "leaf.fill",
                hook: "Selling in \(city.name) this spring? Do these 3 things first.",
                category: .listingTour
            ))
        }
        if month == 5 || month == 6 {
            list.append(SeasonalMoment(
                id: "hurricane-prep",
                title: month == 5 ? "Hurricane season starts June 1" : "Hurricane season is here",
                detail: "Homeowners want a simple checklist: shutters, roof, insurance documents, generator safety.",
                icon: "hurricane",
                hook: "Hurricane season starts June 1. Here is the 60 second homeowner checklist.",
                category: .mythBuster
            ))
        }
        if (8...10).contains(month) && city.has(.coastalCounty) {
            list.append(SeasonalMoment(
                id: "hurricane-peak",
                title: "Peak hurricane season",
                detail: "Buyers ask about flood zones, elevation and insurance. Calm, useful answers build trust.",
                icon: "hurricane",
                hook: "Buying in \(city.name) during hurricane season? Ask these 3 questions.",
                category: .mythBuster
            ))
        }
        if (6...8).contains(month) {
            list.append(SeasonalMoment(
                id: "summer",
                title: "Florida summer",
                detail: "Fewer buyers touring means more room to negotiate. Show where locals cool off.",
                icon: "thermometer.sun.fill",
                hook: "Summer in \(city.name) is the best kept secret for buyers. Here is why.",
                category: .marketUpdate
            ))
        }
        if month == 8 {
            list.append(SeasonalMoment(
                id: "back-to-school",
                title: "Back to school",
                detail: "Families moving before school starts. Show how to look up school assignments for any address.",
                icon: "backpack.fill",
                hook: "Moving to \(city.name) with kids? Check this before you make an offer.",
                category: .mythBuster
            ))
        }
        if city.has(.college) && (9...11).contains(month) {
            list.append(SeasonalMoment(
                id: "game-day",
                title: "Football season and game days",
                detail: "Parents of students and alumni think about buying near campus. Talk rentals and game day homes.",
                icon: "football.fill",
                hook: "Parents, stop paying rent for your college kid in \(city.name). Here is the math.",
                category: .mythBuster
            ))
        }
        if month == 11 {
            list.append(SeasonalMoment(
                id: "property-tax",
                title: "Property tax bills and the November discount",
                detail: "Florida tax bills arrive in November and paying early earns the biggest discount. A quick reminder gets shared.",
                icon: "dollarsign.circle.fill",
                hook: "\(city.county) County homeowners: your tax bill is here. Pay in November and save.",
                category: .mythBuster
            ))
            list.append(SeasonalMoment(
                id: "hurricane-end",
                title: "Hurricane season ends November 30",
                detail: "A good time to talk about roof age, insurance renewals and wind mitigation reports.",
                icon: "checkmark.shield.fill",
                hook: "Hurricane season is over. Here is what to check on your home now.",
                category: .mythBuster
            ))
        }
        if city.has(.boating) && month == 12 {
            list.append(SeasonalMoment(
                id: "boat-parade",
                title: "Holiday boat parades",
                detail: "Film the lights on the water and talk about waterfront living.",
                icon: "sailboat.fill",
                hook: "This is what December looks like on the water in \(city.name).",
                category: .neighborhood
            ))
        }
        if month == 12 || month == 1 {
            list.append(SeasonalMoment(
                id: "year-review",
                title: month == 12 ? "Your year in review" : "What to expect this year",
                detail: "Recap the \(city.name) market in 3 numbers and say what you expect next.",
                icon: "chart.line.uptrend.xyaxis",
                hook: month == 12 ? "\(city.name) real estate this year in 30 seconds." : "Here is what I expect for \(city.name) real estate this year.",
                category: .marketUpdate
            ))
        }

        var seen = Set<String>()
        return list.filter { seen.insert($0.id).inserted }
    }

    /// Reads "in late January", "in March", "late winter", "each winter" from a highlight.
    static func months(in text: String) -> Set<Int> {
        let lower = text.lowercased()
        var result = Set<Int>()
        for (index, name) in monthNames.enumerated() where lower.contains(name) {
            result.insert(index + 1)
        }
        if lower.contains("late winter") { result.formUnion([2, 3]) }
        if lower.contains("each winter") || lower.contains("every winter") { result.formUnion([12, 1, 2]) }
        return result
    }
}

struct LocalIdeaEngine: IdeaEngine {
    var calendar = Calendar.current

    func generateIdeas(for profile: AgentProfile) async throws -> [Idea] {
        ideas(for: profile, count: 10, seed: UInt64.random(in: 1...UInt64.max))
    }

    /// Deterministic for a given seed, so "idea of the day" stays put all day.
    func ideas(for profile: AgentProfile, count: Int, seed: UInt64, date: Date = Date()) -> [Idea] {
        let month = calendar.component(.month, from: date)
        let home = FloridaMarkets.city(profile.cityID) ?? FloridaMarkets.fallback
        let areas = [home] + profile.serviceAreaIDs.compactMap { FloridaMarkets.city($0) }
        var rng = SeededGenerator(seed: seed)

        var scored: [(Double, Idea)] = []
        for (areaIndex, city) in areas.enumerated() {
            for template in Self.templates where template.fits(city: city, month: month) {
                var score = Double.random(in: 0...1.5, using: &rng)
                if !template.anyOf.isEmpty { score += 2 }
                if !template.months.isEmpty { score += 2.5 }
                if template.niches.contains(profile.niche) { score += 3 }
                if !template.goals.isDisjoint(with: profile.goals) { score += 1.5 }
                if areaIndex > 0 { score -= 1 } // home city first
                scored.append((score, template.make(for: city, rng: &rng)))
            }
            for moment in FloridaCalendar.moments(month: month, city: city).prefix(2) {
                scored.append((4 + Double.random(in: 0...1, using: &rng) - Double(areaIndex), Self.idea(from: moment, city: city)))
            }
        }

        // Highest score first, no repeated titles, and mix the categories.
        var picked: [Idea] = []
        var titles = Set<String>()
        var perCategory: [IdeaCategory: Int] = [:]
        for (_, idea) in scored.sorted(by: { $0.0 > $1.0 }) where picked.count < count {
            guard titles.insert(idea.title).inserted else { continue }
            if perCategory[idea.category, default: 0] >= 3 { continue }
            perCategory[idea.category, default: 0] += 1
            picked.append(idea)
        }
        return picked
    }

    func ideas(for city: FloridaCity, profile: AgentProfile, count: Int, seed: UInt64) -> [Idea] {
        var local = profile
        local.cityID = city.id
        local.serviceAreaIDs = []
        return ideas(for: local, count: count, seed: seed)
    }

    static func idea(from moment: SeasonalMoment, city: FloridaCity) -> Idea {
        Idea(
            title: moment.title,
            hook: moment.hook,
            category: moment.category,
            shots: [
                "Open on you, close and direct to camera, saying the hook",
                "B-roll of \(city.name) that shows the moment",
                "One key fact on screen, big and simple",
                "Close on you with the comment keyword"
            ],
            script: "\(moment.hook) \(moment.detail) Want my full guide? Comment \(city.name.keywordStem) and I will send it to you.",
            targetSeconds: 35,
            whyItWorks: "Timely local topics get searched and shared right now, and they show you know \(city.name).",
            cityName: city.name
        )
    }

    /// A neighborhood spotlight for a specific street or area.
    static func neighborhoodIdea(_ hood: String, city: FloridaCity) -> Idea {
        Idea(
            title: "Neighborhood spotlight: \(hood)",
            hook: "If you move to \(hood), this is your Saturday.",
            category: .neighborhood,
            shots: [
                "Walking shot down a main street in \(hood)",
                "Your favorite coffee or lunch spot, slow motion detail",
                "You at a table: the 3 things you love about \(hood)",
                "Quick cuts of homes for sale nearby",
                "End with the keyword on screen"
            ],
            script: "If you move to \(hood) in \(city.name), this is your Saturday. Start with coffee at my favorite spot, walk the streets locals love, and end the day on a patio. Homes here are in demand, and I know which streets hold value. Want my list? Comment \(hood.keywordStem).",
            targetSeconds: 40,
            whyItWorks: "Lifestyle content reaches buyers months before they search listings, and a named neighborhood shows real local knowledge.",
            cityName: city.name
        )
    }
}

extension IdeaTemplate {
    func fits(city: FloridaCity, month: Int) -> Bool {
        (anyOf.isEmpty || !anyOf.isDisjoint(with: city.traits)) && (months.isEmpty || months.contains(month))
    }

    func make(for city: FloridaCity, rng: inout SeededGenerator) -> Idea {
        let hood = city.neighborhoods.randomElement(using: &rng) ?? "downtown \(city.name)"
        let highlight = city.highlights.randomElement(using: &rng) ?? "life in \(city.name)"
        func fill(_ text: String) -> String {
            text.replacingOccurrences(of: "{city}", with: city.name)
                .replacingOccurrences(of: "{county}", with: city.county)
                .replacingOccurrences(of: "{region}", with: city.region.title)
                .replacingOccurrences(of: "{hood}", with: hood)
                .replacingOccurrences(of: "{highlight}", with: highlight)
                .replacingOccurrences(of: "{KEY}", with: keyword)
        }
        return Idea(
            title: fill(title),
            hook: fill(hook),
            category: category,
            shots: shots.map(fill),
            script: fill(script),
            targetSeconds: seconds,
            whyItWorks: fill(why),
            cityName: city.name
        )
    }
}

/// Small fast random generator so a seed gives the same ideas every time.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

extension String {
    /// "Seminole Heights" becomes "SEMINOLE" for a comment keyword.
    var keywordStem: String {
        let first = split(separator: " ").first { $0.count > 2 && $0.lowercased() != "the" } ?? Substring(self)
        return first.filter { $0.isLetter }.uppercased()
    }
}

// MARK: - Templates

extension LocalIdeaEngine {
    static let templates: [IdeaTemplate] = [
        // Every city
        IdeaTemplate(
            key: "moving-to", category: .neighborhood, niches: ["Relocation", "First time buyers"], goals: [.relocation, .moreBuyers],
            title: "Moving to {city}? Watch this first",
            hook: "Thinking about moving to {city}? Here are 3 things nobody tells you.",
            shots: ["You on a recognizable street in {city}, phone at eye level", "B-roll: a local spot people love", "B-roll: a typical neighborhood street", "Close on you with the keyword on screen"],
            script: "Thinking about moving to {city}? Here are three things nobody tells you. One: where you live in {county} County changes your commute more than the miles do. Two: insurance and HOA fees matter as much as the price. Three: the best homes go fast, so get your lender letter first. Want my free {city} relocation guide? Comment {KEY}.",
            seconds: 40, why: "Relocation searches are huge in Florida. A clear list with a free guide turns out of state viewers into leads.", keyword: "MOVE"
        ),
        IdeaTemplate(
            key: "market-30", category: .marketUpdate, niches: ["Residential", "Investors"], goals: [.personalBrand, .moreListings],
            title: "{city} market in 30 seconds",
            hook: "Here is what happened in the {city} market this month.",
            shots: ["Tight shot, walking toward camera", "Screen with 3 numbers: median price, days on market, new listings", "Close on you: what it means for buyers and sellers"],
            script: "Here is what happened in the {city} market this month. Median price, days on market and new listings, in plain English. Sellers, here is how to price it right. Buyers, here is where you have room to negotiate. Follow for the {city} update every month.",
            seconds: 30, why: "A monthly series builds a habit and makes you the name people connect with {city} real estate.", keyword: "MARKET"
        ),
        IdeaTemplate(
            key: "budget-tour", category: .listingTour, niches: ["First time buyers", "Residential"], goals: [.moreBuyers],
            title: "What your budget buys in {city}",
            hook: "This is what three different budgets buy you in {city} right now.",
            shots: ["Front of home 1 with the price on screen", "Best room of home 1", "Front of home 2 with price", "Best feature of home 2", "Home 3 reveal, then you on camera"],
            script: "This is what three different budgets buy you in {city} right now. Home one, the starter. Home two, more space and a better location. Home three, the one everybody wants. Which one would you pick? Tell me in the comments, and comment {KEY} for the full list.",
            seconds: 45, why: "Price comparison videos get comments and saves because everyone has an opinion.", keyword: "LIST"
        ),
        IdeaTemplate(
            key: "local-business", category: .neighborhood, goals: [.personalBrand],
            title: "Local business spotlight in {hood}",
            hook: "This is my favorite spot in {hood}, and here is why.",
            shots: ["Walk in with the owner, both on camera", "Detail shots of the product being made", "Owner shares one fun fact", "You both say the name together at the end"],
            script: "This is my favorite spot in {hood}, and here is why. Meet the owner, who has been part of {city} for years. Try this, it is the best in town. Supporting local is what makes {city} home. Tag a friend you would bring here.",
            seconds: 40, why: "Collabs get shared by the business too, which puts you in front of their followers.", keyword: "LOCAL"
        ),
        IdeaTemplate(
            key: "day-in-life", category: .dayInLife, goals: [.personalBrand, .recruit],
            title: "A day in the life of a {city} agent",
            hook: "Come with me for a real day selling homes in {city}.",
            shots: ["Morning coffee and your calendar", "Driving clip, phone mounted", "Showing or listing appointment, with permission", "Quick office or team moment", "Selfie wrap up: best part of the day"],
            script: "Come with me for a real day selling homes in {city}. Coffee, calls, two showings in {hood}, a listing appointment and a celebration with my team. This is why I love this job.",
            seconds: 50, why: "Behind the scenes content builds trust and shows you are busy, which signals success.", keyword: "DAY"
        ),
        IdeaTemplate(
            key: "open-house", category: .openHouse, niches: ["Residential", "Luxury"], goals: [.moreBuyers, .moreListings],
            title: "Open house this weekend in {hood}",
            hook: "You are invited. Here is a sneak peek of this weekend's open house in {hood}.",
            shots: ["You at the front door: 'You are invited'", "3 best rooms, slow walk", "One detail close up", "Address and time on screen"],
            script: "You are invited. Here is a sneak peek of this weekend's open house in {hood}. Three reasons to stop by: the kitchen, the backyard and the location. Saturday and Sunday. Comment {KEY} and I will send you the details.",
            seconds: 30, why: "A sneak peek drives foot traffic and the keyword captures buyers who cannot make it.", keyword: "OPEN"
        ),
        IdeaTemplate(
            key: "client-story", category: .clientStory, goals: [.moreListings, .moreBuyers],
            title: "Why my clients chose {city}",
            hook: "They moved across the country and picked {city}. Here is why.",
            shots: ["Clients in front of their home, with permission", "Them sharing the moment they knew", "B-roll of their favorite local spot", "Keys or a hug at the end"],
            script: "They moved across the country and picked {city}. They wanted space, sunshine and a real neighborhood, and they found it in {hood}. Here is what they told me after move in day. If you are thinking about {city}, comment {KEY} and I will help you find yours.",
            seconds: 45, why: "Real client stories are proof. Viewers picture themselves in the story.", keyword: "HOME"
        ),
        IdeaTemplate(
            key: "county-towns", category: .neighborhood, niches: ["Relocation", "Residential"], goals: [.relocation],
            title: "{county} County: 3 places to consider",
            hook: "If you are moving to {county} County, look at these 3 places first.",
            shots: ["Map on screen with 3 pins", "B-roll of place 1", "B-roll of place 2", "B-roll of place 3", "You: which one fits you"],
            script: "If you are moving to {county} County, look at these three places first. One for space and value, one for walkability, and one for a shorter commute. Every one of them fits a different life. Comment {KEY} and I will send you the pros and cons of each.",
            seconds: 45, why: "Comparing places answers the first question every relocating buyer asks.", keyword: "COUNTY"
        ),
        IdeaTemplate(
            key: "flood-zone", category: .mythBuster, anyOf: [.coastalCounty, .boating, .lakes],
            title: "Check the flood zone before you buy in {city}",
            hook: "Before you buy in {city}, check this one thing. It changes your insurance more than the price.",
            shots: ["You at the edge of the water or a canal", "Screen recording of a flood zone map", "Text on screen: X, AE, VE", "Close on you with the keyword"],
            script: "Before you buy in {city}, check this one thing. The flood zone. It changes your insurance more than the price does. Zones like X, AE and VE mean very different costs. Ask for the elevation certificate and get an insurance quote before you write the offer. Want my checklist? Comment {KEY}.",
            seconds: 40, why: "Useful warnings get saved and shared, and they make you the agent who protects buyers.", keyword: "FLOOD"
        ),
        IdeaTemplate(
            key: "roof-insurance", category: .mythBuster, niches: ["First time buyers", "Residential"], goals: [.moreBuyers],
            title: "Why roof age matters so much in Florida",
            hook: "In Florida, the age of the roof can make or break your home purchase.",
            shots: ["Wide shot of a home with you in front", "Close up of shingles or tile", "Text on screen: roof age, wind mitigation, 4 point inspection", "You with the takeaway"],
            script: "In Florida, the age of the roof can make or break your purchase. Insurance companies look closely at roof age and condition. Ask for the four point inspection and the wind mitigation report early. They can save you a lot on insurance. Questions? Comment {KEY}.",
            seconds: 35, why: "Florida specific advice shows expertise that national agents and websites cannot match.", keyword: "ROOF"
        ),
        IdeaTemplate(
            key: "no-income-tax", category: .mythBuster, niches: ["Relocation", "Investors", "Luxury"], goals: [.relocation],
            title: "Moving to {city} from up north: the money side",
            hook: "Florida has no state income tax. Here is what that means if you move to {city}.",
            shots: ["You in sunglasses outside, casual", "Text on screen: no state income tax", "Text on screen: homestead exemption", "You with the keyword"],
            script: "Florida has no state income tax. If you move to {city} from up north, that can be real money every year. Add the homestead exemption on your primary home and the math gets even better. Talk to your tax pro about your situation, and comment {KEY} for my relocation guide.",
            seconds: 35, why: "Money questions are the top worry for relocating buyers. Simple answers earn trust.", keyword: "MOVE"
        ),
        IdeaTemplate(
            key: "highlight", category: .neighborhood, goals: [.personalBrand, .relocation],
            title: "{highlight}: living near it in {city}",
            hook: "Everyone knows {city} for this. Here is what it is like to live near it.",
            shots: ["Establishing shot of the place", "You walking in, talking to camera", "Locals enjoying it", "Homes close by", "Close on you with the keyword"],
            script: "Everyone knows {city} for {highlight}. But what is it like to actually live near it? Here is the good, the busy and the best streets close by. If you want to live minutes away, comment {KEY} and I will send you the list.",
            seconds: 40, why: "People search for the famous places first. Connecting them to homes captures that interest.", keyword: "NEAR"
        ),

        // Beaches and water
        IdeaTemplate(
            key: "beach-life", category: .neighborhood, anyOf: [.beach], niches: ["Waterfront homes", "Luxury", "Condos"],
            title: "Beach town living in {city}: pros and cons",
            hook: "Living a few minutes from the beach in {city} sounds perfect. Here is the honest truth.",
            shots: ["Sunrise on the beach, wide", "You walking the sand, talking", "Beach parking or traffic moment", "Homes near the beach", "You at sunset with the keyword"],
            script: "Living a few minutes from the beach in {city} sounds perfect. Here is the honest truth. The pros: sunsets, walks and a relaxed pace. The cons: tourist season traffic, insurance and parking. Worth it? For most of my clients, absolutely. Comment {KEY} for beach homes in your budget.",
            seconds: 45, why: "Honest pros and cons beat hype and get people to comment their own opinion.", keyword: "BEACH"
        ),
        IdeaTemplate(
            key: "boater", category: .listingTour, anyOf: [.boating], niches: ["Waterfront homes", "Luxury"],
            title: "Boater's checklist for a {city} waterfront home",
            hook: "Buying on the water in {city}? Check these 4 things before you fall in love.",
            shots: ["Open at the dock, phone at chest height", "Seawall close up", "Bridge or canal route on a map", "Boat lift or dock detail", "You pointing at the water"],
            script: "Buying on the water in {city}? Check these four things before you fall in love. One, the seawall age and condition. Two, how long the ride is to open water and whether there are bridges. Three, water depth at low tide. Four, dock and lift permits. Want my full waterfront checklist? Comment {KEY}.",
            seconds: 45, why: "Number hooks with a warning hold attention, and waterfront buyers save checklists.", keyword: "DOCK"
        ),
        IdeaTemplate(
            key: "lakefront", category: .listingTour, anyOf: [.lakes], niches: ["Waterfront homes"],
            title: "Lakefront living in {city}",
            hook: "You do not need the ocean to live on the water in {city}.",
            shots: ["Lake at golden hour", "You on a dock talking", "Kayak or boat moment", "Homes along the shore"],
            script: "You do not need the ocean to live on the water in {city}. Central Florida lakes give you sunsets, boating and often more home for the money. Ask if the lake is ski friendly, check the water level history and the HOA rules for docks. Comment {KEY} for lake homes near you.",
            seconds: 40, why: "Lake homes are a value story many buyers have not considered.", keyword: "LAKE"
        ),
        IdeaTemplate(
            key: "condo-rules", category: .mythBuster, anyOf: [.condos], niches: ["Condos", "Investors"],
            title: "Condo buyers in {city}: ask about this first",
            hook: "Buying a condo in {city}? Ask these questions before you sign anything.",
            shots: ["Building exterior, slow tilt up", "You in a lobby or on a balcony", "Text on screen: inspections, reserves, assessments", "Close on you"],
            script: "Buying a condo in {city}? Ask these questions before you sign anything. Florida's condo safety rules now require building inspections and funded reserves for many buildings. Ask for the latest inspection report, the reserve study and any planned special assessments. I read these with every client. Comment {KEY} for my condo checklist.",
            seconds: 45, why: "Condo buyers are nervous about new rules. Clear guidance makes you the go to condo agent.", keyword: "CONDO"
        ),

        // Lifestyle markets
        IdeaTemplate(
            key: "golf", category: .listingTour, anyOf: [.golf], niches: ["Luxury", "Residential"],
            title: "Golf community tour in {city}",
            hook: "This is what golf course living in {city} really looks like.",
            shots: ["Fairway view from a back porch", "Clubhouse arrival", "Golf cart ride, phone mounted", "Home interior highlights", "You on the green with the keyword"],
            script: "This is what golf course living in {city} really looks like. Morning tee times, the clubhouse, and this view from the back porch. Ask about membership types and fees, because they vary a lot. Comment {KEY} and I will send you golf homes in {city}.",
            seconds: 45, why: "Lifestyle tours sell the dream and the membership tip shows you know the details.", keyword: "GOLF"
        ),
        IdeaTemplate(
            key: "retirement", category: .neighborhood, anyOf: [.retirement], niches: ["Residential", "Relocation"], goals: [.relocation],
            title: "55+ living in {city}: what to know",
            hook: "Thinking about a 55 plus community in {city}? Here is what nobody explains.",
            shots: ["Community entrance or amenity center", "Pickleball or pool activity", "You talking with the amenities behind you", "Text on screen: HOA fees, age rules, amenities"],
            script: "Thinking about a 55 plus community in {city}? Here is what nobody explains. HOA fees cover very different things from one community to the next. Age rules can affect who can live with you. And the best amenities are not always in the newest places. Comment {KEY} for my comparison sheet.",
            seconds: 40, why: "Retirees research for months. Helpful content puts you at the top of their list.", keyword: "55PLUS"
        ),
        IdeaTemplate(
            key: "snowbird-buy", category: .marketUpdate, anyOf: [.snowbird], months: [10, 11, 12, 1, 2, 3, 4], niches: ["Condos", "Investors", "Luxury"],
            title: "Snowbirds: rent or buy in {city}?",
            hook: "If you rent in {city} every winter, you need to see this math.",
            shots: ["You outdoors in the sun", "Text on screen: rent per season vs own", "B-roll of seasonal condos or villas", "Close on you with the keyword"],
            script: "If you rent in {city} every winter, you need to see this math. A few seasons of rent can add up to a real down payment. Owning means your place is ready when you land, and you can rent it out when you are home. Comment {KEY} and I will run the numbers for you.",
            seconds: 35, why: "Seasonal residents are already here and already paying. A simple math hook converts them.", keyword: "WINTER"
        ),
        IdeaTemplate(
            key: "college", category: .mythBuster, anyOf: [.college], niches: ["Investors"],
            title: "Parents: buy instead of rent near campus in {city}",
            hook: "Parents, before you pay another year of rent in {city}, watch this.",
            shots: ["You near campus, students in the background", "Text on screen: rent for 4 years", "Small condo or house interior", "You with the keyword"],
            script: "Parents, before you pay another year of rent in {city}, watch this. Buying a small place near campus can turn rent into equity, and roommates can help cover the payment. After graduation, keep it as a rental or sell. Talk to your lender and comment {KEY} for homes near campus.",
            seconds: 40, why: "Parents of students are motivated buyers that few agents talk to directly.", keyword: "CAMPUS"
        ),
        IdeaTemplate(
            key: "military", category: .mythBuster, anyOf: [.military], niches: ["First time buyers", "Relocation"], goals: [.moreBuyers, .relocation],
            title: "PCS to {city}? VA loan basics",
            hook: "Got orders to {city}? Here is how to use your VA loan the smart way.",
            shots: ["You outside with a flag or base area in the background", "Text on screen: no down payment for eligible buyers", "Text on screen: plan your PCS timeline", "You with the keyword"],
            script: "Got orders to {city}? Here is how to use your VA loan the smart way. Eligible buyers can buy with no down payment. Start with a VA lender early, plan around your report date, and think about whether you will rent it out at your next move. Thank you for your service. Comment {KEY} for my PCS guide.",
            seconds: 40, why: "Military families move often and refer each other. Helpful content earns a loyal network.", keyword: "PCS"
        ),
        IdeaTemplate(
            key: "theme-parks", category: .neighborhood, anyOf: [.themeParks, .shortTermRental], niches: ["Investors", "Relocation"],
            title: "Living near the theme parks in {city}",
            hook: "What is it actually like to live 20 minutes from the theme parks?",
            shots: ["Drive toward the parks, phone mounted", "Neighborhood pool or park", "You on camera: pros and cons", "Text on screen: traffic, passes, rentals"],
            script: "What is it actually like to live near the theme parks in {city}? Annual passes, fireworks from your backyard and lots of jobs. But know the traffic patterns, and check the rules before you plan to rent your home short term. Comment {KEY} for neighborhoods locals love.",
            seconds: 40, why: "Theme park living is a bucket list idea for many viewers, so this travels far.", keyword: "PARKS"
        ),
        IdeaTemplate(
            key: "str", category: .marketUpdate, anyOf: [.shortTermRental], niches: ["Investors"],
            title: "Vacation rental numbers in {city}",
            hook: "Thinking about a vacation rental in {city}? Look at these 3 numbers first.",
            shots: ["Pool or beach at a rental home", "Text on screen: occupancy, nightly rate, costs", "You inside the rental", "You with the keyword"],
            script: "Thinking about a vacation rental in {city}? Look at these three numbers first. Occupancy, average nightly rate and real costs, including cleaning, management and insurance. Also check local and HOA rules, because they decide everything. Comment {KEY} and I will send you a sample breakdown.",
            seconds: 40, why: "Investors want numbers. A simple framework gets saves and DMs.", keyword: "RENTAL"
        ),
        IdeaTemplate(
            key: "historic", category: .listingTour, anyOf: [.historic],
            title: "Buying a historic home in {city}",
            hook: "Historic homes in {city} have charm. They also have rules.",
            shots: ["Front porch detail", "Original wood floors or windows", "You on the porch talking", "Text on screen: historic district rules"],
            script: "Historic homes in {city} have charm, and they also have rules. If the home is in a historic district, changes to the outside may need approval. Plan for older systems and get a great inspector. The reward is a home with character you cannot build today. Comment {KEY} for historic homes for sale.",
            seconds: 40, why: "Charm plus a practical warning makes you look like the expert in old homes.", keyword: "HISTORIC"
        ),
        IdeaTemplate(
            key: "luxury", category: .listingTour, anyOf: [.luxury], niches: ["Luxury", "Waterfront homes"], goals: [.moreListings],
            title: "Inside a {city} luxury home: 3 details",
            hook: "These 3 details are why this {city} home is in a different league.",
            shots: ["Slow push in through the front door", "Detail 1 close up", "Detail 2 with natural light", "Detail 3: the view", "You on the terrace"],
            script: "These three details are why this {city} home is in a different league. The arrival. The kitchen built for entertaining. And this view. Luxury is in the details, and so is selling it right. Thinking of selling a home like this? Comment {KEY}.",
            seconds: 40, why: "Detail driven tours feel premium and attract both buyers and future luxury sellers.", keyword: "LUXE"
        ),
        IdeaTemplate(
            key: "new-construction", category: .mythBuster, anyOf: [.growth], niches: ["New construction", "First time buyers", "Relocation"], goals: [.moreBuyers],
            title: "New construction in {city}: bring your own agent",
            hook: "Buying new construction in {city}? Do not walk into the model home alone.",
            shots: ["Model home exterior", "You walking through the model", "Text on screen: incentives, upgrades, lot", "You with the keyword"],
            script: "Buying new construction in {city}? Do not walk into the model home alone. The sales rep works for the builder. Your agent works for you, usually at no extra cost, and helps with incentives, upgrades and picking the right lot. Comment {KEY} for the newest communities in {city}.",
            seconds: 35, why: "Many buyers do not know they can bring an agent. This hook is a lead magnet.", keyword: "NEW"
        ),
        IdeaTemplate(
            key: "builder-vs-resale", category: .marketUpdate, anyOf: [.growth], niches: ["New construction", "Residential"],
            title: "New build vs resale in {city}",
            hook: "New build or resale in {city}? Here is how to choose.",
            shots: ["Split screen: new build and resale exterior", "Yard size comparison", "Text on screen: price, fees, wait time", "You with your verdict"],
            script: "New build or resale in {city}? Here is how to choose. New builds give you warranties and builder incentives but often smaller lots and longer waits. Resales give you mature trees, bigger yards and room to negotiate. Which would you pick? Comment {KEY} and I will send you options for both.",
            seconds: 40, why: "Comparison videos invite debate in the comments, which boosts reach.", keyword: "COMPARE"
        ),
        IdeaTemplate(
            key: "equestrian", category: .listingTour, anyOf: [.equestrian], niches: ["Luxury"],
            title: "Horse property in {city}: what to check",
            hook: "Shopping for horse property in {city}? Check these 4 things.",
            shots: ["Pasture at sunrise", "Barn and stalls", "Fencing and water close ups", "You at the gate"],
            script: "Shopping for horse property in {city}? Check these four things. Zoning, so you know how many horses you can keep. Soil and drainage. Barn condition. And how close you are to the trails and show grounds. Comment {KEY} for farms on the market.",
            seconds: 40, why: "A niche checklist attracts a passionate audience that few agents speak to.", keyword: "FARM"
        ),
        IdeaTemplate(
            key: "launch", category: .neighborhood, anyOf: [.space],
            title: "Launch day in {city}",
            hook: "This is what a rocket launch looks like from {city}.",
            shots: ["Crowd waiting at sunset", "The launch, on a tripod", "Reactions", "You with the keyword"],
            script: "This is what a rocket launch looks like from {city}. Neighbors bring chairs, kids count down, and the sky lights up. The Space Coast is growing fast, with aerospace jobs bringing new buyers every month. Comment {KEY} for homes with launch views.",
            seconds: 30, why: "Launch videos are shareable on their own, and you tie them to homes.", keyword: "LAUNCH"
        ),
        IdeaTemplate(
            key: "downtown-vs-suburbs", category: .marketUpdate, anyOf: [.urban],
            title: "Downtown {city} vs the suburbs",
            hook: "Downtown condo or a house in the suburbs? Here is the real difference in {city}.",
            shots: ["Downtown skyline shot", "Suburban street", "Text on screen: price per square foot, commute, lifestyle", "You with your take"],
            script: "Downtown condo or a house in the suburbs? Here is the real difference in {city}. Downtown gives you walkability and short commutes. The suburbs give you space and yards. The right answer depends on how you live day to day. Comment {KEY} and tell me which one you are.",
            seconds: 40, why: "Lifestyle choice videos get people to comment and identify with one side.", keyword: "CHOOSE"
        ),
        IdeaTemplate(
            key: "small-town", category: .neighborhood, anyOf: [.smallTown], goals: [.relocation],
            title: "Why people are moving to {city}",
            hook: "{city} is one of the most underrated places in {county} County. Here is why.",
            shots: ["Main street or town center", "A local landmark", "Quiet neighborhood street", "You with the keyword"],
            script: "{city} is one of the most underrated places in {county} County. You get a small town feel, room to breathe and you are still close to everything in {region}. It is the kind of place people visit once and then move to. Comment {KEY} and I will show you what is for sale.",
            seconds: 35, why: "Underrated town hooks get local pride shares and curiosity clicks.", keyword: "TOWN"
        ),

        // Seasonal
        IdeaTemplate(
            key: "homestead", category: .mythBuster, months: [1, 2], niches: ["First time buyers", "Residential"],
            title: "{county} County homeowners: file your homestead",
            hook: "Bought a home in {county} County last year? Do this before March 1.",
            shots: ["You at your kitchen table with a laptop", "Screen: the county property appraiser website", "Text on screen: deadline March 1", "You with the keyword"],
            script: "Bought a home in {county} County last year? Do this before March 1. File your homestead exemption with the property appraiser. It lowers your taxable value and caps how fast it can rise. It takes about ten minutes. Comment {KEY} and I will send you the link and a how to.",
            seconds: 30, why: "A deadline makes it urgent, and helping past clients keeps you top of mind.", keyword: "HOMESTEAD"
        ),
        IdeaTemplate(
            key: "hurricane-checklist", category: .mythBuster, months: [5, 6, 7, 8, 9],
            title: "Hurricane ready home checklist",
            hook: "Here is the 60 second hurricane checklist every {city} homeowner needs.",
            shots: ["Shutters or impact windows", "Photos of your home for insurance", "Generator safety tip", "Documents in a waterproof bag", "You with the keyword"],
            script: "Here is the sixty second hurricane checklist every {city} homeowner needs. One: know your shutters or impact windows. Two: take photos and video of your home for insurance. Three: keep documents in a waterproof bag. Four: never run a generator indoors or in the garage. Comment {KEY} for the printable version.",
            seconds: 40, why: "Safety content is shared in neighborhood groups, which spreads your name.", keyword: "READY"
        ),
        IdeaTemplate(
            key: "summer-buy", category: .marketUpdate, months: [6, 7, 8],
            title: "Why summer is a smart time to buy in {city}",
            hook: "Everyone says spring is the time to buy. In {city}, summer might be better.",
            shots: ["You in the heat, a little sweaty, smiling", "Pool or splash pad B-roll", "Text on screen: fewer buyers, more negotiating", "You with the keyword"],
            script: "Everyone says spring is the time to buy. In {city}, summer might be better. It is hot, a lot of buyers wait, and that means less competition and more room to negotiate. Comment {KEY} and I will send you homes that just dropped in price.",
            seconds: 30, why: "Going against common advice is a strong hook, and price drops are a great lead magnet.", keyword: "SUMMER"
        ),
        IdeaTemplate(
            key: "property-tax", category: .mythBuster, months: [11],
            title: "Pay your {county} County taxes in November",
            hook: "{county} County homeowners, your property tax bill is here. Pay in November and save.",
            shots: ["You holding an envelope", "Screen: tax collector website", "Text on screen: biggest discount in November", "You with the keyword"],
            script: "{county} County homeowners, your property tax bill is here. In Florida, paying early earns a discount, and November gives you the biggest one. Set a reminder and save a little money this holiday season. Comment {KEY} if you want help understanding your bill.",
            seconds: 25, why: "Simple money tips get shared, and they keep you in touch with past clients.", keyword: "TAX"
        ),
        IdeaTemplate(
            key: "holiday-lights", category: .neighborhood, months: [12],
            title: "Best holiday lights in {city}",
            hook: "These are the best holiday lights in {city} this year.",
            shots: ["Night drive, phone mounted", "3 houses or streets with lights", "Family reactions, with permission", "You with a hot drink and the keyword"],
            script: "These are the best holiday lights in {city} this year. Save this for your next family night. Which street did I miss? Tell me in the comments, and comment {KEY} for the full map.",
            seconds: 30, why: "Seasonal local guides get saved and shared by families.", keyword: "LIGHTS"
        ),
        IdeaTemplate(
            key: "schools", category: .mythBuster, months: [7, 8], niches: ["First time buyers", "Relocation"],
            title: "How to check school assignments before you buy in {city}",
            hook: "Moving to {city} with kids? Check this before you make an offer.",
            shots: ["You at a kitchen table with a laptop", "Screen: the school district's address lookup", "Text on screen: zoned school vs choice options", "You with the keyword"],
            script: "Moving to {city} with kids? Check this before you make an offer. Every address has a zoned school, and you can look it up on the {county} County school district website. Ask about choice and magnet options too. Comment {KEY} and I will send you the link.",
            seconds: 30, why: "Practical how to content helps families and keeps you within fair housing rules by pointing to official sources.", keyword: "SCHOOL"
        )
    ]
}
