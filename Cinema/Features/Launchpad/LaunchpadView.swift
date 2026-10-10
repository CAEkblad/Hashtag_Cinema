import SwiftUI

/// "I'm a brand new agent" mode: a 90 day launch plan, first deal milestones
/// and the tools a new agent needs, in the order they need them.
struct LaunchpadView: View {
    @Environment(CinemaStore.self) private var store
    @State private var sheet: LaunchSheet?

    enum LaunchSheet: String, Identifiable {
        case announce, contacts, headshots
        var id: String { rawValue }
    }

    private var phases: [LaunchPhase] { LaunchPlan90.phases(store.lex) }
    private var doneCount: Int { phases.flatMap(\.steps).filter { store.isLaunchStepDone($0.id) }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if store.isNewAgent {
                    header
                    milestones
                    ForEach(phases) { phase in
                        phaseCard(phase)
                    }
                    Button("Turn off launchpad") { store.setNewAgent(false) }
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                } else {
                    intro
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Launchpad")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .announce: AnnounceLicenseView()
            case .contacts: FirstHundredView()
            case .headshots: BookingFormView(service: .headshots)
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Theme.red)
            Text("Brand new agent?")
                .font(.cinema(28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Most new agents quit before their first closing because nobody tells them what to do each week. Turn on the launchpad and #Cinema walks you through your first 90 days: get set up, tell everyone, build the habits and get to your first deal.")
                .font(.cinema(15))
                .foregroundStyle(Theme.textSecondary)
            VStack(alignment: .leading, spacing: 8) {
                Label("A week by week plan with one tap to each tool", systemImage: "checklist")
                Label("Your license announcement, written for you", systemImage: "megaphone.fill")
                Label("Your first 100 contacts tracker", systemImage: "person.crop.rectangle.stack.fill")
                Label("Milestones your \(store.lex.teamLeader) gets to celebrate", systemImage: "party.popper.fill")
            }
            .font(.cinema(14, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .cardStyle()
            Button {
                store.setNewAgent(true)
            } label: {
                Label("I'm a brand new agent", systemImage: "sparkles")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            ProgressRing(progress: Double(doneCount) / Double(max(LaunchPlan90.stepCount, 1)), lineWidth: 8, size: 76)
            VStack(alignment: .leading, spacing: 4) {
                Text("Day \(store.launchpad.dayNumber) of 90")
                    .font(.cinema(24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Week \(store.launchpad.currentWeek) · \(doneCount) of \(LaunchPlan90.stepCount) steps done")
                    .font(.cinema(14))
                    .foregroundStyle(Theme.textSecondary)
                if let next = phases.flatMap(\.steps).first(where: { !store.isLaunchStepDone($0.id) }) {
                    Text("Next: \(next.title)")
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(Theme.red)
                }
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    private var milestones: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Firsts")
                .font(.cinema(16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(LaunchMilestone.allCases) { milestone in
                    let hit = store.launchpad.milestones[milestone.rawValue] != nil
                    Button {
                        store.toggleMilestone(milestone)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: hit ? "checkmark.circle.fill" : milestone.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(hit ? Theme.success : Theme.textTertiary)
                            Text(milestone.title)
                                .font(.cinema(12, weight: .semibold))
                                .foregroundStyle(hit ? Theme.textPrimary : Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .background(hit ? Theme.success.opacity(0.12) : Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Tap one when it happens. It posts to your team page so they can cheer you on.")
                .font(.cinema(11))
                .foregroundStyle(Theme.textTertiary)
        }
        .cardStyle()
    }

    private func phaseCard(_ phase: LaunchPhase) -> some View {
        let isNow = phase.weeks.contains(store.launchpad.currentWeek)
        let weeks = phase.weeks.count == 1 ? "Week \(phase.weeks.lowerBound)" : "Weeks \(phase.weeks.lowerBound) to \(phase.weeks.upperBound)"
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(weeks.uppercased())
                        .font(.cinema(11, weight: .heavy))
                        .kerning(1)
                        .foregroundStyle(isNow ? Theme.red : Theme.textTertiary)
                    Text(phase.title)
                        .font(.cinema(17, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                if isNow {
                    Text("This week")
                        .font(.cinema(11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.red, in: Capsule())
                }
            }
            ForEach(phase.steps) { step in
                stepRow(step)
            }
        }
        .cardStyle()
    }

    private func stepRow(_ step: LaunchStep) -> some View {
        let done = store.isLaunchStepDone(step.id)
        return HStack(alignment: .top, spacing: 12) {
            Button {
                store.toggleLaunchStep(step.id)
            } label: {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(done ? Theme.success : Theme.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(done ? "Mark \(step.title) not done" : "Mark \(step.title) done")

            VStack(alignment: .leading, spacing: 3) {
                Text(step.title)
                    .font(.cinema(15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .strikethrough(done, color: Theme.textTertiary)
                Text(step.detail)
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                stepAction(step)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func stepAction(_ step: LaunchStep) -> some View {
        switch step.action {
        case .route(let route):
            NavigationLink(value: route) { actionLabel(step) }
        case .announce:
            Button { sheet = .announce } label: { actionLabel(step) }
        case .contacts:
            Button { sheet = .contacts } label: { actionLabel(step, extra: "\(store.launchpad.contacts.count) of 100") }
        case .headshots:
            Button { sheet = .headshots } label: { actionLabel(step, extra: "Book #Cinema") }
        case nil:
            EmptyView()
        }
    }

    private func actionLabel(_ step: LaunchStep, extra: String? = nil) -> some View {
        Label(extra ?? "Open", systemImage: step.icon)
            .font(.cinema(12, weight: .bold))
            .foregroundStyle(Theme.red)
            .padding(.top, 2)
    }
}

/// The "I just got licensed" post and a personal text for close friends.
struct AnnounceLicenseView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let post = LaunchPlan90.announcement(name: store.profile.name, office: store.myOfficeName, city: store.homeCity.name)
        let text = LaunchPlan90.personalText(name: store.profile.name)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    block("Post for your socials", body: post)
                    ShareLink(item: post) {
                        Label("Share the post", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    block("Text for close friends and family", body: text)
                    ShareLink(item: text) {
                        Label("Send the text", systemImage: "message.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        let idea = ScriptWriter.write(type: .aboutMe, topic: "I just got my real estate license", seconds: 30, city: store.homeCity, agentName: store.profile.name)
                        store.saveScript(idea)
                        store.markLaunchStepDone("announce")
                        store.showToast("Announcement video script saved to your ideas")
                    } label: {
                        Label("Write it as a video", systemImage: "video.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Text("A video announcement gets far more reach than a photo. Film it in front of your new office sign.")
                        .font(.cinema(11))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(Theme.gutter)
            }
            .cinemaScreen()
            .navigationTitle("Announce your license")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.markLaunchStepDone("announce")
                        dismiss()
                    }
                }
            }
        }
    }

    private func block(_ title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.cinema(13, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
            Text(body)
                .font(.cinema(15))
                .foregroundStyle(Theme.textPrimary)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

/// A running list of the first 100 people a new agent will tell.
struct FirstHundredView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var focused: Bool

    private let joggers = ["Family", "Close friends", "Old coworkers", "Your gym", "Church or groups", "Kids' school parents", "Neighbors", "Your hair stylist", "Your dentist and doctor", "College friends", "Your landlord", "Social media friends"]

    var body: some View {
        let count = store.launchpad.contacts.count
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        ProgressRing(progress: Double(count) / 100, lineWidth: 6, size: 56)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(count) of 100")
                                .font(.cinema(20, weight: .bold))
                            Text("Everyone you know who could buy, sell or send you someone.")
                                .font(.cinema(13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    HStack {
                        TextField("Add a name", text: $name)
                            .focused($focused)
                            .submitLabel(.next)
                            .onSubmit(add)
                        Button("Add", action: add)
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .listRowBackground(Theme.surface)

                Section("Stuck? Think about") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(joggers, id: \.self) { jogger in
                                Text(jogger)
                                    .font(.cinema(12, weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Theme.surfaceRaised, in: Capsule())
                            }
                        }
                    }
                }
                .listRowBackground(Theme.surface)

                if !store.launchpad.contacts.isEmpty {
                    Section("Your list") {
                        ForEach(store.launchpad.contacts, id: \.self) { contact in
                            Text(contact)
                        }
                        .onDelete { offsets in
                            let names = offsets.map { store.launchpad.contacts[$0] }
                            names.forEach(store.removeLaunchContact)
                        }
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .cinemaScreen()
            .navigationTitle("First 100 contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .onAppear { focused = true }
        }
    }

    private func add() {
        store.addLaunchContact(name)
        name = ""
        focused = true
    }
}
