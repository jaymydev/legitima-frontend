import Combine
import Foundation

final class PremiumPreparationDraft: ObservableObject {
    @Published var anchorRole: String = ""
    @Published var baseAnalysis: AnalysisResponse?

    func reset() {
        anchorRole = ""
        baseAnalysis = nil
    }
}
