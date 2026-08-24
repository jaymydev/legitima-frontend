import SwiftUI

/// Everything between choosing an interview type and reading the questions.
///
/// The questionnaires are tiny now — one pasted job offer, four short fields for
/// an internal move, nothing at all for a performance review — because the model
/// writes the questions instead of the user answering twelve of them. A type
/// with no questions skips the form entirely rather than showing an empty one.
struct InterviewPreparationFlowScreen: View {
    let useCaseID: String

    @State private var stage: Stage = .loadingCatalog
    @State private var answers: [String: String] = [:]
    private let service = InterviewQuestionsService()

    enum Stage {
        case loadingCatalog
        case form(InterviewUseCase)
        case generating(InterviewUseCase)
        case result(PreparedInterview)
        case failed(String)
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

            switch stage {
            case .loadingCatalog:
                ProgressView().tint(LegitimaColors.accent)

            case let .form(useCase):
                formView(useCase)

            case .generating:
                AnalysisLoadingCard(
                    steps: [
                        "Lecture de ce que vous avez donné",
                        "Recherche des questions les plus probables",
                        "Rédaction de vos réponses",
                    ],
                    accent: LegitimaColors.accent,
                    typicalDuration: 12
                )
                .padding(24)

            case let .result(preparation):
                PreparedInterviewScreen(preparation: preparation)

            case let .failed(message):
                failureView(message)
            }
        }
        .task { await loadCatalog() }
    }

    private func formView(_ useCase: InterviewUseCase) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(useCase.title.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundColor(LegitimaColors.accent)

                    Text("Quelques précisions")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .foregroundColor(LegitimaColors.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Plus vous en donnez, plus les réponses vous ressemblent. Vous pouvez aussi continuer sans.")
                        .font(.subheadline)
                        .foregroundColor(LegitimaColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ForEach(useCase.questions) { question in
                    questionField(question)
                }

                Button {
                    Task { await generate(useCase) }
                } label: {
                    Text("Préparer mes réponses")
                        .legitimaPrimaryLabel()
                }
                .disabled(!useCase.hasAllRequiredAnswers(answers))
                .opacity(useCase.hasAllRequiredAnswers(answers) ? 1 : 0.5)
            }
            .frame(maxWidth: 720)
            .padding(22)
            .frame(maxWidth: .infinity)
        }
    }

    private func questionField(_ question: InterviewQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(question.title)
                    .font(.headline)
                    .foregroundColor(LegitimaColors.ink)
                if !question.required {
                    Text("Facultatif")
                        .font(.caption)
                        .foregroundColor(LegitimaColors.muted)
                }
            }

            Text(question.helper)
                .font(.subheadline)
                .foregroundColor(LegitimaColors.muted)
                .fixedSize(horizontal: false, vertical: true)

            let binding = Binding(
                get: { answers[question.id] ?? "" },
                set: { answers[question.id] = $0 }
            )

            if question.inputType == "short_text" {
                TextField("", text: binding)
                    .textInputAutocapitalization(.sentences)
                    .padding(14)
                    .background(LegitimaColors.field)
                    .overlay(
                        RoundedRectangle(cornerRadius: LegitimaRadius.control)
                            .stroke(LegitimaColors.hairline, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))
            } else {
                PlaceholderTextEditor(
                    placeholder: "Collez ou écrivez ici",
                    text: binding,
                    primaryColor: LegitimaColors.ink,
                    minHeight: 150
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LegitimaRadius.control)
                        .stroke(LegitimaColors.hairline, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))
            }
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    private func failureView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text(message)
                .font(.subheadline)
                .foregroundColor(LegitimaColors.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("Réessayer") {
                stage = .loadingCatalog
                Task { await loadCatalog() }
            }
            .font(.headline)
            .foregroundColor(LegitimaColors.accent)
        }
        .padding(30)
    }

    private func loadCatalog() async {
        guard case .loadingCatalog = stage else { return }
        do {
            let catalog = try await service.fetchUseCases()
            guard let useCase = catalog.useCases.first(where: { $0.id == useCaseID }) else {
                stage = .failed("Ce type d'entretien n'est pas reconnu. Mettez l'application à jour, puis réessayez.")
                return
            }
            // Nothing to ask: go straight to the questions. Showing an empty form
            // would be asking someone to confirm they have nothing to say.
            if useCase.questions.isEmpty {
                await generate(useCase)
            } else {
                stage = .form(useCase)
            }
        } catch {
            stage = .failed(error.localizedDescription)
        }
    }

    private func generate(_ useCase: InterviewUseCase) async {
        stage = .generating(useCase)
        let payload = PreparedInterviewRequest(
            useCaseID: useCase.id,
            questionnaireVersion: useCase.questionnaireVersion,
            answers: answers
                .filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .map { PreparedInterviewAnswer(questionID: $0.key, answer: $0.value) },
            // The CV is not wired yet. Recruitment and internal mobility will
            // fill this; every other type ignores it by contract.
            experiences: []
        )

        do {
            stage = .result(try await service.prepare(payload))
        } catch {
            stage = .failed(error.localizedDescription)
        }
    }
}
