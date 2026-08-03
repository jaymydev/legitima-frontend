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

final class IAService {

    enum IAServiceError: Error {
        case invalidURL
        case invalidRequestBody
        case requestFailed(Error)
        case decodingFailed(Error)
    }

    func analyze(request payload: AnalyzeRequest) async throws -> AnalysisResponse {
        guard let url = BackendConfiguration.analyzeURL(path: "/analyze") else {
            throw IAServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let requestBody: Data
        do {
            requestBody = try JSONEncoder().encode(payload)
        } catch {
            throw IAServiceError.invalidRequestBody
        }
        request.httpBody = requestBody

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw IAServiceError.requestFailed(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IAServiceError.requestFailed(URLError(.badServerResponse))
        }

        if httpResponse.statusCode != 200 {
            if let backendError = try? JSONDecoder().decode(BackendError.self, from: data),
               let message = backendError.detail?.first?.msg ?? backendError.detailMessage {
                throw IAServiceError.requestFailed(
                    NSError(
                        domain: "",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: message]
                    )
                )
            } else {
                throw IAServiceError.requestFailed(
                    NSError(
                        domain: "",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Erreur serveur"]
                    )
                )
            }
        }
        do {
            return try JSONDecoder().decode(AnalysisResponse.self, from: data)
        } catch {
            throw IAServiceError.decodingFailed(error)
        }
    }
}

extension IAService.IAServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL backend invalide."
        case .invalidRequestBody:
            return "Impossible de construire la requete d'analyse."
        case .requestFailed(let error):
            return error.localizedDescription
        case .decodingFailed:
            return "La reponse backend est invalide ou incomplete."
        }
    }
}
