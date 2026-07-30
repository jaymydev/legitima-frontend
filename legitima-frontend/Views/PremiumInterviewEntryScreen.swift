import SwiftUI

struct PremiumInterviewEntryScreen: View {
    private static let recruitmentUseCaseID = "recruitment"

    private enum Phase {
        case loading
        case loadingFailed
        case recruitment(InterviewUseCase)
        case questionnaire(InterviewUseCase)
        case result(InterviewPreparationResponse)
        case chooseUseCase
    }

    @EnvironmentObject private var interviewPreparationStore: InterviewPreparationStore
    @EnvironmentObject private var preparationStore: LocalPreparationStore

    @StateObject private var useCasesViewModel = InterviewUseCasesViewModel()
    @State private var phase: Phase = .loading

    var body: some View {
        content
            .task {
                await resolveInitialPhase()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            loadingView

        case .loadingFailed:
            loadingFailedView

        case .recruitment(let useCase):
            RecruitmentPremiumFlowScreen(
                useCase: useCase,
                store: interviewPreparationStore,
                context: recruitmentContext,
                onTargetRoleChange: { targetRole in
                    preparationStore.updateTargetRole(targetRole)
                },
                onComplete: { response in
                    phase = .result(response)
                }
            )

        case .questionnaire(let useCase):
            InterviewQuestionnaireScreen(
                useCase: useCase,
                store: interviewPreparationStore,
                onComplete: { response in
                    phase = .result(response)
                },
                onBack: {
                    phase = .chooseUseCase
                }
            )

        case .result(let response):
            InterviewPreparationResultScreen(
                response: response,
                onChooseAnother: {
                    phase = .chooseUseCase
                }
            )

        case .chooseUseCase:
            InterviewUseCaseSelectionScreen(
                savedPreparation: interviewPreparationStore.saved,
                onSelect: select,
                onResume: resume
            )
        }
    }

    private var loadingView: some View {
        ZStack {
            entryBackground
            ProgressView("Préparation de votre parcours…")
        }
    }

    private var loadingFailedView: some View {
        ZStack {
            entryBackground
            VStack(spacing: 14) {
                Text("Impossible de charger votre préparation. Vérifiez votre connexion puis réessayez.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button("Réessayer") {
                    Task { await startRecruitmentContinuation() }
                }
                .fontWeight(.semibold)
            }
            .padding(24)
        }
    }

    private var entryBackground: some View {
        LinearGradient(
            colors: [
                Color(light: .rgb(218, 249, 246), dark: LegitimaColors.darkBackgroundTop),
                Color(light: .rgb(247, 242, 232), dark: LegitimaColors.darkBackgroundBottom)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func resolveInitialPhase() async {
        guard case .loading = phase else { return }

        switch PremiumEntryRouting.destination(
            for: interviewPreparationStore.saved,
            recruitmentUseCaseID: Self.recruitmentUseCaseID
        ) {
        case .result(let result):
            phase = .result(result)
        case .recruitment(let useCase):
            phase = .recruitment(useCase)
        case .questionnaire(let useCase):
            phase = .questionnaire(useCase)
        case .startRecruitment:
            await startRecruitmentContinuation()
        }
    }

    private func startRecruitmentContinuation() async {
        phase = .loading

        if let recruitment = recruitmentUseCase {
            begin(recruitment)
            return
        }

        await useCasesViewModel.load()

        if let recruitment = recruitmentUseCase {
            begin(recruitment)
        } else {
            phase = .loadingFailed
        }
    }

    private var recruitmentUseCase: InterviewUseCase? {
        useCasesViewModel.useCases.first { $0.id == Self.recruitmentUseCaseID }
    }

    private func begin(_ useCase: InterviewUseCase) {
        interviewPreparationStore.start(useCase: useCase)
        phase = .recruitment(useCase)
    }

    private func select(_ useCase: InterviewUseCase) {
        interviewPreparationStore.start(useCase: useCase)
        if useCase.id == Self.recruitmentUseCaseID {
            phase = .recruitment(useCase)
        } else {
            phase = .questionnaire(useCase)
        }
    }

    private func resume(_ saved: SavedInterviewPreparation) {
        guard let useCase = saved.useCase else { return }

        if let result = saved.result {
            phase = .result(result)
        } else if useCase.id == Self.recruitmentUseCaseID {
            phase = .recruitment(useCase)
        } else {
            phase = .questionnaire(useCase)
        }
    }

    private var recruitmentContext: InterviewPreparationContext {
        let snapshot = preparationStore.snapshot
        return InterviewPreparationContext(
            targetRole: snapshot.targetRole,
            careerExperiences: snapshot.careerSummary,
            sensitivePoint: snapshot.sensitivePoint,
            freemiumAnalysis: snapshot.analysis.map(freemiumSummary) ?? ""
        )
    }

    private func freemiumSummary(_ response: AnalysisResponse) -> String {
        [
            response.analysis.strategic_reading,
            response.analysis.dominant_competencies,
            response.analysis.career_logic,
            response.sensitive_reframing.strategic_reinterpretation,
            response.narrative.core_thread,
            response.interview_preparation.probable_objections,
            response.interview_preparation.structured_answers,
            response.legitimacy_anchor.objective_strength,
        ].joined(separator: "\n\n")
    }
}
