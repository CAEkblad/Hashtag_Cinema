import Foundation

/// Prospecting call scripts for power hour. {me}, {city} and {name} are filled in.
struct CallScript: Identifiable, Hashable {
    let id: String
    let title: String
    let who: String
    let icon: String
    let opener: String
    let questions: [String]
    let ifTheySay: [(String, String)]
    let close: String
    let voicemail: String
    let text: String
    /// Cold outreach needs a do not call check first.
    let isCold: Bool

    static func == (a: CallScript, b: CallScript) -> Bool { a.id == b.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum CallScriptLibrary {
    static let all: [CallScript] = [
        CallScript(
            id: "sphere",
            title: "Sphere check in",
            who: "Friends, family, people you know",
            icon: "person.2.fill",
            opener: "Hey {name}, it's {me}! No reason for the call, I was just thinking about you. How's everything going?",
            questions: [
                "How's the family? Anything new at work?",
                "Still loving the house, or has anything changed with your plans?",
                "Who do you know that's talked about moving this year?"
            ],
            ifTheySay: [
                ("We're happy where we are", "Love that. If anything ever changes, or a friend asks you about real estate, I'd be grateful if you thought of me."),
                ("My cousin is an agent", "That's great, family helps family. If they ever can't help a friend of yours, I'd love to.")
            ],
            close: "Thanks for catching up. I'm going to send you my monthly market update. Want it by text or email?",
            voicemail: "Hey {name}, it's {me}. Just thinking about you and wanted to say hi. No need to call back, I'll try you later this week!",
            text: "Hey {name}! Just thinking about you. Hope all is well. Anything new? {me}",
            isCold: false
        ),
        CallScript(
            id: "past-client",
            title: "Past client",
            who: "People you helped buy or sell",
            icon: "house.and.flag.fill",
            opener: "Hi {name}, it's {me}. I was driving by and thought of you. How are you liking the house?",
            questions: [
                "Any projects you've done since you moved in?",
                "Do you want me to keep an eye on what homes near you are selling for?",
                "Have any friends or neighbors mentioned wanting to move?"
            ],
            ifTheySay: [
                ("We're thinking about refinancing", "I can connect you with a lender I trust. Want me to send their info?"),
                ("Our home's getting small", "Let's look at what yours would sell for and what's out there. No pressure, just numbers.")
            ],
            close: "It was great talking to you. I'll send you a quick home value update this month.",
            voicemail: "Hi {name}, it's {me}. I was thinking about you and the house. Give me a call when you get a sec, nothing urgent!",
            text: "Hi {name}! It's {me}. Hope you're loving the house. Want a quick update on what homes near you are selling for?",
            isCold: false
        ),
        CallScript(
            id: "online-lead",
            title: "New online lead",
            who: "Comment, DM or website leads. Call within 5 minutes",
            icon: "bolt.fill",
            opener: "Hi {name}, it's {me}. You just asked about homes in {city} and I wanted to reach out personally. Is now a good time?",
            questions: [
                "What made you start looking?",
                "When would you ideally like to be moved?",
                "Have you talked to a lender yet?",
                "Are you working with an agent already?"
            ],
            ifTheySay: [
                ("I'm just looking", "Totally fine. Most people start that way. Want me to send you new homes the day they hit, so you see them first?"),
                ("I already have an agent", "Great, stick with them. If anything changes, I'm here.")
            ],
            close: "Let's find a 20 minute time to go over what you want, and I'll set up a search for you. Does tomorrow at 5 or Saturday morning work better?",
            voicemail: "Hi {name}, it's {me} with the info you asked for on homes in {city}. I'll text you too. Talk soon!",
            text: "Hi {name}, it's {me}! You asked about homes in {city}. I'd love to help. When's a good time for a quick call?",
            isCold: false
        ),
        CallScript(
            id: "open-house",
            title: "Open house follow up",
            who: "Visitors who signed in",
            icon: "house.fill",
            opener: "Hi {name}, it's {me}. Thanks for stopping by the open house! What did you think of the home?",
            questions: [
                "What did you like most? What would you change?",
                "Are you looking in this area or all over {city}?",
                "Do you have a home to sell first?"
            ],
            ifTheySay: [
                ("It's not the one", "That helps. Tell me what would make it the one and I'll send you homes that fit."),
                ("We're early in the process", "Perfect time to get a plan together. I can walk you through the steps in 20 minutes.")
            ],
            close: "I'd love to set up a few showings for you. Are you free this weekend?",
            voicemail: "Hi {name}, it's {me} from the open house. Thanks for coming by! I'd love to hear what you thought. I'll text you too.",
            text: "Hi {name}! Thanks for stopping by the open house. What did you think? I can send you similar homes. {me}",
            isCold: false
        ),
        CallScript(
            id: "expired",
            title: "Expired listing",
            who: "Homes that came off the market unsold",
            icon: "clock.badge.xmark.fill",
            opener: "Hi, I'm looking for {name}. This is {me}, a local agent. I saw your home came off the market and wanted to ask: are you still hoping to sell?",
            questions: [
                "What do you think kept it from selling?",
                "If it had sold, where were you moving to?",
                "How soon do you need to be there?",
                "What would you want done differently this time?"
            ],
            ifTheySay: [
                ("We're taking a break", "Totally understand. Can I ask what your plan is for next spring? I'd love to show you what I'd do differently, whenever you're ready."),
                ("We'll relist with our agent", "Makes sense. If you'd like a second opinion on price or marketing before you do, I'm happy to give one.")
            ],
            close: "I'd like to come by for 20 minutes and show you exactly how I'd market it, including pro video. Is tomorrow afternoon or Thursday better?",
            voicemail: "Hi {name}, this is {me}, a local agent. I noticed your home came off the market. I have a few ideas on what could get it sold. Give me a call back.",
            text: "Hi {name}, this is {me}, a local agent. I saw your home came off the market. If you're still hoping to sell, I'd love to share a few ideas.",
            isCold: true
        ),
        CallScript(
            id: "fsbo",
            title: "For sale by owner",
            who: "Owners selling it themselves",
            icon: "signpost.right.fill",
            opener: "Hi, I'm calling about the home for sale. This is {me}, a local agent. I'm not calling to list it. I just wanted to ask how it's going.",
            questions: [
                "How many showings have you had?",
                "Are you open to working with a buyer's agent if they bring an offer?",
                "Where are you moving to, and when?"
            ],
            ifTheySay: [
                ("We don't want to pay a commission", "Fair. A lot of my sellers felt the same until they saw their net. Want me to show you what you'd walk away with both ways?"),
                ("It's going great", "Awesome. If you want, I can send you a checklist for inspections and closing so nothing surprises you.")
            ],
            close: "Can I drop off a free seller checklist and the recent sales near you? No strings. Would tomorrow work?",
            voicemail: "Hi, this is {me}, a local agent. I saw your home for sale and have a free checklist that helps owners sell on their own. Call me back if you want it.",
            text: "Hi! This is {me}, a local agent. I saw your home for sale. Want a free checklist for selling on your own? Happy to drop it off.",
            isCold: true
        ),
        CallScript(
            id: "circle",
            title: "Just listed or just sold neighbors",
            who: "Homes around your listing or sale",
            icon: "circle.dashed",
            opener: "Hi, this is {me}, a local agent. I'm calling a few neighbors because a home on your street just sold. Have you thought about what your home might be worth right now?",
            questions: [
                "How long have you been in the home?",
                "Do you know anyone who'd love to live in the neighborhood?",
                "If you ever moved, where would you go?"
            ],
            ifTheySay: [
                ("We're not selling", "Totally fine. Would a free value update once a year be helpful? It's good to know for insurance and taxes too."),
                ("How much did it sell for?", "I can share the details once it closes. Want me to send you what homes on your street are selling for?")
            ],
            close: "I'll send over the recent sales near you. Is text or email better?",
            voicemail: "Hi, this is {me}, a local agent. A home on your street just sold and I had a few buyers miss out. Call me back if you've ever thought about selling.",
            text: "Hi, this is {me}, a local agent. A home on your street just sold. Want to see what homes nearby are going for?",
            isCold: true
        ),
        CallScript(
            id: "referral",
            title: "Ask for a referral",
            who: "Happy clients and close friends",
            icon: "heart.fill",
            opener: "Hey {name}, it's {me}. Got a quick favor to ask. Is now okay?",
            questions: [
                "My business runs on referrals from people like you. Who's the first person you think of who's talked about moving?",
                "Anyone at work or in the neighborhood growing out of their place?"
            ],
            ifTheySay: [
                ("I can't think of anyone", "No worries at all. If someone comes up, would you text me their name? I'll take great care of them."),
                ("Actually, yes", "Amazing. Would you mind if I reached out, or would you rather introduce us by text?")
            ],
            close: "Thank you so much. It means a lot. I'll keep you posted.",
            voicemail: "Hey {name}, it's {me}. I have a quick favor to ask. Call me back when you have a sec!",
            text: "Hey {name}! Quick favor: do you know anyone thinking about buying or selling this year? I'd take great care of them. {me}",
            isCold: false
        )
    ]

    static func fill(_ text: String, me: String, city: String, name: String) -> String {
        text.replacingOccurrences(of: "{me}", with: me)
            .replacingOccurrences(of: "{city}", with: city)
            .replacingOccurrences(of: "{name}", with: name.isEmpty ? "[name]" : name)
    }
}
