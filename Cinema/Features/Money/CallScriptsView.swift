import SwiftUI
import UIKit

/// Prospecting scripts for power hour, with one tap tallies while you talk.
struct CallScriptsView: View {
    @Environment(CinemaStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Call scripts")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("What to say for every kind of call in your power hour. Open one, put the phone on speaker and read it the first few times until it sounds like you.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }
                ForEach(CallScriptLibrary.all) { script in
                    NavigationLink(value: Route.callScript(script.id)) {
                        HStack(spacing: 14) {
                            Image(systemName: script.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.red)
                                .frame(width: 34, height: 34)
                                .background(Theme.redSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(script.title)
                                    .font(.cinema(16, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(script.who)
                                    .font(.cinema(13))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer(minLength: 0)
                            if script.isCold {
                                Pill(text: "Cold", color: Theme.surfaceRaised, textColor: Theme.textSecondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .cardStyle(padding: 14)
                    }
                    .buttonStyle(.plain)
                }
                Text("Before cold calling, scrub numbers against the National Do Not Call Registry and Florida's no sales solicitation list, and follow your brokerage's calling rules.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Call scripts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CallScriptView: View {
    @Environment(CinemaStore.self) private var store
    let scriptID: String
    @State private var name = ""

    private var script: CallScript? { CallScriptLibrary.all.first { $0.id == scriptID } }

    var body: some View {
        Group {
            if let script {
                content(script)
            } else {
                EmptyStateView(title: "Script not found", message: "Go back and pick another.", icon: "phone")
            }
        }
        .cinemaScreen()
        .navigationTitle(script?.title ?? "Script")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func fill(_ text: String) -> String {
        CallScriptLibrary.fill(text, me: store.profile.firstName, city: store.homeCity.name, name: name.trimmingCharacters(in: .whitespaces))
    }

    private func content(_ script: CallScript) -> some View {
        let today = store.prospecting(on: Date())
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Who are you calling? (optional)", text: $name)
                    .textInputAutocapitalization(.words)
                    .inputStyle()

                block("OPEN WITH") {
                    Text(fill(script.opener))
                        .font(.cinema(18, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }

                block("ASK") {
                    ForEach(Array(script.questions.enumerated()), id: \.offset) { _, question in
                        Label(fill(question), systemImage: "questionmark.circle.fill")
                            .font(.cinema(15))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }

                block("IF THEY SAY") {
                    ForEach(Array(script.ifTheySay.enumerated()), id: \.offset) { _, pair in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\u{201C}\(pair.0)\u{201D}")
                                .font(.cinema(14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(fill(pair.1))
                                .font(.cinema(14))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }

                block("CLOSE FOR THE NEXT STEP") {
                    Text(fill(script.close))
                        .font(.cinema(16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }

                block("NO ANSWER? LEAVE THIS") {
                    Text(fill(script.voicemail))
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                    HStack {
                        Text(fill(script.text))
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer(minLength: 8)
                        ShareLink(item: fill(script.text)) {
                            Image(systemName: "message.fill")
                        }
                        .tint(Theme.red)
                        .accessibilityLabel("Send the follow up text")
                    }
                    .padding(12)
                    .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if script.isCold {
                    Label("Cold call: check the Do Not Call lists first.", systemImage: "exclamationmark.shield.fill")
                        .font(.cinema(12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(Theme.gutter)
            .padding(.bottom, 90)
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 8) {
                tally(.calls, today: today)
                tally(.conversations, today: today)
                tally(.appointments, today: today)
                tally(.texts, today: today)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    private func tally(_ action: ProspectAction, today: [ProspectAction: Int]) -> some View {
        Button {
            store.tallyProspect(action)
        } label: {
            VStack(spacing: 2) {
                Text("\(today[action] ?? 0)")
                    .font(.cinema(18, weight: .bold))
                Text("+ \(action.title)")
                    .font(.cinema(11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add one to \(action.title)")
    }

    private func block<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.cinema(12, weight: .bold))
                .foregroundStyle(Theme.red)
                .tracking(1)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
