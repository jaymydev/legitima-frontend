import Combine
import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    enum Root {
        case onboarding
        case result(AnalysisResponse)
    }

    enum Route: Hashable {
        case progression
        case premiumUpsell
    }

    @Published var root: Root = .onboarding
    @Published var path: [Route] = []

    func showResult(_ response: AnalysisResponse) {
        root = .result(response)
        path = []
    }

    func showProgression() {
        path.append(.progression)
    }

    func showPremiumUpsell() {
        path.append(.premiumUpsell)
    }

    func backToResults() {
        path.removeAll()
    }

    func restartAnalysis() {
        path.removeAll()
        root = .onboarding
    }
}
