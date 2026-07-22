import Foundation
import UIKit

struct CVImportResult {
    let steps: [String]

    var summary: String {
        steps.map { "• \($0)" }.joined(separator: "\n")
    }
}

private struct CVParseResponse: Decodable {
    let experiences: [CVParsedExperience]
}

private struct CVParsedExperience: Decodable {
    let title: String
    let company: String
    let period: String
}

enum CVImportServiceError: LocalizedError {
    case noTextDetected
    case unsupportedImageImport

    var errorDescription: String? {
        switch self {
        case .noTextDetected:
            return "Nous n'avons pas trouve d'experiences exploitables dans ce PDF. Verifiez qu'il s'agit d'un CV textuel lisible."
        case .unsupportedImageImport:
            return "Pour le moment, l'import CV accepte uniquement un PDF textuel. Les photos, captures et scans ne sont pas encore pris en charge."
        }
    }
}

private enum CVUploadMimeType: String {
    case pdf = "application/pdf"
}

final class CVImportService {
    func extractSummary(fromPDFAt url: URL) async throws -> CVImportResult {
        let fileData = try Data(contentsOf: url)

        return try await parseWithBackend(
            fileData: fileData,
            fileName: url.lastPathComponent.isEmpty ? "cv.pdf" : url.lastPathComponent,
            mimeType: .pdf
        )
    }

    func extractSummary(from image: UIImage, originalData: Data? = nil) async throws -> CVImportResult {
        _ = image
        _ = originalData
        throw CVImportServiceError.unsupportedImageImport
    }

    private func parseWithBackend(
        fileData: Data,
        fileName: String,
        mimeType: CVUploadMimeType
    ) async throws -> CVImportResult {
        guard fileData.count <= BackendConfiguration.maxCVFileSizeBytes else {
            throw NSError(
                domain: "",
                code: 413,
                userInfo: [
                    NSLocalizedDescriptionKey: "Le fichier depasse la taille maximale de 10 Mo pour l'import CV."
                ]
            )
        }

        guard let url = BackendConfiguration.url(path: "/cv/parse") else {
            throw NSError(
                domain: "",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "URL backend invalide."]
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = makeMultipartBody(
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType,
            boundary: boundary
        )

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw NSError(
                domain: "",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
            )
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Reponse backend invalide."]
            )
        }

        guard httpResponse.statusCode == 200 else {
            throw backendRequestError(statusCode: httpResponse.statusCode, data: data)
        }

        let decodedResponse: CVParseResponse
        do {
            decodedResponse = try JSONDecoder().decode(CVParseResponse.self, from: data)
        } catch {
            throw NSError(
                domain: "",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "La reponse CV du backend est invalide."]
            )
        }

        let parsedSteps = decodedResponse.experiences.compactMap(formatBackendExperience)
        let uniqueSteps = Array(uniquePreservingOrder(parsedSteps).prefix(5))

        guard !uniqueSteps.isEmpty else {
            throw CVImportServiceError.noTextDetected
        }

        return CVImportResult(steps: uniqueSteps)
    }

    private func makeMultipartBody(
        fileData: Data,
        fileName: String,
        mimeType: CVUploadMimeType,
        boundary: String
    ) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType.rawValue)\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append(fileData)
        body.append(lineBreak.data(using: .utf8)!)
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)

        return body
    }

    private func backendRequestError(statusCode: Int, data: Data) -> NSError {
        let backendMessage = (try? JSONDecoder().decode(BackendError.self, from: data))
            .flatMap { $0.detail?.first?.msg ?? $0.detailMessage }

        let fallbackMessage: String

        switch statusCode {
        case 413:
            fallbackMessage = "Le fichier depasse la taille maximale de 10 Mo pour l'import CV."
        case 415:
            fallbackMessage = "Le format de fichier n'est pas pris en charge. Utilisez un PDF textuel."
        case 422:
            fallbackMessage = "Le CV n'a pas pu etre interprete. Utilisez un PDF textuel exploitable, pas un scan, une photo ou une capture."
        case 500:
            fallbackMessage = "Le backend n'a pas pu analyser ce CV pour le moment."
        default:
            fallbackMessage = "Erreur serveur pendant l'import CV."
        }

        return NSError(
            domain: "",
            code: statusCode,
            userInfo: [NSLocalizedDescriptionKey: backendMessage ?? fallbackMessage]
        )
    }

    private func formatBackendExperience(_ experience: CVParsedExperience) -> String? {
        let components = [
            experience.title.trimmingCharacters(in: .whitespacesAndNewlines),
            experience.company.trimmingCharacters(in: .whitespacesAndNewlines),
            experience.period.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        .filter { !$0.isEmpty }

        guard !components.isEmpty else {
            return nil
        }

        return components.joined(separator: " — ")
    }

    private func uniquePreservingOrder(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []

        for value in values {
            if seen.insert(value).inserted {
                ordered.append(value)
            }
        }

        return ordered
    }
}
