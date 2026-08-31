import Foundation

/// Talks to the V3 route: the interview type carries the preparation.
///
/// The catalog is fetched rather than hardcoded. `questionnaire_version` is the
/// contract that lets the backend change its questions without a client
/// release, and a client answering from a copy it holds locally would defeat it.
final class InterviewQuestionsService {
    /// La banque écrite à la main. Aucun appel modèle derrière : la réponse est
    /// instantanée, ne coûte rien, et arrive même sans que la personne ait saisi
    /// quoi que ce soit.
    func fetchBank(
        useCaseID: String,
        seen: [String] = [],
        metier: String? = nil,
        encadrement: Bool = false
    ) async throws -> BankPage {
        var query = "use_case_id=\(useCaseID)"
        if !seen.isEmpty {
            query += "&seen=\(seen.joined(separator: ","))"
        }
        if let metier, !metier.isEmpty {
            query += "&metier=\(metier)"
        }
        if encadrement {
            query += "&encadrement=true"
        }
        return try await request(path: "/v3/interview/bank?\(query)", method: "GET")
    }

    /// Les verticales métier disponibles, avec leurs libellés. Récupérées
    /// plutôt que codées : une verticale ajoutée à la banque apparaît dans
    /// l'app sans nouvelle version.
    func fetchMetiers() async throws -> [MetierChoice] {
        let catalog: MetierCatalog = try await request(path: "/v3/interview/metiers", method: "GET")
        return catalog.catalog
    }

    /// Le catalogue, pour connaître les questions et la version du
    /// questionnaire d'un type. Récupéré plutôt que codé en dur : c'est ce qui
    /// permet au backend de changer ses questions sans nouvelle version d'app.
    func fetchUseCase(id: String) async throws -> InterviewUseCase? {
        let catalog: InterviewUseCaseCatalog = try await request(
            path: "/v3/interview/use-cases",
            method: "GET"
        )
        return catalog.useCases.first { $0.id == id }
    }

    /// La personnalisation : deux appels modèle côté serveur — la génération,
    /// puis la passe qui vérifie que rien n'est affirmé sans source. D'où le
    /// délai long : couper à 60 s abandonnerait des générations qui allaient
    /// aboutir, et ce qui a été envoyé aurait coûté ses tokens pour rien.
    func personalize(_ payload: PreparedInterviewRequest) async throws -> PreparedInterview {
        try await request(
            path: "/v3/interview/questions",
            method: "POST",
            body: try JSONEncoder().encode(payload),
            timeout: 180
        )
    }

    private func request<Response: Decodable>(
        path: String,
        method: String,
        body: Data? = nil,
        timeout: TimeInterval? = nil
    ) async throws -> Response {
        guard let url = BackendConfiguration.analyzeURL(path: path) else {
            throw IAService.IAServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        if let timeout {
            request.timeoutInterval = timeout
        }
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
            // The backend writes `detail` in French, for this screen. Showing it
            // as written is the whole point of that contract.
            let backendError = try? JSONDecoder().decode(BackendError.self, from: data)
            let message = backendError?.detail?.first?.msg
                ?? backendError?.detailMessage
                ?? "Le service est momentanément indisponible. Réessayez dans quelques instants."
            throw IAService.IAServiceError.requestFailed(
                NSError(
                    domain: "LegitimaInterviewQuestions",
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
