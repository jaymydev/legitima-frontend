import Foundation

@main
struct LocalStateTests {
    @MainActor
    static func main() throws {
        try testInterviewDatePersistence()
        testInterviewCountdown()
        testInterviewRemindersNeverFireLateOrIntoThePast()
        try testOrphanedStorageIsDeleted()
        print("Local state tests passed")
    }

    /// The orphaned file held a copy of the analysis — the user's career
    /// history. Dropping the writing code without deleting it would have left
    /// personal data on every device that ran the old build.
    private static func testOrphanedStorageIsDeleted() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let kept = directory.appendingPathComponent("preparation.json")
        try Data("{}".utf8).write(to: kept)

        for name in OrphanedStorage.fileNames {
            try Data("{}".utf8).write(to: directory.appendingPathComponent(name))
        }

        OrphanedStorage.removeAll(in: directory)

        for name in OrphanedStorage.fileNames {
            precondition(
                !FileManager.default.fileExists(atPath: directory.appendingPathComponent(name).path),
                "\(name) doit être supprimé : il contient des données de carrière"
            )
        }
        precondition(
            FileManager.default.fileExists(atPath: kept.path),
            "le nettoyage ne doit toucher que les fichiers orphelins"
        )

        // Running on a device that never had the old build must not throw.
        OrphanedStorage.removeAll(in: directory)
    }

    private static func testInterviewRemindersNeverFireLateOrIntoThePast() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!

        func day(_ d: Int, hour: Int = 12) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 9, day: d, hour: hour))!
        }

        // Interview on the 20th, seen from the 1st: both reminders scheduled.
        let full = InterviewReminderPlan.reminders(
            interviewDate: day(20), now: day(1), calendar: calendar
        )
        precondition(full.count == 2)
        precondition(full.allSatisfy { calendar.component(.hour, from: $0.fireDate) == 9 },
                     "un rappel à l'heure de saisie réveillerait quelqu'un en pleine nuit")
        precondition(calendar.component(.day, from: full[0].fireDate) == 17)
        precondition(calendar.component(.day, from: full[1].fireDate) == 19)
        precondition(full[1].title.contains("demain"))
        precondition(full[1].body.contains("synthèse"), "la veille, l'artefact est la synthèse")

        // Two days out: the J-3 window has passed, only the eve remains.
        let late = InterviewReminderPlan.reminders(
            interviewDate: day(20), now: day(18), calendar: calendar
        )
        precondition(late.count == 1)
        precondition(late[0].title.contains("demain"))

        // Interview today, or already past: reminding someone about an
        // interview they have had is worse than saying nothing.
        precondition(InterviewReminderPlan.reminders(
            interviewDate: day(20), now: day(20), calendar: calendar).isEmpty)
        precondition(InterviewReminderPlan.reminders(
            interviewDate: day(20), now: day(25), calendar: calendar).isEmpty)

        // Date cleared: nothing to schedule.
        precondition(InterviewReminderPlan.reminders(
            interviewDate: nil, now: day(1), calendar: calendar).isEmpty)

        // Every identifier the plan can produce must be cancellable, or moving
        // the interview earlier leaves a reminder pointing at a dead day.
        let ids = Set(InterviewReminderPlan.allIdentifiers)
        precondition(full.allSatisfy { ids.contains($0.id) })
        precondition(ids.count == 2)
    }

    @MainActor
    private static func testInterviewDatePersistence() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = ProtectedJSONStore<PreparationSnapshot>(
            fileURL: directory.appendingPathComponent("preparation.json")
        )
        let store = LocalPreparationStore(storage: storage)

        precondition(store.snapshot.interviewDate == nil)

        let interviewDate = Calendar.current.date(byAdding: .day, value: 5, to: .now)!
        store.updateInterviewDate(interviewDate)

        let restored = LocalPreparationStore(storage: storage)
        precondition(restored.snapshot.interviewDate != nil)

        restored.updateInterviewDate(nil)
        precondition(LocalPreparationStore(storage: storage).snapshot.interviewDate == nil)

        // The declared interview intent persists and can be cleared.
        precondition(store.snapshot.intendedUseCaseID == nil)
        store.updateIntendedUseCase("annual_review")
        precondition(
            LocalPreparationStore(storage: storage).snapshot.intendedUseCaseID == "annual_review"
        )
        store.updateIntendedUseCase(nil)
        precondition(LocalPreparationStore(storage: storage).snapshot.intendedUseCaseID == nil)

        // Un état écrit par une version antérieure doit encore se décoder.
        // Le pivot a retiré le parcours, le point sensible, l'analyse et le
        // kickoff : ces clés traînent sur les appareils qui ont vu l'ancienne
        // app, et les ignorer vaut mieux que perdre la date d'entretien qui,
        // elle, survit.
        let legacyJSON = Data(
            """
            {"targetRole":"Rôle","careerSummary":"Résumé","sensitivePoint":"",
             "analysis":null,"debrief":null,"kickoff":null,"updatedAt":0}
            """.utf8
        )
        let legacy = try JSONDecoder().decode(PreparationSnapshot.self, from: legacyJSON)
        precondition(legacy.interviewDate == nil)
        precondition(legacy.intendedUseCaseID == nil)

        try? FileManager.default.removeItem(at: directory)
    }

    private static func testInterviewCountdown() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        precondition(InterviewCountdown.daysUntil(now, from: now) == 0)
        precondition(
            InterviewCountdown.daysUntil(calendar.date(byAdding: .day, value: 1, to: today)!, from: now) == 1
        )
        precondition(
            InterviewCountdown.daysUntil(calendar.date(byAdding: .day, value: 12, to: today)!, from: now) == 12
        )
        precondition(
            InterviewCountdown.daysUntil(calendar.date(byAdding: .day, value: -1, to: today)!, from: now) == nil
        )

        precondition(InterviewCountdown.label(daysUntil: 0) == "Votre entretien a lieu aujourd'hui")
        precondition(InterviewCountdown.label(daysUntil: 1) == "Votre entretien a lieu demain")
        precondition(InterviewCountdown.label(daysUntil: 5) == "Votre entretien a lieu dans 5 jours")
    }
}
