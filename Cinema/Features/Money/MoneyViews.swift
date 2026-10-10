import SwiftUI

/// One place for the money side of the business.
struct MoneyView: View {
    @Environment(CinemaStore.self) private var store

    var body: some View {
        let split = store.splitSummary
        let taxes = store.taxEstimate
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("My money")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("What you've earned, what you keep, what to save for taxes and what you can write off.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    StatTile(value: split.gross.compactMoney, label: "GCI this cap year", icon: "dollarsign.circle.fill")
                    StatTile(value: split.net.compactMoney, label: "You kept", icon: "banknote.fill")
                    StatTile(value: taxes.setAside.compactMoney, label: "Set aside for taxes", icon: "building.columns.fill")
                    StatTile(value: store.deductionsThisYear.compactMoney, label: "Write offs so far", icon: "car.fill")
                }

                NavigationLink(value: Route.splitTracker) {
                    VStack(alignment: .leading, spacing: 8) {
                        IconRow(icon: "chart.pie.fill", title: "Split and cap", subtitle: split.capProgress(store.splitPlan) >= 1 ? "Capped! You keep 100% of the split now." : "\(split.gciToCap(store.splitPlan).compactMoney) more GCI to cap")
                        ProgressView(value: split.capProgress(store.splitPlan))
                            .tint(Theme.red)
                    }
                    .cardStyle()
                }
                .buttonStyle(.plain)

                NavigationLink(value: Route.taxes) {
                    IconRow(icon: "building.columns.fill", title: "Tax set aside", subtitle: TaxPlan.nextDue().map { "Next estimated payment \($0.date.formatted(.dateTime.month(.abbreviated).day()))" } ?? "Quarterly estimated taxes")
                        .cardStyle()
                }
                .buttonStyle(.plain)

                NavigationLink(value: Route.expenses) {
                    IconRow(icon: "car.fill", title: "Mileage and expenses", subtitle: "Log trips and costs, export for taxes")
                        .cardStyle()
                }
                .buttonStyle(.plain)

                NavigationLink(value: Route.businessPlan) {
                    IconRow(icon: "target", title: "Business plan", subtitle: "Your income goal, worked back to videos a week")
                        .cardStyle()
                }
                .buttonStyle(.plain)

                NavigationLink(value: Route.scorecard) {
                    IconRow(icon: "checklist.checked", title: store.lex.weeklyPlanTitle, subtitle: "Your targets for the week, filled in for you")
                        .cardStyle()
                }
                .buttonStyle(.plain)

                NavigationLink(value: Route.license) {
                    IconRow(icon: "checkmark.seal.fill", title: "License and CE", subtitle: "\(store.licensePlan.daysLeft) days to renew · \(String(format: "%g", store.licensePlan.totalDone)) of \(String(format: "%g", store.licensePlan.totalNeeded)) hours")
                        .cardStyle()
                }
                .buttonStyle(.plain)

                Text("Estimates to help you plan, not tax or accounting advice. Your accountant has the final word.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Money")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SplitTrackerView: View {
    @Environment(CinemaStore.self) private var store
    @State private var plan = SplitPlan()
    @State private var didLoad = false

    var body: some View {
        let summary = SplitSummary.run(plan, closings: store.closingsInCapYear(plan))
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(summary.capProgress(plan) >= 1 ? "You've capped!" : "\(summary.gciToCap(plan).compactMoney) more GCI to cap")
                        .font(.cinema(24, weight: .heavy))
                    ProgressView(value: summary.capProgress(plan))
                        .tint(.white)
                    Text("\(summary.companyPaid.compactMoney) of \(plan.capAmount.compactMoney) cap paid · cap year ends \(plan.capYearEnd.formatted(.dateTime.month(.abbreviated).day().year()))")
                        .font(.cinema(12, weight: .semibold))
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.red, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(spacing: 10) {
                    row("Gross commission (GCI)", summary.gross, bold: true)
                    row("Company split", -summary.companyPaid)
                    row("Royalty", -summary.royaltyPaid)
                    if summary.fees > 0 { row("Per deal fees", -summary.fees) }
                    Divider()
                    row("You kept", summary.net, bold: true)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    DatePicker("Cap year starts", selection: $plan.capYearStart, displayedComponents: .date)
                    stepper("Company split", value: $plan.companySplitPercent, range: 0...50, step: 1, label: "\(Int(plan.companySplitPercent))%")
                    stepper("Cap", value: $plan.capAmount, range: 0...60_000, step: 500, label: plan.capAmount.compactMoney)
                    stepper("Royalty", value: $plan.royaltyPercent, range: 0...10, step: 0.5, label: SellerNetSheet.percent(plan.royaltyPercent))
                    stepper("Royalty cap", value: $plan.royaltyCap, range: 0...10_000, step: 250, label: plan.royaltyCap.compactMoney)
                    stepper("Per deal fee", value: $plan.perDealFee, range: 0...1_000, step: 25, label: plan.perDealFee.compactMoney)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GCI closed before you used #Cinema this cap year")
                            .font(.cinema(13, weight: .semibold))
                        TextField("0", value: $plan.priorGCI, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .keyboardType(.numberPad)
                            .inputStyle()
                    }
                }
                .font(.cinema(14))
                .cardStyle()

                Text("Your closed deals in Under contract count automatically. Caps, \(store.lex.companySplit) and royalty vary by \(store.lex.office), so set yours here.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Split and cap")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            plan = store.splitPlan
        }
        .onChange(of: plan) { _, newValue in store.saveSplitPlan(newValue) }
    }

    private func row(_ title: String, _ value: Double, bold: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.cinema(14, weight: bold ? .bold : .regular))
                .foregroundStyle(bold ? Theme.textPrimary : Theme.textSecondary)
            Spacer()
            Text(value < 0 ? "-\((-value).formatted(.currency(code: "USD").precision(.fractionLength(0))))" : value.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                .font(.cinema(14, weight: bold ? .bold : .semibold))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
        }
    }

