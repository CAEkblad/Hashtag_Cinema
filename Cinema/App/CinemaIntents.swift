import AppIntents
import Foundation

/// "Hey Siri, log mileage in CloseUp." Runs without opening the app.
struct LogMileageIntent: AppIntent {
    static var title: LocalizedStringResource = "Log mileage"
    static var description = IntentDescription("Add a business trip to your CloseUp mileage log.")
    static var openAppWhenRun = false

    @Parameter(title: "Miles", requestValueDialog: "How many miles?")
    var miles: Double

    @Parameter(title: "Note", requestValueDialog: "What was the trip for?")
    var note: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let expense = BusinessExpense(date: Date(), category: .mileage, amount: miles, note: note ?? "Logged with Siri")
        if let store = CinemaStore.shared {
            store.addExpense(expense)
        } else {
            CinemaStore.appendExpenseToStorage(expense)
        }
        return .result(dialog: "Logged \(Int(miles.rounded())) miles.")
    }
}

/// "What's my video idea in CloseUp?"
struct TodaysIdeaIntent: AppIntent {
    static var title: LocalizedStringResource = "Today's video idea"
    static var description = IntentDescription("Hear today's video idea, then open CloseUp to film it.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        if let idea = CinemaStore.shared?.ideaOfTheDay {
            return .result(dialog: "Today's idea: \(idea.title). It takes about \(idea.targetSeconds) seconds to film.")
        }
        return .result(dialog: "Opening CloseUp with today's idea.")
    }
}

/// "Check my leads in CloseUp."
struct NewLeadsIntent: AppIntent {
    static var title: LocalizedStringResource = "Check my leads"
    static var description = IntentDescription("Hear how many new leads are waiting for you.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let store = CinemaStore.shared else {
            return .result(dialog: "Open CloseUp to see your leads.")
        }
        let fresh = store.leads.filter { $0.status == .new }
        let due = store.leadsDueForFollowUp.count
        if fresh.isEmpty && due == 0 {
            return .result(dialog: "No new leads right now. Post today's video to bring some in.")
        }
        var line = "You have \(fresh.count) new lead\(fresh.count == 1 ? "" : "s")"
        if let first = fresh.first { line += ", including \(first.name)" }
        if due > 0 { line += ", and \(due) follow up\(due == 1 ? "" : "s") due today" }
        return .result(dialog: "\(line).")
    }
}

struct CinemaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogMileageIntent(),
            phrases: ["Log mileage in \(.applicationName)", "Log a trip in \(.applicationName)"],
            shortTitle: "Log mileage",
            systemImageName: "car.fill"
        )
        AppShortcut(
            intent: TodaysIdeaIntent(),
            phrases: ["What's my video idea in \(.applicationName)", "Today's idea in \(.applicationName)"],
            shortTitle: "Today's idea",
            systemImageName: "lightbulb.fill"
        )
        AppShortcut(
            intent: NewLeadsIntent(),
            phrases: ["Check my leads in \(.applicationName)", "Any new leads in \(.applicationName)"],
            shortTitle: "Check leads",
            systemImageName: "person.badge.plus"
        )
    }
}
