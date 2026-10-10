import SwiftUI

/// Every tool in the app, grouped the way agents think about their work.
enum ToolCatalog {
    struct Tool: Identifiable {
        var id: String { title }
        var title: String
        var keywords: String
        var icon: String
        var route: Route
        var group: Group
    }

    enum Group: String, CaseIterable, Identifiable {
        case create, listings, clients, business, brand, grow
        var id: String { rawValue }
        var title: String {
            switch self {
            case .create: return "Make content"
            case .listings: return "Listings and deals"
            case .clients: return "Clients and leads"
            case .business: return "Run my business"
            case .brand: return "Brand and market"
            case .grow: return "Learn and grow"
            }
        }
    }

    static let all: [Tool] = [
        Tool(title: "Script writer", keywords: "script write hook", icon: "text.quote", route: .scriptWriter, group: .create),
        Tool(title: "What to say when", keywords: "objections scripts commission buyer agreement rates insurance", icon: "quote.bubble.fill", route: .objections, group: .create),
        Tool(title: "Hook library", keywords: "hooks first line", icon: "bolt.fill", route: .hooks, group: .create),
        Tool(title: "Teleprompter", keywords: "own script read", icon: "text.viewfinder", route: .teleprompter, group: .create),
        Tool(title: "Caption writer", keywords: "caption hashtags", icon: "text.bubble.fill", route: .captionWriter, group: .create),
        Tool(title: "Plan my week", keywords: "calendar schedule plan", icon: "calendar.badge.plus", route: .weekPlan, group: .create),
        Tool(title: "Content calendar", keywords: "scheduled posts", icon: "calendar", route: .calendar, group: .create),
        Tool(title: "Photo reel", keywords: "video slideshow photos listing reel tiktok", icon: "film.stack.fill", route: .photoReel, group: .create),
        Tool(title: "Poster maker", keywords: "just listed just sold coming soon open house graphic", icon: "rectangle.portrait.on.rectangle.portrait.fill", route: .posterMaker, group: .create),
        Tool(title: "Holiday posts", keywords: "greeting thanksgiving christmas", icon: "gift.fill", route: .greetings, group: .create),
        Tool(title: "Market update graphic", keywords: "stats numbers median price", icon: "chart.bar.xaxis", route: .marketUpdate, group: .create),
        Tool(title: "My listings", keywords: "listing open house description", icon: "house.and.flag.fill", route: .listings, group: .listings),
        Tool(title: "Book a pro shoot", keywords: "booking deposit listing package", icon: "camera.fill", route: .bookings, group: .listings),
        Tool(title: "Find a photographer", keywords: "shooter crew book drone video photos map", icon: "person.crop.rectangle.stack.fill", route: .findShooter, group: .listings),
        Tool(title: "Help me choose a package", keywords: "which package recommend add ons twilight 3d tour", icon: "wand.and.stars", route: .packageAdvisor, group: .listings),
        Tool(title: "Under contract", keywords: "deals pending deadlines inspection closing escrow timeline", icon: "doc.text.fill", route: .deals, group: .listings),
        Tool(title: "Listing presentation", keywords: "pitch seller marketing plan", icon: "doc.richtext.fill", route: .listingPitch, group: .listings),
        Tool(title: "Seller prep checklist", keywords: "prepare home shoot", icon: "checklist", route: .sellerPrep, group: .listings),
        Tool(title: "Home value report", keywords: "cma comps value estimate worth bpo pdf", icon: "chart.line.uptrend.xyaxis", route: .homeValue, group: .listings),
        Tool(title: "Seller net sheet", keywords: "net proceeds closing costs doc stamps title commission", icon: "dollarsign.circle.fill", route: .netSheet, group: .listings),
        Tool(title: "Agent network", keywords: "coming soon off market pocket listings agents buyers inventory national", icon: "point.3.connected.trianglepath.dotted", route: .agentNetwork, group: .listings),
        Tool(title: "Showing tours", keywords: "buyer showings schedule route recap", icon: "car.fill", route: .tours, group: .listings),
        Tool(title: "Buyer cash to close", keywords: "closing costs down payment intangible tax doc stamps", icon: "creditcard.fill", route: .buyerCosts, group: .listings),
        Tool(title: "Payment calculator", keywords: "mortgage monthly payment", icon: "function", route: .paymentCalculator, group: .listings),
        Tool(title: "My team", keywords: "team page roster leaderboard recruit join code round robin", icon: "person.3.fill", route: .team, group: .clients),
        Tool(title: "Recruiting page", keywords: "recruit agents join team hiring", icon: "megaphone.fill", route: .recruit, group: .clients),
        Tool(title: "Leads", keywords: "contacts follow up", icon: "person.badge.plus", route: .leads, group: .clients),
        Tool(title: "Buyer wishlists", keywords: "buyer needs match criteria search alert", icon: "heart.text.square", route: .buyers, group: .clients),
        Tool(title: "Auto DM keywords", keywords: "comment to dm manychat keyword lead capture instagram", icon: "bubble.left.and.text.bubble.right.fill", route: .keywords, group: .clients),
        Tool(title: "Past clients", keywords: "home anniversary sphere repeat value check in", icon: "house.and.flag.fill", route: .pastClients, group: .clients),
        Tool(title: "Trusted pros", keywords: "vendors lender inspector title insurance pool movers", icon: "person.2.badge.gearshape.fill", route: .vendors, group: .clients),
        Tool(title: "Partners", keywords: "book staging cleaning movers junk handyman painting landscaping pressure wash tc transaction coordinator assistant signs gifts services", icon: "hammer.fill", route: .partners, group: .clients),
        Tool(title: "Testimonials", keywords: "reviews client love", icon: "heart.text.square.fill", route: .testimonials, group: .clients),
        Tool(title: "Monthly newsletter", keywords: "email sphere past clients update", icon: "envelope.fill", route: .newsletter, group: .clients),
        Tool(title: "Agent referral network", keywords: "refer client relocation another city fee", icon: "arrow.triangle.branch", route: .referralNetwork, group: .clients),
        Tool(title: "Brand shoot prep", keywords: "brand video story wardrobe locations producer", icon: "person.crop.square.filled.and.at.rectangle", route: .brandShootPrep, group: .brand),
        Tool(title: "Brand kit", keywords: "logo headshot color", icon: "paintpalette.fill", route: .brandKit, group: .brand),
        Tool(title: "Link in bio", keywords: "bio page instagram", icon: "link.circle.fill", route: .linkInBio, group: .brand),
        Tool(title: "My market", keywords: "city neighborhoods local", icon: "mappin.and.ellipse", route: .market, group: .brand),
        Tool(title: "My farm", keywords: "farming neighborhood geographic postcards door knock", icon: "map.fill", route: .farm, group: .brand),
        Tool(title: "Moving to Florida guide", keywords: "relocation out of state buyers homestead pdf", icon: "airplane.arrival", route: .relocationGuide, group: .brand),
        Tool(title: "Insights", keywords: "analytics views stats", icon: "chart.xyaxis.line", route: .insights, group: .brand),
        Tool(title: "My money", keywords: "income gci earnings commission dashboard", icon: "banknote.fill", route: .money, group: .business),
        Tool(title: "Split and cap", keywords: "kw cap royalty company dollar split brokerage", icon: "chart.pie.fill", route: .splitTracker, group: .business),
        Tool(title: "Tax set aside", keywords: "taxes quarterly estimated irs 1099 save", icon: "building.columns.fill", route: .taxes, group: .business),
        Tool(title: "Power hour", keywords: "prospecting calls dials timer streak door knocking", icon: "timer", route: .powerHour, group: .business),
        Tool(title: "Time blocks", keywords: "schedule calendar routine daily focus reminders", icon: "clock.fill", route: .timeBlocks, group: .business),
        Tool(title: "Weekly scorecard", keywords: "4-1-1 411 goals accountability targets week", icon: "checklist.checked", route: .scorecard, group: .business),
        Tool(title: "Business card", keywords: "vcard qr contact digital card share", icon: "person.text.rectangle.fill", route: .businessCard, group: .business),
        Tool(title: "License and CE", keywords: "renewal continuing education dbpr post licensing hours", icon: "checkmark.seal.fill", route: .license, group: .business),
        Tool(title: "Mileage and expenses", keywords: "tax deduction miles receipts accountant csv", icon: "car.fill", route: .expenses, group: .business),
        Tool(title: "Business plan", keywords: "gci goal income closings how many videos", icon: "target", route: .businessPlan, group: .business),
        Tool(title: "New agent launchpad", keywords: "brand new agent first 90 days start career rookie licensed first deal", icon: "airplane.departure", route: .launchpad, group: .grow),
        Tool(title: "Courses", keywords: "learn lessons", icon: "play.rectangle.on.rectangle.fill", route: .courses, group: .grow),
        Tool(title: "Coach", keywords: "tips feedback", icon: "graduationcap.fill", route: .coach, group: .grow),
        Tool(title: "Challenges", keywords: "streak contest", icon: "flag.checkered", route: .challenges, group: .grow),
        Tool(title: "Achievements", keywords: "badges level leaderboard", icon: "trophy.fill", route: .achievements, group: .grow),
        Tool(title: "Invite agents", keywords: "referral credits", icon: "gift.fill", route: .referrals, group: .grow),
        Tool(title: "Join #Cinema Crew", keywords: "photographer apply shooter", icon: "camera.aperture", route: .joinCrew, group: .grow),
        Tool(title: "Help", keywords: "how it works faq support", icon: "questionmark.circle.fill", route: .help, group: .grow)
    ]
}


