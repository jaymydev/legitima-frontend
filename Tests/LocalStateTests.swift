import Foundation

@main
struct LocalStateTests {
    @MainActor
    static func main() throws {
        try testDraftAndAnalysisRestoration()
        testDailyTestQuota()
        print("Local state tests passed")
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
