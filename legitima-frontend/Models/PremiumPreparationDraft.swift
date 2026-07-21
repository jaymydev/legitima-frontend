import Combine
import Foundation

final class PremiumPreparationDraft: ObservableObject {
    @Published var anchorRole: String = ""
    @Published var careerKeySteps: String = ""
    @Published var careerTransitions: String = ""
    @Published var baseAnalysis: AnalysisResponse?

    func reset() {
        anchorRole = ""
        careerKeySteps = ""
        careerTransitions = ""
        baseAnalysis = nil
    }
}
