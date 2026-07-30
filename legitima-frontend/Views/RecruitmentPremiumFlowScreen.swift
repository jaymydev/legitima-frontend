import SwiftUI

struct RecruitmentPremiumFlowScreen: View {
    @StateObject private var viewModel: InterviewQuestionnaireViewModel
    @State private var step = 0
    @State private var targetRole: String

    let context: InterviewPreparationContext
    let onTargetRoleChange: (String) -> Void
    let onComplete: (InterviewPreparationResponse) -> Void
    let onChangeUseCase: (() -> Void)?

    private let accent = LegitimaColors.accent

    init(
        useCase: InterviewUseCase,
        store: InterviewPreparationStore,
        context: InterviewPreparationContext,
        onTargetRoleChange: @escaping (String) -> Void,
        onComplete: @escaping (InterviewPreparationResponse) -> Void,
        onChangeUseCase: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: InterviewQuestionnaireViewModel(
                useCase: useCase,
                store: store,
                context: context
            )
        )
        _targetRole = State(initialValue: context.targetRole)
        self.context = context
        self.onTargetRoleChange = onTargetRoleChange
        self.onComplete = onComplete
        self.onChangeUseCase = onChangeUseCase
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(light: .rgb(218, 249, 246), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(247, 242, 232), dark: LegitimaColors.darkBackgroundBottom)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if let onChangeUseCase {
                        Button(action: onChangeUseCase) {
                            Label("Changer de type d’entretien", systemImage: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                        }
                    }

                    progressHeader

                    Group {
                        switch step {
                        case 0:
                            interviewContextStep
                        case 1:
                            evidenceStep
                        case 2:
                            difficultQuestionStep
                        default:
                            objectiveStep
                        }
                    }
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))

                    navigationButtons

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: 720)
                .padding(22)
                .frame(maxWidth: .infinity)
            }
            .disabled(viewModel.isLoading)

            if viewModel.isLoading {
                AnalysisLoadingCard(
                    steps: [
                        "Relecture de vos réponses",
                        "Construction de vos réponses aux objections",
                        "Rédaction de votre plan d’action",
                    ],
                    accent: accent,
                    typicalDuration: 25
                )
                .padding(24)
                .transition(.opacity)
            }
        }
        .animation(LegitimaMotion.reveal, value: viewModel.isLoading)
        .onChange(of: viewModel.answers) { _, _ in
            viewModel.saveDraft()
        }
        .onChange(of: targetRole) { _, newValue in
            let updatedContext = InterviewPreparationContext(
                targetRole: newValue,
                careerExperiences: context.careerExperiences,
                sensitivePoint: context.sensitivePoint,
                freemiumAnalysis: context.freemiumAnalysis
            )
            viewModel.updateContext(updatedContext)
            onTargetRoleChange(newValue)
        }
        .onChange(of: viewModel.result) { _, result in
            if let result {
                onComplete(result)
            }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PRÉPARATION RECRUTEMENT")
                    .font(.caption.bold())
                    .foregroundColor(accent)
                Spacer()
                Text("\(step + 1)/4")
                    .font(.caption.bold())
                    .foregroundColor(LegitimaColors.muted)
            }

            ProgressView(value: Double(step + 1), total: 4)
                .tint(accent)
                .animation(LegitimaMotion.control, value: step)

            Text(stepTitle)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))

            Text(stepSubtitle)
                .foregroundColor(LegitimaColors.muted)
        }
    }

    private var interviewContextStep: some View {
        VStack(spacing: 16) {
            RecruitmentTargetRoleCard(targetRole: $targetRole)
            choiceCard(questionID: "interview_stage")
            textCard(questionID: "company_context", minHeight: 110)
            choiceCard(questionID: "interviewer")
        }
    }

    private var evidenceStep: some View {
        VStack(spacing: 16) {
            existingDataCard(
                title: "Vos expériences sont déjà disponibles",
                content: context.careerExperiences,
                icon: "checkmark.circle.fill"
            )
            textCard(questionID: "key_strengths", minHeight: 105)
            textCard(questionID: "proof_example", minHeight: 130)
            textCard(questionID: "measurable_impact", minHeight: 95)
        }
    }

    private var difficultQuestionStep: some View {
        VStack(spacing: 16) {
            if !context.sensitivePoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                existingDataCard(
                    title: "Point sensible repris du freemium",
                    content: context.sensitivePoint,
                    icon: "arrow.triangle.2.circlepath"
                )
            }
            textCard(questionID: "feared_question", minHeight: 120)
            choiceCard(questionID: "secondary_topic")
            choiceCard(questionID: "answer_tone")
        }
    }

    private var objectiveStep: some View {
        VStack(spacing: 16) {
            existingDataCard(
                title: "Poste visé",
                content: targetRole,
                icon: "scope"
            )
            textCard(questionID: "desired_takeaway", minHeight: 120)
            textCard(questionID: "questions_to_ask", minHeight: 100)
            choiceCard(questionID: "preparation_depth")
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("Retour") {
                    withAnimation(LegitimaMotion.control) { step -= 1 }
                }
                .fontWeight(.semibold)
                .padding(.horizontal, 18)
                .padding(.vertical, 15)
                .foregroundColor(accent)
                .background(LegitimaColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))
            }

            Button {
                if step < 3 {
                    withAnimation(LegitimaMotion.control) { step += 1 }
                } else {
                    Task { await viewModel.analyze() }
                }
            } label: {
                Text(step < 3 ? "Continuer" : "Générer ma préparation premium")
                    .legitimaPrimaryLabel()
            }
            .disabled(!isCurrentStepComplete || viewModel.isLoading)
            .opacity(isCurrentStepComplete ? 1 : 0.5)
        }
    }

    private func choiceCard(questionID: String) -> some View {
        Group {
            if let question = question(questionID) {
                RecruitmentChoiceCard(
                    question: question,
                    selection: answerBinding(questionID),
                    accent: accent
                )
            }
        }
    }

    private func textCard(questionID: String, minHeight: CGFloat) -> some View {
        Group {
            if let question = question(questionID) {
                RecruitmentTextCard(
                    question: question,
                    answer: answerBinding(questionID),
                    minHeight: minHeight
                )
            }
        }
    }

    private func existingDataCard(title: String, content: String, icon: String) -> some View {
        RecruitmentExistingDataCard(
            title: title,
            content: content,
            icon: icon,
            accent: accent
        )
    }

    private func question(_ id: String) -> InterviewQuestion? {
        viewModel.useCase.questions.first { $0.id == id }
    }

    private func answerBinding(_ id: String) -> Binding<String> {
        Binding(
            get: { viewModel.answers[id] ?? "" },
            set: { viewModel.answers[id] = $0 }
        )
    }

    private var isCurrentStepComplete: Bool {
        let requiredAnswersAreComplete = requiredQuestionIDsForCurrentStep.allSatisfy {
            !(viewModel.answers[$0] ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        }
        let targetRoleIsComplete = step != 0
            || !targetRole.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return requiredAnswersAreComplete && targetRoleIsComplete
    }

    private var requiredQuestionIDsForCurrentStep: [String] {
        switch step {
        case 0: return ["interview_stage"]
        case 1: return ["key_strengths", "proof_example"]
        case 2: return ["feared_question", "answer_tone"]
        default: return ["desired_takeaway", "preparation_depth"]
        }
    }

    private var stepTitle: String {
        ["Votre prochain entretien", "Ce que vous voulez démontrer", "La question difficile", "Votre objectif"][step]
    }

    private var stepSubtitle: String {
        [
            "Quelques repères rapides pour adapter la préparation.",
            "Nous réutilisons vos expériences : aucun CV à importer de nouveau.",
            "Préparons le point qui vous demande le plus d’attention.",
            "Définissez l’impression à laisser avant la génération finale.",
        ][step]
    }
}
