import Foundation

@main
struct LocalStateTests {
    @MainActor
    static func main() throws {
        try testDraftAndAnalysisRestoration()
        try testInterviewDatePersistence()
        testInterviewCountdown()
        testObjectionTeaserExtraction()
        testDailyTestQuota()
        testSimulatedPremiumUnlockPersistence()
        testLoadingProgressNeverOverclaims()
        print("Local state tests passed")
    }

    private static func testLoadingProgressNeverOverclaims() {
        let typical: TimeInterval = 18

        // Starts at zero and only ever moves forward.
        precondition(LoadingProgressEstimate.progress(elapsed: 0, typicalDuration: typical) == 0)
        var previous = 0.0
        for second in stride(from: 0.0, through: 120.0, by: 0.5) {
            let value = LoadingProgressEstimate.progress(elapsed: second, typicalDuration: typical)
            precondition(value >= previous, "la progression ne doit jamais reculer")
            precondition(value <= LoadingProgressEstimate.ceiling)
            previous = value
        }

        // The ceiling is the whole point: the backend gives no progress
        // signal, so the bar must never sit at 100 % while still waiting.
        precondition(
            LoadingProgressEstimate.progress(elapsed: 600, typicalDuration: typical)
                < LoadingProgressEstimate.ceiling + 0.0001
        )
        precondition(
            LoadingProgressEstimate.progress(elapsed: 600, typicalDuration: typical) > 0.9
        )

        // It should feel like it is moving early on, then visibly decelerate.
        let atQuarter = LoadingProgressEstimate.progress(elapsed: typical / 4, typicalDuration: typical)
        let atTypical = LoadingProgressEstimate.progress(elapsed: typical, typicalDuration: typical)
        precondition(atQuarter > 0.2, "trop lent au démarrage : l'attente paraîtrait figée")
        precondition(atTypical > 0.7 && atTypical < LoadingProgressEstimate.ceiling)

        // Steps derive from the same value, so words and number agree.
        precondition(LoadingProgressEstimate.stepIndex(for: 0.1, count: 3) == 0)
        precondition(LoadingProgressEstimate.stepIndex(for: 0.5, count: 3) == 1)
        precondition(LoadingProgressEstimate.stepIndex(for: 0.85, count: 3) == 2)
        // A shorter list must not index out of bounds.
        precondition(LoadingProgressEstimate.stepIndex(for: 0.85, count: 2) == 1)
        precondition(LoadingProgressEstimate.stepIndex(for: 0.5, count: 1) == 0)

        // The notice appears once, then escalates once. Never before 12 s.
        precondition(LoadingProgressEstimate.slowNotice(elapsed: 5) == nil)
        precondition(LoadingProgressEstimate.slowNotice(elapsed: 11.9) == nil)
        let first = LoadingProgressEstimate.slowNotice(elapsed: 20)
        let second = LoadingProgressEstimate.slowNotice(elapsed: 45)
        precondition(first != nil && second != nil && first != second)
        precondition(second?.contains("conservées") == true)
    }

    @MainActor
    private static func testDraftAndAnalysisRestoration() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("preparation.json")
        let storage = ProtectedJSONStore<PreparationSnapshot>(fileURL: fileURL)
        let store = LocalPreparationStore(storage: storage)

        store.saveDraft(
            targetRole: "Responsable produit",
            careerSummary: "Développement puis coordination",
            sensitivePoint: "Transition en 2025"
        )
        store.saveAnalysis(sampleAnalysis)

        let restored = LocalPreparationStore(storage: storage)
        precondition(restored.hasSavedWork)
        precondition(restored.snapshot.targetRole == "Responsable produit")
        precondition(restored.snapshot.careerSummary == "Développement puis coordination")
        precondition(restored.snapshot.sensitivePoint == "Transition en 2025")
        precondition(restored.snapshot.analysis == sampleAnalysis)

        restored.updateTargetRole("Directrice produit")
        let updatedRole = LocalPreparationStore(storage: storage)
        precondition(updatedRole.snapshot.targetRole == "Directrice produit")
        precondition(updatedRole.snapshot.analysis == sampleAnalysis)

        updatedRole.beginNewAnalysis()
        let restarted = LocalPreparationStore(storage: storage)
        precondition(restarted.hasSavedWork)
        precondition(restarted.snapshot.analysis == nil)
        precondition(restarted.snapshot.targetRole == "Directrice produit")

