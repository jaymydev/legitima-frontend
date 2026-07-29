import SwiftUI

struct PremiumInterviewEntryScreen: View {
    @EnvironmentObject private var interviewPreparationStore: InterviewPreparationStore
    @EnvironmentObject private var preparationStore: LocalPreparationStore

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
            recruitmentDestination
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
            interviewPreparationStore.start(useCase: useCase)
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
        } else if useCase.id == "recruitment" {
            showRecruitmentFlow = true
        } else {
            showQuestionnaire = true
        }
    }

    @ViewBuilder
    private var recruitmentDestination: some View {
        if let selectedUseCase {
            RecruitmentPremiumFlowScreen(
                useCase: selectedUseCase,
                store: interviewPreparationStore,
                context: recruitmentContext,
                onTargetRoleChange: { targetRole in
                    preparationStore.updateTargetRole(targetRole)
                },
                onComplete: { response in
                    preparationResult = response
                    showRecruitmentFlow = false
                    showResult = true
                }
            )
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
            response.legitimacy_anchor.objective_strength,
        ].joined(separator: "\n\n")
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
