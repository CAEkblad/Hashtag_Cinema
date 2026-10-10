import SwiftUI

/// Six short steps. Each one explains why we ask, and nothing is required
/// except a name and a city.
struct OnboardingView: View {
    @Environment(CinemaStore.self) private var store
    @State private var step = 0
    @State private var name = ""
    @State private var brokerage = ""
    @State private var role: UserRole = .agent
    @State private var cityQuery = ""
    @State private var city: FloridaCity?
    @State private var serviceAreas: [FloridaCity] = []
    @State private var niche = "Residential"
    @State private var goals: Set<ContentGoal> = [.personalBrand]
    @State private var weeklyGoal = 3
    @State private var plan: Plan = .creator
    @State private var teamName = ""
    @State private var alsoSells = true
    @State private var officeCode = ""
    @FocusState private var cityFieldFocused: Bool

    private let niches = ["Residential", "Luxury", "Waterfront homes", "First time buyers", "Investors", "Condos", "New construction", "Relocation"]

    private enum Stage { case welcome, about, role, market, office, goals, plan }

    /// Partner agents (KW) get a step to connect their market center.
    private var stages: [Stage] {
        var list: [Stage] = [.welcome, .about, .role, .market]
        if store.partner != nil { list.append(.office) }
        list += [.goals, .plan]
        return list
    }

    private var totalSteps: Int { stages.count }
    private var stage: Stage { stages[min(step, stages.count - 1)] }