        restarted.clear()
        precondition(!LocalPreparationStore(storage: storage).hasSavedWork)
        try? FileManager.default.removeItem(at: directory)
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

        // Snapshots saved before the interviewDate and intendedUseCaseID
        // fields existed must still decode.
        let legacyJSON = """
        {"targetRole":"Rôle","careerSummary":"Résumé","sensitivePoint":"","updatedAt":0}
        """.data(using: .utf8)!
        let legacy = try JSONDecoder().decode(PreparationSnapshot.self, from: legacyJSON)
        precondition(legacy.interviewDate == nil)
        precondition(legacy.intendedUseCaseID == nil)
        precondition(legacy.targetRole == "Rôle")

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

    private static func testObjectionTeaserExtraction() {
        // Empty or whitespace-only input yields nothing.
        precondition(ObjectionTeaser.firstObjection(from: "") == nil)
        precondition(ObjectionTeaser.firstObjection(from: "  \n\n  ") == nil)

        // A plain question is returned as-is, punctuation included.
        precondition(
            ObjectionTeaser.firstObjection(from: "Pourquoi une transition en 2025 ?")
                == "Pourquoi une transition en 2025 ?"
        )

        // Only the first sentence of a paragraph is kept.
        precondition(
            ObjectionTeaser.firstObjection(
                from: "Votre parcours manque de continuité. Il faudra aussi expliquer le changement de secteur."
            ) == "Votre parcours manque de continuité."
        )

        // List markers are stripped and only the first item is used.
        precondition(
            ObjectionTeaser.firstObjection(
                from: "- Pourquoi avoir quitté votre poste ?\n- Que faisiez-vous en 2025 ?"
            ) == "Pourquoi avoir quitté votre poste ?"
        )
        precondition(
            ObjectionTeaser.firstObjection(
                from: "1. Première objection notable ?\n2. Seconde objection ?"
            ) == "Première objection notable ?"
        )

        // Blank leading lines are skipped.
        precondition(
            ObjectionTeaser.firstObjection(from: "\n\n• Objection après lignes vides ?")
                == "Objection après lignes vides ?"
        )

        // Long sentences are truncated with an ellipsis under the cap.
        let long = String(repeating: "a", count: 300)
        let truncated = ObjectionTeaser.firstObjection(from: long)
        precondition(truncated != nil)
        precondition(truncated!.count <= 180)
        precondition(truncated!.hasSuffix("..."))
    }

    @MainActor
    private static func testDailyTestQuota() {
        let suiteName = "LocalStateTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("Unable to create isolated UserDefaults")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(0, forKey: "user_status.remaining_free_analyses")
        defaults.set(2, forKey: "user_status.configured_daily_limit")

        let status = UserStatus(defaults: defaults)
        precondition(status.remainingFreeAnalyses == 20)

        for _ in 0..<20 {
            precondition(status.canStartAnalysis)
            status.consumeFreeAnalysisIfNeeded()
        }

        precondition(status.remainingFreeAnalyses == 0)
        precondition(!status.canStartAnalysis)
    }

    @MainActor
    private static func testSimulatedPremiumUnlockPersistence() {
        let suiteName = "LocalStateTests.premium.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("Unable to create isolated UserDefaults")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SimulatedPremiumUnlockStore(defaults: defaults)
        precondition(!store.isUnlocked)

        store.unlock()
        precondition(store.isUnlocked)

        let reloaded = SimulatedPremiumUnlockStore(defaults: defaults)
        precondition(reloaded.isUnlocked)

        reloaded.reset()
        precondition(!store.isUnlocked)
    }

    private static let sampleAnalysis = AnalysisResponse(
        analysis: AnalysisSection(
            strategic_reading: "Lecture",
            dominant_competencies: "Compétences",
            career_logic: "Logique"
        ),
        sensitive_reframing: SensitiveSection(
            identified_fragilities: "Fragilité",
            strategic_reinterpretation: "Réinterprétation",
            rational_reframing: "Reformulation"
        ),
        narrative: NarrativeSection(
            core_thread: "Fil",
            positioning_statement: "Positionnement"
        ),
        interview_preparation: InterviewSection(
            probable_objections: "Objections",
            structured_answers: "Réponses"
        ),
        legitimacy_anchor: LegitimacySection(
            objective_strength: "Force",
            final_alignment_statement: "Alignement"
        )
    )
}
