import Foundation

/// Reads a social comment and suggests a public reply, a DM and whether it's a lead.
enum ReplyHelper {
    enum Kind: String, CaseIterable {
        case keyword, showing, price, location, process, sellerCurious, compliment, skeptic, agent, other

        var title: String {
            switch self {
            case .keyword: return "Asked for your keyword"
            case .showing: return "Wants to see it"
            case .price: return "Asked about price"
            case .location: return "Asked where it is"
            case .process: return "Buying question"
            case .sellerCurious: return "Thinking about selling"
            case .compliment: return "Compliment"
            case .skeptic: return "Skeptic or troll"
            case .agent: return "Another agent"
            case .other: return "General comment"
            }
        }

        var icon: String {
            switch self {
            case .keyword: return "key.fill"
            case .showing: return "calendar.badge.plus"
            case .price: return "dollarsign.circle.fill"
            case .location: return "mappin.circle.fill"
            case .process: return "questionmark.circle.fill"
            case .sellerCurious: return "house.fill"
            case .compliment: return "heart.fill"
            case .skeptic: return "hand.raised.fill"
            case .agent: return "person.2.fill"
            case .other: return "bubble.left.fill"
            }
        }

        var isLead: Bool {
            switch self {
            case .keyword, .showing, .price, .location, .process, .sellerCurious: return true
            default: return false
            }
        }
    }

    struct Suggestion {
        var kind: Kind
        var keyword: String?
        var publicReply: String
        var dm: String?
        var tip: String
    }

    static func read(_ comment: String, name: String, keywords: [KeywordRule], agentFirstName: String, city: String) -> Suggestion {
        let text = comment.lowercased()
        let first = name.split(separator: " ").first.map(String.init) ?? ""
        let hi = first.isEmpty ? "" : "\(first), "
        let hiCap = first.isEmpty ? "" : "\(first)! "

        func has(_ words: [String]) -> Bool { words.contains { text.contains($0) } }

        // A comment that is only (or mostly) one of the agent's keywords.
        let upperWords = comment.components(separatedBy: CharacterSet.letters.inverted).map { $0.uppercased() }
        if let rule = keywords.first(where: { $0.isOn && upperWords.contains($0.keyword.uppercased()) }) {
            return Suggestion(
                kind: .keyword,
                keyword: rule.keyword.uppercased(),
                publicReply: "\(hiCap)Just sent it to your DMs. Check your message requests if you don't see it.",
                dm: rule.fullMessage,
                tip: "Reply publicly so the post gets more comments, then DM within the hour."
            )
        }

        if has(["agent here", "fellow agent", "realtor here", "great listing", "co-op", "coop", "cobroke", "my buyers", "my client"]) {
            return Suggestion(kind: .agent, keyword: nil,
                              publicReply: "Thanks \(first.isEmpty ? "so much" : first)! Happy to connect if you have buyers. Send me a DM.",
                              dm: nil,
                              tip: "Agents commenting helps reach. Keep it short and friendly.")
        }

        if has(["overpriced", "crazy", "bubble", "crash", "who can afford", "nobody can afford", "ridiculous", "scam", "lol no", "insane price"]) {
            return Suggestion(kind: .skeptic, keyword: nil,
                              publicReply: "Fair question! Prices depend a lot on the street and the home. Happy to share what's actually selling near you if you're curious.",
                              dm: nil,
                              tip: "Stay calm and helpful. Never argue in the comments. Other people are reading how you respond.")
        }

        let aboutMyHome = has(["my house", "my home", "our house", "our home", "my condo", "my place", "my property"])
        if has(["sell my", "selling my", "list my", "how much could i get", "thinking of selling", "thinking about selling", "home value", "house value"])
            || (aboutMyHome && has(["sell", "worth", "value", "get for", "list"])) {
            return Suggestion(kind: .sellerCurious, keyword: "VALUE",
                              publicReply: "\(hiCap)Great question. I'll send you a free value report, check your DMs!",
                              dm: "Hi \(first.isEmpty ? "there" : first)! It's \(agentFirstName). Happy to put together a free home value report. What's the address? No pressure, just numbers.",
                              tip: "Seller leads are gold. Ask for the address in the DM, not in public.")
        }

        if has(["see it", "tour", "showing", "available", "still for sale", "can i see", "come see", "open house", "when can"]) {
            return Suggestion(kind: .showing, keyword: "TOUR",
                              publicReply: "\(hiCap)Yes! Sending you the details and times now.",
                              dm: "Hi \(first.isEmpty ? "there" : first)! It's \(agentFirstName). Thanks for asking about the home. When works for a showing? I have openings this week.",
                              tip: "A showing request is your hottest lead. Call or DM within 5 minutes.")
        }

        if has(["how much", "price", "what's the price", "whats the price", "cost", "$", "listed at", "hoa"]) {
            return Suggestion(kind: .price, keyword: "INFO",
                              publicReply: "\(hiCap)Sent you the price and details in DMs!",
                              dm: "Hi \(first.isEmpty ? "there" : first)! It's \(agentFirstName). Here are the price and details. Want me to send you similar homes too?",
                              tip: "Putting the price in the DM starts a conversation. Putting it in the comments ends one.")
        }

        if has(["where", "what area", "which neighborhood", "address", "what city", "location", "zip"]) {
            return Suggestion(kind: .location, keyword: "INFO",
                              publicReply: "\(hiCap)It's in \(city)! Sending you the full details.",
                              dm: "Hi \(first.isEmpty ? "there" : first)! It's \(agentFirstName). Here's the location and info. Are you looking in that area?",
                              tip: "Share the general area publicly and the exact address in the DM.")
        }

        if has(["first time", "down payment", "credit", "pre approved", "preapproved", "pre-approved", "how do i", "can i buy", "qualify", "closing cost", "fha", "va loan", "rent vs", "renting"]) {
            return Suggestion(kind: .process, keyword: "GUIDE",
                              publicReply: "\(hiCap)Great question. I'll DM you my free buyer guide!",
                              dm: "Hi \(first.isEmpty ? "there" : first)! It's \(agentFirstName). Here's my buyer guide with every step and the real costs. Happy to answer anything. What's your timeline?",
                              tip: "Send the Buyer guide PDF from Client guides. Questions like this are future buyers.")
        }

        if has(["beautiful", "gorgeous", "love", "stunning", "amazing", "dream", "wow", "obsessed", "goals", "❤", "😍", "🔥", "🙌"]) {
            return Suggestion(kind: .compliment, keyword: nil,
                              publicReply: "Thank you\(first.isEmpty ? "" : ", \(first)")! Isn't it great? Which part was your favorite?",
                              dm: nil,
                              tip: "Ask a question back. Every reply pushes the post to more people.")
        }

        return Suggestion(kind: .other, keyword: nil,
                          publicReply: "\(hi.isEmpty ? "Thanks" : "Thanks \(hi.dropLast(2))") for watching! Anything you'd want to see next?",
                          dm: nil,
                          tip: "Reply to every comment in the first hour. It's one of the biggest signals for reach.")
    }
}
