import Combine
import Foundation

struct PreparationSnapshot: Codable, Equatable {
    var targetRole: String = ""
    var careerSummary: String = ""
    var sensitivePoint: String = ""
    var interviewDate: Date?
    var analysis: AnalysisResponse?
    var updatedAt: Date = .now

    var hasWork: Bool {
        analysis != nil
            || !targetRole.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !careerSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !sensitivePoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

enum InterviewCountdown {
    /// Whole days between today and the interview day, or nil when the date is past.
    static func daysUntil(
        _ date: Date,
        from reference: Date = .now,
        calendar: Calendar = .current
    ) -> Int? {
        let start = calendar.startOfDay(for: reference)
        let target = calendar.startOfDay(for: date)
        guard let days = calendar.dateComponents([.day], from: start, to: target).day,
              days >= 0 else {
            return nil
        }
        return days
    }

    static func label(daysUntil days: Int) -> String {
        switch days {
        case 0:
            return "Votre entretien a lieu aujourd'hui"
        case 1:
            return "Votre entretien a lieu demain"
        default:
            return "Votre entretien a lieu dans \(days) jours"
        }
    }
}

@MainActor
final class LocalPreparationStore: ObservableObject {
    @Published private(set) var snapshot: PreparationSnapshot

    private let storage: ProtectedJSONStore<PreparationSnapshot>

    convenience init() {
        self.init(storage: .preparation)
    }

    init(storage: ProtectedJSONStore<PreparationSnapshot>) {
        self.storage = storage
        snapshot = storage.load() ?? PreparationSnapshot()
    }

    var hasSavedWork: Bool {
        snapshot.hasWork
    }

    func saveDraft(targetRole: String, careerSummary: String, sensitivePoint: String) {
        snapshot.targetRole = targetRole
        snapshot.careerSummary = careerSummary
        snapshot.sensitivePoint = sensitivePoint
        persist()
    }

    func saveAnalysis(_ analysis: AnalysisResponse) {
        snapshot.analysis = analysis
        persist()
    }

    func updateTargetRole(_ targetRole: String) {
        snapshot.targetRole = targetRole
        persist()
    }

    func updateInterviewDate(_ interviewDate: Date?) {
        snapshot.interviewDate = interviewDate
        persist()
    }

    func beginNewAnalysis() {
        snapshot.analysis = nil
        persist()
    }

    func clear() {
        snapshot = PreparationSnapshot()
        storage.remove()
    }

    private func persist() {
        snapshot.updatedAt = .now
        storage.save(snapshot)
    }
}

struct ProtectedJSONStore<Value: Codable> {
    let fileURL: URL

    func load() -> Value? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }

    func save(_ value: Value) {
        guard let data = try? JSONEncoder().encode(value) else { return }

        let directory = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    func remove() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

extension ProtectedJSONStore where Value == PreparationSnapshot {
    static var preparation: Self {
        Self(fileURL: applicationSupportURL.appendingPathComponent("preparation.json"))
    }
}

extension ProtectedJSONStore where Value == PremiumPreparationSnapshot {
    static var premiumPreparation: Self {
        Self(fileURL: applicationSupportURL.appendingPathComponent("premium-preparation.json"))
    }
}

extension ProtectedJSONStore where Value == InterviewUseCaseCatalog {
    static var interviewCatalog: Self {
        Self(fileURL: applicationSupportURL.appendingPathComponent("interview-catalog.json"))
    }
}

extension ProtectedJSONStore where Value == SavedInterviewPreparation {
    static var interviewPreparation: Self {
        Self(fileURL: applicationSupportURL.appendingPathComponent("interview-preparation.json"))
    }
}

@MainActor
final class InterviewPreparationStore: ObservableObject {
    @Published private(set) var saved: SavedInterviewPreparation

    private let storage: ProtectedJSONStore<SavedInterviewPreparation>

    convenience init() {
        self.init(storage: .interviewPreparation)
    }

    init(storage: ProtectedJSONStore<SavedInterviewPreparation>) {
        self.storage = storage
        saved = storage.load() ?? SavedInterviewPreparation()
    }

    func saveDraft(useCase: InterviewUseCase, answers: [String: String]) {
        saved.useCase = useCase
        saved.answers = answers
        saved.updatedAt = .now
        storage.save(saved)
    }

    func saveResult(_ result: InterviewPreparationResponse) {
        saved.result = result
        saved.updatedAt = .now
        storage.save(saved)
    }

    func start(useCase: InterviewUseCase) {
        if saved.useCase?.id != useCase.id {
            saved = SavedInterviewPreparation(useCase: useCase)
            storage.save(saved)
        }
    }

    func clear() {
        saved = SavedInterviewPreparation()
        storage.remove()
    }
}

private var applicationSupportURL: URL {
    let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return baseURL.appendingPathComponent("Legitima", isDirectory: true)
}
