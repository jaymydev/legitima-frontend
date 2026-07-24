import SwiftUI

struct InterviewQuestionnaireScreen: View {
    @EnvironmentObject private var userStatus: UserStatus
    @StateObject private var viewModel: InterviewQuestionnaireViewModel

    let onComplete: (InterviewPreparationResponse) -> Void
    let onBack: () -> Void

    init(
        useCase: InterviewUseCase,
        store: InterviewPreparationStore,
        onComplete: @escaping (InterviewPreparationResponse) -> Void,
        onBack: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: InterviewQuestionnaireViewModel(useCase: useCase, store: store)
        )
        self.onComplete = onComplete
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 220 / 255, green: 249 / 255, blue: 246 / 255),
                    Color(red: 244 / 255, green: 241 / 255, blue: 232 / 255)
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
                            .background(Color(red: 35 / 255, green: 105 / 255, blue: 109 / 255))
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
                    accent: Color(red: 35 / 255, green: 105 / 255, blue: 109 / 255)
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

            Text(question.helper)
                .font(.subheadline)
                .foregroundColor(.secondary)

            PlaceholderTextEditor(
                placeholder: "Votre réponse",
                text: binding(for: question.id),
                primaryColor: Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255),
                minHeight: 120
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            AnswerGuidanceView(
                suggestions: question.suggestions,
                answer: viewModel.answers[question.id] ?? ""
            )
        }
        .padding(16)
        .background(Color.white.opacity(0.92))
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
