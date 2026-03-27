import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleWeeklyCheckInReminder(weekday: Int, hour: Int = 9, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["weekly_checkin"])

        let content = UNMutableNotificationContent()
        content.title = "Time for your weekly check-in!"
        content.body = "Log your progress photo to stay on track toward your Future Self."
        content.sound = .default

        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_checkin", content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleStreakMilestone(streakWeeks: Int) {
        let content = UNMutableNotificationContent()
        content.title = "\(streakWeeks)-Week Streak! 🔥"
        content.body = "You've been consistent for \(streakWeeks) weeks. Your Future Self is getting closer!"
        content.sound = .defaultCritical

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_\(streakWeeks)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
