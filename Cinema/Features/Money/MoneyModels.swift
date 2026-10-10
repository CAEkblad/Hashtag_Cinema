import Foundation

/// How the agent's brokerage split works. Defaults follow a typical Keller Williams
/// setup (company split up to a cap, plus a franchise royalty up to its own cap),
/// but every number is editable for any brokerage.
struct SplitPlan: Codable, Equatable {
    var capYearStart: Date = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: Date()), month: 1, day: 1)) ?? Date()
    var companySplitPercent: Double = 30
    var capAmount: Double = 15_000
    var royaltyPercent: Double = 6
    var royaltyCap: Double = 3_000
    var priorGCI: Double = 0
    var perDealFee: Double = 0

    var capYearEnd: Date { Calendar.current.date(byAdding: .year, value: 1, to: capYearStart) ?? capYearStart }
}

/// The result of running a year of closings through the split plan.
struct SplitSummary {
    var gross: Double = 0
    var companyPaid: Double = 0
    var royaltyPaid: Double = 0
    var fees: Double = 0
    var net: Double { gross - companyPaid - royaltyPaid - fees }

    static func run(_ plan: SplitPlan, closings: [Double]) -> SplitSummary {
        var summary = SplitSummary()
        let all = (plan.priorGCI > 0 ? [plan.priorGCI] : []) + closings
        for (index, gross) in all.enumerated() {
            summary.gross += gross
            let company = min(gross * plan.companySplitPercent / 100, max(0, plan.capAmount - summary.companyPaid))
            let royalty = min(gross * plan.royaltyPercent / 100, max(0, plan.royaltyCap - summary.royaltyPaid))
            summary.companyPaid += company
            summary.royaltyPaid += royalty
            // Prior GCI is a lump sum, so per deal fees only apply to tracked closings.
            if !(plan.priorGCI > 0 && index == 0) { summary.fees += plan.perDealFee }
        }
        return summary
    }

    func capProgress(_ plan: SplitPlan) -> Double { plan.capAmount > 0 ? min(1, companyPaid / plan.capAmount) : 1 }

    /// GCI still needed before the company split stops.
    func gciToCap(_ plan: SplitPlan) -> Double {
        guard plan.companySplitPercent > 0 else { return 0 }
        return max(0, plan.capAmount - companyPaid) / (plan.companySplitPercent / 100)
    }
}

/// What to put aside for taxes, and when estimated payments are due.
struct TaxPlan: Codable, Equatable {
    var setAsidePercent: Double = 25
    var remindersOn = false

    /// Federal estimated tax due dates for a tax year, moved to Monday when they land on a weekend.
    static func dueDates(taxYear: Int) -> [(label: String, date: Date)] {
        let raw: [(String, Int, Int, Int)] = [
            ("Q1 estimated tax", taxYear, 4, 15),
            ("Q2 estimated tax", taxYear, 6, 15),
            ("Q3 estimated tax", taxYear, 9, 15),
            ("Q4 estimated tax", taxYear + 1, 1, 15)
        ]
        let calendar = Calendar.current
        return raw.compactMap { label, year, month, day in
            guard var date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { return nil }
            while calendar.isDateInWeekend(date) {
                date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            }
            return (label, date)
        }
    }

    /// The next due date from today, looking across this tax year and the next.
    static func nextDue(from now: Date = Date()) -> (label: String, date: Date)? {
        let year = Calendar.current.component(.year, from: now)
        return (dueDates(taxYear: year - 1) + dueDates(taxYear: year) + dueDates(taxYear: year + 1))
            .filter { $0.date >= Calendar.current.startOfDay(for: now) }
            .min { $0.date < $1.date }
    }
}
