import SwiftUI

struct PremiumInterviewEntryScreen: View {
    @EnvironmentObject private var interviewPreparationStore: InterviewPreparationStore

    @State private var selectedUseCase: InterviewUseCase?
    @State private var preparationResult: InterviewPreparationResponse?
    @State private var showRecruitmentFlow = false
    @State private var showQuestionnaire = false
    @State private var showResult = false

    var body: some View {
        InterviewUseCaseSelectionScreen(
            savedPreparation: interviewPreparationStore.saved,
            onSelect: select,
            onResume: resume
        )
        .navigationDestination(isPresented: $showRecruitmentFlow) {
            ContexteEntretienScreen()
        }
        .navigationDestination(isPresented: $showQuestionnaire) {
            questionnaireDestination
        }
        .navigationDestination(isPresented: $showResult) {
            resultDestination
        }
    }

    private func select(_ useCase: InterviewUseCase) {
        selectedUseCase = useCase
        if useCase.id == "recruitment" {
            showRecruitmentFlow = true
            return
        }

        interviewPreparationStore.start(useCase: useCase)
        showQuestionnaire = true
    }

    private func resume(_ saved: SavedInterviewPreparation) {
        guard let useCase = saved.useCase else { return }
        selectedUseCase = useCase

        if let result = saved.result {
            preparationResult = result
            showResult = true
        } else {
            showQuestionnaire = true
        }
    }

    @ViewBuilder
    private var questionnaireDestination: some View {
        if let selectedUseCase {
            InterviewQuestionnaireScreen(
                useCase: selectedUseCase,
                store: interviewPreparationStore,
                onComplete: { response in
                    preparationResult = response
                    showQuestionnaire = false
                    showResult = true
                },
                onBack: {
                    showQuestionnaire = false
                }
            )
        }
    }

    @ViewBuilder
    private var resultDestination: some View {
        if let preparationResult {
            InterviewPreparationResultScreen(
                response: preparationResult,
                onChooseAnother: {
                    showResult = false
                }
            )
        }
    }
}
