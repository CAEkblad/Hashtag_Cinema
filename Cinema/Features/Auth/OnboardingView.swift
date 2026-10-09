import SwiftUI

struct OnboardingView: View {
    @Environment(CinemaStore.self) private var store
    @State private var step = 0
    @State private var name = ""
    @State private var role: UserRole = .agent
    @State private var market = ""
    @State private var niche = "Residential"
    @State private var plan: Plan = .creator

    private let niches = ["Residential", "Luxury", "Waterfront homes", "First time buyers", "Investors", "Condos", "New construction", "Relocation"]
    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $step) {
                aboutYou.tag(0)
                roleStep.tag(1)
                nicheStep.tag(2)
                planStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)

            footer
        }
        .background(Theme.background.ignoresSafeArea())
    }

    // MARK: Pieces

    private var header: some View {
        VStack(spacing: 14) {
            CinemaLogo(size: 24)
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? Theme.red : Theme.surfaceRaised)
                        .frame(height: 4)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("Back") { step -= 1 }
                    .buttonStyle(SecondaryButtonStyle(fullWidth: false))
            }
            Button(step == totalSteps - 1 ? "Start creating" : "Continue") {
                if step < totalSteps - 1 {
                    step += 1
                } else {
                    store.completeOnboarding(name: name, role: role, market: market, niche: niche, plan: plan)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
    }

    private func title(_ text: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.cinema(28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(subtitle)
                .font(.cinema(16))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Steps

    private var aboutYou: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                title("Welcome to #Cinema", "Tell us about you so your ideas fit your market.")
                TextField("Your name", text: $name)
                    .textContentType(.name)
                    .inputStyle()
                TextField("Your market (city, state)", text: $market)
                    .textContentType(.addressCity)
                    .inputStyle()
            }
            .padding(24)
        }
    }

    private var roleStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                title("How do you work?", "This sets up your dashboard and credits.")
                ForEach(UserRole.allCases) { option in
                    Button {
                        role = option
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: option.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.red)
                                .frame(width: 40, height: 40)
                                .background(Theme.surfaceRaised, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                    .font(.cinema(17, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(option.subtitle)
                                    .font(.cinema(14))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: role == option ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(role == option ? Theme.red : Theme.textTertiary)
                                .font(.system(size: 22))
                        }
                        .cardStyle()
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                                .stroke(role == option ? Theme.red : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
    }

    private var nicheStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                title("What's your niche?", "Your idea feed and community groups start here.")
                FlowLayout(spacing: 10) {
                    ForEach(niches, id: \.self) { option in
                        Button {
                            niche = option
                        } label: {
                            Text(option)
                                .font(.cinema(15, weight: .semibold))
                                .foregroundStyle(niche == option ? .white : Theme.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(niche == option ? Theme.red : Theme.surface, in: Capsule())
                                .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
        }
    }

    private var planStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if role.isLeader {
                    title("You're free", "Leaders use #Cinema at no cost to promote their \(role.orgWord) and their agents.")
                    PlanCard(plan: .leader, isSelected: true) {}
                } else {
                    title("Pick your plan", "Change anytime in Me > Plan.")
                    ForEach([Plan.starter, .creator, .pro]) { option in
                        PlanCard(plan: option, isSelected: plan == option) { plan = option }
                    }
                    Text("Brokerage seats are set up by your broker.")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(24)
        }
    }
}

struct PlanCard: View {
    let plan: Plan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(plan.name)
                        .font(.cinema(20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    if plan == .creator {
                        Pill(text: "Most popular", color: Theme.red, textColor: .white)
                    }
                    Spacer()
                    Text(plan.price)
                        .font(.cinema(17, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
                ForEach(plan.perks, id: \.self) { perk in
                    Label(perk, systemImage: "checkmark")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .cardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .stroke(isSelected ? Theme.red : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
