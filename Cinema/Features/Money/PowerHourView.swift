import SwiftUI
import Charts

/// A daily prospecting session: a 60 minute timer and one tap tallies.
enum ProspectAction: String, CaseIterable, Identifiable, Codable {
    case calls, texts, conversations, appointments, doors, notes
    var id: String { rawValue }
    var title: String {
        switch self {
        case .calls: return "Calls"
        case .texts: return "Texts"
        case .conversations: return "Talks"
        case .appointments: return "Appts set"
        case .doors: return "Doors"
        case .notes: return "Notes"
        }
    }
    var icon: String {
        switch self {
        case .calls: return "phone.fill"
        case .texts: return "message.fill"
        case .conversations: return "person.2.wave.2.fill"
        case .appointments: return "calendar.badge.checkmark"
        case .doors: return "door.left.hand.closed"
        case .notes: return "envelope.fill"
        }
    }
}

struct PowerHourView: View {
    @Environment(CinemaStore.self) private var store
    @State private var goalMinutes = 60

    private struct DayBar { var label: String; var count: Int }

    var body: some View {
        let today = store.prospecting(on: Date())
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Power hour")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("One focused hour a day talking to people. Tap a button every time you make a touch.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                timerCard

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(ProspectAction.allCases) { action in
                        Button {
                            store.tallyProspect(action)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Theme.red)
                                Text("\(today[action] ?? 0)")
                                    .font(.cinema(24, weight: .heavy))
                                    .foregroundStyle(Theme.textPrimary)
                                    .contentTransition(.numericText())
                                Text(action.title)
                                    .font(.cinema(12, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .cardStyle(padding: 12)
                        }
                        .buttonStyle(.plain)
                        .sensoryFeedback(.increase, trigger: today[action] ?? 0)
                        .contextMenu {
                            Button {
                                store.tallyProspect(action, by: -1)
                            } label: {
                                Label("Take one off", systemImage: "minus.circle")
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    StatTile(value: "\(store.prospectStreak)", label: "Day streak", icon: "flame.fill")
                    StatTile(value: "\(store.prospectTotal(days: 7))", label: "Touches, 7 days", icon: "hand.tap.fill")
                    StatTile(value: "\(store.prospectTotal(days: 30, only: .appointments))", label: "Appts, 30 days", icon: "calendar.badge.checkmark")
                }

                HStack(spacing: 10) {
                    NavigationLink(value: Route.scorecard) {
                        Label("Weekly scorecard", systemImage: "checklist.checked")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    NavigationLink(value: Route.timeBlocks) {
                        Label("Time blocks", systemImage: "clock.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                SectionHeader(title: "Last 7 days")
                Chart(lastWeek(), id: \.label) { bar in
                    BarMark(x: .value("Day", bar.label), y: .value("Touches", bar.count))
                        .foregroundStyle(Theme.red.gradient)
                        .cornerRadius(4)
                }
                .frame(height: 150)
                .cardStyle()

                Text("Press and hold a button to take one off. A day counts toward your streak once you log 10 touches.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Power hour")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var timerCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = store.powerHourEnds.map { max(0, $0.timeIntervalSince(context.date)) }
            VStack(spacing: 12) {
                Text(remaining.map(format) ?? "\(goalMinutes):00")
                    .font(.system(size: 54, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                if let remaining, remaining == 0 {
                    Text("Hour done. Nice work!")
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                HStack(spacing: 10) {
                    if store.powerHourEnds == nil {
                        Picker("Length", selection: $goalMinutes) {
                            Text("30 min").tag(30)
                            Text("60 min").tag(60)
                            Text("90 min").tag(90)
                        }
                        .pickerStyle(.segmented)
                        Button("Start") { store.startPowerHour(minutes: goalMinutes) }
                            .font(.cinema(15, weight: .bold))
                            .foregroundStyle(Theme.red)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(.white, in: Capsule())
                    } else {
                        Button("End session") { store.endPowerHour() }
                            .font(.cinema(15, weight: .bold))
                            .foregroundStyle(Theme.red)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(.white, in: Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Theme.red, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func lastWeek() -> [DayBar] {
        (0..<7).reversed().map { back in
            let date = Calendar.current.date(byAdding: .day, value: -back, to: Date()) ?? Date()
            let count = store.prospecting(on: date).values.reduce(0, +)
            return DayBar(label: date.formatted(.dateTime.weekday(.abbreviated)), count: count)
        }
    }
}
