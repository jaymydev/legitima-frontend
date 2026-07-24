import Foundation

@main
struct InterviewPreparationStateTests {
    @MainActor
    static func main() throws {
        try testBackendCatalogDecoding()
        try testProtectedDraftAndResultRestoration()
        testRequiredQuestionValidation()
        print("Interview preparation state tests passed")
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
                  "input_type": "long_text"
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
                inputType: "long_text"
            ),
            InterviewQuestion(
                id: "optional",
                title: "Un obstacle ?",
                helper: "Facultatif.",
                required: false,
                inputType: "long_text"
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
}
