import Charts
import SwiftUI

/// How much home a buyer can likely afford, with the full monthly payment
/// including Florida-sized taxes and insurance.
struct AffordabilityView: View {
    @Environment(CinemaStore.self) private var store
    @State private var calc = Affordability(annualIncome: 120_000, monthlyDebts: 600, downPayment: 30_000, ratePercent: 6.5)

    var body: some View {
        let maxPrice = calc.maxPrice
        let b = calc.breakdown(price: maxPrice)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("How much home?")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("A quick estimate from income, debts and down payment, using common lender limits. Great for a first buyer call.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(spacing: 6) {
                    Text(maxPrice > 0 ? maxPrice.formatted(.currency(code: "USD").precision(.fractionLength(0))) : "Not enough room yet")
                        .font(.cinema(34, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Estimated top price, \(b.total.formatted(.currency(code: "USD").precision(.fractionLength(0)))) a month")
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .cardStyle()

                Picker("Loan", selection: $calc.loanType) {
                    ForEach(Affordability.LoanType.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 14) {
                    CalcSlider(title: "Household income", value: $calc.annualIncome, range: 30_000...500_000, step: 5_000, label: calc.annualIncome.compactMoney + " a year")
                    CalcSlider(title: "Monthly debts", value: $calc.monthlyDebts, range: 0...5_000, step: 50, label: calc.monthlyDebts.compactMoney)
                    CalcSlider(title: "Down payment", value: $calc.downPayment, range: 0...300_000, step: 1_000, label: calc.downPayment.compactMoney)
                    CalcSlider(title: "Interest rate", value: $calc.ratePercent, range: 3...10, step: 0.125, label: String(format: "%.3f%%", calc.ratePercent))
                    CalcSlider(title: "Home insurance", value: $calc.annualInsurance, range: 1_000...15_000, step: 250, label: calc.annualInsurance.compactMoney + " a year")
                    CalcSlider(title: "HOA", value: $calc.monthlyHOA, range: 0...1_500, step: 25, label: calc.monthlyHOA.compactMoney + " a month")
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    line("Principal and interest", b.principalInterest)
                    line("Property taxes", b.taxes)
                    line("Insurance", b.insurance)
                    if b.mortgageInsurance > 0 { line(calc.loanType == .fha ? "FHA mortgage insurance" : "PMI", b.mortgageInsurance) }
                    if b.hoa > 0 { line("HOA", b.hoa) }
                    Divider()
                    line("Cash to close, about", b.cashToClose)
                }
                .cardStyle()

                ShareLink(item: shareText(maxPrice: maxPrice, b: b)) {
                    Label("Send to my buyer", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("Estimate only, not a loan approval. Uses \(Int(calc.loanType.ratios.front * 100))/\(Int(calc.loanType.ratios.back * 100)) debt ratios, \(String(format: "%.1f", calc.taxRatePercent))% property taxes and about 3% closing costs. A lender preapproval is the real answer.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("How much home")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func line(_ title: String, _ value: Double) -> some View {
        HStack {
            Text(title).font(.cinema(14))
            Spacer()
            Text(value.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                .font(.cinema(14, weight: .semibold))
                .monospacedDigit()
        }
        .foregroundStyle(Theme.textPrimary)
    }

    private func shareText(maxPrice: Double, b: Affordability.Breakdown) -> String {
        "Here's a rough idea of your budget: homes up to about \(maxPrice.compactMoney), around \(b.total.compactMoney) a month with taxes and insurance, and about \(b.cashToClose.compactMoney) to close. Next step is a quick preapproval so we know for sure. Want me to connect you with a great lender? \(store.profile.firstName)"
    }
}

/// When buying beats renting, year by year.
struct RentVsBuyView: View {
    @Environment(CinemaStore.self) private var store
    @State private var calc = RentVsBuy(price: 400_000, downPercent: 10, ratePercent: 6.5, rent: 2_400)

    var body: some View {
        let years = calc.years()
        let breakEven = calc.breakEvenYear
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rent or buy?")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("What renting costs against what owning really costs after equity, year by year.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(spacing: 6) {
                    Text(breakEven.map { "Buying wins in year \($0)" } ?? "Renting wins for 10 years")
                        .font(.cinema(26, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                    if let tenth = years.last {
                        Text(tenth.buyAdvantage >= 0 ? "About \(tenth.buyAdvantage.compactMoney) ahead by owning after 10 years" : "Renting saves about \((-tenth.buyAdvantage).compactMoney) over 10 years")
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .cardStyle()

                Chart {
                    ForEach(years) { year in
                        LineMark(x: .value("Year", year.id), y: .value("Cost", year.rentPaid))
                            .foregroundStyle(by: .value("Option", "Renting"))
                        LineMark(x: .value("Year", year.id), y: .value("Cost", year.ownCost))
                            .foregroundStyle(by: .value("Option", "Owning"))
                    }
                }
                .chartForegroundStyleScale(["Renting": Theme.textTertiary, "Owning": Theme.red])
                .chartYAxis { AxisMarks { value in AxisGridLine(); AxisValueLabel { if let v = value.as(Double.self) { Text(v.compactMoney) } } } }
                .frame(height: 200)
                .cardStyle()

                VStack(spacing: 14) {
                    CalcSlider(title: "Home price", value: $calc.price, range: 150_000...2_000_000, step: 5_000, label: calc.price.compactMoney)
                    CalcSlider(title: "Down payment", value: $calc.downPercent, range: 0...50, step: 1, label: "\(Int(calc.downPercent))%")
                    CalcSlider(title: "Interest rate", value: $calc.ratePercent, range: 3...10, step: 0.125, label: String(format: "%.3f%%", calc.ratePercent))
                    CalcSlider(title: "Rent today", value: $calc.rent, range: 800...10_000, step: 50, label: calc.rent.compactMoney + " a month")
                    CalcSlider(title: "Home values grow", value: $calc.appreciationPercent, range: 0...8, step: 0.5, label: String(format: "%.1f%% a year", calc.appreciationPercent))
                    CalcSlider(title: "Rent goes up", value: $calc.rentIncreasePercent, range: 0...8, step: 0.5, label: String(format: "%.1f%% a year", calc.rentIncreasePercent))
                }
                .cardStyle()

                ShareLink(item: shareText(breakEven: breakEven, years: years)) {
                    Label("Send to my buyer", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    let idea = ScriptWriter.write(type: .mythBuster, topic: "renting vs buying in \(store.homeCity.name)", seconds: 30, city: store.homeCity, agentName: store.profile.name)
                    store.saveScript(idea)
                    store.showToast("Rent or buy video script saved to your ideas")
                } label: {
                    Label("Make it a video", systemImage: "video.fill")
                }
                .buttonStyle(SecondaryButtonStyle())

                Text("Owning counts the mortgage, PMI under 20% down, \(String(format: "%.1f", calc.taxRatePercent))% taxes, insurance, 1% a year upkeep, 3% to buy and 6% to sell, minus the equity built. It leaves out tax write offs and what the down payment could earn invested.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Rent or buy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func shareText(breakEven: Int?, years: [RentVsBuy.Year]) -> String {
        let five = years.count >= 5 ? years[4] : years.last
        var text = "I ran the numbers on a \(calc.price.compactMoney) home against \(calc.rent.compactMoney) a month in rent. "
        if let breakEven {
            text += "Buying comes out ahead in year \(breakEven)"
            if let five, five.buyAdvantage > 0 { text += ", and by year 5 you'd be about \(five.buyAdvantage.compactMoney) ahead" }
            text += "."
        } else {
            text += "At these numbers renting is cheaper for now, so let's look at price range and rates together."
        }
        return text + " Want to walk through it together? \(store.profile.firstName)"
    }
}

struct CalcSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.cinema(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(label)
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(Theme.red)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range, step: step)
                .tint(Theme.red)
        }
    }
}
