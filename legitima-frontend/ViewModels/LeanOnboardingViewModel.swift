import Foundation
import Combine

@MainActor
final class LeanOnboardingViewModel: ObservableObject {
    @Published var posteVise: String = ""
    @Published var parcoursResume: String = ""
    @Published var zoneSensible: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var analysisResponse: AnalysisResponse?

    private let iaService = IAService()

    func analyze() {
        let trimmedPosteVise = posteVise.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedParcoursResume = parcoursResume.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedPosteVise.isEmpty, !trimmedParcoursResume.isEmpty else {
            errorMessage = "Veuillez renseigner le poste visé et votre parcours résumé."
            return
        }

        errorMessage = nil
        isLoading = true

        Task {
            defer { isLoading = false }

            do {
                let request = AnalyzeRequest(
                    input: FilConducteurRequest(
                        meta: .init(
                            version: "1.0",
                            language: "fr",
                            target_market: "US",
                            interview_type: "recruitment"
                        ),
                        narrative_positioning: .init(
                            short_summary: trimmedParcoursResume,
                            current_positioning: trimmedPosteVise,
                            evolution_logic: zoneSensible.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    )
                )

                analysisResponse = try await iaService.analyze(request: request)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
