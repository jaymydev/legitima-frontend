import Combine
import Foundation

@MainActor
final class InterviewUseCasesViewModel: ObservableObject {
    @Published private(set) var useCases: [InterviewUseCase] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service: InterviewPreparationService
    private let cache: ProtectedJSONStore<InterviewUseCaseCatalog>

    convenience init() {
        self.init(
            service: InterviewPreparationService(),
            cache: .interviewCatalog
        )
    }

    init(
        service: InterviewPreparationService,
        cache: ProtectedJSONStore<InterviewUseCaseCatalog>
    ) {
        self.service = service
        self.cache = cache
        useCases = cache.load()?.useCases ?? []
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let catalog = try await service.fetchUseCases()
            useCases = catalog.useCases
            cache.save(catalog)
            errorMessage = nil
        } catch {
            if useCases.isEmpty {
                errorMessage = "Impossible de charger les types d’entretien. Vérifiez votre connexion puis réessayez."
            }
        }
    }
}

@MainActor
final class InterviewQuestionnaireViewModel: ObservableObject {
    @Published var answers: [String: String]
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var result: InterviewPreparationResponse?

    let useCase: InterviewUseCase

    private let service: InterviewPreparationService
    private let store: InterviewPreparationStore
    private var context: InterviewPreparationContext?

    convenience init(
        useCase: InterviewUseCase,
        store: InterviewPreparationStore,
        context: InterviewPreparationContext? = nil
    ) {
        self.init(
            useCase: useCase,
            store: store,
            context: context,
            service: InterviewPreparationService()
        )
    }

    init(
        useCase: InterviewUseCase,
        store: InterviewPreparationStore,
        context: InterviewPreparationContext? = nil,
        service: InterviewPreparationService
    ) {
        self.useCase = useCase
        self.store = store
        self.context = context
        self.service = service
        answers = store.saved.useCase?.id == useCase.id ? store.saved.answers : [:]
    }

    var canSubmit: Bool {
        useCase.hasAllRequiredAnswers(answers)
    }

    func saveDraft() {
        store.saveDraft(useCase: useCase, answers: answers)
    }

    func updateContext(_ context: InterviewPreparationContext) {
        self.context = context
    }

    func analyze() async {
        guard canSubmit, !isLoading else {
            errorMessage = "Répondez aux questions obligatoires avant de continuer."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let payload = InterviewPreparationRequest(
            useCaseID: useCase.id,
            questionnaireVersion: useCase.questionnaireVersion,
            answers: useCase.questions.compactMap { question in
                let value = (answers[question.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? nil : InterviewAnswer(questionID: question.id, answer: value)
            },
            context: context
        )

        do {
            let response = try await service.analyze(payload)
            result = response
            store.saveResult(response)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
