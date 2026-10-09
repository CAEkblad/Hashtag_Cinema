import SwiftUI

/// Work backward from an income goal to closings, appointments, leads and videos.
struct BusinessPlan: Codable, Equatable {
    var gciGoal: Double = 150_000
    var averagePrice: Double = 450_000
    var commissionPercent: Double = 2.75
    var keepPercent: Double = 70
    var leadsPerAppointment: Double = 10
    var appointmentsPerClosing: Double = 2
    var leadsPerVideo: Double = 0.5

    var grossPerDeal: Double { averagePrice * commissionPercent / 100 }
    var netPerDeal: Double { grossPerDeal * keepPercent / 100 }
    var closingsPerYear: Double { gciGoal / max(grossPerDeal, 1) }
    var closingsPerMonth: Double { closingsPerYear / 12 }
    var appointmentsPerMonth: Double { closingsPerMonth * appointmentsPerClosing }
    var leadsPerMonth: Double { appointmentsPerMonth * leadsPerAppointment }
    var videosPerWeek: Double { leadsPerMonth / max(leadsPerVideo, 0.05) / 4.33 }
    var takeHome: Double { gciGoal * keepPercent / 100 }
}

struct BusinessPlanView: View {
    @Environment(CinemaStore.self) private var store
    @State private var plan = BusinessPlan()
    @State private var didLoad = false

    private var closedThisYear: [Deal] {
        let year = Calendar.current.component(.year, from: Date())
        return store.deals.filter { $0.isClosed && Calendar.current.component(.year, from: $0.closingDate) == year }
    }
    private var gciSoFar: Double { closedThisYear.reduce(0) { $0 + $1.commission } }
    private var pendingGCI: Double { store.deals.filter { !$0.isClosed }.reduce(0) { $0 + $1.commission } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("My business plan")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Start with what you want to earn. We'll work backward to how many videos a week gets you there.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(plan.gciGoal.compactMoney)
                            .font(.cinema(34, weight: .heavy))
                        Text("GCI goal this year")
                            .font(.cinema(13, weight: .semibold))
                            .opacity(0.85)
                    }
                    ProgressView(value: min(gciSoFar, plan.gciGoal), total: plan.gciGoal)
                        .tint(.white)
                    Text("\(gciSoFar.compactMoney) closed · \(pendingGCI.compactMoney) pending · about \(plan.takeHome.compactMoney) take home at goal")
                        .font(.cinema(12, weight: .semibold))
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.red, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    funnel(value: plan.closingsPerYear, label: "closings a year", detail: "\(String(format: "%.1f", plan.closingsPerMonth)) a month", icon: "key.fill")
                    funnel(value: plan.appointmentsPerMonth, label: "appointments a month", detail: "Listing or buyer consults", icon: "calendar")
                    funnel(value: plan.leadsPerMonth, label: "leads a month", detail: "DMs, sign ins, referrals", icon: "person.badge.plus")
                    funnel(value: plan.videosPerWeek, label: "videos a week", detail: "At \(String(format: "%.1f", plan.leadsPerVideo)) leads per video", icon: "video.fill")
                }

                Button {
                    store.setWeeklyGoal(Int(plan.videosPerWeek.rounded(.up)))
                    store.showToast("Weekly goal set to \(min(14, max(1, Int(plan.videosPerWeek.rounded(.up))))) videos")
                } label: {
                    Label("Make \(min(14, max(1, Int(plan.videosPerWeek.rounded(.up))))) videos a week my goal", systemImage: "target")
                }
                .buttonStyle(PrimaryButtonStyle())

                VStack(alignment: .leading, spacing: 14) {
                    slider("Income goal (GCI)", value: $plan.gciGoal, range: 25_000...1_000_000, step: 5_000, label: plan.gciGoal.compactMoney)
                    slider("Average sale price", value: $plan.averagePrice, range: 150_000...3_000_000, step: 10_000, label: plan.averagePrice.compactMoney)
                    slider("Your commission", value: $plan.commissionPercent, range: 1...4, step: 0.25, label: SellerNetSheet.percent(plan.commissionPercent))
                    slider("You keep after splits", value: $plan.keepPercent, range: 30...100, step: 5, label: "\(Int(plan.keepPercent))%")
                    slider("Leads for one appointment", value: $plan.leadsPerAppointment, range: 2...30, step: 1, label: "\(Int(plan.leadsPerAppointment))")
                    slider("Appointments for one closing", value: $plan.appointmentsPerClosing, range: 1...5, step: 0.5, label: String(format: "%.1f", plan.appointmentsPerClosing))
                    slider("Leads from each video", value: $plan.leadsPerVideo, range: 0.1...3, step: 0.1, label: String(format: "%.1f", plan.leadsPerVideo))
                }
                .cardStyle()

                Text("Your own numbers beat averages. As your videos bring in leads, update leads per video to match what you see in Insights.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Business plan")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            plan = store.businessPlan
        }
        .onChange(of: plan) { _, newValue in
            store.saveBusinessPlan(newValue)
        }
    }

    private func funnel(value: Double, label: String, detail: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.red)
                .frame(width: 30, height: 30)
                .background(Theme.redSoft, in: Circle())
            Text(value < 10 ? String(format: "%.1f", value) : "\(Int(value.rounded()))")
                .font(.cinema(24, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText())
            Text(label)
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(detail)
                .font(.cinema(11))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 14)
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
}
