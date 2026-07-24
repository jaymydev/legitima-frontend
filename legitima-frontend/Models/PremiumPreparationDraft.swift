import Combine
import Foundation

struct PremiumPreparationSnapshot: Codable {
    var anchorRole: String = ""
    var careerKeySteps: String = ""
    var careerTransitions: String = ""
    var baseAnalysis: AnalysisResponse?
}

@MainActor
final class PremiumPreparationDraft: ObservableObject {
    @Published var anchorRole: String {
        didSet { persist() }
    }
    @Published var careerKeySteps: String {
        didSet { persist() }
    }
    @Published var careerTransitions: String {
        didSet { persist() }
    }
    @Published var baseAnalysis: AnalysisResponse? {
        didSet { persist() }
    }

    private let storage: ProtectedJSONStore<PremiumPreparationSnapshot>

    convenience init() {
        self.init(storage: .premiumPreparation)
    }

    init(storage: ProtectedJSONStore<PremiumPreparationSnapshot>) {
        self.storage = storage
        let snapshot = storage.load() ?? PremiumPreparationSnapshot()
        anchorRole = snapshot.anchorRole
        careerKeySteps = snapshot.careerKeySteps
        careerTransitions = snapshot.careerTransitions
        baseAnalysis = snapshot.baseAnalysis
    }

    func reset() {
        anchorRole = ""
        careerKeySteps = ""
        careerTransitions = ""
        baseAnalysis = nil
        storage.remove()
    }

    private func persist() {
        storage.save(
            PremiumPreparationSnapshot(
                anchorRole: anchorRole,
                careerKeySteps: careerKeySteps,
                careerTransitions: careerTransitions,
                baseAnalysis: baseAnalysis
            )
        )
    }
}
