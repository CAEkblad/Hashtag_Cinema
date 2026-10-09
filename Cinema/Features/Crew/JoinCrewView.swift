import SwiftUI

/// Photographers and videographers apply to shoot for #Cinema anywhere in Florida (and later the US).
struct JoinCrewView: View {
    @Environment(CinemaStore.self) private var store
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var city: FloridaCity?
    @State private var showCityPicker = false
    @State private var skills: Set<ShooterSkill> = [.listingPhotos]
    @State private var portfolioURL = ""
    @State private var years = 2
    @State private var hasInsurance = false
    @State private var hasPart107 = false
    @State private var agreedNonSolicit = false

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && email.contains("@") && city != nil && !skills.isEmpty && agreedNonSolicit
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let application = store.crewApplication {
                    submitted(application)
                } else {
                    intro
                    tierLadder
                    form
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Join #Cinema Crew")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            if name.isEmpty { name = store.profile.name }
            if email.isEmpty { email = store.profile.email }
            if city == nil { city = store.homeCity }
        }
        .sheet(isPresented: $showCityPicker) {
            CityPickerView(title: "Where you shoot", selectedIDs: Set(city.map { [$0.id] } ?? [])) { picked in
                city = picked
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shoot for #Cinema")
                .font(.cinema(26, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Get booked by agents near you, shoot, upload and get paid in one app. No chasing invoices, no selling yourself. Level up for bigger jobs and cash bonuses.")
                .font(.cinema(15))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var tierLadder: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Level up")
            ForEach(CrewTier.allCases) { tier in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: tier.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Theme.gradient(tier.paletteIndex), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(tier.title)
                                .font(.cinema(16, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if tier.levelUpBonus > 0 {
                                Text("$\(tier.levelUpBonus.formatted()) bonus")
                                    .font(.cinema(12, weight: .bold))
                                    .foregroundStyle(Theme.success)
                            }
                        }
                        Text(tier == .rookie ? "Where everyone starts" : "\(tier.minJobs) shoots, \(tier.minFiveStar) five star ratings, \(String(format: "%.1f", tier.minRating))+ average")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                        Text(tier.perks.joined(separator: " · "))
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .cardStyle(padding: 12)
            }
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Apply")
            TextField("Full name", text: $name)
                .textContentType(.name)
                .inputStyle()
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .inputStyle()
            TextField("Phone", text: $phone)
                .keyboardType(.phonePad)
                .inputStyle()
            Button {
                showCityPicker = true
            } label: {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(Theme.red)
                    Text(city?.displayName ?? "Where you shoot")
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("Change")
                        .foregroundStyle(Theme.red)
                }
                .font(.cinema(15, weight: .medium))
                .inputStyle()
            }
            .buttonStyle(.plain)

            Text("What you shoot")
                .font(.cinema(15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            FlowLayout(spacing: 8) {
                ForEach(ShooterSkill.allCases) { skill in
                    let isOn = skills.contains(skill)
                    Button {
                        if isOn { skills.remove(skill) } else { skills.insert(skill) }
                    } label: {
                        Label(skill.title, systemImage: skill.icon)
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(isOn ? Color.white : Theme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isOn ? Theme.red : Theme.surface, in: Capsule())
                            .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("Portfolio link (website, Instagram, Google Drive)", text: $portfolioURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .inputStyle()
            Stepper("\(years) years shooting", value: $years, in: 0...40)
                .font(.cinema(15, weight: .medium))
                .cardStyle(padding: 12)

            VStack(spacing: 10) {
                Toggle("I carry liability insurance", isOn: $hasInsurance)
                Toggle("I'm an FAA Part 107 drone pilot", isOn: $hasPart107)
                Toggle(isOn: $agreedNonSolicit) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("I agree to the #Cinema Crew non-solicit")
                        Text("Agents I meet through #Cinema are booked through #Cinema. No side deals for 24 months.")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .font(.cinema(14, weight: .medium))
            .tint(Theme.red)
            .cardStyle()

            Button("Send application") {
                guard let city else { return }
                store.submitCrewApplication(CrewApplication(
                    name: name.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces),
                    phone: phone,
                    cityID: city.id,
                    skills: ShooterSkill.allCases.filter { skills.contains($0) },
                    portfolioURL: portfolioURL,
                    yearsShooting: years,
                    hasInsurance: hasInsurance,
                    hasPart107: hasPart107,
                    agreedNonSolicit: agreedNonSolicit,
                    submittedAt: Date()
                ))
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.5)

            Text("Next: a quick portfolio review, background check and a paid test shoot.")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func submitted(_ application: CrewApplication) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 54))
                .foregroundStyle(Theme.red)
            Text("Application received")
                .font(.cinema(26, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Thanks, \(application.name.split(separator: " ").first.map { String($0) } ?? application.name). We review new shooters within 3 business days. Here is a preview of your Crew dashboard.")
                .font(.cinema(15))
                .foregroundStyle(Theme.textSecondary)
            NavigationLink(value: Route.crewDashboard) {
                Text("Open Crew dashboard preview")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

/// What a shooter sees: tier progress, job offers, earnings and perks.
struct CrewDashboardView: View {
    @Environment(CinemaStore.self) private var store
    // Preview numbers for a new Pro on the way to Elite.
    private let tier: CrewTier = .pro
    private let jobs = 61
    private let fiveStar = 44
    private let rating = 4.84
    private let monthEarnings = 2_340

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    TierBadge(tier: tier)
                    Text("\(jobs) shoots · \(String(format: "%.2f", rating)) rating")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                if let next = tier.next {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Next: \(next.title)")
                            .font(.cinema(18, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        progress("Shoots", value: jobs, goal: next.minJobs)
                        progress("Five star ratings", value: fiveStar, goal: next.minFiveStar)
                        Text("Reach \(next.title) for a $\(next.levelUpBonus.formatted()) bonus and \(next.perks.first ?? "").")
                            .font(.cinema(13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .cardStyle()
                }

                HStack(spacing: 10) {
                    StatTile(value: "$\(monthEarnings.formatted())", label: "This month", icon: "dollarsign.circle.fill")
                    StatTile(value: "$\(tier.bonusPerJob)", label: "Bonus per job", icon: "gift.fill")
                }

                SectionHeader(title: "Jobs offered to you")
                if store.crewJobOffers.isEmpty {
                    Text("You're all caught up. New jobs show up here and on your lock screen.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                        .cardStyle()
                }
                ForEach(store.crewJobOffers) { offer in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(offer.title, systemImage: offer.skill.icon)
                                .font(.cinema(15, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("$\(offer.pay + offer.bonus)")
                                .font(.cinema(17, weight: .bold))
                                .foregroundStyle(Theme.success)
                        }
                        Text("\(offer.address) · \(offer.date.shortDay) at \(offer.date.timeOnly)")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                        Text("Includes your $\(offer.bonus) \(tier.title) bonus. Paid 24 hours after upload passes QC.")
                            .font(.cinema(11))
                            .foregroundStyle(Theme.textTertiary)
                        Button("Accept job") { store.acceptJob(offer) }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                    .cardStyle()
                }

                SectionHeader(title: "How it works")
                VStack(alignment: .leading, spacing: 8) {
                    Label("Accept a job, the address and notes unlock", systemImage: "1.circle.fill")
                    Label("Check in on site, the agent gets a heads up", systemImage: "2.circle.fill")
                    Label("Upload straight from your camera card or phone", systemImage: "3.circle.fill")
                    Label("Pass QC, get paid by direct deposit", systemImage: "4.circle.fill")
                }
                .font(.cinema(14))
                .foregroundStyle(Theme.textPrimary)
                .cardStyle()

                Text("Preview. The full #Cinema Crew app is next on the roadmap.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Crew dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func progress(_ label: String, value: Int, goal: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value) of \(goal)")
            }
            .font(.cinema(13, weight: .semibold))
            .foregroundStyle(Theme.textSecondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceRaised)
                    Capsule().fill(Theme.red)
                        .frame(width: geo.size.width * min(1, Double(value) / Double(max(goal, 1))))
                }
            }
            .frame(height: 8)
        }
    }
}