/// Search everything: tools, ideas, listings, leads, clips and Florida cities.
struct SearchView: View {
    @Environment(CinemaStore.self) private var store
    @State private var query = ""

    typealias Tool = ToolCatalog.Tool
    private let tools = ToolCatalog.all

    private func matches(_ text: String) -> Bool {
        text.localizedCaseInsensitiveContains(query.trimmingCharacters(in: .whitespaces))
    }

    var body: some View {
        List {
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                ForEach(ToolCatalog.Group.allCases) { group in
                    Section(group.title) {
                        ForEach(tools.filter { $0.group == group }) { tool in toolRow(tool) }
                    }
                    .listRowBackground(Theme.surface)
                }
            } else {
                let toolHits = tools.filter { matches($0.title) || matches($0.keywords) }
                let ideaHits = store.ideas.filter { matches($0.title) || matches($0.hook) }.prefix(8)
                let listingHits = store.listings.filter { matches($0.address) }
                let leadHits = store.leads.filter { matches($0.name) || matches($0.message) }
                let clipHits = store.clips.filter { matches($0.title) }
                let cityHits = FloridaMarkets.search(query, limit: 5)

                if !toolHits.isEmpty {
                    Section("Tools") { ForEach(toolHits) { toolRow($0) } }
                        .listRowBackground(Theme.surface)
                }
                if !ideaHits.isEmpty {
                    Section("Ideas") {
                        ForEach(Array(ideaHits)) { idea in
                            NavigationLink(value: Route.idea(idea.id)) {
                                IconRow(icon: idea.category.icon, title: idea.title, subtitle: idea.cityName)
                            }
                        }
                    }
                    .listRowBackground(Theme.surface)
                }
                if !listingHits.isEmpty {
                    Section("Listings") {
                        ForEach(listingHits) { listing in
                            NavigationLink(value: Route.listing(listing.id)) {
                                IconRow(icon: listing.status.icon, title: listing.address, subtitle: "\(listing.status.title) · \(listing.priceLabel)")
                            }
                        }
                    }
                    .listRowBackground(Theme.surface)
                }
                if !leadHits.isEmpty {
                    Section("Leads") {
                        ForEach(leadHits) { lead in
                            NavigationLink(value: Route.lead(lead.id)) {
                                IconRow(icon: "person.fill", title: lead.name, subtitle: lead.status.title)
                            }
                        }
                    }
                    .listRowBackground(Theme.surface)
                }
                if !clipHits.isEmpty {
                    Section("Clips") {
                        ForEach(clipHits) { clip in
                            NavigationLink(value: Route.clip(clip.id)) {
                                IconRow(icon: "film.fill", title: clip.title, subtitle: clip.status.title)
                            }
                        }
                    }
                    .listRowBackground(Theme.surface)
                }
                if !cityHits.isEmpty {
                    Section("Florida cities") {
                        ForEach(cityHits) { city in
                            NavigationLink(value: Route.city(city.id)) {
                                CityRow(city: city)
                            }
                        }
                    }
                    .listRowBackground(Theme.surface)
                }
                if toolHits.isEmpty && ideaHits.isEmpty && listingHits.isEmpty && leadHits.isEmpty && clipHits.isEmpty && cityHits.isEmpty {
                    Text("Nothing matches \"\(query)\".")
                        .foregroundStyle(Theme.textSecondary)
                        .listRowBackground(Theme.surface)
                }
            }
        }
        .cinemaScreen()
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search tools, ideas, listings, leads")
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toolRow(_ tool: Tool) -> some View {
        NavigationLink(value: tool.route) {
            IconRow(icon: tool.icon, title: tool.title)
        }
    }
}
