import Foundation

/// Monthly principal and interest on a fixed rate loan.
enum Mortgage {
    static func payment(loan: Double, ratePercent: Double, years: Int = 30) -> Double {
        guard loan > 0 else { return 0 }
        let n = Double(years * 12)
        let r = ratePercent / 100 / 12
        guard r > 0 else { return loan / n }
        return loan * r / (1 - pow(1 + r, -n))
    }

    /// Loan balance left after a number of monthly payments.
    static func balance(loan: Double, ratePercent: Double, years: Int = 30, afterMonths months: Int) -> Double {
        guard loan > 0 else { return 0 }
        let r = ratePercent / 100 / 12
        let pay = payment(loan: loan, ratePercent: ratePercent, years: years)
        guard r > 0 else { return max(loan - pay * Double(months), 0) }
        let k = pow(1 + r, Double(months))
        return max(loan * k - pay * (k - 1) / r, 0)
    }
}

// MARK: - How much home can I afford

struct Affordability {
    enum LoanType: String, CaseIterable, Identifiable, Codable {
        case conventional, fha, va
        var id: String { rawValue }
        var title: String {
            switch self {
            case .conventional: return "Conventional"
            case .fha: return "FHA"
            case .va: return "VA"
            }
        }
        /// Housing payment and total debt limits as a share of gross monthly income.
        var ratios: (front: Double, back: Double) {
            switch self {
            case .conventional: return (0.28, 0.36)
            case .fha: return (0.31, 0.43)
            case .va: return (0.41, 0.41)
            }
        }
        var minDownPercent: Double {
            switch self {
            case .conventional: return 3
            case .fha: return 3.5
            case .va: return 0
            }
        }
    }

    var annualIncome: Double
    var monthlyDebts: Double
    var downPayment: Double
    var ratePercent: Double
    var loanType: LoanType = .conventional
    var taxRatePercent: Double = 1.6
    var annualInsurance: Double = 4_000
    var monthlyHOA: Double = 0

    struct Breakdown {
        var price: Double
        var loan: Double
        var principalInterest: Double
        var taxes: Double
        var insurance: Double
        var mortgageInsurance: Double
        var hoa: Double
        var total: Double { principalInterest + taxes + insurance + mortgageInsurance + hoa }
        var cashToClose: Double
    }

    func breakdown(price: Double) -> Breakdown {
        let minDown = price * loanType.minDownPercent / 100
        let down = min(max(downPayment, minDown), price)
        var loan = price - down
        var mi = 0.0
        switch loanType {
        case .conventional:
            if down / max(price, 1) < 0.20 { mi = loan * 0.006 / 12 }
        case .fha:
            loan += loan * 0.0175
            mi = loan * 0.0055 / 12
        case .va:
            if down / max(price, 1) < 0.05 { loan += loan * 0.0215 }
        }
        let pi = Mortgage.payment(loan: loan, ratePercent: ratePercent)
        return Breakdown(
            price: price,
            loan: loan,
            principalInterest: pi,
            taxes: price * taxRatePercent / 100 / 12,
            insurance: annualInsurance / 12,
            mortgageInsurance: mi,
            hoa: monthlyHOA,
            cashToClose: down + price * 0.03
        )
    }

    /// The most a lender is likely to allow each month for the house.
    var maxHousingPayment: Double {
        let monthly = annualIncome / 12
        return max(min(monthly * loanType.ratios.front, monthly * loanType.ratios.back - monthlyDebts), 0)
    }

    /// Highest price whose full monthly payment fits the limit, to the nearest $1,000.
    var maxPrice: Double {
        let limit = maxHousingPayment
        guard limit > 0 else { return 0 }
        var low = 0.0
        var high = 5_000_000.0
        for _ in 0..<40 {
            let mid = (low + high) / 2
            if breakdown(price: mid).total <= limit { low = mid } else { high = mid }
        }
        return (low / 1_000).rounded(.down) * 1_000
    }
}

// MARK: - Rent or buy

