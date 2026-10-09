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

    static func scheduleFollowUp(for lead: Lead, at date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Follow up with \(lead.name)"
        content.body = lead.openHouseAddress.map { "They visited \($0). A quick text keeps you top of mind." } ?? "They commented \(lead.keyword). A quick text keeps you top of mind."
        content.sound = .default
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "cinema.follow-up.\(lead.id.uuidString)", content: content, trigger: trigger))
    }

    static func cancelFollowUp(for leadID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["cinema.follow-up.\(leadID.uuidString)"])
    }

    static func scheduleAnniversary(for client: PastClient) async {
        let content = UNMutableNotificationContent()
        content.title = "\(client.name)'s home anniversary is today"
        content.body = "A quick note keeps you their agent for life. Your text is ready in #Cinema."
        content.sound = .default
        var parts = Calendar.current.dateComponents([.month, .day], from: client.closeDate)
        // A Feb 29 closing would only fire in leap years. Use Feb 28 so it fires every year.
        if parts.month == 2 && parts.day == 29 { parts.day = 28 }
        parts.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "cinema.anniversary.\(client.id.uuidString)", content: content, trigger: trigger))
    }

    static func cancelAnniversary(_ id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["cinema.anniversary.\(id.uuidString)"])
    }

    /// A one time reminder at 9 AM on a date, used for deal deadlines.
    static func scheduleOnce(id: String, title: String, body: String, on date: Date) async {
        var parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        parts.hour = 9
        guard let fire = Calendar.current.date(from: parts), fire > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    /// Every scheduled #Cinema reminder, used when an account is deleted.
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static func cancel(ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
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
