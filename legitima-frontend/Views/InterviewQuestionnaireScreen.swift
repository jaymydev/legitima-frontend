import SwiftUI

struct InterviewQuestionnaireScreen: View {
    @EnvironmentObject private var userStatus: UserStatus
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
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        Text(viewModel.useCase.description)
                            .foregroundColor(.secondary)
                    }

                    existingDataCards

                    ForEach(viewModel.useCase.questions) { question in
                        questionCard(question)
                    }

                    Button {
                        startAnalysis()
                    } label: {
                        Text("Préparer mon entretien")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(LegitimaColors.accentSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(viewModel.isLoading || !viewModel.canSubmit || !userStatus.canStartAnalysis)
                    .opacity(viewModel.canSubmit && userStatus.canStartAnalysis ? 1 : 0.55)

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
                    title: "Préparation en cours",
                    subtitle: "Nous structurons vos réponses pour cet entretien.",
                    accent: LegitimaColors.accent
                )
                .padding(24)
            }
        }
        .onChange(of: viewModel.answers) { _, _ in
            viewModel.saveDraft()
        }
        .onChange(of: viewModel.result) { _, result in
            if let result {
                onComplete(result)
            }
        }
    }

    /// Mirrors the recruitment flow: show what the free analysis already
    /// provides, so the premium never reads as a cold restart.
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
                        .foregroundColor(.secondary)
                }
            }

            JustifiedText(question.helper, color: .secondary)

            PlaceholderTextEditor(
                placeholder: "Votre réponse",
                text: binding(for: question.id),
                primaryColor: LegitimaColors.ink,
                minHeight: 120
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LegitimaColors.hairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            AnswerGuidanceView(
                suggestions: question.suggestions,
                answer: viewModel.answers[question.id] ?? ""
            )
        }
        .padding(16)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func binding(for questionID: String) -> Binding<String> {
        Binding(
            get: { viewModel.answers[questionID] ?? "" },
            set: { viewModel.answers[questionID] = $0 }
        )
    }

    private func startAnalysis() {
        userStatus.refreshFreeQuotaIfNeeded()
        guard userStatus.canStartAnalysis else {
            viewModel.errorMessage = "Vous avez atteint vos 20 analyses de test pour aujourd’hui. Votre brouillon reste sauvegardé."
            return
        }
        Task { await viewModel.analyze() }
    }
}