struct RentVsBuy {
    var price: Double
    var downPercent: Double
    var ratePercent: Double
    var rent: Double
    var appreciationPercent: Double = 4
    var rentIncreasePercent: Double = 4
    var taxRatePercent: Double = 1.6
    var annualInsurance: Double = 4_000
    var monthlyHOA: Double = 0

    struct Year: Identifiable {
        let id: Int
        var rentPaid: Double
        var ownCost: Double
        var equity: Double
        /// Positive means buying came out ahead by this much.
        var buyAdvantage: Double
    }

    /// Year by year totals. Owning counts payments, taxes, insurance, upkeep,
    /// buying costs and selling costs, minus the equity you'd walk away with.
    func years(_ count: Int = 10) -> [Year] {
        let down = price * downPercent / 100
        let loan = price - down
        let pi = Mortgage.payment(loan: loan, ratePercent: ratePercent)
        let pmi = downPercent < 20 ? loan * 0.006 / 12 : 0
        var rentPaid = 0.0
        var monthlyRent = rent
        var ownPaid = down + price * 0.03
        var result: [Year] = []
        for year in 1...count {
            rentPaid += monthlyRent * 12
            monthlyRent *= 1 + rentIncreasePercent / 100
            let value = price * pow(1 + appreciationPercent / 100, Double(year))
            ownPaid += pi * 12 + pmi * 12 + value * taxRatePercent / 100 + annualInsurance + monthlyHOA * 12 + value * 0.01
            let balance = Mortgage.balance(loan: loan, ratePercent: ratePercent, afterMonths: year * 12)
            let equity = value - balance - value * 0.06
            let net = ownPaid - equity
            result.append(Year(id: year, rentPaid: rentPaid, ownCost: net, equity: equity, buyAdvantage: rentPaid - net))
        }
        return result
    }

    /// First year buying beats renting, if it does within 10 years.
    var breakEvenYear: Int? { years().first { $0.buyAdvantage > 0 }?.id }
}

// MARK: - Comparing offers

struct OfferEntry: Identifiable, Codable, Hashable {
    enum Financing: String, CaseIterable, Identifiable, Codable {
        case cash, conventional, fha, va
        var id: String { rawValue }
        var title: String {
            switch self {
            case .cash: return "Cash"
            case .conventional: return "Conventional"
            case .fha: return "FHA"
            case .va: return "VA"
            }
        }
    }

    var id = UUID()
    var buyerName: String
    var price: Double
    var financing: Financing = .conventional
    var downPercent: Double = 20
    var escrowDeposit: Double = 10_000
    var sellerCredit: Double = 0
    var buyerAgentPercent: Double = 2.5
    var inspectionDays: Int = 15
    var appraisalGap: Double = 0
    var closingDays: Int = 30
    var saleContingency = false
    var notes: String = ""

    /// 0 to 100: how likely this offer is to make it to closing as written.
    var strength: Int {
        var score = 50.0
        switch financing {
        case .cash: score += 20
        case .conventional: score += downPercent >= 20 ? 10 : 5
        case .fha, .va: score += 0
        }
        score += min(escrowDeposit / max(price, 1) * 100, 5) * 2
        score += inspectionDays <= 7 ? 8 : inspectionDays <= 10 ? 4 : 0
        if appraisalGap > 0 && financing != .cash { score += min(appraisalGap / max(price, 1) * 100 * 2, 10) }
        if saleContingency { score -= 20 }
        if closingDays <= 21 { score += 4 }
        return Int(min(max(score, 0), 100))
    }

    var strengthNotes: [String] {
        var notes: [String] = []
        if financing == .cash { notes.append("Cash, no loan or appraisal risk") }
        if escrowDeposit / max(price, 1) >= 0.03 { notes.append("Strong deposit") }
        if inspectionDays <= 7 { notes.append("Short inspection period") }
        if appraisalGap > 0 && financing != .cash { notes.append("Covers up to \(appraisalGap.compactMoney) appraisal gap") }
        if saleContingency { notes.append("Needs to sell their home first") }
        if financing == .fha || financing == .va { notes.append("\(financing.title) appraisal and repair rules apply") }
        return notes
    }
}
