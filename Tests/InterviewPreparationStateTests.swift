import Foundation

@main
struct InterviewPreparationStateTests {
    @MainActor
    static func main() throws {
        try testBackendCatalogDecoding()
        try testProtectedDraftAndResultRestoration()
        testRequiredQuestionValidation()
        testShortAnswersRemainValidButAreFlagged()
        testFreemiumEntryStillUsesLeanOnboarding()
        try testRecruitmentRequestReusesFreemiumContext()
        testExportContentAssembly()
        print("Interview preparation state tests passed")
    }

    private static func testShortAnswersRemainValidButAreFlagged() {
        let answers = ["role_context": "A"]

        precondition(sampleUseCase.hasAllRequiredAnswers(answers))
        precondition(InterviewAnswerQuality.isTooShort("A"))
        precondition(InterviewAnswerQuality.isTooShort(" abc "))
        precondition(!InterviewAnswerQuality.isTooShort(""))
        precondition(!InterviewAnswerQuality.isTooShort("abcd"))
    }

    private static func testBackendCatalogDecoding() throws {
        let data = """
        {
          "use_cases": [
            {
              "id": "mid_year",
              "title": "Entretien de mi-année",
              "short_title": "Mi-année",
              "description": "Faire le point.",
              "questionnaire_version": "1.0",
              "questions": [
                {
                  "id": "role_context",
                  "title": "Quel est votre rôle ?",
                  "helper": "Résumez votre périmètre.",
                  "required": true,
                  "input_type": "long_text",
                  "options": []
                }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        let catalog = try JSONDecoder().decode(InterviewUseCaseCatalog.self, from: data)
        precondition(catalog.useCases.first?.id == "mid_year")
        precondition(catalog.useCases.first?.questions.first?.required == true)
    }

    @MainActor
    private static func testProtectedDraftAndResultRestoration() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = ProtectedJSONStore<SavedInterviewPreparation>(
            fileURL: directory.appendingPathComponent("interview.json")
        )
        let useCase = sampleUseCase
        let store = InterviewPreparationStore(storage: storage)

        store.start(useCase: useCase)
        store.saveDraft(useCase: useCase, answers: ["role_context": "Responsable produit"])
        store.saveResult(sampleResult)

        let restored = InterviewPreparationStore(storage: storage)
        precondition(restored.saved.hasWork)
        precondition(restored.saved.useCase == useCase)
        precondition(restored.saved.answers["role_context"] == "Responsable produit")
        precondition(restored.saved.result == sampleResult)

        restored.clear()
        precondition(!InterviewPreparationStore(storage: storage).saved.hasWork)
        try? FileManager.default.removeItem(at: directory)
    }

    private static func testRequiredQuestionValidation() {
        precondition(!sampleUseCase.hasAllRequiredAnswers([:]))
        precondition(!sampleUseCase.hasAllRequiredAnswers(["optional": "Texte facultatif"]))
        precondition(
            sampleUseCase.hasAllRequiredAnswers(["role_context": "Responsable produit"])
        )
    }

    @MainActor
    private static func testFreemiumEntryStillUsesLeanOnboarding() {
        let router = AppRouter()

        router.enterTestMode(savedAnalysis: nil)
        guard case .onboarding = router.root else {
            preconditionFailure("Empty test sessions must open LeanOnboarding")
        }

        router.enterTestMode(savedAnalysis: sampleLeanAnalysis)
        guard case .result(let restored) = router.root else {
            preconditionFailure("Saved analyses must reopen their result")
        }
        precondition(restored == sampleLeanAnalysis)

        router.showPremiumInterviewEntry()
        precondition(
            router.path == [.premiumInterviewEntry],
            "Premium results must open the guided preparation directly"
        )
    }

    private static func testRecruitmentRequestReusesFreemiumContext() throws {
        let request = InterviewPreparationRequest(
            useCaseID: "recruitment",
            questionnaireVersion: "1.1",
            answers: [
                InterviewAnswer(questionID: "interview_stage", answer: "Entretien manager"),
                InterviewAnswer(questionID: "desired_takeaway", answer: "Ma légitimité"),
            ],
            context: InterviewPreparationContext(
                targetRole: "Responsable produit",
                careerExperiences: "Coordination de projets",
                sensitivePoint: "Transition",
                freemiumAnalysis: "Parcours cohérent"
            )
        )

        let encoded = try JSONEncoder().encode(request)
        let object = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        let context = object?["context"] as? [String: String]

        precondition(context?["target_role"] == "Responsable produit")
        precondition(context?["career_experiences"] == "Coordination de projets")
        precondition(object?["file"] == nil)
        precondition(object?["cv"] == nil)
    }

    private static func testExportContentAssembly() {
        let content = PreparationExportContent(response: sampleResult)

        precondition(content.title == "Préparation mi-année")
        precondition(content.blocks.count == 4)
        precondition(content.blocks[0].title == "Votre ligne directrice")
        precondition(content.blocks[0].paragraphs == ["Bilan factuel."])
        precondition(content.blocks[1].title == "Avancement")
        precondition(content.blocks[2].title == "Points à faire passer")
        precondition(content.blocks[2].numbered)
        precondition(content.blocks[3].title == "Plan d'action")

        // Empty and whitespace-only material must be dropped, not exported blank.
        let sparse = InterviewPreparationResponse(
            useCaseID: "recruitment",
            title: " Préparation ",
            summary: "  ",
            sections: [InterviewPreparationSection(title: "Vide", content: " \n ")],
            talkingPoints: ["  ", "Un seul point"],
            actionPlan: []
        )
        let sparseContent = PreparationExportContent(response: sparse)
        precondition(sparseContent.title == "Préparation")
        precondition(sparseContent.blocks.count == 1)
        precondition(sparseContent.blocks[0].title == "Points à faire passer")
        precondition(sparseContent.blocks[0].paragraphs == ["Un seul point"])
    }

    private static let sampleUseCase = InterviewUseCase(
        id: "mid_year",
        title: "Entretien de mi-année",
        shortTitle: "Mi-année",
        description: "Faire le point.",
        questionnaireVersion: "1.0",
        questions: [
            InterviewQuestion(
                id: "role_context",
                title: "Quel est votre rôle ?",
                helper: "Résumez votre périmètre.",
                required: true,
                inputType: "long_text",
                options: []
            ),
            InterviewQuestion(
                id: "optional",
                title: "Un obstacle ?",
                helper: "Facultatif.",
                required: false,
                inputType: "long_text",
                options: []
            ),
        ]
    )

    private static let sampleResult = InterviewPreparationResponse(
        useCaseID: "mid_year",
        title: "Préparation mi-année",
        summary: "Bilan factuel.",
        sections: [
            InterviewPreparationSection(title: "Avancement", content: "Objectifs en cours.")
        ],
        talkingPoints: ["Présenter les résultats."],
        actionPlan: ["Définir les priorités."]
    )

    private static let sampleLeanAnalysis = AnalysisResponse(
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
