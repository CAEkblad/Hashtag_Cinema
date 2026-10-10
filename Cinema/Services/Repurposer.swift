import Foundation

/// Turns one video script into ready to paste posts for every place an agent shows up.
enum Repurposer {
    struct Piece: Identifiable, Hashable {
        var id: String { title }
        var title: String
        var icon: String
        var subject: String?
        var text: String
        /// Platform limit, when there is one.
        var limit: Int?
    }

    static func pieces(for idea: Idea, city: FloridaCity, agentName: String, brokerage: String) -> [Piece] {
        let place = idea.cityName ?? city.name
        let keyword = commentKeyword(in: idea.script) ?? "INFO"
        let tags = hashtags(city: city, category: idea.category)
        let first = agentName.split(separator: " ").first.map(String.init) ?? agentName
        let points = idea.shots.prefix(4).map { cleaned($0) }
        let body = scriptBody(idea.script, keyword: keyword, hook: idea.hook)
        let signoff = brokerage.isEmpty ? agentName : "\(agentName), \(brokerage)"

        return [
            Piece(
                title: "Instagram Reel",
                icon: "camera.circle.fill",
                text: "\(idea.hook)\n\n\(firstSentences(body, 2))\n\nComment \(keyword) and I'll send you the details. Save this for later.\n\n\(tags.prefix(9).joined(separator: " "))",
                limit: 2_200
            ),
            Piece(
                title: "TikTok",
                icon: "music.note",
                text: "\(idea.hook) Comment \(keyword) for more. \(tags.prefix(4).joined(separator: " "))",
                limit: 2_200
            ),
            Piece(
                title: "Facebook",
                icon: "f.circle.fill",
                text: "\(idea.hook)\n\n\(body)\n\nIf you or someone you know is thinking about \(place), comment \(keyword) or message me. Happy to help, no pressure.",
                limit: nil
            ),
            Piece(
                title: "YouTube Shorts",
                icon: "play.rectangle.fill",
                subject: shortTitle(idea, place: place),
                text: "\(firstSentences(body, 2))\n\nComment \(keyword) and I'll reply with the details.\n\n\(tags.prefix(3).joined(separator: " "))",
                limit: 5_000
            ),
            Piece(
                title: "LinkedIn",
                icon: "briefcase.fill",
                text: "\(idea.hook)\n\n\(body)\n\nWhat would you add? I'm always happy to compare notes with other \(place) professionals.",
                limit: 3_000
            ),
            Piece(
                title: "Google Business Profile",
                icon: "mappin.circle.fill",
                text: "\(idea.hook) \(firstSentences(body, 3)) Call or message \(first) for help with buying or selling in \(place).",
                limit: 1_500
            ),
            Piece(
                title: "Email to your sphere",
                icon: "envelope.fill",
                subject: emailSubject(idea, place: place),
                text: "Hi [first name],\n\n\(idea.hook)\n\n\(body)\n\nI just posted a short video on this. Reply to this email if you want me to send it, or if you have a question about your home.\n\n\(signoff)",
                limit: nil
            ),
            Piece(
                title: "Text to a past client",
                icon: "message.fill",
                text: "Hey [name]! I just made a quick video on this and thought of you: \(idea.hook) Want me to send it? \(first)",
                limit: nil
            ),
            Piece(
                title: "Blog post outline",
                icon: "doc.text.fill",
                subject: shortTitle(idea, place: place),
                text: (["Intro: \(idea.hook)"] + points.enumerated().map { "\($0.offset + 1). \($0.element)" } + ["Wrap up: what this means for buyers and sellers in \(place), and how to reach you."]).joined(separator: "\n"),
                limit: nil
            )
        ]
    }

    // MARK: Helpers

    /// The capitalized word agents ask people to comment, for example TOUR.
    static func commentKeyword(in script: String) -> String? {
        let words = script.components(separatedBy: CharacterSet.letters.inverted).filter { $0.count >= 3 }
        let skip: Set<String> = ["MYTH", "FAQ", "HOA", "USA", "MLS", "FHA", "VA"]
        return words.last { $0 == $0.uppercased() && $0.rangeOfCharacter(from: .lowercaseLetters) == nil && !skip.contains($0) }
    }

    /// The script without its closing "comment X" ask, so each piece can add its own.
    /// The script without its closing "comment X" ask and without the hook, so each piece can add its own.
    static func scriptBody(_ script: String, keyword: String, hook: String = "") -> String {
        let hookSentences = Set(splitSentences(hook).map(normalized))
        let sentences = splitSentences(script).filter { !hookSentences.contains(normalized($0)) }
        let kept = sentences.filter { !$0.localizedCaseInsensitiveContains("comment \(keyword)") && !$0.contains(keyword) }
        return (kept.isEmpty ? sentences : kept).joined(separator: " ")
    }

    private static func normalized(_ text: String) -> String {
        text.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    static func splitSentences(_ text: String) -> [String] {
        var result: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { sentence, _, _, _ in
            if let sentence = sentence?.trimmingCharacters(in: .whitespacesAndNewlines), !sentence.isEmpty { result.append(sentence) }
        }
        return result
    }

    static func firstSentences(_ text: String, _ count: Int) -> String {
        splitSentences(text).prefix(count).joined(separator: " ")
    }

    private static func cleaned(_ shot: String) -> String {
        shot.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "."))
    }

    private static func shortTitle(_ idea: Idea, place: String) -> String {
        let title = idea.title.count <= 70 ? idea.title : String(idea.title.prefix(67)) + "..."
        return title.localizedCaseInsensitiveContains(place) ? title : "\(title) | \(place)"
    }

    private static func emailSubject(_ idea: Idea, place: String) -> String {
        switch idea.category {
        case .marketUpdate: return "What's happening in the \(place) market"
        case .mythBuster: return "A real estate myth I hear all the time"
        case .neighborhood: return "A \(place) spot worth knowing"
        case .listingTour, .openHouse: return "A home I think you'll like"
        case .clientStory: return "A quick story from this week"
        case .dayInLife: return "Behind the scenes this week"
        }
    }

    static func hashtags(city: FloridaCity, category: IdeaCategory) -> [String] {
        let cityTag = city.name.filter(\.isLetter).lowercased()
        let countyTag = city.county.filter(\.isLetter).lowercased()
        var tags = ["#\(cityTag)realestate", "#\(cityTag)", "#\(countyTag)county", "#floridarealestate"]
        switch category {
        case .listingTour, .openHouse: tags += ["#hometour", "#justlisted"]
        case .marketUpdate: tags += ["#housingmarket", "#marketupdate"]
        case .neighborhood: tags += ["#\(cityTag)living", "#movingtoflorida"]
        case .mythBuster: tags += ["#homebuyingtips", "#firsttimehomebuyer"]
        case .clientStory: tags += ["#closingday", "#newhomeowner"]
        case .dayInLife: tags += ["#realtorlife", "#dayinthelife"]
        }
        if city.has(.beach) { tags.append("#beachlife") }
        if city.has(.boating) { tags.append("#waterfronthomes") }
        if city.has(.luxury) { tags.append("#luxuryrealestate") }
        tags.append("#realtor")
        return tags
    }
}
