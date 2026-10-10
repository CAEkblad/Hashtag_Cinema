import SwiftUI

/// 8 touches in 8 weeks for new contacts, then 33 touches a year.
/// Each touch comes with what to say and one tap to send it.
struct TouchPlansView: View {
    @Environment(CinemaStore.self) private var store
    @State private var showAdd = false
    @State private var openContact: TouchContact?

    var body: some View {
        let due = store.touchesDueToday
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Touch plans")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("New people get your \(store.lex.newContactPlanLong). After that, your \(store.lex.yearPlanLong) keeps you top of mind so they call you, not the agent their cousin knows.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack(spacing: 12) {
                    StatTile(value: "\(due.count)", label: "Due today", icon: "bell.fill")
                    StatTile(value: "\(store.touchContacts.filter { $0.plan == .eightWeek }.count)", label: store.lex.newContactPlan, icon: "8.circle.fill")
                    StatTile(value: "\(store.touchContacts.filter { $0.plan == .yearRound }.count)", label: store.lex.yearPlanTitle, icon: "calendar")
                }

                Button {
                    showAdd = true
                } label: {
                    Label("Add someone", systemImage: "person.badge.plus")
                }
                .buttonStyle(PrimaryButtonStyle())

                if !due.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Due today")
                            .font(.cinema(16, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        ForEach(due, id: \.contact.id) { item in
                            TouchStepCard(contact: item.contact, step: item.step)
                        }
                    }
                } else if !store.touchContacts.isEmpty {
                    Label("All caught up for today", systemImage: "checkmark.circle.fill")
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(Theme.success)
                        .cardStyle()
                }

                ForEach(TouchContact.Plan.allCases) { plan in
                    let people = store.touchContacts.filter { $0.plan == plan }
                    if !people.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(plan == .eightWeek ? store.lex.newContactPlanLong : store.lex.yearPlanLong)
                                .font(.cinema(15, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            ForEach(people) { contact in
                                Button { openContact = contact } label: { contactRow(contact) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .cardStyle()
                    }
                }

                if store.touchContacts.isEmpty {
                    EmptyStateView(title: "No one on a plan yet", message: "Add a new lead, someone you met at an open house, or your first 100 contacts.", icon: "person.2.wave.2")
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Touch plans")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) { AddTouchContactView() }
        .sheet(item: $openContact) { contact in TouchContactView(contactID: contact.id) }
    }

    private func contactRow(_ contact: TouchContact) -> some View {
        let total = contact.steps.count
        return HStack(spacing: 12) {
            ProgressRing(progress: Double(contact.done.count) / Double(max(total, 1)), lineWidth: 4, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.cinema(15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(contact.nextStep.map { "Next: \($0.title), \(contact.date(of: $0).relativeDayLabel.lowercased())" } ?? "Plan complete")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if !contact.due.isEmpty {
                Pill(text: "Due", color: Theme.redSoft, textColor: Theme.red)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
    }
}

/// One touch with its script and the way to send it.
struct TouchStepCard: View {
    @Environment(CinemaStore.self) private var store
    let contact: TouchContact
    let step: TouchStep

    var body: some View {
        let message = step.message(to: contact, from: store.profile.name)
        let isDone = store.touchContacts.first { $0.id == contact.id }?.done.contains(step.id) ?? false
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("\(step.kind.title) · \(contact.name)", systemImage: step.kind.icon)
                    .font(.cinema(14, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(contact.plan.title(store.lex))
                    .font(.cinema(11, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            Text(step.title)
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text(message)
                .font(.cinema(14))
                .foregroundStyle(Theme.textPrimary)
                .textSelection(.enabled)
            HStack(spacing: 10) {
                if step.kind == .call, let url = phoneURL {
                    Link(destination: url) { Label("Call", systemImage: "phone.fill") }
                        .buttonStyle(SecondaryButtonStyle())
                } else if [.text, .video, .email, .note].contains(step.kind) {
                    ShareLink(item: message) { Label("Send", systemImage: "paperplane.fill") }
                        .buttonStyle(SecondaryButtonStyle())
                }
                Button {
                    store.toggleTouch(contact.id, step: step.id)
                } label: {
                    Label(isDone ? "Done" : "Mark done", systemImage: isDone ? "checkmark.circle.fill" : "checkmark")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .cardStyle()
    }

    private var phoneURL: URL? {
        let digits = contact.phone.filter(\.isNumber)
        return digits.isEmpty ? nil : URL(string: "tel:\(digits)")
    }
}

struct TouchContactView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let contactID: UUID

    var body: some View {
        NavigationStack {
            Group {
                if let contact = store.touchContacts.first(where: { $0.id == contactID }) {
                    List {
                        if contact.isComplete && contact.plan == .eightWeek {
                            Section {
                                Button("Move to my \(store.lex.yearPlan)") { store.moveToYearPlan(contact.id) }
                                    .font(.cinema(15, weight: .semibold))
                                    .foregroundStyle(Theme.red)
                            }
                            .listRowBackground(Theme.surface)
                        }
                        Section(contact.plan == .eightWeek ? store.lex.newContactPlanLong : store.lex.yearPlanLong) {
                            ForEach(contact.steps) { step in
                                Button {
                                    store.toggleTouch(contact.id, step: step.id)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: contact.done.contains(step.id) ? "checkmark.circle.fill" : step.kind.icon)
                                            .foregroundStyle(contact.done.contains(step.id) ? Theme.success : Theme.red)
                                            .frame(width: 22)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(step.title)
                                                .font(.cinema(14, weight: .semibold))
                                                .foregroundStyle(Theme.textPrimary)
                                                .strikethrough(contact.done.contains(step.id), color: Theme.textTertiary)
                                            Text("\(step.kind.title) · \(contact.date(of: step).formatted(date: .abbreviated, time: .omitted))")
                                                .font(.cinema(12))
                                                .foregroundStyle(Theme.textSecondary)
                                        }
                                    }
                                }
                            }
                        }
                        .listRowBackground(Theme.surface)
                        Section {
                            Button("Take \(contact.firstName) off the plan", role: .destructive) {
                                store.removeTouchContact(contact.id)
                                dismiss()
                            }
                        }
                        .listRowBackground(Theme.surface)
                    }
                    .scrollContentBackground(.hidden)
                    .navigationTitle(contact.name)
                } else {
                    EmptyStateView(title: "Not on a plan", message: "This person was taken off their plan.", icon: "person")
                }
            }
            .cinemaScreen()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

struct AddTouchContactView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var plan: TouchContact.Plan = .eightWeek

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    TextField("Phone (optional)", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    Picker("Plan", selection: $plan) {
                        ForEach(TouchContact.Plan.allCases) { Text($0.title(store.lex)).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(plan == .eightWeek ? "For someone you just met. 8 touches over 8 weeks so they remember you." : "For your sphere and past clients. 33 touches spread over the year.")
                }

                if !store.launchpad.contacts.isEmpty {
                    let notOnPlan = store.launchpad.contacts.filter { name in !store.touchContacts.contains { $0.name.caseInsensitiveCompare(name) == .orderedSame } }
                    if !notOnPlan.isEmpty {
                        Section {
                            Button("Add all \(notOnPlan.count) from my first 100 contacts") {
                                notOnPlan.forEach { store.startTouchPlan(name: $0, plan: plan, quiet: true) }
                                store.showToast("\(notOnPlan.count) people added to your \(plan.title(store.lex))")
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add someone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if store.startTouchPlan(name: name, phone: phone, plan: plan) {
                            dismiss()
                        } else {
                            store.showToast("\(name.trimmingCharacters(in: .whitespaces)) is already on a plan")
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
