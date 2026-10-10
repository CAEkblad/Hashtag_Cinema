import Foundation

/// Someone on a touch plan: 8 touches in 8 weeks for a new contact,
/// then 33 touches a year to stay top of mind.
struct TouchContact: Identifiable, Codable, Hashable {
    enum Plan: String, Codable, CaseIterable, Identifiable {
        case eightWeek, yearRound
        var id: String { rawValue }
        func title(_ lex: Lexicon) -> String { self == .eightWeek ? lex.newContactPlan : lex.yearPlan }
    }

    var id = UUID()
    var name: String
    var phone: String = ""
    var plan: Plan
    var start: Date
    var done: [Int] = []
    var leadID: UUID?

    var firstName: String { name.split(separator: " ").first.map(String.init) ?? name }
    var steps: [TouchStep] { TouchStep.steps(for: plan) }
    var isComplete: Bool { steps.allSatisfy { done.contains($0.id) } }
    var nextStep: TouchStep? { steps.first { !done.contains($0.id) } }

    func date(of step: TouchStep) -> Date {
        Calendar.current.date(byAdding: .day, value: step.dayOffset, to: Calendar.current.startOfDay(for: start)) ?? start
    }

    /// "today", "tomorrow", "overdue since Oct 6" or "Tue, Oct 14".
    func whenLabel(of step: TouchStep) -> String {
        let cal = Calendar.current
        let day = date(of: step)
        let today = cal.startOfDay(for: Date())
        if day < today { return "overdue since \(day.formatted(.dateTime.month(.abbreviated).day()))" }
        if cal.isDateInToday(day) { return "today" }
        if cal.isDateInTomorrow(day) { return "tomorrow" }
        return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    /// Steps whose date has come and that aren't done yet.
    var due: [TouchStep] {
        let today = Calendar.current.startOfDay(for: Date())
        return steps.filter { !done.contains($0.id) && date(of: $0) <= today }
    }
}

struct TouchStep: Identifiable, Hashable {
    enum Kind: String {
        case call, text, note, mail, popBy, email, social, event, video

        var title: String {
            switch self {
            case .call: return "Call"
            case .text: return "Text"
            case .note: return "Handwritten note"
            case .mail: return "Mailer"
            case .popBy: return "Pop by"
            case .email: return "Email"
            case .social: return "Social"
            case .event: return "Event invite"
            case .video: return "Video text"
            }
        }

        var icon: String {
            switch self {
            case .call: return "phone.fill"
            case .text: return "message.fill"
            case .note: return "pencil.and.scribble"
            case .mail: return "envelope.open.fill"
            case .popBy: return "gift.fill"
            case .email: return "envelope.fill"
            case .social: return "heart.fill"
            case .event: return "party.popper.fill"
            case .video: return "video.fill"
            }
        }
    }

    let id: Int
    let dayOffset: Int
    let kind: Kind
    let title: String
    /// What to say. {name} and {me} are filled in.
    let script: String

    func message(to contact: TouchContact, from agentName: String) -> String {
        let me = agentName.split(separator: " ").first.map(String.init) ?? agentName
        return script.replacingOccurrences(of: "{name}", with: contact.firstName).replacingOccurrences(of: "{me}", with: me)
    }

    static func steps(for plan: TouchContact.Plan) -> [TouchStep] {
        plan == .eightWeek ? eightWeek : yearRound
    }

    static let eightWeek: [TouchStep] = [
        TouchStep(id: 1, dayOffset: 0, kind: .note, title: "Great to meet you note", script: "{name}, it was great connecting with you! I'm here for anything real estate, even just questions. Talk soon, {me}"),
        TouchStep(id: 2, dayOffset: 7, kind: .call, title: "Quick check in call", script: "Hi {name}, it's {me}. Just calling to say thanks again and see if anything came up I can help with."),
        TouchStep(id: 3, dayOffset: 14, kind: .email, title: "Send something useful", script: "Hi {name}! Thought you'd like this month's market update for your area. Happy to explain any of it. {me}"),
        TouchStep(id: 4, dayOffset: 21, kind: .video, title: "Short video hello", script: "Hey {name}! Recorded a quick video on what's happening in the market right now. Let me know what you think! {me}"),
        TouchStep(id: 5, dayOffset: 28, kind: .popBy, title: "Small pop by gift", script: "Dropped off a little something for you, {name}. Have a great week! {me}"),
        TouchStep(id: 6, dayOffset: 35, kind: .text, title: "Home value offer", script: "Hi {name}, curious what your home would sell for today? I can put together a free, no pressure value report. {me}"),
        TouchStep(id: 7, dayOffset: 42, kind: .social, title: "Engage on social", script: "Like and comment on one of {name}'s posts. Keep it genuine."),
        TouchStep(id: 8, dayOffset: 49, kind: .call, title: "Coffee and referral ask", script: "Hi {name}, it's {me}. Would love to grab coffee and hear how things are going. And if you ever hear of anyone thinking about moving, I'd be grateful for the intro.")
    ]

    static let yearRound: [TouchStep] = {
        var steps: [TouchStep] = []
        var id = 1
        func add(_ day: Int, _ kind: Kind, _ title: String, _ script: String) {
            steps.append(TouchStep(id: id, dayOffset: day, kind: kind, title: title, script: script))
            id += 1
        }
        for month in 0..<12 {
            add(month * 30, .email, "Monthly newsletter", "Hi {name}! Here's this month's update with what's selling near you and a few homeowner tips. {me}")
        }
        for quarter in 0..<4 {
            add(quarter * 91 + 10, .call, "Quarterly check in call", "Hi {name}, it's {me}! Just checking in. How's everything with the house and the family?")
            add(quarter * 91 + 45, .popBy, "Seasonal pop by", "Dropped off a little seasonal treat for you, {name}! {me}")
        }
        for slot in 0..<6 {
            add(slot * 60 + 20, slot.isMultiple(of: 2) ? .social : .text, slot.isMultiple(of: 2) ? "Engage on social" : "Thinking of you text", slot.isMultiple(of: 2) ? "Comment on one of {name}'s posts. Keep it genuine." : "Hey {name}, saw something that made me think of you. Hope you're doing great! {me}")
        }
        add(120, .event, "Client event invite", "{name}, I'm hosting a client appreciation event and would love for you to come. Bring a friend! {me}")
        add(300, .event, "Holiday event invite", "{name}, you're invited to my holiday get together. It wouldn't be the same without you! {me}")
        add(75, .mail, "Market update mailer", "Mail a printed market update for {name}'s neighborhood.")
        add(255, .mail, "Home value mailer", "Mail {name} a home value update with a note offering a full report.")
        add(150, .video, "Video market update", "Hey {name}! Quick video on what homes like yours are selling for right now. {me}")
        add(330, .note, "Holiday card", "Happy holidays, {name}! Thank you for being part of my year. {me}")
        add(360, .call, "Year end thank you call", "Hi {name}, it's {me}. Just calling to say thank you for a great year. Anything I can help with for the new one?")
        return steps.sorted { $0.dayOffset < $1.dayOffset }
    }()
}

extension TouchContact {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        phone = try c.decodeIfPresent(String.self, forKey: .phone) ?? ""
        plan = try c.decodeIfPresent(Plan.self, forKey: .plan) ?? .eightWeek
        start = try c.decodeIfPresent(Date.self, forKey: .start) ?? Date()
        done = try c.decodeIfPresent([Int].self, forKey: .done) ?? []
        leadID = try c.decodeIfPresent(UUID.self, forKey: .leadID)
    }
}
