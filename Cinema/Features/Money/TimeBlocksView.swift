import SwiftUI

/// A repeating block of focused time, like a daily power hour.
struct TimeBlock: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var hour: Int
    var minute: Int
    var minutes: Int
    /// 1 is Sunday, 7 is Saturday, matching Calendar weekdays.
    var weekdays: Set<Int> = [2, 3, 4, 5, 6]
    var isOn = true

    var startLabel: String {
        let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    var endLabel: String {
        let start = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
        return start.addingTimeInterval(TimeInterval(minutes * 60)).formatted(date: .omitted, time: .shortened)
    }

    func isNow(_ now: Date = Date()) -> Bool {
        let calendar = Calendar.current
        guard isOn, weekdays.contains(calendar.component(.weekday, from: now)) else { return false }
        let nowMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let start = hour * 60 + minute
        return nowMinutes >= start && nowMinutes < start + minutes
    }

    static let defaults: [TimeBlock] = [
        TimeBlock(title: "Power hour: calls and texts", hour: 9, minute: 0, minutes: 60, isOn: false),
        TimeBlock(title: "Follow up with leads", hour: 10, minute: 0, minutes: 30, isOn: false),
        TimeBlock(title: "Film today's video", hour: 13, minute: 0, minutes: 30, isOn: false),
        TimeBlock(title: "Post and reply to comments", hour: 16, minute: 30, minutes: 30, isOn: false)
    ]
}

struct TimeBlocksView: View {
    @Environment(CinemaStore.self) private var store
    @State private var editing: TimeBlock?
    @State private var showNew = false

    private let dayLetters = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Time blocks")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Top agents guard the same hours every day. Set your blocks and we'll tap you on the shoulder when each one starts.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                if let current = store.timeBlocks.first(where: { $0.isNow() }) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 20, weight: .semibold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Right now: \(current.title)")
                                .font(.cinema(16, weight: .bold))
                            Text("Until \(current.endLabel). Phone on do not disturb, everything else waits.")
                                .font(.cinema(12))
                                .opacity(0.9)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.red, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                ForEach(store.timeBlocks.sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }) { block in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(block.startLabel)
                                .font(.cinema(14, weight: .bold))
                                .foregroundStyle(block.isOn ? Theme.red : Theme.textTertiary)
                            Text("\(block.minutes) min")
                                .font(.cinema(11))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .frame(width: 70, alignment: .leading)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(block.title)
                                .font(.cinema(15, weight: .semibold))
                                .foregroundStyle(block.isOn ? Theme.textPrimary : Theme.textTertiary)
                            HStack(spacing: 4) {
                                ForEach(1...7, id: \.self) { day in
                                    Text(dayLetters[day - 1])
                                        .font(.cinema(10, weight: .bold))
                                        .frame(width: 18, height: 18)
                                        .foregroundStyle(block.weekdays.contains(day) ? .white : Theme.textTertiary)
                                        .background(block.weekdays.contains(day) ? Theme.red.opacity(block.isOn ? 1 : 0.4) : Theme.surfaceRaised, in: Circle())
                                }
                            }
                            Button("Edit") { editing = block }
                                .font(.cinema(12, weight: .semibold))
                                .foregroundStyle(Theme.red)
                        }
                        Spacer()
                        Toggle("On", isOn: Binding(get: { block.isOn }, set: { on in
                            var updated = block
                            updated.isOn = on
                            store.saveTimeBlock(updated)
                        }))
                        .labelsHidden()
                        .tint(Theme.red)
                    }
                    .cardStyle()
                }

                Button {
                    showNew = true
                } label: {
                    Label("Add a block", systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Time blocks")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { block in
            TimeBlockEditor(block: block, isNew: false)
        }
        .sheet(isPresented: $showNew) {
            TimeBlockEditor(block: TimeBlock(title: "", hour: 11, minute: 0, minutes: 30), isNew: true)
        }
    }
}

struct TimeBlockEditor: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var block: TimeBlock
    let isNew: Bool

    private let dayNames = Calendar.current.shortWeekdaySymbols

    private var startBinding: Binding<Date> {
        Binding(get: {
            Calendar.current.date(from: DateComponents(hour: block.hour, minute: block.minute)) ?? Date()
        }, set: { date in
            block.hour = Calendar.current.component(.hour, from: date)
            block.minute = Calendar.current.component(.minute, from: date)
        })
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("What's this block for?", text: $block.title)
                DatePicker("Starts", selection: startBinding, displayedComponents: .hourAndMinute)
                Stepper("\(block.minutes) minutes", value: $block.minutes, in: 15...180, step: 15)
                Section("Days") {
                    ForEach(1...7, id: \.self) { day in
                        Toggle(dayNames[day - 1], isOn: Binding(get: { block.weekdays.contains(day) }, set: { on in
                            if on { block.weekdays.insert(day) } else { block.weekdays.remove(day) }
                        }))
                        .tint(Theme.red)
                    }
                }
                if !isNew {
                    Section {
                        Button("Delete block", role: .destructive) {
                            store.deleteTimeBlock(block.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New block" : "Edit block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.saveTimeBlock(block)
                        dismiss()
                    }
                    .disabled(block.title.trimmingCharacters(in: .whitespaces).isEmpty || block.weekdays.isEmpty)
                }
            }
        }
    }
}
