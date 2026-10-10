import SwiftUI
import UIKit

/// One lead: where they came from, ready to send follow up texts, notes, status and a reminder.
struct LeadDetailView: View {
    @Environment(CinemaStore.self) private var store
    let leadID: UUID

    @State private var notes = ""
    @State private var remindOn = false
    @State private var remindAt = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    @State private var loaded = false

    var body: some View {
        Group {
            if let lead = store.lead(leadID) {
                content(lead)
            } else {
                EmptyStateView(title: "Lead not found", message: "It may have been removed.", icon: "person.crop.circle.badge.questionmark")
            }
        }
        .cinemaScreen()
        .navigationTitle("Lead")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func templates(for lead: Lead) -> [FollowUpTemplate] {
        var list: [FollowUpTemplate] = [lead.openHouseAddress == nil ? .firstReply : .openHouseThanks, .checkIn]
        if lead.status == .booked { list.insert(.booked, at: 0) }
        return list
    }

    private var phoneDigits: String? {
        guard let lead = store.lead(leadID) else { return nil }
        let digits = lead.handle.filter(\.isNumber)
        return digits.count >= 10 ? digits : nil
    }

    private func content(_ lead: Lead) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Avatar(initials: String(lead.name.split(separator: " ").prefix(2).compactMap { $0.first }).uppercased(), size: 54, paletteIndex: lead.name.count)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(lead.name)
                            .font(.cinema(22, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(lead.handle)
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textSecondary)
                        Text(lead.openHouseAddress.map { "Open house at \($0)" } ?? "Commented \(lead.keyword) on \(lead.sourceClip)")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer(minLength: 0)
                }

                Text("\u{201C}\(lead.message)\u{201D}")
                    .font(.cinema(15))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                Picker("Status", selection: Binding(get: { lead.status }, set: { store.setLeadStatus($0, for: lead.id) })) {
                    ForEach(LeadStatus.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                if let digits = phoneDigits {
                    HStack(spacing: 10) {
                        if let call = URL(string: "tel:\(digits)") {
                            Link(destination: call) {
                                Label("Call", systemImage: "phone.fill")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        if let text = URL(string: "sms:\(digits)") {
                            Link(destination: text) {
                                Label("Text", systemImage: "message.fill")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                }

                if let team = store.team {
                    HStack {
                        Label(store.leadAssignments[lead.id.uuidString].map { "With \($0)" } ?? "With you", systemImage: "person.crop.circle.badge.checkmark")
                            .font(.cinema(14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Menu {
                            Button("Keep it myself") { store.assignLead(lead.id, to: nil) }
                            if team.leadRoutingOn, let next = store.nextLeadAssignee {
                                Button("Next in round robin (\(next.isMe ? "you" : next.name))") { store.routeLead(lead.id) }
                            }
                            ForEach(team.members.filter { !$0.isMe && $0.role != .admin }) { member in
                                Button(member.name) { store.assignLead(lead.id, to: member.name) }
                            }
                        } label: {
                            Label("Hand off", systemImage: "arrow.triangle.swap")
                                .font(.cinema(13, weight: .semibold))
                                .foregroundStyle(Theme.red)
                        }
                    }
                    .cardStyle(padding: 14)
                }

                if let plan = store.touchContact(for: lead.id) {
                    NavigationLink(value: Route.touchPlans) {
                        IconRow(icon: "point.3.filled.connected.trianglepath.dotted", title: "On your \(plan.plan.title(store.lex))", subtitle: plan.nextStep.map { "Next: \($0.title), \(plan.whenLabel(of: $0))" } ?? "Plan complete")
                            .cardStyle()
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        store.startTouchPlan(name: lead.name, plan: .eightWeek, leadID: lead.id)
                    } label: {
                        IconRow(icon: "point.3.filled.connected.trianglepath.dotted", title: "Start their \(store.lex.newContactPlan)", subtitle: "8 touches in 8 weeks, with what to say each time")
                            .cardStyle()
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 10) {
                    if lead.keyword.uppercased() == "VALUE" {
                        NavigationLink(value: Route.homeValue) {
                            IconRow(icon: "chart.line.uptrend.xyaxis", title: "Make their home value report", subtitle: "3 comps in, a branded PDF out")
                                .cardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                    SectionHeader(title: "Follow up messages")
                    ForEach(templates(for: lead)) { template in
                        let message = template.message(lead: lead, agentFirstName: store.profile.firstName, cityName: store.homeCity.name)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.title)
                                .font(.cinema(13, weight: .bold))
                                .foregroundStyle(Theme.textTertiary)
                            Text(message)
                                .font(.cinema(14))
                                .foregroundStyle(Theme.textPrimary)
                                .textSelection(.enabled)
                            HStack(spacing: 18) {
                                ShareLink(item: message) {
                                    Label("Send", systemImage: "paperplane.fill")
                                }
                                .simultaneousGesture(TapGesture().onEnded { store.markContacted(lead.id) })
                                Button {
                                    UIPasteboard.general.string = message
                                    store.markContacted(lead.id)
                                    store.showToast("Copied")
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                            }
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(Theme.red)
                            .buttonStyle(.plain)
                        }
                        .cardStyle()
                    }
                    if let last = lead.lastContacted {
                        Text("Last contacted \(last.relative)")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $remindOn) {
                        Text("Remind me to follow up")
                            .font(.cinema(15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .tint(Theme.red)
                    if remindOn {
                        DatePicker("When", selection: $remindAt, in: Date()...)
                            .font(.cinema(14))
                    }
                    Divider()
                    Button {
                        store.startFollowUpPlan(leadID)
                    } label: {
                        Label("Start a 3 touch plan: day 1, 3 and 7", systemImage: "list.number")
                            .font(.cinema(14, weight: .semibold))
                            .foregroundStyle(Theme.red)
                    }
                    Text("Day 1: a thank you text. Day 3: send similar homes. Day 7: a friendly check in. We'll remind you each morning.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    TextField("Budget, timeline, what they're looking for", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                        .inputStyle()
                }
            }
            .padding(Theme.gutter)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            guard !loaded else { return }
            notes = lead.notes
            if let due = lead.followUpDate {
                remindOn = true
                remindAt = due
            }
            loaded = true
        }
        .onChange(of: notes) { _, value in
            guard loaded, var current = store.lead(leadID) else { return }
            current.notes = value
            store.updateLead(current)
        }
        .onChange(of: remindOn) { _, on in
            guard loaded else { return }
            Task { await store.setFollowUp(leadID, on: on ? remindAt : nil) }
        }
        .onChange(of: remindAt) { _, date in
            guard loaded, remindOn else { return }
            Task { await store.setFollowUp(leadID, on: date) }
        }
    }
}
