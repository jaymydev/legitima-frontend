import CoreGraphics
import Foundation
import ImageIO
import UIKit

struct CVImportResult {
    var experiences: [CVExperienceRow] = []
    let steps: [String]
    /// Le texte extrait avant sa réduction en lignes — la matière de la
    /// personnalisation. Vide face à un backend qui ne le renvoie pas encore.
    var rawText: String = ""

    var summary: String {
        steps.map { "• \($0)" }.joined(separator: "\n")
    }
}

private struct CVParseResponse: Decodable {
    let experiences: [CVExperienceRow]
    let rawText: String

    private enum CodingKeys: String, CodingKey {
        case experiences
        case rawText = "raw_text"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        experiences = try container.decode([CVExperienceRow].self, forKey: .experiences)
        rawText = try container.decodeIfPresent(String.self, forKey: .rawText) ?? ""
    }
}


enum CVImportServiceError: LocalizedError {
    case unreadableDocument
    case noTextDetected
    case noCameraAvailable
    case unsupportedFileType
    case imageConversionFailed

    var errorDescription: String? {
        switch self {
        case .unreadableDocument:
            return "Le fichier n'a pas pu être lu. Réessayez avec un PDF, une photo JPEG ou une image PNG lisible."
        case .noTextDetected:
            return "Nous n'avons pas trouvé d'expérience professionnelle exploitable. Vérifiez que le CV est lisible et réessayez."
        case .noCameraAvailable:
            return "La caméra n'est pas disponible sur cet appareil."
        case .unsupportedFileType:
            return "Ce format de fichier n'est pas pris en charge. Utilisez un PDF, une photo JPEG ou une image PNG."
        case .imageConversionFailed:
            return "L'image n'a pas pu être préparée pour l'import. Réessayez avec une image plus lisible."
        }
    }
}

private enum CVUploadMimeType: String {
    case pdf = "application/pdf"
    case jpeg = "image/jpeg"
    case png = "image/png"

    var fileExtension: String {
        switch self {
        case .pdf:
            return "pdf"
        case .jpeg:
            return "jpg"
        case .png:
            return "png"
        }
    }
}

private enum CVDetectedFileType {
    case pdf
    case jpeg
    case png
    case heic
    case heif
    case unknown
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
        let uploadPayload = try imageUploadPayload(from: image, originalData: originalData)

