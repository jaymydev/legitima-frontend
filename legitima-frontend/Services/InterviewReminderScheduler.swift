import Foundation
import UserNotifications

/// Schedules the local reminders described by `InterviewReminderPlan`.
///
/// Everything is local: no account, no server, no push certificate. The user
/// supplied the date themselves, which is why asking permission at that exact
/// moment reads as the app doing what it was told rather than as a demand.
@MainActor
final class InterviewReminderScheduler {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// Bring the scheduled reminders in line with the saved date.
    ///
    /// Always clears the previous ones first: moving the interview earlier
    /// would otherwise leave a reminder pointing at a day that no longer
    /// means anything.
    func sync(interviewDate: Date?, now: Date = .now) async {
        center.removePendingNotificationRequests(
            withIdentifiers: InterviewReminderPlan.allIdentifiers
        )

        let reminders = InterviewReminderPlan.reminders(interviewDate: interviewDate, now: now)
        guard !reminders.isEmpty, await hasPermission() else { return }

        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminder.fireDate
            )
            try? await center.add(
                UNNotificationRequest(
                    identifier: reminder.id,
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
            )
        }
    }

    /// Asks once, and never again after a refusal — the date still drives the
    /// in-app countdown, so a declined permission costs the user nothing.
    private func hasPermission() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        default:
            return false
        }
    }
}
