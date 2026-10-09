import SwiftUI

/// Search everything: tools, ideas, listings, leads, clips and Florida cities.
struct SearchView: View {
    @Environment(CinemaStore.self) private var store
    @State private var query = ""

    struct Tool: Identifiable {
        var id: String { title }
        var title: String
        var keywords: String
        var icon: String
        var route: Route
    }

    private let tools: [Tool] = [
        Tool(title: "Poster maker", keywords: "just listed just sold coming soon open house graphic", icon: "rectangle.portrait.on.rectangle.portrait.fill", route: .posterMaker),
        Tool(title: "Find a photographer", keywords: "shooter crew book drone video photos", icon: "person.crop.rectangle.stack.fill", route: .findShooter),
        Tool(title: "Book a pro shoot", keywords: "booking deposit listing package", icon: "camera.fill", route: .bookings),
        Tool(title: "My listings", keywords: "listing open house description", icon: "house.and.flag.fill", route: .listings),
        Tool(title: "Script writer", keywords: "script write hook", icon: "text.quote", route: .scriptWriter),
        Tool(title: "Hook library", keywords: "hooks first line", icon: "bolt.fill", route: .hooks),
        Tool(title: "Teleprompter", keywords: "own script read", icon: "text.viewfinder", route: .teleprompter),
        Tool(title: "Caption writer", keywords: "caption hashtags", icon: "text.bubble.fill", route: .captionWriter),
        Tool(title: "Market update graphic", keywords: "stats numbers median price", icon: "chart.bar.xaxis", route: .marketUpdate),
        Tool(title: "Testimonials", keywords: "reviews client love", icon: "heart.text.square.fill", route: .testimonials),
        Tool(title: "Holiday posts", keywords: "greeting thanksgiving christmas", icon: "gift.fill", route: .greetings),
        Tool(title: "Plan my week", keywords: "calendar schedule plan", icon: "calendar.badge.plus", route: .weekPlan),
        Tool(title: "Content calendar", keywords: "scheduled posts", icon: "calendar", route: .calendar),
        Tool(title: "Insights", keywords: "analytics views stats", icon: "chart.xyaxis.line", route: .insights),
        Tool(title: "Leads", keywords: "contacts follow up", icon: "person.badge.plus", route: .leads),
        Tool(title: "Payment calculator", keywords: "mortgage monthly payment", icon: "function", route: .paymentCalculator),
        Tool(title: "Listing presentation", keywords: "pitch seller marketing plan", icon: "doc.richtext.fill", route: .listingPitch),
        Tool(title: "Seller net sheet", keywords: "net proceeds closing costs doc stamps title commission", icon: "dollarsign.circle.fill", route: .netSheet),
        Tool(title: "Seller prep checklist", keywords: "prepare home shoot", icon: "checklist", route: .sellerPrep),
        Tool(title: "Brand kit", keywords: "logo headshot color", icon: "paintpalette.fill", route: .brandKit),
        Tool(title: "Link in bio", keywords: "bio page instagram", icon: "link.circle.fill", route: .linkInBio),
        Tool(title: "My market", keywords: "city neighborhoods local", icon: "mappin.and.ellipse", route: .market),
        Tool(title: "Agent referral network", keywords: "refer client relocation another city fee", icon: "arrow.triangle.branch", route: .referralNetwork),
        Tool(title: "Past clients", keywords: "home anniversary sphere repeat value check in", icon: "house.and.flag.fill", route: .pastClients),
        Tool(title: "Trusted pros", keywords: "vendors lender inspector title insurance pool movers", icon: "person.2.badge.gearshape.fill", route: .vendors),
        Tool(title: "Invite agents", keywords: "referral credits", icon: "gift.fill", route: .referrals),
        Tool(title: "Achievements", keywords: "badges level leaderboard", icon: "trophy.fill", route: .achievements),
        Tool(title: "Courses", keywords: "learn lessons", icon: "play.rectangle.on.rectangle.fill", route: .courses),
        Tool(title: "Challenges", keywords: "streak contest", icon: "flag.checkered", route: .challenges),
        Tool(title: "Coach", keywords: "tips feedback", icon: "graduationcap.fill", route: .coach),
        Tool(title: "Join #Cinema Crew", keywords: "photographer apply shooter", icon: "camera.aperture", route: .joinCrew),
        Tool(title: "Help", keywords: "how it works faq support", icon: "questionmark.circle.fill", route: .help)
    ]

    private func matches(_ text: String) -> Bool {
        text.localizedCaseInsensitiveContains(query.trimmingCharacters(in: .whitespaces))
    }

    var body: some View {
        List {
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                Section("Tools") {
                    ForEach(tools) { tool in toolRow(tool) }
                }
                .listRowBackground(Theme.surface)
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
