import Foundation
import UserNotifications

/// Daily "your idea for today" nudge. Local notifications, no server needed.
/// When the backend is live, push notifications for edits and leads come from APNs.
enum ReminderScheduler {
    static let identifier = "cinema.daily-idea"

    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        default:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
    }

    static func scheduleDaily(hour: Int, minute: Int, idea: Idea?, city: FloridaCity) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Your \(city.name) video idea is ready"
        if let idea {
            content.body = "\(idea.title). Tap to see the shot list and film it in \(idea.targetSeconds) seconds."
        } else {
            content.body = "Open #Cinema for today's idea, shot list and script."
        }
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    static func label(hour: Int, minute: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}
