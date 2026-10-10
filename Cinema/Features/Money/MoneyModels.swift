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

    /// Which cap year a date falls in, counting from the saved start (0 is the first one).
    func capYearIndex(for date: Date) -> Int {
        let calendar = Calendar.current
        var index = calendar.dateComponents([.year], from: capYearStart, to: date).year ?? 0
        if date < start(ofIndex: index) { index -= 1 }
        return index
    }

    func start(ofIndex index: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: index, to: capYearStart) ?? capYearStart
    }

    /// The cap year we're in now. Rolls forward on its own every year.
    var currentYearStart: Date { start(ofIndex: max(0, capYearIndex(for: Date()))) }
    var capYearEnd: Date { Calendar.current.date(byAdding: .year, value: 1, to: currentYearStart) ?? currentYearStart }

    /// Prior GCI only belongs to the first cap year the agent set up.
    var effectivePriorGCI: Double { capYearIndex(for: Date()) <= 0 ? priorGCI : 0 }

    /// What the agent kept on each closing, in order, with the cap resetting every cap year.
    func nets(for closings: [(date: Date, gross: Double)]) -> [(date: Date, net: Double)] {
        var paid: [Int: (company: Double, royalty: Double)] = [:]
        var result: [(date: Date, net: Double)] = []
        func take(_ gross: Double, index: Int, fee: Double) -> Double {
            var totals = paid[index] ?? (0, 0)
            let company = min(gross * companySplitPercent / 100, max(0, capAmount - totals.company))
            let royalty = min(gross * royaltyPercent / 100, max(0, royaltyCap - totals.royalty))
            totals.company += company
            totals.royalty += royalty
            paid[index] = totals
            return gross - company - royalty - fee
        }
        if priorGCI > 0 {
            result.append((capYearStart, take(priorGCI, index: 0, fee: 0)))
        }
        for closing in closings.sorted(by: { $0.date < $1.date }) {
            result.append((closing.date, take(closing.gross, index: capYearIndex(for: closing.date), fee: perDealFee)))
        }
        return result
    }
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
        let prior = plan.effectivePriorGCI
        let all = (prior > 0 ? [prior] : []) + closings
        for (index, gross) in all.enumerated() {
            summary.gross += gross
            let company = min(gross * plan.companySplitPercent / 100, max(0, plan.capAmount - summary.companyPaid))
            let royalty = min(gross * plan.royaltyPercent / 100, max(0, plan.royaltyCap - summary.royaltyPaid))
            summary.companyPaid += company
            summary.royaltyPaid += royalty
            // Prior GCI is a lump sum, so per deal fees only apply to tracked closings.
            if !(prior > 0 && index == 0) { summary.fees += plan.perDealFee }
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

    /// Federal estimated tax due dates for a tax year. A date on a weekend or a federal
    /// holiday (MLK Day in January, Emancipation Day in April) moves to the next business day.
    static func dueDates(taxYear: Int) -> [(id: String, label: String, date: Date)] {
        let raw: [(Int, Int, Int, Int)] = [
            (1, taxYear, 4, 15),
            (2, taxYear, 6, 15),
            (3, taxYear, 9, 15),
            (4, taxYear + 1, 1, 15)
        ]
        let calendar = Calendar.current
        return raw.compactMap { quarter, year, month, day in
            guard var date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { return nil }
            while calendar.isDateInWeekend(date) || isHoliday(date) {
                date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            }
            return ("cinema.tax.\(taxYear)-Q\(quarter)", "Q\(quarter) estimated tax", date)
        }
    }

    private static func isHoliday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        guard let year = parts.year, let month = parts.month, let day = parts.day else { return false }
        // MLK Day: third Monday of January.
        if month == 1, parts.weekday == 2, (15...21).contains(day) { return true }
        // Emancipation Day: April 16, observed Friday if Saturday, Monday if Sunday.
        if month == 4, let april16 = calendar.date(from: DateComponents(year: year, month: 4, day: 16)) {
            var observed = april16
            switch calendar.component(.weekday, from: april16) {
            case 7: observed = calendar.date(byAdding: .day, value: -1, to: april16) ?? april16
            case 1: observed = calendar.date(byAdding: .day, value: 1, to: april16) ?? april16
            default: break
            }
            return calendar.isDate(date, inSameDayAs: observed)
        }
        return false
    }

    /// The next due date from today, looking across last, this and next tax year.
    static func nextDue(from now: Date = Date()) -> (id: String, label: String, date: Date)? {
        let year = Calendar.current.component(.year, from: now)
        return (dueDates(taxYear: year - 1) + dueDates(taxYear: year) + dueDates(taxYear: year + 1))
            .filter { $0.date >= Calendar.current.startOfDay(for: now) }
            .min { $0.date < $1.date }
    }
}
