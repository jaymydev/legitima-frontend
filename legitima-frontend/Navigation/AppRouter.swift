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
        case kickoff
        case interviewEntry
        /// Maquette du pivot : les questions préparées pour le type choisi.
        case preparedQuestions(String)
    }

    @Published var root: Root = .access
    @Published var path: [Route] = []

    func showResult(_ response: AnalysisResponse) {
        root = .result(response)
        path = []
    }

    func enterApp(savedAnalysis: AnalysisResponse?) {
        path = []
        root = savedAnalysis.map(Root.result) ?? .onboarding
    }

    func showPreparedQuestions(useCaseID: String) {
        path.append(.preparedQuestions(useCaseID))
    }

    func showInterviewEntry() {
        path.append(.interviewEntry)
    }

    func showKickoff() {
        path.append(.kickoff)
    }

    /// Leaving the kickoff replaces it in the stack so back never returns to
    /// a generation the user has already moved past.
    func continueFromKickoff() {
        path = [.interviewEntry]
    }

    func backToResults() {
        path.removeAll()
    }

    func restartAnalysis() {
        path.removeAll()
        root = .onboarding
    }
}
