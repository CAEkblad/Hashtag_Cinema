import Foundation

/// The words the app uses for offices, leaders and plans. Generic by default,
/// and Keller Williams' own terms when the agent signs in with a KW email,
/// so KW agents and leaders see the language they already use every day.
struct Lexicon {
    let isKW: Bool

    /// "Market Center" or "brokerage".
    var office: String { isKW ? "Market Center" : "brokerage" }
    var officeTitle: String { isKW ? "Market Center" : "Brokerage" }
    var offices: String { isKW ? "Market Centers" : "brokerages" }

    /// The office leader: "MCA" or "broker".
    var officeLeader: String { isKW ? "MCA" : "broker" }
    var officeLeaderLong: String { isKW ? "Market Center Administrator (MCA)" : "broker or office manager" }

    /// The team leader: "Team Leader" or "team lead".
    var teamLeader: String { isKW ? "Team Leader" : "team lead" }
    var teamLeaders: String { isKW ? "Team Leaders" : "team leads" }

    /// What agents on a team or office are called.
    var agents: String { isKW ? "associates" : "agents" }
    var agentsTitle: String { isKW ? "Associates" : "Agents" }

    /// The weekly goals sheet: "4-1-1" or "weekly scorecard".
    var weeklyPlan: String { isKW ? "4-1-1" : "weekly scorecard" }
    var weeklyPlanTitle: String { isKW ? "My 4-1-1" : "Weekly scorecard" }

    /// The split the office keeps: "company dollar" or "brokerage split".
    var companySplit: String { isKW ? "company dollar" : "brokerage split" }

    /// A deal where both agents are in the same office.
    var inHouse: String { isKW ? "in-house: both sides stay in your Market Center" : "in-house: both sides stay in your brokerage" }

    /// Who leaders are, for "free for ..." lines.
    var leadersList: String { isKW ? "Team Leaders, MCAs and Market Center staff" : "team leads, brokers and office staff" }

    /// Touch plans: KW's 8x8 and 33 Touch, or plain names everywhere else.
    var newContactPlan: String { isKW ? "8x8" : "8 week plan" }
    var newContactPlanLong: String { isKW ? "8x8: 8 touches in 8 weeks" : "8 week plan: 8 touches in 8 weeks" }
    var yearPlan: String { isKW ? "33 Touch" : "year round plan" }
    var yearPlanTitle: String { isKW ? "33 Touch" : "Year round plan" }
    /// For use inside a sentence.
    var newContactPlanInline: String { isKW ? "8x8 (8 touches in 8 weeks)" : "8 week plan (8 touches in 8 weeks)" }
    var yearPlanInline: String { isKW ? "33 Touch plan (33 touches a year)" : "year round plan (33 touches a year)" }
    var yearPlanLong: String { isKW ? "33 Touch: 33 touches a year" : "Year round plan: 33 touches a year" }

    var joinCodePrompt: String { isKW ? "Have a join code from your MCA?" : "Have a join code from your broker?" }
}

extension UserRole {
    func title(_ lex: Lexicon) -> String {
        switch self {
        case .agent: return "Agent"
        case .teamLead: return lex.isKW ? "Team Leader" : "Team lead"
        case .marketCenter: return lex.isKW ? "MCA or Operating Principal" : "Broker or office leader"
        case .brokerageAdmin: return lex.isKW ? "Market Center staff" : "Brokerage admin"
        }
    }

    func subtitle(_ lex: Lexicon) -> String {
        switch self {
        case .agent: return "I market myself and my listings"
        case .teamLead: return "I run a team. Free to promote my team"
        case .marketCenter: return lex.isKW ? "I lead a Market Center. Free to promote it" : "I lead an office or brokerage. Free to promote it"
        case .brokerageAdmin: return lex.isKW ? "I support associates and seats. Free" : "I manage agents and seats. Free"
        }
    }

    func orgWord(_ lex: Lexicon) -> String {
        switch self {
        case .teamLead: return "team"
        case .marketCenter, .brokerageAdmin: return lex.office
        case .agent: return lex.office
        }
    }
}
