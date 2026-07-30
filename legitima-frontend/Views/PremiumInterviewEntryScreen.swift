import SwiftUI

struct PremiumInterviewEntryScreen: View {
    private static let recruitmentUseCaseID = "recruitment"

    private enum Phase: Equatable {
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
            .transition(.opacity)
            .animation(LegitimaMotion.reveal, value: phase)
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
                context: leanContext,
                onTargetRoleChange: { targetRole in
                    preparationStore.updateTargetRole(targetRole)
                },
                onComplete: { response in
                    phase = .result(response)
                },
                onChangeUseCase: {
                    phase = .chooseUseCase
                }
            )

        case .questionnaire(let useCase):
            InterviewQuestionnaireScreen(
                useCase: useCase,
                store: interviewPreparationStore,
                context: leanContext,
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
                    .foregroundColor(LegitimaColors.muted)
                    .multilineTextAlignment(.center)

                Button("Réessayer") {
                    Task { await startContinuation(useCaseID: initialUseCaseID) }
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
            intendedUseCaseID: preparationStore.snapshot.intendedUseCaseID,
            recruitmentUseCaseID: Self.recruitmentUseCaseID
        ) {
        case .result(let result):
            phase = .result(result)
        case .recruitment(let useCase):
            await resumeOrRestart(useCase)
        case .questionnaire(let useCase):
            await resumeOrRestart(useCase)
        case .startUseCase(let id):
            await startContinuation(useCaseID: id)
        }
    }

    private var initialUseCaseID: String {
        preparationStore.snapshot.intendedUseCaseID ?? Self.recruitmentUseCaseID
    }

    private func startContinuation(useCaseID: String) async {
        phase = .loading

        if let useCase = useCase(withID: useCaseID) {
            begin(useCase)
            return
        }

        await useCasesViewModel.load()

        if let useCase = useCase(withID: useCaseID) {
            begin(useCase)
        } else if let recruitment = useCase(withID: Self.recruitmentUseCaseID) {
            // Unknown intent ID (e.g. removed from the catalog): fall back.
            begin(recruitment)
        } else {
            phase = .loadingFailed
        }
    }

    private func useCase(withID id: String) -> InterviewUseCase? {
        useCasesViewModel.useCases.first { $0.id == id }
    }

    private func begin(_ useCase: InterviewUseCase) {
        interviewPreparationStore.startNew(useCase: useCase)
        show(useCase)
    }

    private func select(_ useCase: InterviewUseCase) {
        begin(useCase)
    }

    private func resume(_ saved: SavedInterviewPreparation) {
        guard let useCase = saved.useCase else { return }

        if let result = saved.result {
            phase = .result(result)
        } else {
            Task { await resumeOrRestart(useCase) }
        }
    }

    /// Open a saved draft, or start over when the questionnaire it was filled
    /// against has since changed. Letting the user complete a form the backend
    /// will refuse is worse than asking them to begin again.
    private func resumeOrRestart(_ savedUseCase: InterviewUseCase) async {
        phase = .loading
        await useCasesViewModel.load()

        guard let current = useCase(withID: savedUseCase.id) else {
            // Catalog unreachable, or the use case was withdrawn: keep the work.
            show(savedUseCase)
            return
        }

        if interviewPreparationStore.saved.isStale(comparedTo: current) {
            begin(current)
        } else {
            show(current)
        }
    }

    private func show(_ useCase: InterviewUseCase) {
        phase = useCase.id == Self.recruitmentUseCaseID
            ? .recruitment(useCase)
            : .questionnaire(useCase)
    }

    /// Every use case starts from the free analysis, not just recruitment:
    /// the « récit → réponses » mechanism is what the premium is bought for.
    private var leanContext: InterviewPreparationContext {
        .lean(from: preparationStore.snapshot)
    }
}
