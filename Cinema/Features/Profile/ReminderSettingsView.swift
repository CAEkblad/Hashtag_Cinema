import SwiftUI

struct ReminderSettingsView: View {
    @Environment(CinemaStore.self) private var store
    @State private var enabled = false
    @State private var time = Date()
    @State private var loaded = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $enabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily video idea")
                            .font(.cinema(16, weight: .semibold))
                        Text("A nudge with today's idea for \(store.homeCity.name)")
                            .font(.cinema(13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .tint(Theme.red)

                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    .disabled(!enabled)
            } footer: {
                Text("Most agents film best mid morning when the light is good. Pick a time you are usually free.")
            }
            .listRowBackground(Theme.surface)

            Section("Coming with the live backend") {
                Label("Your edit is ready", systemImage: "wand.and.stars")
                Label("New lead from a comment keyword", systemImage: "person.badge.plus")
                Label("Shoot day reminders", systemImage: "camera.fill")
            }
            .font(.cinema(14))
            .foregroundStyle(Theme.textSecondary)
            .listRowBackground(Theme.surface)
        }
        .cinemaScreen()
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            enabled = store.reminderEnabled
            var parts = DateComponents()
            parts.hour = store.reminderHour
            parts.minute = store.reminderMinute
            time = Calendar.current.date(from: parts) ?? Date()
            loaded = true
        }
        .onChange(of: enabled) { _, _ in save() }
        .onChange(of: time) { _, _ in save() }
    }

    private func save() {
        guard loaded else { return }
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        Task {
            await store.setReminder(enabled: enabled, hour: parts.hour ?? 9, minute: parts.minute ?? 0)
            if enabled && !store.reminderEnabled { enabled = false }
        }
    }
}