    private var canContinue: Bool {
        switch stage {
        case .about: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case .market: return city != nil
        case .office: return store.profile.marketCenterID != nil
        default: return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Group {
                switch stage {
                case .welcome: welcome
                case .about: aboutYou
                case .role: roleStep
                case .market: marketStep
                case .office: officeStep
                case .goals: goalsStep
                case .plan: planStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            .id(step)

            footer
        }
        .background(Theme.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    // MARK: Frame

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
            Text("Step \(step + 1) of \(totalSteps)")
                .font(.cinema(12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
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
            Button(step == totalSteps - 1 ? "Start creating" : (step == 0 ? "Let's go" : "Continue")) {
                if step < totalSteps - 1 {
                    step += 1
                } else {
                    finish()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canContinue)
            .opacity(canContinue ? 1 : 0.5)
        }
        .padding(24)
    }

    private func finish() {
        store.completeOnboarding(
            name: name.trimmingCharacters(in: .whitespaces),
            brokerage: brokerage.trimmingCharacters(in: .whitespaces),
            teamName: teamName.trimmingCharacters(in: .whitespaces),
            alsoSells: alsoSells,
            role: role,
            city: city ?? FloridaMarkets.fallback,
            serviceAreas: serviceAreas,
            niche: niche,
            goals: ContentGoal.allCases.filter { goals.contains($0) },
            weeklyGoal: weeklyGoal,
            plan: plan
        )
    }

    private func title(_ text: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.cinema(28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(subtitle)
                .font(.cinema(16))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Steps

    private var welcome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                title("Your content team, in your pocket", "#Cinema helps you show up on video every week without a film crew.")
                VStack(spacing: 12) {
                    welcomeRow("lightbulb.fill", "Ideas for your city", "A new video idea every day, written for your Florida market.")
                    welcomeRow("video.fill", "Film on your phone", "Teleprompter, framing guides and practice mode.")
                    welcomeRow("wand.and.stars", "We edit it", "AI first cut in minutes, polished by #Cinema editors.")
                    welcomeRow("paperplane.fill", "Post and get leads", "All 4 platforms at once, comment keywords become leads.")
                }
                Text("Setup takes about a minute.")
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(24)
        }
    }

    private func welcomeRow(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Theme.red, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.cinema(16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle(padding: 14)
    }

    private var aboutYou: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                title("Nice to meet you", "Your name goes on your scripts, posters and community posts.")
                if let partner = store.partner {
                    HStack(spacing: 12) {
                        Text(partner.shortName)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Theme.red, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(partner.name) agent")
                                .font(.cinema(15, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(store.profile.email)
                                .font(.cinema(13, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                            Text("\(partner.signupDiscountPercent)% off is applied to your account")
                                .font(.cinema(12, weight: .semibold))
                                .foregroundStyle(Theme.red)
                        }
                        Spacer(minLength: 0)
                    }
                    .cardStyle(padding: 14)
                }
                TextField("Your name", text: $name)
                    .textContentType(.name)
                    .inputStyle()
                if store.partner == nil {
                    TextField("Brokerage (optional)", text: $brokerage)
                        .textContentType(.organizationName)
                        .inputStyle()
                }
                TextField("Team name (optional)", text: $teamName)
                    .inputStyle()
            }
            .padding(24)
        }
    }

    private var roleStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                title("How do you work?", "\(store.lex.leadersList.prefix(1).uppercased() + store.lex.leadersList.dropFirst()) use #Cinema free.")
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
                                Text(option.title(store.lex))
                                    .font(.cinema(17, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(option.subtitle(store.lex))
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

                if role.isLeader {
                    Toggle(isOn: $alsoSells) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("I also sell real estate")
                                .font(.cinema(16, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("Keep every agent tool and post as yourself, your team or your \(store.partner?.officeWord ?? role.orgWord(store.lex)).")
                                .font(.cinema(13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .tint(Theme.red)
                    .cardStyle()
                }
            }
            .padding(24)
        }
    }

    private var officeStep: some View {
        let partner = store.partner ?? .kellerWilliams
        let centers = store.marketCenters(near: city ?? store.homeCity, partner: partner)
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                title("Connect your \(partner.officeWord)", "Your \(partner.officeWord) gets credit for your work, and you get office challenges and shared content.")

                VStack(alignment: .leading, spacing: 8) {
                    Text(store.lex.joinCodePrompt)
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 10) {
                        TextField("Join code", text: $officeCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .inputStyle()
                        Button("Join") {
                            if store.joinMarketCenter(code: officeCode) { officeCode = "" }
                        }
                        .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                        .disabled(officeCode.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Text("Or pick yours and your leader approves it:")
                    .font(.cinema(15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                VStack(spacing: 0) {
                    ForEach(centers) { center in
                        Button {
                            store.requestMarketCenter(center)
                        } label: {
                            MarketCenterRow(center: center, isSelected: store.profile.marketCenterID == center.id)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
                .cardStyle(padding: 12)

                if store.profile.marketCenterID != nil {
                    Label(store.profile.membership == .approved ? "Connected and verified" : "Request sent. You can keep going.", systemImage: store.profile.membership.icon)
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(store.profile.membership == .approved ? Theme.success : Theme.red)
                }
                if centers.contains(where: \.isSample) {
                    Text("Demo: sample \(store.lex.offices). Try code TAMPA1.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(24)
        }
    }

    private var marketStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                title("Where do you sell?", "We write ideas for your city: local events, seasons, neighborhoods and what buyers there ask about.")

                if let city {
                    HStack(spacing: 12) {
                        CityRow(city: city, isSelected: true)
                        Button("Change") {
                            self.city = nil
                            serviceAreas = []
                            cityQuery = ""
                            cityFieldFocused = true
                        }
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(Theme.red)
                    }
                    .cardStyle(padding: 14)
                    .overlay(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).stroke(Theme.red, lineWidth: 1.5))

                    let suggestions = FloridaMarkets.suggestedServiceAreas(for: city)
                    if !suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Do you also sell in any of these?")
                                .font(.cinema(15, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            FlowLayout(spacing: 8) {
                                ForEach(suggestions) { option in
                                    let isOn = serviceAreas.contains(option)
                                    Button {
                                        if isOn {
                                            serviceAreas.removeAll { $0.id == option.id }
                                        } else {
                                            serviceAreas.append(option)
                                        }
                                    } label: {
                                        Label(option.name, systemImage: isOn ? "checkmark" : "plus")
                                            .font(.cinema(14, weight: .semibold))
                                            .foregroundStyle(isOn ? .white : Theme.textPrimary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 9)
                                            .background(isOn ? Theme.red : Theme.surface, in: Capsule())
                                            .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            Text("You can add more later in Me > My market.")
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Theme.textTertiary)
                        TextField("City or county, like Tampa or Lee", text: $cityQuery)
                            .textContentType(.addressCity)
                            .autocorrectionDisabled()
                            .focused($cityFieldFocused)
                    }
                    .inputStyle()

                    VStack(spacing: 0) {
                        ForEach(FloridaMarkets.search(cityQuery, limit: cityQuery.isEmpty ? 8 : 12)) { option in
                            Button {
                                city = option
                                cityFieldFocused = false
                            } label: {
                                CityRow(city: option)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                    .cardStyle(padding: 12)

                    Text("Every city and town in Florida is here. More states are coming.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var goalsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                title("What should your videos do?", "Pick your niche and goals. Your idea feed leans into them.")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Your niche")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    FlowLayout(spacing: 10) {
                        ForEach(niches, id: \.self) { option in
                            chip(option, isOn: niche == option) { niche = option }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Your goals")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    FlowLayout(spacing: 10) {
                        ForEach(ContentGoal.allCases) { goal in
                            chip(goal.title, icon: goal.icon, isOn: goals.contains(goal)) {
                                if goals.contains(goal) { goals.remove(goal) } else { goals.insert(goal) }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Stepper(value: $weeklyGoal, in: 1...14) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(weeklyGoal) videos a week")
                                .font(.cinema(16, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(weeklyGoal <= 3 ? "A great start. Consistency beats volume." : "Ambitious. We will keep you on track.")
                                .font(.cinema(13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .cardStyle()
            }
            .padding(24)
        }
    }

    private func chip(_ text: String, icon: String? = nil, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(text)
            }
            .font(.cinema(15, weight: .semibold))
            .foregroundStyle(isOn ? .white : Theme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isOn ? Theme.red : Theme.surface, in: Capsule())
            .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var planStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if role.isLeader {
                    title("You're free", "Leaders use #Cinema at no cost to promote their \(role.orgWord(store.lex)) and their \(store.lex.agents).")
                    PlanCard(plan: .leader, isSelected: true) {}
                } else {
                    title("Pick your plan", "Start on any plan and change anytime in Me > Plan and credits.")
                    if let partner = store.partner {
                        Label("\(partner.name) agents get \(partner.signupDiscountPercent)% off", systemImage: "tag.fill")
                            .font(.cinema(14, weight: .semibold))
                            .foregroundStyle(Theme.red)
                    }
                    ForEach([Plan.starter, .creator, .pro]) { option in
                        PlanCard(plan: option, isSelected: plan == option, discountPercent: store.discountPercent) { plan = option }
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
    var discountPercent: Int = 0
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
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(plan.price(discountPercent: discountPercent))
                            .font(.cinema(17, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        if plan.price(discountPercent: discountPercent) != plan.price {
                            Text(plan.price)
                                .font(.cinema(12))
                                .strikethrough()
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
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
