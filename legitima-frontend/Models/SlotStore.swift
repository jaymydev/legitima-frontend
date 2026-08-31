import Combine
import Foundation

/// Ce que la personne a écrit dans les blancs, gardé d'une fois sur l'autre.
///
/// C'est tout l'anti-friction du produit : le formulaire d'accueil a disparu, et
/// on ne demande jamais rien en amont. Un blanc se remplit là où on voit à quoi
/// il sert, une seule fois — puis il est rempli partout, et à la préparation
/// suivante aussi.
///
/// Rien de tout cela ne quitte l'appareil. C'est indispensable pour les balises
/// de salaire, et c'est gratuit pour les autres.
@MainActor
final class SlotStore: ObservableObject {
    @Published private(set) var values: [String: String]

    private let storage: ProtectedJSONStore<[String: String]>

    convenience init() {
        self.init(storage: .slots)
    }

    init(storage: ProtectedJSONStore<[String: String]>) {
        self.storage = storage
        values = storage.load() ?? [:]
    }

    func value(for slot: String) -> String? {
        let filled = values[slot]?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (filled?.isEmpty == false) ? filled : nil
    }

    func set(_ value: String, for slot: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            values.removeValue(forKey: slot)
        } else {
            values[slot] = trimmed
        }
        storage.save(values)
    }

    /// Les blancs d'un gabarit qui restent à remplir, dans l'ordre du texte.
    func unfilled(in template: String) -> [String] {
        SlotVocabulary.slots(in: template).filter { value(for: $0) == nil }
    }

    func clear() {
        values = [:]
        storage.remove()
    }
}

extension ProtectedJSONStore where Value == [String: String] {
    static var slots: Self {
        Self(fileURL: slotsFileURL)
    }
}

private var slotsFileURL: URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return base
        .appendingPathComponent("Legitima", isDirectory: true)
        .appendingPathComponent("slots.json")
}
