import Foundation

final class InterviewPreparationService {
    func fetchUseCases() async throws -> InterviewUseCaseCatalog {
        try await request(path: "/v2/interview-preparation/use-cases", method: "GET")
    }

    func analyze(_ payload: InterviewPreparationRequest) async throws -> InterviewPreparationResponse {
        try await request(
            path: "/v2/interview-preparation/analyze",
            method: "POST",
            body: try JSONEncoder().encode(payload)
        )
    }

    func kickoff(_ payload: PremiumKickoffRequest) async throws -> PremiumKickoffResponse {
        try await request(
            path: "/v2/interview-preparation/kickoff",
            method: "POST",
            body: try JSONEncoder().encode(payload)
        )
    }

    private func request<Response: Decodable>(
        path: String,
        method: String,
        body: Data? = nil
    ) async throws -> Response {
        guard let url = BackendConfiguration.analyzeURL(path: path) else {
            throw IAService.IAServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw IAService.IAServiceError.requestFailed(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IAService.IAServiceError.requestFailed(URLError(.badServerResponse))
        }
        guard httpResponse.statusCode == 200 else {
            let backendError = try? JSONDecoder().decode(BackendError.self, from: data)
            let message = backendError?.detail?.first?.msg
                ?? backendError?.detailMessage
                ?? "Erreur serveur"
            throw IAService.IAServiceError.requestFailed(
                NSError(
                    domain: "LegitimaInterviewPreparation",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
            )
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw IAService.IAServiceError.decodingFailed(error)
        }
    }
}
