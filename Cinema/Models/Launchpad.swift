import Foundation

/// Saved progress for "I'm a brand new agent" mode.
struct LaunchpadState: Codable, Equatable {
    var isOn = false
    var start = Calendar.current.startOfDay(for: Date())
    var done: [String] = []
    var milestones: [String: Date] = [:]
    var contacts: [String] = []
    var celebrated: Bool?
    var hit100: Bool?

    /// Week 1 to 13 of the first 90 days.
    var currentWeek: Int {
        let days = Calendar.current.dateComponents([.day], from: start, to: Calendar.current.startOfDay(for: Date())).day ?? 0
        return min(max(days / 7 + 1, 1), 13)
    }

    var dayNumber: Int {
        let days = Calendar.current.dateComponents([.day], from: start, to: Calendar.current.startOfDay(for: Date())).day ?? 0
        return min(max(days + 1, 1), 90)
    }
}

/// One step on the 90 day launch plan.
struct LaunchStep: Identifiable {
    enum Action {
        case route(Route)
        case announce
        case contacts
        case headshots
    }

    let id: String
    let title: String
    let detail: String
    let icon: String
    let action: Action?
}

struct LaunchPhase: Identifiable {
    let id: String
    let title: String
    let weeks: ClosedRange<Int>
    let steps: [LaunchStep]
}

enum LaunchMilestone: String, CaseIterable, Identifiable {
    case firstLead, firstAppointment, firstShowing, firstOpenHouse, firstContract, firstClosing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstLead: return "First lead"
        case .firstAppointment: return "First appointment"
        case .firstShowing: return "First showing"
        case .firstOpenHouse: return "First open house"
        case .firstContract: return "First contract"
        case .firstClosing: return "First closing"
        }
    }

    var icon: String {
        switch self {
        case .firstLead: return "person.badge.plus"
        case .firstAppointment: return "cup.and.saucer.fill"
        case .firstShowing: return "key.fill"
        case .firstOpenHouse: return "house.fill"
        case .firstContract: return "signature"
        case .firstClosing: return "party.popper.fill"
        }
    }

    var cheer: String {
        switch self {
        case .firstLead: return "Got my first lead!"
        case .firstAppointment: return "Booked my first appointment!"
        case .firstShowing: return "Showed my first home!"
        case .firstOpenHouse: return "Held my first open house!"
        case .firstContract: return "Wrote my first contract!"
        case .firstClosing: return "Closed my first deal!"
        }
    }
}

