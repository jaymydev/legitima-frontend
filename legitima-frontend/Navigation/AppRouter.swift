import Combine
import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    enum Root {
        case access
        case interviewUseCases
        case onboarding
        case result(AnalysisResponse)
        case interviewQuestionnaire(InterviewUseCase)
        case interviewPreparationResult(InterviewPreparationResponse)
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

    func enterTestMode() {
        path = []
        root = .interviewUseCases
    }

    func showInterviewUseCases() {
        path = []
        root = .interviewUseCases
    }

    func startRecruitment(savedAnalysis: AnalysisResponse?) {
        path = []
        root = savedAnalysis.map(Root.result) ?? .onboarding
    }

    func startInterviewQuestionnaire(_ useCase: InterviewUseCase) {
        path = []
        root = .interviewQuestionnaire(useCase)
    }

    func showInterviewPreparationResult(_ response: InterviewPreparationResponse) {
        path = []
        root = .interviewPreparationResult(response)
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
