import Foundation

/// What to remind, and when, from the interview date the user already gave us.
///
/// That date was collected to « rythmer votre préparation jusqu'au jour J » and
/// until now it only decremented a label nobody was told to come back and read.
/// This is the one moment the app has a legitimate reason to reach out.
///
/// Foundation-only so the pacing and the copy can be tested without a
/// notification centre.
enum InterviewReminderPlan {
    struct Reminder: Equatable {
        let id: String
        let fireDate: Date
        let title: String
        let body: String
    }

    /// Notifications are fired at this hour, local time, rather than at the
    /// moment the date was entered — nobody wants a reminder at 02:14.
    static let hourOfDay = 9

    /// Three days out there is still time to work; the evening before, the
    /// exported synthesis is the revision artefact (docs § 5).
    private static let daysBefore = [3, 1]

    /// - Parameter interviewDate: the day of the interview, or nil once the
    ///   user clears it — which must cancel everything.
    /// - Returns: reminders to schedule, always in the future. Empty when the
    ///   date is absent, today, or past: reminding someone about an interview
    ///   they have already had is worse than saying nothing.
    static func reminders(
        interviewDate: Date?,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Reminder] {
        guard let interviewDate else { return [] }

        return daysBefore.compactMap { offset in
            guard
                let day = calendar.date(byAdding: .day, value: -offset, to: interviewDate),
                let fireDate = calendar.date(
                    bySettingHour: hourOfDay, minute: 0, second: 0, of: day
                ),
                fireDate > now
            else {
                return nil
            }

            return Reminder(
                id: "interview-reminder-\(offset)",
                fireDate: fireDate,
                title: title(daysBefore: offset),
                body: body(daysBefore: offset)
            )
        }
    }

    /// Every identifier this plan can ever produce, so cancelling never leaves
    /// a stale notification behind when the date moves earlier.
    static var allIdentifiers: [String] {
        daysBefore.map { "interview-reminder-\($0)" }
    }

    private static func title(daysBefore days: Int) -> String {
        days == 1 ? "Votre entretien a lieu demain" : "Votre entretien est dans \(days) jours"
    }

    private static func body(daysBefore days: Int) -> String {
        days == 1
            ? "Relisez votre synthèse : les points à faire passer et votre plan d’action."
            : "Il reste du temps pour préparer vos réponses aux questions difficiles."
    }
}