enum LaunchPlan90 {
    static func phases(_ lex: Lexicon) -> [LaunchPhase] {
        [
            LaunchPhase(id: "setup", title: "Get set up", weeks: 1...1, steps: [
                LaunchStep(id: "training", title: lex.isKW ? "Sign up for Ignite" : "Sign up for new agent training", detail: lex.isKW ? "Ask your \(lex.office) when the next Ignite class starts. It's the fastest way to learn the KW systems." : "Ask your \(lex.officeLeader) what training they offer new agents, and get it on your calendar.", icon: "graduationcap.fill", action: nil),
                LaunchStep(id: "team", title: "Join your team on CloseUp", detail: "Your videos, listings and wins post to your team page so your \(lex.teamLeader) sees your hustle.", icon: "person.3.fill", action: .route(.team)),
                LaunchStep(id: "headshots", title: "Get pro headshots", detail: "Your face is your brand. Every post, card and sign uses it.", icon: "camera.fill", action: .headshots),
                LaunchStep(id: "brand", title: "Set up your brand kit", detail: "Add your headshot, logo and colors once. Every poster and video picks them up.", icon: "paintpalette.fill", action: .route(.brandKit)),
                LaunchStep(id: "card", title: "Make your digital business card", detail: "A QR card people can save straight to their phone.", icon: "person.text.rectangle.fill", action: .route(.businessCard)),
                LaunchStep(id: "license", title: "Add your license dates", detail: "We'll track your 45 hour post licensing deadline so it never sneaks up on you.", icon: "checkmark.seal.fill", action: .route(.license))
            ]),
            LaunchPhase(id: "announce", title: "Tell everyone", weeks: 2...2, steps: [
                LaunchStep(id: "announce", title: "Announce your license", detail: "A ready to post announcement and a text for close friends.", icon: "megaphone.fill", action: .announce),
                LaunchStep(id: "contacts", title: "List your first 100 contacts", detail: "Everyone you know who could buy, sell or refer. This is your business.", icon: "person.crop.rectangle.stack.fill", action: .contacts),
                LaunchStep(id: "aboutMe", title: "Film your \"about me\" video", detail: "60 seconds on who you are and why you got into real estate.", icon: "video.fill", action: .route(.scriptWriter)),
                LaunchStep(id: "bio", title: "Set up your link in bio", detail: "One link for your socials with your card, listings and contact.", icon: "link", action: .route(.linkInBio))
            ]),
            LaunchPhase(id: "habits", title: "Build the habits", weeks: 3...4, steps: [
                LaunchStep(id: "powerHour", title: "Do your first power hour", detail: "One focused hour of calls and texts. Do it daily and the business follows.", icon: "timer", action: .route(.powerHour)),
                LaunchStep(id: "blocks", title: "Set your time blocks", detail: "Protect prospecting time before the day fills up.", icon: "clock.fill", action: .route(.timeBlocks)),
                LaunchStep(id: "targets", title: lex.isKW ? "Set up your 4-1-1" : "Set your weekly targets", detail: "Calls, appointments and videos per week, tracked for you.", icon: "checklist.checked", action: .route(.scorecard)),
                LaunchStep(id: "objections", title: "Practice your objection handlers", detail: "Know what to say when someone says they have a cousin in real estate.", icon: "bubble.left.and.bubble.right.fill", action: .route(.objections))
            ]),
            LaunchPhase(id: "visible", title: "Get in front of people", weeks: 5...8, steps: [
                LaunchStep(id: "openHouse", title: "Hold an open house for a teammate", detail: "No listings yet? Ask a teammate. Open houses are where new agents meet buyers.", icon: "house.fill", action: .route(.team)),
                LaunchStep(id: "farm", title: "Pick a farm area", detail: "One neighborhood you'll own with mail, door knocks and videos.", icon: "map.fill", action: .route(.farm)),
                LaunchStep(id: "weekPlan", title: "Post 3 videos a week", detail: "We'll plan the topics. You just film.", icon: "calendar.badge.plus", action: .route(.weekPlan)),
                LaunchStep(id: "touch", title: lex.isKW ? "Put everyone you meet on an 8x8" : "Put everyone you meet on an 8 week plan", detail: "8 touches in 8 weeks turns a new contact into someone who remembers your name.", icon: "point.3.filled.connected.trianglepath.dotted", action: .route(.touchPlans)),
                LaunchStep(id: "pros", title: "Line up your trusted pros", detail: "Clients will ask you for a lender, inspector and movers. Have answers ready.", icon: "hammer.fill", action: .route(.partners))
            ]),
            LaunchPhase(id: "close", title: "Get to your first closing", weeks: 9...13, steps: [
                LaunchStep(id: "contract", title: "Learn the contract timeline", detail: "Deposit, inspection, loan approval and closing dates, tracked for each deal.", icon: "doc.text.fill", action: .route(.deals)),
                LaunchStep(id: "buyerCosts", title: "Know your buyer costs", detail: "Walk a buyer through cash to close with confidence.", icon: "dollarsign.circle.fill", action: .route(.buyerCosts)),
                LaunchStep(id: "plan", title: "Write your first year business plan", detail: "Your income goal worked back to calls and videos a week.", icon: "target", action: .route(.businessPlan)),
                LaunchStep(id: "newsletter", title: "Send your first newsletter", detail: "Stay in front of your 100 contacts every month.", icon: "envelope.fill", action: .route(.newsletter))
            ])
        ]
    }

    static var stepCount: Int { phases(Lexicon(isKW: false)).reduce(0) { $0 + $1.steps.count } }

    static func announcement(name: String, office: String, city: String) -> String {
        "I have some exciting news! I'm officially a licensed real estate agent\(office.isEmpty ? "" : " with \(office)") here in \(city). Whether you're thinking about buying, selling or just curious what your home is worth, I'd love to help. And if you know anyone making a move, I'd be grateful for the introduction. \(name)"
    }

    static func personalText(name: String) -> String {
        let first = name.split(separator: " ").first.map(String.init) ?? name
        return "Hey! Quick news: I just got my real estate license. I'm not asking you to buy a house, ha. But if you ever hear of anyone thinking about moving, would you keep me in mind? It would mean a lot. \(first)"
    }
}
