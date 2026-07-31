import Foundation

enum BackendConfiguration {
    static let analyzeBaseURLString = "https://legitima-backend.onrender.com"
    /// Same service as `analyzeBaseURLString`. The OCR deployment ran the very
    /// same image — both answer `/cv/parse` and `/v2/...` — so it was a
    /// duplicate. It stays reachable until installed builds have updated.
    static let cvParseBaseURLString = analyzeBaseURLString
    static let maxCVFileSizeBytes = 10 * 1024 * 1024

    static func analyzeURL(path: String) -> URL? {
        URL(string: "\(analyzeBaseURLString)\(path)")
    }

    static func cvParseURL(path: String) -> URL? {
        URL(string: "\(cvParseBaseURLString)\(path)")
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
