import SwiftUI

/// Florida seller costs, worked out from the sale price.
struct SellerNetSheet {
    var price: Double
    var payoff: Double
    var listingPercent: Double
    var buyerAgentPercent: Double
    var concessions: Double
    var otherCosts: Double
    var miamiDade: Bool
    var sellerPaysTitle: Bool

    var listingCommission: Double { price * listingPercent / 100 }
    var buyerAgentCommission: Double { price * buyerAgentPercent / 100 }

    /// Florida documentary stamp tax on the deed: $0.70 per $100, or $0.60 in Miami-Dade
    /// (Miami-Dade adds a surtax on some non single family sales, not included here).
    var docStamps: Double {
        let units = (price / 100).rounded(.up)
        return units * (miamiDade ? 0.60 : 0.70)
    }

    /// Owner's title policy at Florida's promulgated rates.
    var titlePolicy: Double {
        guard sellerPaysTitle else { return 0 }
        let thousands = (price / 1_000).rounded(.up)
        let tiers: [(upTo: Double, rate: Double)] = [(100, 5.75), (1_000, 5.00), (5_000, 2.50), (10_000, 2.25), (.greatestFiniteMagnitude, 2.00)]
        var remaining = thousands
        var lower = 0.0
        var total = 0.0
        for tier in tiers where remaining > 0 {
            let band = min(remaining, tier.upTo - lower)
            total += band * tier.rate
            remaining -= band
            lower = tier.upTo
        }
        return total
    }

    var totalCosts: Double { listingCommission + buyerAgentCommission + docStamps + titlePolicy + concessions + otherCosts }
    var net: Double { price - payoff - totalCosts }

    var lines: [(String, Double)] {
        var rows: [(String, Double)] = [
            ("Listing agent (\(Self.percent(listingPercent)))", listingCommission)
        ]
        if buyerAgentPercent > 0 { rows.append(("Buyer's agent (\(Self.percent(buyerAgentPercent)))", buyerAgentCommission)) }
        rows.append(("Doc stamps on the deed", docStamps))
        if sellerPaysTitle { rows.append(("Owner's title policy", titlePolicy)) }
        if concessions > 0 { rows.append(("Seller concessions", concessions)) }
        if otherCosts > 0 { rows.append(("Closing, HOA and other fees", otherCosts)) }
        return rows
    }

    static func percent(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))%" : String(format: "%.1f%%", value)
    }
}

struct NetSheetView: View {
    @Environment(CinemaStore.self) private var store
    var startingPrice: Double = 450_000
    var address: String = ""

    @State private var price: Double = 450_000
    @State private var payoff: Double = 220_000
    @State private var listingPercent: Double = 3
    @State private var buyerAgentPercent: Double = 2.5
    @State private var concessions: Double = 0
    @State private var otherCosts: Double = 1_500
    @State private var miamiDade = false
    @State private var sellerPaysTitle = true
    @State private var didLoad = false

    private var sheet: SellerNetSheet {
        SellerNetSheet(price: price, payoff: payoff, listingPercent: listingPercent, buyerAgentPercent: buyerAgentPercent, concessions: concessions, otherCosts: otherCosts, miamiDade: miamiDade, sellerPaysTitle: sellerPaysTitle)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated seller net")
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(money(sheet.net))
                        .font(.cinema(38, weight: .heavy))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("on a \(money(price)) sale\(address.isEmpty ? "" : " of \(address)")")
                        .font(.cinema(13))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.red, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(spacing: 10) {
                    row("Sale price", price, bold: true)
                    row("Mortgage payoff", -payoff)
                    ForEach(Array(sheet.lines.enumerated()), id: \.offset) { _, line in
                        row(line.0, -line.1)
                    }
                    Divider()
                    row("Estimated net to you", sheet.net, bold: true)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 14) {
                    slider("Sale price", value: $price, range: 100_000...5_000_000, step: 5_000, label: money(price))
                    slider("Mortgage payoff", value: $payoff, range: 0...4_000_000, step: 5_000, label: money(payoff))
                    slider("Listing commission", value: $listingPercent, range: 0...6, step: 0.25, label: SellerNetSheet.percent(listingPercent))
                    slider("Buyer's agent (if seller pays)", value: $buyerAgentPercent, range: 0...4, step: 0.25, label: SellerNetSheet.percent(buyerAgentPercent))
                    slider("Seller concessions", value: $concessions, range: 0...50_000, step: 500, label: money(concessions))
                    slider("Closing, HOA and other fees", value: $otherCosts, range: 0...15_000, step: 100, label: money(otherCosts))
                    Toggle("Seller pays owner's title policy", isOn: $sellerPaysTitle)
                        .tint(Theme.red)
                    Toggle("Property is in Miami-Dade", isOn: $miamiDade)
                        .tint(Theme.red)
                }
                .font(.cinema(14))
                .cardStyle()

                ShareLink(item: shareText) {
                    Label("Send to my seller", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("Estimate only. Doc stamps use Florida's $0.70 per $100 rate ($0.60 in Miami-Dade). Title uses Florida's promulgated rates. Who pays title varies by county. Property tax prorations aren't included. Your title company provides the final numbers.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Seller net sheet")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            price = startingPrice
            payoff = (startingPrice * 0.5 / 5_000).rounded() * 5_000
        }
    }

    private var shareText: String {
        var lines = ["Your estimated net\(address.isEmpty ? "" : " for \(address)"):", "", "Sale price: \(money(price))", "Mortgage payoff: -\(money(payoff))"]
        lines += sheet.lines.map { "\($0.0): -\(money($0.1))" }
        lines += ["", "Estimated net to you: \(money(sheet.net))", "", "This is an estimate. Final numbers come from the title company. Happy to walk through it anytime. \(store.profile.firstName)"]
        return lines.joined(separator: "\n")
    }

    private func row(_ title: String, _ value: Double, bold: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.cinema(14, weight: bold ? .bold : .regular))
                .foregroundStyle(bold ? Theme.textPrimary : Theme.textSecondary)
            Spacer()
            Text(value < 0 ? "-\(money(-value))" : money(value))
                .font(.cinema(14, weight: bold ? .bold : .semibold))
                .foregroundStyle(value < 0 ? Theme.textSecondary : Theme.textPrimary)
                .monospacedDigit()
        }
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
