import Foundation

/// Flags wording in listing remarks, captions and ads that can read as a
/// preference for or against a protected group, and suggests a fix.
/// The rule of thumb: describe the property, not the people who should live there.
enum FairHousingCheck {
    enum Level: Int, Comparable {
        case style, caution, high
        static func < (lhs: Level, rhs: Level) -> Bool { lhs.rawValue < rhs.rawValue }

        var title: String {
            switch self {
            case .high: return "Change this"
            case .caution: return "Be careful"
            case .style: return "Better wording"
            }
        }
    }

    struct Rule {
        let pattern: String
        let level: Level
        let topic: String
        let why: String
        /// A drop in replacement, when one exists.
        let replacement: String?
    }

    struct Finding: Identifiable, Hashable {
        let id = UUID()
        let phrase: String
        let range: Range<String.Index>
        let level: Level
        let topic: String
        let why: String
        let replacement: String?

        static func == (lhs: Finding, rhs: Finding) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    private static let familial = "Familial status"
    private static let religion = "Religion"
    private static let race = "Race, color or national origin"
    private static let disability = "Disability"
    private static let sex = "Sex"
    private static let age = "Age and familial status"
    private static let steering = "Steering"
    private static let local = "Local rules"

    static let rules: [Rule] = [
        // Familial status and age
        Rule(pattern: #"perfect for (a )?(young )?famil(y|ies)"#, level: .high, topic: familial, why: "Says who should live there. Describe the space instead.", replacement: "room for everyone"),
        Rule(pattern: #"ideal for (a )?(young )?famil(y|ies)"#, level: .high, topic: familial, why: "Says who should live there. Describe the space instead.", replacement: "room for everyone"),
        Rule(pattern: #"great for (a )?(young )?famil(y|ies)"#, level: .high, topic: familial, why: "Says who should live there. Describe the space instead.", replacement: "room for everyone"),
        Rule(pattern: #"family[ -]friendly (neighborhood|community|street|area)"#, level: .caution, topic: familial, why: "Can suggest a preference for households with children.", replacement: "neighborhood with parks nearby"),
        Rule(pattern: #"family neighborhood"#, level: .caution, topic: familial, why: "Can suggest a preference for households with children.", replacement: "neighborhood with parks nearby"),
        Rule(pattern: #"no (kids|children)"#, level: .high, topic: familial, why: "Excluding children is not allowed outside qualifying 55 and over or 62 and over housing.", replacement: nil),
        Rule(pattern: #"adults? only"#, level: .high, topic: familial, why: "Only allowed for housing that legally qualifies as 55 and over or 62 and over. If it does, say that instead.", replacement: nil),
        Rule(pattern: #"empty[ -]nesters?"#, level: .caution, topic: age, why: "Describes a type of buyer, not the home.", replacement: "low maintenance living"),
        Rule(pattern: #"(perfect|ideal|great) for (singles|a single person|a couple|couples|newlyweds|retirees|seniors|young professionals|students)"#, level: .high, topic: age, why: "Says who should live there. Describe the space instead.", replacement: "easy to live in"),
        Rule(pattern: #"bachelor(ette)? pad"#, level: .caution, topic: sex, why: "Suggests a preferred buyer by sex and family status.", replacement: "stylish retreat"),
        Rule(pattern: #"mature (individual|person|couple|adults?)"#, level: .high, topic: age, why: "Age preference for a buyer or tenant.", replacement: nil),
        Rule(pattern: #"(senior|elderly)( citizens?)?( living| community)?"#, level: .caution, topic: age, why: "Fine for qualifying 55 and over communities. Otherwise describe features like single story or no steps.", replacement: nil),

        // Religion
        Rule(pattern: #"(walking distance|steps|close|minutes) (to|from) (the |a )?(church|churches|synagogue|temple|mosque)"#, level: .caution, topic: religion, why: "Can read as a preference for buyers of one faith. Name it as a landmark among others, or leave it out.", replacement: nil),
        Rule(pattern: #"(christian|catholic|jewish|muslim) (home|family|neighborhood|community|area)"#, level: .high, topic: religion, why: "Religious preference for buyers or neighbors.", replacement: nil),

        // Race, color, national origin, steering
        Rule(pattern: #"exclusive (neighborhood|community|area|enclave)"#, level: .caution, topic: race, why: "Has been used to signal who is welcome. Describe what's there instead.", replacement: "sought after neighborhood"),
        Rule(pattern: #"(integrated|ethnic|diverse|hispanic|latino|asian|white|black|african american) (neighborhood|community|area)"#, level: .high, topic: race, why: "Describes the people who live there.", replacement: nil),
        Rule(pattern: #"english[ -]only"#, level: .high, topic: race, why: "Can discriminate by national origin.", replacement: nil),
        Rule(pattern: #"(safe|safest|low[ -]crime|crime[ -]free) (neighborhood|area|community|street)"#, level: .caution, topic: steering, why: "Safety claims can steer buyers. Point people to public crime maps and let them decide.", replacement: "quiet street"),
        Rule(pattern: #"(good|great|best|top[ -]rated|excellent) school(s| district)"#, level: .caution, topic: steering, why: "School quality claims can steer. Name the assigned schools and suggest buyers check ratings themselves.", replacement: "zoned for [school names]"),
        Rule(pattern: #"desirable (neighborhood|area)"#, level: .style, topic: steering, why: "Vague. Say what makes it desirable.", replacement: nil),

        // Disability
        Rule(pattern: #"handicap(ped)?[ -]?(accessible)?"#, level: .caution, topic: disability, why: "Outdated wording.", replacement: "accessible"),
        Rule(pattern: #"(not suitable|no good) for (wheelchairs?|disabled|the disabled|handicapped)"#, level: .high, topic: disability, why: "Excludes people with disabilities. Describe the feature, like stairs or no elevator.", replacement: "second floor, no elevator"),
        Rule(pattern: #"able[ -]bodied"#, level: .high, topic: disability, why: "Excludes people with disabilities.", replacement: nil),
        Rule(pattern: #"must be able to (climb|walk)"#, level: .high, topic: disability, why: "Describe the feature (stairs, steep driveway) instead of the buyer.", replacement: nil),
        Rule(pattern: #"no (wheelchairs?|service animals|emotional support animals)"#, level: .high, topic: disability, why: "Assistance animals and mobility aids are protected.", replacement: nil),

        // Sex
        Rule(pattern: #"man cave"#, level: .style, topic: sex, why: "Many MLSs prefer neutral wording.", replacement: "bonus room"),
        Rule(pattern: #"(perfect|ideal) for (a )?(man|woman|men|women|gentleman|lady|ladies)"#, level: .high, topic: sex, why: "Preference by sex.", replacement: nil),

        // Style many MLSs ask for
        Rule(pattern: #"master (bedroom|bed|suite|bath|bathroom|closet)"#, level: .style, topic: "MLS wording", why: "Most MLSs and builders now say primary.", replacement: nil),

        // Local rules
        Rule(pattern: #"no section 8|no housing vouchers?|no vouchers"#, level: .caution, topic: local, why: "Some Florida counties and cities protect source of income. Check local rules before using this.", replacement: nil),
        Rule(pattern: #"no students"#, level: .caution, topic: local, why: "Some local rules protect student status. Check before using this.", replacement: nil)
    ]

    static func check(_ text: String) -> [Finding] {
        var findings: [Finding] = []
        var used: [Range<String.Index>] = []
        for rule in rules {
            guard let regex = try? NSRegularExpression(pattern: "\\b" + rule.pattern + "\\b", options: [.caseInsensitive]) else { continue }
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                guard let range = Range(match.range, in: text) else { continue }
                if used.contains(where: { $0.overlaps(range) }) { continue }
                used.append(range)
                let phrase = String(text[range])
                var replacement = rule.replacement
                if rule.pattern.hasPrefix("master"), let word = phrase.split(separator: " ").last {
                    replacement = "primary \(word)"
                }
                findings.append(Finding(phrase: phrase, range: range, level: rule.level, topic: rule.topic, why: rule.why, replacement: replacement.map { matchCase(of: phrase, $0) }))
            }
        }
        return findings.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }

    /// Applies every finding that has a drop in replacement.
    static func fixAll(_ text: String) -> String {
        var result = text
        for finding in check(text).reversed() {
            guard let replacement = finding.replacement, !replacement.contains("[") else { continue }
            if let range = Range(NSRange(finding.range, in: text), in: result) {
                result.replaceSubrange(range, with: replacement)
            }
        }
        return result
    }

    private static func matchCase(of original: String, _ replacement: String) -> String {
        guard let first = original.first, first.isUppercase else { return replacement }
        return replacement.prefix(1).uppercased() + replacement.dropFirst()
    }
}