        return try await parseWithBackend(
            fileData: uploadPayload.data,
            fileName: uploadPayload.fileName,
            mimeType: uploadPayload.mimeType
        )
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
                    NSLocalizedDescriptionKey: "Le fichier dépasse la taille maximale de 10 Mo pour l'import CV."
                ]
            )
        }

        guard let url = BackendConfiguration.cvParseURL(path: "/cv/parse") else {
            throw NSError(
                domain: "",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "URL backend CV invalide."]
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
                userInfo: [NSLocalizedDescriptionKey: "Réponse backend invalide."]
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
                userInfo: [NSLocalizedDescriptionKey: "La réponse CV du backend est invalide."]
            )
        }

        let parsedSteps = decodedResponse.experiences.compactMap(formatBackendExperience)
        let uniqueSteps = Array(uniquePreservingOrder(parsedSteps).prefix(5))

        guard !uniqueSteps.isEmpty else {
            throw CVImportServiceError.noTextDetected
        }

        return CVImportResult(
            experiences: decodedResponse.experiences,
            steps: uniqueSteps,
            rawText: decodedResponse.rawText
        )
    }

    private func imageUploadPayload(from image: UIImage, originalData: Data?) throws -> (data: Data, fileName: String, mimeType: CVUploadMimeType) {
        if let originalData {
            switch detectFileType(from: originalData) {
            case .png:
                if originalData.count <= BackendConfiguration.maxCVFileSizeBytes {
                    return (originalData, "cv.png", .png)
                }

                guard let recompressedJPEG = compressedJPEGData(from: image) else {
                    throw CVImportServiceError.imageConversionFailed
                }

                return (recompressedJPEG, "cv.jpg", .jpeg)
            case .jpeg:
                if originalData.count <= BackendConfiguration.maxCVFileSizeBytes {
                    return (originalData, "cv.jpg", .jpeg)
                }

                guard let recompressedJPEG = compressedJPEGData(from: image) else {
                    throw CVImportServiceError.imageConversionFailed
                }

                return (recompressedJPEG, "cv.jpg", .jpeg)
            case .heic, .heif:
                guard let convertedJPEG = compressedJPEGData(from: image) else {
                    throw CVImportServiceError.imageConversionFailed
                }

                return (convertedJPEG, "cv.jpg", .jpeg)
            case .pdf:
                throw CVImportServiceError.unsupportedFileType
            case .unknown:
                break
            }
        }

        guard let fallbackJPEG = compressedJPEGData(from: image) else {
            throw CVImportServiceError.imageConversionFailed
        }

        return (fallbackJPEG, "cv.jpg", .jpeg)
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
        let backendMessage = backendDetailMessage(from: data)
        let fallbackMessage: String

        switch statusCode {
        case 413:
            fallbackMessage = "Le fichier dépasse la taille maximale de 10 Mo pour l'import CV."
        case 415:
            fallbackMessage = "Ce format de fichier n'est pas pris en charge. Utilisez un PDF, une photo JPEG ou une image PNG."
        case 422:
            fallbackMessage = "Nous n'avons pas trouvé d'expérience professionnelle exploitable. Vérifiez que le CV est lisible et réessayez."
        case 500:
            fallbackMessage = "Le traitement du CV est momentanément indisponible. Réessayez dans quelques instants."
        default:
            fallbackMessage = "Erreur serveur pendant l'import CV."
        }

        return NSError(
            domain: "",
            code: statusCode,
            userInfo: [NSLocalizedDescriptionKey: backendMessage ?? fallbackMessage]
        )
    }

    private func backendDetailMessage(from data: Data) -> String? {
        if let backendError = try? JSONDecoder().decode(BackendError.self, from: data),
           let message = backendError.detail?.first?.msg ?? backendError.detailMessage {
            return message
        }

        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let detail = object["detail"] {
            if let message = detail as? String {
                return message
            }

            if let array = detail as? [[String: Any]],
               let message = array.compactMap({ $0["msg"] as? String }).first {
                return message
            }
        }

        return nil
    }

    private func detectFileType(from data: Data) -> CVDetectedFileType {
        if data.starts(with: [0x25, 0x50, 0x44, 0x46]) {
            return .pdf
        }

        if data.starts(with: [0xFF, 0xD8, 0xFF]) {
            return .jpeg
        }

        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return .png
        }

        let signatureWindow = min(data.count, 16)
        if signatureWindow >= 12,
           let signature = String(data: data.subdata(in: 4..<12), encoding: .ascii)?.lowercased() {
            if signature.contains("heic") || signature.contains("heix") || signature.contains("hevc") || signature.contains("hevx") {
                return .heic
            }

            if signature.contains("mif1") || signature.contains("msf1") {
                return .heif
            }
        }

        return .unknown
    }

    private func compressedJPEGData(from image: UIImage) -> Data? {
        let maxSize = BackendConfiguration.maxCVFileSizeBytes
        let longestEdgeTarget = max(image.size.width, image.size.height) > 2400 ? 2400.0 : max(image.size.width, image.size.height)
        var workingImage = resizedImageIfNeeded(image, longestEdge: longestEdgeTarget)
        var quality: CGFloat = 0.9

        while quality >= 0.45 {
            if let jpegData = workingImage.jpegData(compressionQuality: quality),
               jpegData.count <= maxSize {
                return jpegData
            }

            quality -= 0.15
        }

        var resizeEdge = max(workingImage.size.width, workingImage.size.height)

        while resizeEdge > 1200 {
            resizeEdge *= 0.85
            workingImage = resizedImageIfNeeded(workingImage, longestEdge: resizeEdge)

            if let jpegData = workingImage.jpegData(compressionQuality: 0.7),
               jpegData.count <= maxSize {
                return jpegData
            }
        }

        return workingImage.jpegData(compressionQuality: 0.6).flatMap { $0.count <= maxSize ? $0 : nil }
    }

    private func resizedImageIfNeeded(_ image: UIImage, longestEdge: CGFloat) -> UIImage {
        let currentLongestEdge = max(image.size.width, image.size.height)
        guard currentLongestEdge > longestEdge, currentLongestEdge > 0 else {
            return image
        }

        let scaleRatio = longestEdge / currentLongestEdge
        let newSize = CGSize(
            width: image.size.width * scaleRatio,
            height: image.size.height * scaleRatio
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func formatBackendExperience(_ experience: CVExperienceRow) -> String? {
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