    private func stepper(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, label: String) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text(label)
                    .foregroundStyle(Theme.red)
                    .fontWeight(.semibold)
            }
        }
    }
}

struct TaxSetAsideView: View {
    @Environment(CinemaStore.self) private var store
    @State private var plan = TaxPlan()
    @State private var didLoad = false
    @State private var skipNextChange = false

    var body: some View {
        let estimate = store.taxEstimate(plan)
        let year = Calendar.current.component(.year, from: Date())
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Set aside \(estimate.setAside.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
                        .font(.cinema(28, weight: .heavy))
                    Text("\(Int(plan.setAsidePercent))% of \(estimate.taxable.compactMoney) earned after splits and write offs in \(String(year))")
                        .font(.cinema(13, weight: .semibold))
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Stepper(value: $plan.setAsidePercent, in: 10...45, step: 1) {
                        HStack {
                            Text("Set aside")
                            Spacer()
                            Text("\(Int(plan.setAsidePercent))%")
                                .foregroundStyle(Theme.red)
                                .fontWeight(.semibold)
                        }
                    }
                    Text("Many 1099 agents save 25% to 30% of what they keep. Ask your accountant for your number.")
                        .font(.cinema(11))
                        .foregroundStyle(Theme.textTertiary)
                }
                .font(.cinema(14))
                .cardStyle()

                VStack(spacing: 10) {
                    row("You kept after splits", estimate.earned)
                    row("Mileage and expenses", -estimate.deductions)
                    Divider()
                    row("Estimated taxable", estimate.taxable)
                }
                .cardStyle()

                SectionHeader(title: "Estimated tax due dates")
                VStack(spacing: 10) {
                    ForEach(TaxPlan.dueDates(taxYear: year), id: \.id) { due in
                        let passed = due.date < Calendar.current.startOfDay(for: Date())
                        HStack {
                            Image(systemName: passed ? "checkmark.circle.fill" : "calendar")
                                .foregroundStyle(passed ? Theme.success : Theme.red)
                            Text(due.label)
                                .font(.cinema(14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(due.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year()))
                                .font(.cinema(13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Toggle("Remind me a week before each one", isOn: $plan.remindersOn)
                        .font(.cinema(14))
                        .tint(Theme.red)
                }
                .cardStyle()

                Text("Federal estimated tax dates, moved to Monday when they fall on a weekend. Florida has no state income tax. Estimates only, not tax advice.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Tax set aside")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            if plan != store.taxPlan {
                skipNextChange = true
                plan = store.taxPlan
            }
        }
        .onChange(of: plan) { old, new in
            if skipNextChange {
                skipNextChange = false
                return
            }
            store.saveTaxPlan(new, remindersChanged: old.remindersOn != new.remindersOn)
        }
    }

    private func row(_ title: String, _ value: Double) -> some View {
        HStack {
            Text(title)
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value < 0 ? "-\((-value).formatted(.currency(code: "USD").precision(.fractionLength(0))))" : value.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                .font(.cinema(14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
        }
    }
}
