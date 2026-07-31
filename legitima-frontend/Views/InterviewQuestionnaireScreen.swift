import SwiftUI

struct InterviewQuestionnaireScreen: View {
    @StateObject private var viewModel: InterviewQuestionnaireViewModel

    let onComplete: (InterviewPreparationResponse) -> Void
    let onBack: () -> Void

    private let context: InterviewPreparationContext

    init(
        useCase: InterviewUseCase,
        store: InterviewPreparationStore,
        context: InterviewPreparationContext,
        onComplete: @escaping (InterviewPreparationResponse) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.context = context
        _viewModel = StateObject(
            wrappedValue: InterviewQuestionnaireViewModel(
                useCase: useCase,
                store: store,
                context: context
            )
        )
        self.onComplete = onComplete
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(light: .rgb(220, 249, 246), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(244, 241, 232), dark: LegitimaColors.darkBackgroundBottom)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Button(action: onBack) {
                        Label("Changer de type d’entretien", systemImage: "chevron.left")
                            .font(.subheadline.weight(.semibold))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.useCase.title)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))

                        Text(viewModel.useCase.description)
                            .foregroundColor(LegitimaColors.muted)
                    }

                    existingDataCards

                    ForEach(viewModel.useCase.questions) { question in
                        questionCard(question)
                    }

                    Button {
                        Task { await viewModel.analyze() }
                    } label: {
                        Text("Préparer mon entretien")
                            .legitimaPrimaryLabel()
                    }
                    .disabled(viewModel.isLoading || !viewModel.canSubmit)
                    .opacity(viewModel.canSubmit ? 1 : 0.55)

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
                        "Structuration de vos arguments",
                        "Rédaction de votre synthèse",
                    ],
                    accent: LegitimaColors.accent,
                    typicalDuration: 12
                )
                .padding(24)
                .transition(.opacity)
            }
        }
        .animation(LegitimaMotion.reveal, value: viewModel.isLoading)
        .onChange(of: viewModel.answers) { _, _ in
            viewModel.saveDraft()
        }
        .onChange(of: viewModel.result) { _, result in
            if let result {
                onComplete(result)
            }
        }
    }

    /// Mirrors the recruitment flow: show what the first analysis already
    /// provides, so the guided preparation never reads as a cold restart.
    @ViewBuilder
    private var existingDataCards: some View {
        if !context.careerExperiences.trimmed.isEmpty {
            RecruitmentExistingDataCard(
                title: "Votre parcours, déjà transmis",
                content: context.careerExperiences,
                icon: "text.book.closed.fill",
                accent: LegitimaColors.accent
            )
        }

        if !context.sensitivePoint.trimmed.isEmpty {
            RecruitmentExistingDataCard(
                title: "La zone sensible identifiée",
                content: context.sensitivePoint,
                icon: "exclamationmark.bubble.fill",
                accent: LegitimaColors.accent
            )
        }
    }

    private func questionCard(_ question: InterviewQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(question.title)
                    .font(.headline)
                if !question.required {
                    Text("Facultatif")
                        .font(.caption)
                        .foregroundColor(LegitimaColors.muted)
                }
            }

            JustifiedText(question.helper, color: LegitimaColors.muted)

            PlaceholderTextEditor(
                placeholder: "Votre réponse",
                text: binding(for: question.id),
                primaryColor: LegitimaColors.ink,
                minHeight: 120
            )
            .overlay(
                RoundedRectangle(cornerRadius: LegitimaRadius.control)
                    .stroke(LegitimaColors.hairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))

            AnswerGuidanceView(
                suggestions: question.suggestions,
                answer: viewModel.answers[question.id] ?? "",
                expectsShortAnswer: !question.options.isEmpty
            )
        }
        .padding(16)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    private func binding(for questionID: String) -> Binding<String> {
        Binding(
            get: { viewModel.answers[questionID] ?? "" },
            set: { viewModel.answers[questionID] = $0 }
        )
    }
}
