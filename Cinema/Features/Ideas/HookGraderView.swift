import SwiftUI
import UIKit

/// Scores a video's first line and suggests stronger versions.
struct HookGraderView: View {
    @Environment(CinemaStore.self) private var store
    @State private var hook = ""
    @State private var topic = ""
    @State private var openIdea: Idea?

    private var result: HookGrade {
        HookGrader.grade(hook, city: store.homeCity.name, places: Array(store.homeCity.neighborhoods.prefix(12)))
    }

    private var rewrites: [String] {
        HookGrader.rewrites(topic: topic.trimmingCharacters(in: .whitespaces), city: store.homeCity.name)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hook grader")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Type the first thing you'll say on camera. You get a score, what's working, what to fix, and stronger versions to try.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Like: Hey guys, today I want to talk about the market", text: $hook)
                        .inputStyle()
                    TextField("What's the video about? Like closing costs", text: $topic)
                        .inputStyle()
                }
                .cardStyle()

                if !hook.trimmingCharacters(in: .whitespaces).isEmpty {
                    scoreCard
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Try one of these")
                        .font(.cinema(15, weight: .bold))
                    ForEach(rewrites, id: \.self) { line in
                        rewriteRow(line)
                    }
                }
                .cardStyle()

                NavigationLink(value: Route.hooks) {
                    IconRow(icon: "bolt.fill", title: "Hook library", subtitle: "Proven first lines by style")
                        .cardStyle(padding: 14)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Hook grader")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .navigationDestination(item: $openIdea) { idea in
            IdeaDetailView(idea: idea)
        }
    }

    private var scoreCard: some View {
        let grade = result
        let color: Color = grade.score >= 75 ? Theme.success : (grade.score >= 50 ? Theme.warning : Theme.red)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().stroke(color.opacity(0.18), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: CGFloat(grade.score) / 100)
                        .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(grade.score)")
                        .font(.cinema(22, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(width: 70, height: 70)
                VStack(alignment: .leading, spacing: 3) {
                    Text(grade.verdict)
                        .font(.cinema(17, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(grade.wordCount) words, about \(grade.seconds.formatted(.number.precision(.fractionLength(1)))) seconds to say")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            ForEach(grade.checks) { check in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: check.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(check.passed ? Theme.success : Theme.textTertiary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(check.title)
                            .font(.cinema(14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        if !check.passed {
                            Text(check.tip)
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private func rewriteRow(_ line: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(line)
                .font(.cinema(14, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                hook = line
            } label: {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 20))
            }
            .tint(Theme.red)
            .accessibilityLabel("Grade this one")
            Button {
                openIdea = store.addIdea(HookGrader.idea(hook: line, topic: topic, city: store.homeCity.name))
            } label: {
                Image(systemName: "video.badge.plus").font(.system(size: 18))
            }
            .tint(Theme.red)
            .accessibilityLabel("Save as an idea")
        }
        .padding(.vertical, 4)
    }
}

struct HookCheck: Identifiable {
    let id = UUID()
    let title: String
    let passed: Bool
    let tip: String
}

struct HookGrade {
    let score: Int
    let wordCount: Int
    let seconds: Double
    let checks: [HookCheck]

    var verdict: String {
        switch score {
        case 80...: return "Strong hook"
        case 60..<80: return "Good, could be sharper"
        case 40..<60: return "People may scroll past"
        default: return "Needs a rewrite"
        }
    }
}

enum HookGrader {
    private static let strongOpeners = ["stop", "don't", "dont", "never", "why", "how", "what", "if you", "this", "here's", "heres", "pov", "the truth", "nobody", "no one", "before you", "i just", "you won't", "you need", "you're", "this is"]
    private static let weakOpeners = ["hi", "hey", "hello", "my name", "welcome", "so ", "so,", "today i", "today we", "in this video", "um", "okay so", "ok so", "good morning"]
    private static let curiosity = ["secret", "mistake", "nobody tells", "no one tells", "truth", "before you", "wrong", "hidden", "actually", "really", "surprising", "shocked", "crazy", "worst", "best", "never", "regret", "warning", "don't"]

    static func grade(_ raw: String, city: String, places: [String]) -> HookGrade {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = text.lowercased()
        let words = lower.split { !$0.isLetter && !$0.isNumber && $0 != "'" && $0 != "$" }
        let count = words.count
        let seconds = Double(count) / 2.6

        let short = count > 0 && count <= 12
        let opener = strongOpeners.contains { lower.hasPrefix($0) } || (lower.first?.isNumber ?? false)
        let weak = weakOpeners.contains { lower.hasPrefix($0) }
        let speaksToViewer = words.contains { ["you", "your", "you're", "youre", "you'll"].contains(String($0)) }
        let hasNumber = lower.contains { $0.isNumber } || lower.contains("$")
        let local = ([city] + places).contains { !$0.isEmpty && lower.contains($0.lowercased()) }
        let curious = curiosity.contains { lower.contains($0) } || lower.hasSuffix("?")

        let checks = [
            HookCheck(title: "Short enough to say in 3 seconds", passed: short, tip: count > 12 ? "Cut it to 12 words or fewer. Save the details for the next line." : "Write a full first line."),
            HookCheck(title: "Starts strong", passed: opener && !weak, tip: weak ? "Skip the hello. Start with the most interesting thing, like a number, a warning or a question." : "Open with Stop, Don't, Why, How, a number or \"If you...\"."),
            HookCheck(title: "Talks to the viewer", passed: speaksToViewer, tip: "Use you or your so it feels like it's for them."),
            HookCheck(title: "Has a number or price", passed: hasNumber, tip: "Numbers stop thumbs: 3 mistakes, $10K, 30 days."),
            HookCheck(title: "Mentions your area", passed: local, tip: "Name \(city) or a neighborhood so locals know it's for them."),
            HookCheck(title: "Makes them curious", passed: curious, tip: "Hint at a secret, a mistake or a surprise they'll only get by watching.")
        ]

        var score = 10
        if short { score += 20 } else if count <= 18 { score += 8 }
        if opener { score += 18 }
        if weak { score -= 20 }
        if speaksToViewer { score += 12 }
        if hasNumber { score += 12 }
        if local { score += 14 }
        if curious { score += 14 }
        return HookGrade(score: max(0, min(100, score)), wordCount: count, seconds: seconds, checks: checks)
    }

    static func rewrites(topic: String, city: String) -> [String] {
        let subject = topic.isEmpty ? "buying a home" : topic.lowercased()
        return [
            "Stop. Don't start \(subject) in \(city) until you hear this.",
            "3 \(subject) mistakes I see every week in \(city)",
            "Nobody tells you this about \(subject)",
            "Here's what \(subject) really costs in \(city) right now",
            "If you're thinking about \(subject), watch this first"
        ]
    }

    static func idea(hook: String, topic: String, city: String) -> Idea {
        let subject = topic.isEmpty ? "buying a home" : topic
        return Idea(
            title: subject.prefix(1).uppercased() + subject.dropFirst(),
            hook: hook,
            category: .mythBuster,
            shots: ["Talking to camera, close up", "B roll that shows the topic", "End on you pointing to the caption"],
            script: "\(hook) [Give the 3 most useful points about \(subject) in \(city), one sentence each.] Want my full list? Comment GUIDE and I'll send it to you.",
            targetSeconds: 30,
            whyItWorks: "A strong first line keeps people watching past the first 3 seconds, which is what the apps reward.",
            cityName: city
        )
    }
}
