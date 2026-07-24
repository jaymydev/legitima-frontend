import Combine
import Foundation

struct PreparationSnapshot: Codable, Equatable {
    var targetRole: String = ""
    var careerSummary: String = ""
    var sensitivePoint: String = ""
    var analysis: AnalysisResponse?
    var updatedAt: Date = .now

    var hasWork: Bool {
        analysis != nil
            || !targetRole.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !careerSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !sensitivePoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

@MainActor
final class LocalPreparationStore: ObservableObject {
    @Published private(set) var snapshot: PreparationSnapshot

    private let storage: ProtectedJSONStore<PreparationSnapshot>

    init(storage: ProtectedJSONStore<PreparationSnapshot> = .preparation) {
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

private var applicationSupportURL: URL {
    let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return baseURL.appendingPathComponent("Legitima", isDirectory: true)
}
