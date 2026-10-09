import SwiftUI

/// Florida buyer cash to close: down payment, loan taxes, title, prepaids.
struct BuyerCashToClose {
    var price: Double
    var downPercent: Double
    var lenderFees: Double
    var insuranceYearly: Double
    var taxRate: Double
    var inspection: Double
    var sellerCredits: Double
    var sellerPaysOwnersTitle: Bool

    var downPayment: Double { price * downPercent / 100 }
    var loan: Double { max(0, price - downPayment) }

    /// Florida doc stamps on the promissory note: $0.35 per $100 of the loan.
    var noteStamps: Double { (loan / 100).rounded(.up) * 0.35 }
    /// Florida intangible tax on the mortgage: 0.2% of the loan.
    var intangibleTax: Double { loan * 0.002 }

    /// Lender's policy. Nearly free as a simultaneous issue when the seller buys the owner's policy.
    var titleCosts: Double {
        if loan == 0 { return sellerPaysOwnersTitle ? 0 : SellerNetSheet(price: price, payoff: 0, listingPercent: 0, buyerAgentPercent: 0, concessions: 0, otherCosts: 0, miamiDade: false, sellerPaysTitle: true).titlePolicy }
        if sellerPaysOwnersTitle { return 25 + 300 }
        return SellerNetSheet(price: price, payoff: 0, listingPercent: 0, buyerAgentPercent: 0, concessions: 0, otherCosts: 0, miamiDade: false, sellerPaysTitle: true).titlePolicy + 25 + 300
    }

    /// First year of insurance plus about 3 months of tax and insurance in escrow.
    var prepaids: Double {
        let monthlyEscrow = (price * taxRate / 100 + insuranceYearly) / 12
        return insuranceYearly + (loan > 0 ? monthlyEscrow * 3 : 0)
    }

    var closingCosts: Double { (loan > 0 ? lenderFees + noteStamps + intangibleTax : 0) + titleCosts + inspection }
    var cashToClose: Double { max(0, downPayment + closingCosts + prepaids - sellerCredits) }

    var lines: [(String, Double)] {
        var rows: [(String, Double)] = [("Down payment (\(SellerNetSheet.percent(downPercent)))", downPayment)]
        if loan > 0 {
            rows += [("Lender fees and appraisal", lenderFees), ("Doc stamps on the note", noteStamps), ("Intangible tax", intangibleTax)]
        }
        rows += [(sellerPaysOwnersTitle ? "Lender's title and endorsements" : "Title policies", titleCosts), ("Inspections", inspection), ("Insurance and escrow prepaids", prepaids)]
        if sellerCredits > 0 { rows.append(("Seller credits", -sellerCredits)) }
        return rows
    }
}

struct BuyerCostsView: View {
    @Environment(CinemaStore.self) private var store
    @State private var price: Double = 450_000
    @State private var downPercent: Double = 10
    @State private var lenderFees: Double = 3_000
    @State private var insurance: Double = 4_200
    @State private var taxRate: Double = 1.1
    @State private var inspection: Double = 650
    @State private var credits: Double = 0
    @State private var sellerPaysTitle = true

    private var estimate: BuyerCashToClose {
        BuyerCashToClose(price: price, downPercent: downPercent, lenderFees: lenderFees, insuranceYearly: insurance, taxRate: taxRate, inspection: inspection, sellerCredits: credits, sellerPaysOwnersTitle: sellerPaysTitle)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated cash to close")
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(money(estimate.cashToClose))
                        .font(.cinema(38, weight: .heavy))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("on a \(money(price)) home with \(SellerNetSheet.percent(downPercent)) down")
                        .font(.cinema(13))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(spacing: 10) {
                    ForEach(Array(estimate.lines.enumerated()), id: \.offset) { _, line in
                        HStack {
                            Text(line.0)
                                .font(.cinema(14))
                                .foregroundStyle(Theme.textSecondary)
                            Spacer()
                            Text(line.1 < 0 ? "-\(money(-line.1))" : money(line.1))
                                .font(.cinema(14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                                .monospacedDigit()
                        }
                    }
                    Divider()
                    HStack {
                        Text("Cash to close")
                            .font(.cinema(14, weight: .bold))
                        Spacer()
                        Text(money(estimate.cashToClose))
                            .font(.cinema(14, weight: .bold))
                            .monospacedDigit()
                    }
                    .foregroundStyle(Theme.textPrimary)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 14) {
                    slider("Price", value: $price, range: 100_000...5_000_000, step: 5_000, label: money(price))
                    slider("Down payment", value: $downPercent, range: 0...100, step: 0.5, label: SellerNetSheet.percent(downPercent))
                    slider("Lender fees and appraisal", value: $lenderFees, range: 0...15_000, step: 100, label: money(lenderFees))
                    slider("Home insurance", value: $insurance, range: 0...20_000, step: 100, label: "\(money(insurance)) a year")
                    slider("Property tax rate", value: $taxRate, range: 0.5...2.5, step: 0.05, label: String(format: "%.2f%%", taxRate))
                    slider("Inspections", value: $inspection, range: 0...2_000, step: 25, label: money(inspection))
                    slider("Seller credits", value: $credits, range: 0...50_000, step: 500, label: money(credits))
                    Toggle("Seller pays owner's title policy", isOn: $sellerPaysTitle)
                        .tint(Theme.red)
                }
                .font(.cinema(14))
                .cardStyle()

                ShareLink(item: shareText) {
                    Label("Send to my buyer", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("Estimate only. Uses Florida's doc stamps on the note ($0.35 per $100) and intangible tax (0.2% of the loan). Earnest money counts toward cash to close. Your lender's Loan Estimate has the real numbers.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Buyer cash to close")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var shareText: String {
        var lines = ["Here's a rough idea of your cash to close on a \(money(price)) home:", ""]
        lines += estimate.lines.map { "\($0.0): \($0.1 < 0 ? "-\(money(-$0.1))" : money($0.1))" }
        lines += ["", "Estimated cash to close: \(money(estimate.cashToClose))", "", "Your lender will send exact numbers. Happy to connect you with a great one! \(store.profile.firstName)"]
        return lines.joined(separator: "\n")
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.cinema(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(label)
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(Theme.red)
            }
            Slider(value: value, in: range, step: step)
                .tint(Theme.red)
        }
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}
