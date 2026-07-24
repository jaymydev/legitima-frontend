import Combine
import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    enum Root {
        case access
        case onboarding
        case result(AnalysisResponse)
    }

    enum Route: Hashable {
        case progression
    }

    @Published var root: Root = .access
    @Published var path: [Route] = []

    func showResult(_ response: AnalysisResponse) {
        root = .result(response)
        path = []
    }

    func enterTestMode(savedAnalysis: AnalysisResponse?) {
        path = []
        root = savedAnalysis.map(Root.result) ?? .onboarding
    }

    func showProgression() {
        path.append(.progression)
    }

    func backToResults() {
        path.removeAll()
    }

    func restartAnalysis() {
        path.removeAll()
        root = .onboarding
    }
}
