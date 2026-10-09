import Foundation

/// A home under contract, tracked from the effective date to closing.
struct Deal: Identifiable, Hashable, Codable {
    var id = UUID()
    var address: String
    var clientName: String
    var side: Testimonial.Side
    var price: Int
    var effectiveDate: Date
    var closingDate: Date
    var commissionPercent: Double = 3
    var milestones: [DealMilestone] = []
    var isClosed = false
    var remindersOn = false

    var commission: Double { Double(price) * commissionPercent / 100 }
    var priceLabel: String { price.formatted(.currency(code: "USD").precision(.fractionLength(0))) }
    var nextMilestone: DealMilestone? { milestones.filter { !$0.isDone }.min { $0.dueDate < $1.dueDate } }
    var progress: Double { milestones.isEmpty ? 0 : Double(milestones.filter(\.isDone).count) / Double(milestones.count) }
    var daysToClose: Int { Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: closingDate)).day ?? 0 }

    /// Default timelines from the Florida Realtors/Florida Bar AS IS contract.
    /// Every contract can change them, so agents can edit each date.
    static func defaultMilestones(effective: Date, closing: Date, financed: Bool) -> [DealMilestone] {
        func day(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: effective) ?? effective }
        var list = [
            DealMilestone(title: "Initial escrow deposit due", detail: "Usually within 3 days of the effective date.", dueDate: day(3)),
            DealMilestone(title: "Inspection period ends", detail: "15 days by default. Inspections, wind mit and 4 point done before this.", dueDate: day(15))
        ]
        if financed {
            list += [
                DealMilestone(title: "Loan application submitted", detail: "Buyer applies within 5 days by default.", dueDate: day(5)),
                DealMilestone(title: "Appraisal back", detail: "Ask the lender for the appraisal date.", dueDate: day(21)),
                DealMilestone(title: "Loan approval deadline", detail: "30 days by default.", dueDate: day(30))
            ]
        }
        list += [
            DealMilestone(title: "Insurance bound", detail: "Florida insurance can take time. Get the binder early.", dueDate: Calendar.current.date(byAdding: .day, value: -10, to: closing) ?? closing),
            DealMilestone(title: "Final walkthrough", detail: "Check repairs, appliances and that the home is as agreed.", dueDate: Calendar.current.date(byAdding: .day, value: -1, to: closing) ?? closing),
            DealMilestone(title: "Closing day", detail: "Keys, photos and a just sold post.", dueDate: closing)
        ]
        return list.sorted { $0.dueDate < $1.dueDate }
    }
}

struct DealMilestone: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var detail: String
    var dueDate: Date
    var isDone = false

    var isOverdue: Bool { !isDone && Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(for: Date()) }
}

enum DealCopy {
    static func timeline(_ deal: Deal, agentName: String) -> String {
        let me = agentName.split(separator: " ").first.map(String.init) ?? agentName
        let first = deal.clientName.split(separator: " ").first.map(String.init) ?? deal.clientName
        var lines = ["Hi \(first)! Here's our timeline for \(deal.address):", ""]
        for milestone in deal.milestones {
            lines.append("\(milestone.isDone ? "✓" : "•") \(milestone.dueDate.formatted(.dateTime.month(.abbreviated).day())): \(milestone.title)")
        }
        lines += ["", "I'll keep you posted at every step. \(me)"]
        return lines.joined(separator: "\n")
    }
}

extension Date {
    /// "today", "tomorrow" or "on Tue, Oct 14".
    var relativeDayLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "is today" }
        if calendar.isDateInTomorrow(self) { return "is tomorrow" }
        return "is \(formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))"
    }
}
