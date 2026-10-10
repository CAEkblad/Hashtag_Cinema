import Foundation

/// A quick read on how a listing is doing and what to do next, from days on
/// market, showings, buyer agent feedback and open house traffic.
struct ListingHealth {
    enum Verdict: String {
        case tooEarly, onTrack, needsExposure, priceConversation, offerReady

        var title: String {
            switch self {
            case .tooEarly: return "Too early to tell"
            case .onTrack: return "On track"
            case .needsExposure: return "Needs more eyes"
            case .priceConversation: return "Time for a price conversation"
            case .offerReady: return "Buyers are close"
            }
        }

        var icon: String {
            switch self {
            case .tooEarly: return "hourglass"
            case .onTrack: return "checkmark.seal.fill"
            case .needsExposure: return "eye.trianglebadge.exclamationmark.fill"
            case .priceConversation: return "tag.fill"
            case .offerReady: return "flame.fill"
            }
        }
    }

    let listing: Listing
    let openHouseVisitors: Int

    var days: Int { listing.daysOnMarket }
    var showings: Int { listing.feedback.count }
    var hot: Int { listing.feedback.filter { $0.interest == .hot }.count }
    var maybe: Int { listing.feedback.filter { $0.interest == .maybe }.count }
    var pass: Int { listing.feedback.filter { $0.interest == .pass }.count }
    var weeks: Double { max(1, Double(days) / 7) }
    var showingsPerWeek: Double { Double(showings) / weeks }

    /// Feedback that says the price is the problem.
    var priceObjections: Int {
        let words = ["high", "overpriced", "over priced", "expensive", "too much", "price", "pricey", "steep"]
        let okay = ["about right", "fair", "good price", "great price", "priced right", "well priced"]
        return listing.feedback.filter { item in
            let text = (item.priceOpinion + " " + item.comment).lowercased()
            return !okay.contains { text.contains($0) } && words.contains { text.contains($0) }
        }.count
    }

    var marketingDone: Int { listing.tasks.filter { listing.done.contains($0) }.count }
    var marketingTotal: Int { listing.tasks.count }

    var verdict: Verdict {
        guard listing.status == .active else { return .onTrack }
        if hot >= 2 { return .offerReady }
        if days < 10 && showings < 3 { return .tooEarly }
        if days >= 21 && (priceObjections * 2 >= max(1, showings) || (showings >= 6 && hot == 0)) { return .priceConversation }
        if showingsPerWeek < 2 { return .needsExposure }
        if days >= 30 && hot == 0 { return .priceConversation }
        return .onTrack
    }

    var summary: String {
        switch verdict {
        case .tooEarly:
            return "It's been \(days) day\(days == 1 ? "" : "s"). Most of a listing's traffic comes in the first two weeks, so keep the launch marketing going and log every showing."
        case .onTrack:
            return listing.status == .active
                ? "Showings are steady at about \(String(format: "%.1f", showingsPerWeek)) a week. Keep the weekly seller report going so your seller sees the work."
                : "This listing is \(listing.status.title.lowercased()). Check back on the deal timeline for what's next."
        case .needsExposure:
            return "Only \(showings) showing\(showings == 1 ? "" : "s") in \(days) days. Before talking price, make sure buyers are actually seeing it: fresh video, an open house and boosted posts."
        case .priceConversation:
            return "\(showings) showing\(showings == 1 ? "" : "s") in \(days) days and \(priceObjections) said the price is the issue. Buyers are looking but not writing. That's the market's answer on price."
        case .offerReady:
            return "\(hot) buyer\(hot == 1 ? " is" : "s are") very interested. Follow up with those agents today and ask what it would take to get an offer."
        }
    }

    var nextSteps: [(title: String, detail: String, icon: String, route: Route?)] {
        switch verdict {
        case .tooEarly:
            return [
                ("Finish the launch plan", "\(marketingDone) of \(marketingTotal) marketing steps done", "calendar.badge.clock", .launchPlan(listing.id)),
                ("Post a photo reel", "A new video gets the listing in front of more buyers", "film.stack.fill", .listingReel(listing.id)),
                ("Hit the neighbors", "Postcards and door knocks around the home", "mail.stack.fill", .neighborBlast(listing.id))
            ]
        case .onTrack:
            return [
                ("Send the seller report", "A weekly update keeps your seller calm and on your side", "chart.bar.doc.horizontal.fill", .sellerReport(listing.id)),
                ("Keep content going", "A new angle each week: the kitchen, the yard, the neighborhood", "video.badge.plus", .shotList(listing.id))
            ]
        case .needsExposure:
            return [
                ("Book a pro video", "Listings with video get more showings", "camera.fill", .bookings),
                ("Hold an open house", "Schedule one from the listing page", "house.fill", nil),
                ("Neighbor blast", "Postcards and door knocks around the home", "mail.stack.fill", .neighborBlast(listing.id)),
                ("Share to the agent network", "Put it in front of agents with buyers", "point.3.connected.trianglepath.dotted", .agentNetwork)
            ]
        case .priceConversation:
            return [
                ("Pull fresh comps", "Bring 3 to 5 recent sales to the conversation", "chart.line.uptrend.xyaxis", .homeValue),
                ("Show the seller's net at a new price", "So the decision is about dollars, not feelings", "dollarsign.circle.fill", .listingNetSheet(listing.id)),
                ("Price improved poster", "Ready the moment your seller says yes", "rectangle.portrait.on.rectangle.portrait.fill", .listingPoster(listing.id))
            ]
        case .offerReady:
            return [
                ("Compare offers", "Line up every offer with the seller's net", "rectangle.split.3x1.fill", .offers(listing.id)),
                ("Seller net sheet", "Know the walk away number before offers land", "dollarsign.circle.fill", .listingNetSheet(listing.id))
            ]
        }
    }

    /// What to say to the seller, built from their own listing's numbers.
    func sellerScript(sellerName: String, agentName: String) -> String {
        let first = agentName.split(separator: " ").first.map(String.init) ?? agentName
        switch verdict {
        case .priceConversation:
            return "Hi \(sellerName), I want to walk you through where we are. In \(days) days we've had \(showings) showings\(openHouseVisitors > 0 ? " and \(openHouseVisitors) people through the open house" : ""). \(priceObjections) of the buyer's agents told me price was the reason their buyers passed. The good news is buyers are coming. They're just choosing other homes. I'd like to show you the latest sales nearby and what you'd net at a new price, and let you decide. When can we sit down for 20 minutes? \(first)"
        case .needsExposure:
            return "Hi \(sellerName), quick update. We've had \(showings) showing\(showings == 1 ? "" : "s") in \(days) days, which is lighter than I want. Before we talk about price, I'm adding more exposure this week: a new video, an open house and a push to local agents. I'll send you the numbers next week. \(first)"
        case .offerReady:
            return "Hi \(sellerName), good news: \(hot) buyer\(hot == 1 ? " is" : "s are") very interested. I'm following up with their agents today. Let's be ready to move fast if an offer comes in. Are you free for a quick call tonight? \(first)"
        default:
            return "Hi \(sellerName), here's this week's update: \(showings) showing\(showings == 1 ? "" : "s") so far in \(days) days. I'll keep sending feedback as it comes in. \(first)"
        }
    }
}
