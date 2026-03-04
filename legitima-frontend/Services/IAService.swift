import Foundation

struct BackendError: Decodable {
    let detail: [BackendDetail]?
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
        guard let url = URL(string: "http://127.0.0.1:8000/analyze") else {
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
               let message = backendError.detail?.first?.msg {
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
        
        print(String(data: data, encoding: .utf8) ?? "no data")

        do {
            return try JSONDecoder().decode(AnalysisResponse.self, from: data)
        } catch {
            throw IAServiceError.decodingFailed(error)
        }
    }
}
