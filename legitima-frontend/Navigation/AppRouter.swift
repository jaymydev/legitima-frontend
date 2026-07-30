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
        case premiumKickoff
        case premiumInterviewEntry
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

    func showPremiumInterviewEntry() {
        path.append(.premiumInterviewEntry)
    }

    func showPremiumKickoff() {
        path.append(.premiumKickoff)
    }

    /// Leaving the kickoff replaces it in the stack so back never returns to
    /// a stale purchase transition.
    func continueFromKickoff() {
        path = [.premiumInterviewEntry]
    }

    func backToResults() {
        path.removeAll()
    }

    func restartAnalysis() {
        path.removeAll()
        root = .onboarding
    }
}
