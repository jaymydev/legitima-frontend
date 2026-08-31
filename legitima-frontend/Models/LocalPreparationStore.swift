import Combine
import Foundation

/// Ce que l'app garde entre deux ouvertures.
///
/// Il ne reste que deux choses : le type d'entretien choisi et sa date. Le
/// parcours, le point sensible, l'analyse, le kickoff et le débrief ont disparu
/// avec le parcours par le CV — c'est le type d'entretien qui porte désormais la
/// préparation, et les réponses vivent dans les blancs remplis sur l'appareil.
struct PreparationSnapshot: Codable, Equatable {
    var intendedUseCaseID: String?
    var interviewDate: Date?
    /// La verticale métier choisie, gardée d'une fois sur l'autre : son métier
    /// ne change pas entre deux préparations.
    var metierID: String?
    /// « J'encadre une équipe » : débloque les questions qui ne valent que
    /// pour l'encadrement. Ça non plus ne change pas d'une fois sur l'autre.
    var encadrement: Bool = false
    var updatedAt: Date = .now

    init(
        intendedUseCaseID: String? = nil,
        interviewDate: Date? = nil,
        metierID: String? = nil,
        encadrement: Bool = false,
        updatedAt: Date = .now
    ) {
        self.intendedUseCaseID = intendedUseCaseID
        self.interviewDate = interviewDate
        self.metierID = metierID
        self.encadrement = encadrement
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        // Tout est optionnel au décodage : un fichier écrit par une version
        // antérieure ne doit jamais coûter la date d'entretien qui, elle, survit.
        let container = try decoder.container(keyedBy: CodingKeys.self)
        intendedUseCaseID = try container.decodeIfPresent(String.self, forKey: .intendedUseCaseID)
        interviewDate = try container.decodeIfPresent(Date.self, forKey: .interviewDate)
        metierID = try container.decodeIfPresent(String.self, forKey: .metierID)
        encadrement = try container.decodeIfPresent(Bool.self, forKey: .encadrement) ?? false
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now
    }

    private enum CodingKeys: String, CodingKey {
        case intendedUseCaseID, interviewDate, metierID, encadrement, updatedAt
    }
}

enum InterviewCountdown {
    /// Nombre de jours pleins d'ici l'entretien, ou nil si la date est passée.
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

    func updateInterviewDate(_ interviewDate: Date?) {
        snapshot.interviewDate = interviewDate
        persist()
    }

    func updateIntendedUseCase(_ useCaseID: String?) {
        snapshot.intendedUseCaseID = useCaseID
        persist()
    }

    func updateMetier(_ metierID: String?) {
        snapshot.metierID = metierID
        persist()
    }

    func updateEncadrement(_ encadrement: Bool) {
        snapshot.encadrement = encadrement
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

/// Fichiers qu'une version antérieure écrivait et que plus rien ne lit.
///
/// `premium-preparation.json` gardait une copie de l'analyse — donc l'historique
/// professionnel de la personne. Les deux fichiers ajoutés ici gardent ses
/// réponses au questionnaire et le catalogue téléchargé : le pivot les a rendus
/// inutiles, et garder des données personnelles dont l'app n'a plus l'usage est
/// exactement ce qu'il ne faut pas faire. Ils sont donc effacés au lancement.
enum OrphanedStorage {
    static let fileNames = [
        "premium-preparation.json",
        "interview-preparation.json",
        "interview-catalog.json",
    ]

    static func removeAll(in directory: URL = applicationSupportURL) {
        for name in fileNames {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
        }
    }
}

var applicationSupportURL: URL {
    let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return baseURL.appendingPathComponent("Legitima", isDirectory: true)
}
