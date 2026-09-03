import Foundation

enum BackendConfiguration {
    /// One backend, and it has to be the Docker one.
    ///
    /// Two Render services run this repository. `legitima-backend` uses the
    /// native Python runtime: `pip install` and nothing else, so the machine
    /// has no `tesseract` binary. `legitima-backend-ocr` is built from the
    /// Dockerfile, which installs it. They answer the same routes, which is
    /// why they looked interchangeable — but importing a CV *photo* returns
    /// `500 OCR engine is not available` on the first and works on the second.
    ///
    /// 1.0 pointed here at `legitima-backend` and shipped that break. Render
    /// cannot change a service's runtime after creation, and renaming does not
    /// move the `onrender.com` subdomain, so the fix has to come from the
    /// client.
    ///
    /// The name is misleading for a primary backend. Moving to a domain we own
    /// would let the host change without another App Store submission; until
    /// then, this string is the one that works.
    static let baseURLString = "https://legitima-backend-ocr.onrender.com"

    static let maxCVFileSizeBytes = 10 * 1024 * 1024

    static func analyzeURL(path: String) -> URL? {
        URL(string: "\(baseURLString)\(path)")
    }

    static func cvParseURL(path: String) -> URL? {
        analyzeURL(path: path)
    }
}

struct BackendError: Decodable {
    let detail: [BackendDetail]?
    let detailMessage: String?

    private enum CodingKeys: String, CodingKey {
        case detail
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        detail = try? container.decode([BackendDetail].self, forKey: .detail)
        detailMessage = try? container.decode(String.self, forKey: .detail)
    }
}

struct BackendDetail: Decodable {
    let msg: String?
}

/// Ce qui reste d'un service qui appelait /analyze.
///
/// La route a disparu avec le parcours par le CV. Le type survit pour deux
/// choses que tout le reste partage : l'adresse du backend, et le type d'erreur
/// dans lequel les appels échouent.
enum IAService {

    /// `LocalizedError`, et pas seulement `Error` : sans ça, Swift compose
    /// lui-même « The operation couldn't be completed. (…IAServiceError
    /// error 2.) » et jette le message que l'appelant avait pris soin
    /// d'écrire. Le serveur rédige ses erreurs en français pour être lues
    /// telles quelles ; les envelopper dans un type muet les perdait toutes,
    /// et faisait ressembler chaque panne à la même panne.
    enum IAServiceError: LocalizedError {
        case invalidURL
        case invalidRequestBody
        case requestFailed(Error)
        case decodingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .requestFailed(let underlying):
                // C'est ici que tout se joue : `underlying` porte soit le texte
                // français du serveur, soit le message système d'une panne
                // réseau — déjà traduit par iOS. Dans les deux cas il est
                // écrit pour être lu.
                return underlying.localizedDescription
            case .invalidURL, .invalidRequestBody, .decodingFailed:
                // Trois pannes internes : rien à dire d'utile à quelqu'un qui
                // prépare un entretien, et le détail technique l'inquiéterait
                // sans l'aider.
                return "La préparation n'a pas pu être écrite. Réessayez dans quelques instants."
            }
        }
    }

}
