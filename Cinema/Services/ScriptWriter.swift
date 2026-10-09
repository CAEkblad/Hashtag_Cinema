import Foundation

/// Turns a topic into a hook, script and shot list on the phone. With the
/// backend on, the same request goes to Claude through generate-ideas.
enum ScriptWriter {
    static func write(type: ScriptType, topic rawTopic: String, seconds: Int, city: FloridaCity, agentName: String) -> Idea {
        let topic = rawTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = topic.isEmpty ? defaultTopic(type, city: city) : topic
        let keyword = keyword(for: type, subject: subject)
        let first = agentName.split(separator: " ").first.map { String($0) } ?? agentName
        let short = seconds <= 20

        let hook: String
        var body: [String]
        var shots: [String]

        switch type {
        case .marketUpdate:
            hook = "Here's what's really happening in the \(city.name) market right now."
            body = ["\(subject.capitalizedFirst).", "If you're selling, price it right the first time and make the first weekend count.", "If you're buying, this is where you have room to negotiate."]
            shots = ["Walk toward camera, tight framing", "Screen with one or two numbers", "Close on you with the keyword"]
        case .listingTour:
            hook = "Wait until you see what's behind this door in \(city.name)."
            body = ["Welcome to \(subject).", "Here's the room everyone falls in love with.", "And here's the part that sold me: the outdoor space.", "Want a private tour before the weekend?"]
            shots = ["Front door push in", "Best room, slow walk", "Detail close up", "Outdoor reveal", "You on the porch with the keyword"]
        case .mythBuster:
            hook = "Stop believing this: \(subject.lowercasedFirst)."
            body = ["Here's the truth.", "Most buyers in \(city.county) County don't know their options until they talk to a lender.", "Ask me before you rule yourself out."]
            shots = ["Text on screen with the myth", "You shaking your head", "Simple notes app list of the truth", "Close on you"]
        case .neighborhood:
            hook = "If you move to \(subject), this is your Saturday."
            body = ["Coffee first, at my favorite spot.", "Then a walk down the streets locals love.", "End the day on a patio. This is why people pick \(subject) in \(city.name)."]
            shots = ["Walking shot down a main street", "Coffee or food detail, slow motion", "You at a table talking", "Quick cuts of homes nearby"]
        case .clientStory:
            hook = "They almost gave up. Then this happened."
            body = ["\(subject.capitalizedFirst).", "We made a plan, moved fast and wrote the offer that stood out.", "Seeing them get the keys is why I do this."]
            shots = ["You direct to camera, emotional open", "Photo or clip of the clients, with permission", "Keys or sold sign", "Close on you smiling"]
        case .recruiting:
            hook = "Agents, here's what nobody tells you about where you hang your license."
            body = ["\(subject.capitalizedFirst).", "We film content every week, share leads and celebrate wins together.", "If you want that, let's grab coffee."]
            shots = ["Office or team moment", "Content day behind the scenes", "Team celebrating", "You inviting viewers"]
        case .aboutMe:
            hook = "I'm \(first), and here's why I sell homes in \(city.name)."
            body = ["\(subject.capitalizedFirst).", "My job is to make the biggest move of your life feel simple.", "If you're thinking about \(city.name), I'd love to help."]
            shots = ["Close up intro", "B-roll of you in \(city.name)", "With clients or at a showing", "Warm close"]
        }

        if short { body = Array(body.prefix(2)) }
        let close = "Comment \(keyword) and I'll send you the details."
        let script = ([hook] + body + [close]).joined(separator: " ")

        return Idea(
            title: "\(type.title): \(subject.capitalizedFirst)",
            hook: hook,
            category: type.category,
            shots: short ? Array(shots.prefix(3)) : shots,
            script: script,
            targetSeconds: seconds,
            whyItWorks: "Hook in the first 2 seconds, one clear idea, and a comment keyword that turns viewers into leads.",
            cityName: city.name
        )
    }

    private static func defaultTopic(_ type: ScriptType, city: FloridaCity) -> String {
        switch type {
        case .marketUpdate: return "more homes are coming on the market in \(city.name)"
        case .listingTour: return "this \(city.name) home"
        case .mythBuster: return "you need 20% down to buy a home"
        case .neighborhood: return city.neighborhoods.first ?? "downtown \(city.name)"
        case .clientStory: return "my first time buyers won against multiple offers"
        case .recruiting: return "the right team changes your whole business"
        case .aboutMe: return "I grew up loving homes and the people in them"
        }
    }

    private static func keyword(for type: ScriptType, subject: String) -> String {
        switch type {
        case .marketUpdate: return "MARKET"
        case .listingTour: return "TOUR"
        case .mythBuster: return "TRUTH"
        case .neighborhood: return subject.keywordStem.isEmpty ? "AREA" : subject.keywordStem
        case .clientStory: return "HOME"
        case .recruiting: return "TEAM"
        case .aboutMe: return "HELLO"
        }
    }
}

extension String {
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }

    var lowercasedFirst: String {
        guard let first else { return self }
        return first.lowercased() + dropFirst()
    }
}
