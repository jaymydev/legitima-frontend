import Foundation
import PDFKit
import UIKit
import Vision

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
    case unreadableDocument
    case noTextDetected
    case noCameraAvailable

    var errorDescription: String? {
        switch self {
        case .unreadableDocument:
            return "Le document n'a pas pu être lu. Essayez avec un PDF plus net ou une photo plus lisible."
        case .noTextDetected:
            return "Nous n'avons pas trouvé assez d'informations exploitables dans ce CV. Essayez avec une version plus lisible."
        case .noCameraAvailable:
            return "La caméra n'est pas disponible sur cet appareil."
        }
    }
}

private enum CVImportSource {
    case pdf
    case image
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

final class CVImportService {
    func extractSummary(fromPDFAt url: URL) async throws -> CVImportResult {
        if let remoteAttempt = await attemptBackendPDFParse(from: url) {
            switch remoteAttempt {
            case .success(let result):
                return result
            case .failure(let remoteError):
                do {
                    return try extractLocalSummary(fromPDFAt: url)
                } catch let localError as CVImportServiceError {
                    if case .noTextDetected = localError {
                        throw remoteError
                    }
                    throw localError
                } catch {
                    throw remoteError
                }
            }
        }

        return try extractLocalSummary(fromPDFAt: url)
    }

    func extractSummary(from image: UIImage, originalData: Data? = nil) async throws -> CVImportResult {
        if let remoteAttempt = await attemptBackendImageParse(from: image, originalData: originalData) {
            switch remoteAttempt {
            case .success(let result):
                return result
            case .failure(let remoteError):
                do {
                    return try await extractLocalSummary(from: image)
                } catch let localError as CVImportServiceError {
                    if case .noTextDetected = localError {
                        throw remoteError
                    }
                    throw localError
                } catch {
                    throw remoteError
                }
            }
        }

        return try await extractLocalSummary(from: image)
    }

    private func attemptBackendPDFParse(from url: URL) async -> Result<CVImportResult, Error>? {
        do {
            let fileData = try Data(contentsOf: url)
            let result = try await parseWithBackend(
                fileData: fileData,
                fileName: url.lastPathComponent.isEmpty ? "cv.pdf" : url.lastPathComponent,
                mimeType: .pdf
            )
            return .success(result)
        } catch {
            if error is CocoaError {
                return nil
            }
            return .failure(error)
        }
    }

    private func attemptBackendImageParse(from image: UIImage, originalData: Data?) async -> Result<CVImportResult, Error>? {
        do {
            let uploadData = try imageUploadPayload(from: image, originalData: originalData)
            let result = try await parseWithBackend(
                fileData: uploadData.data,
                fileName: "cv.\(uploadData.mimeType.fileExtension)",
                mimeType: uploadData.mimeType
            )
            return .success(result)
        } catch {
            return .failure(error)
        }
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

        let parsedSteps = decodedResponse.experiences
            .compactMap(formatBackendExperience)
        let uniqueSteps = Array(uniquePreservingOrder(parsedSteps).prefix(5))

        guard !uniqueSteps.isEmpty else {
            throw CVImportServiceError.noTextDetected
        }

        return CVImportResult(steps: uniqueSteps)
    }

    private func extractLocalSummary(fromPDFAt url: URL) throws -> CVImportResult {
        guard let document = PDFDocument(url: url), let rawText = document.string else {
            throw CVImportServiceError.unreadableDocument
        }

        return try buildResult(from: rawText, source: .pdf)
    }

    private func extractLocalSummary(from image: UIImage) async throws -> CVImportResult {
        guard let cgImage = image.cgImage else {
            throw CVImportServiceError.unreadableDocument
        }

        let recognizedText = try await recognizeText(in: cgImage)
        return try buildResult(from: recognizedText, source: .image)
    }

    private func imageUploadPayload(from image: UIImage, originalData: Data?) throws -> (data: Data, mimeType: CVUploadMimeType) {
        if let originalData, let detectedMimeType = detectImageMimeType(from: originalData) {
            return (originalData, detectedMimeType)
        }

        guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
            throw CVImportServiceError.unreadableDocument
        }

        return (jpegData, .jpeg)
    }

    private func detectImageMimeType(from data: Data) -> CVUploadMimeType? {
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return .png
        }

        if data.starts(with: [0xFF, 0xD8, 0xFF]) {
            return .jpeg
        }

        return nil
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
            fallbackMessage = "Le fichier dépasse la taille maximale de 10 Mo pour l'import CV."
        case 415:
            fallbackMessage = "Le format de fichier n'est pas pris en charge. Utilisez un PDF, un JPEG ou un PNG."
        case 422:
            fallbackMessage = "Le CV n'a pas pu être interprété par le backend. Essayez un PDF texte ou une image plus lisible."
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

    private func recognizeText(in cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                continuation.resume(returning: text)
            }

            request.recognitionLanguages = ["fr-FR", "en-US"]
            request.usesLanguageCorrection = true
            request.recognitionLevel = .accurate

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func buildResult(from rawText: String, source: CVImportSource) throws -> CVImportResult {
        let extractedSteps = extractRelevantSteps(from: rawText, source: source)

        guard !extractedSteps.isEmpty else {
            throw CVImportServiceError.noTextDetected
        }

        return CVImportResult(steps: Array(extractedSteps.prefix(5)))
    }

    private func extractRelevantSteps(from rawText: String, source: CVImportSource) -> [String] {
        let normalizedText = rawText
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\t", with: " ")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if source == .pdf {
            let pdfSteps = extractPDFExperienceBlocks(from: normalizedText)
            if !pdfSteps.isEmpty {
                return Array(uniquePreservingOrder(pdfSteps).prefix(5))
            }
        }

        let mergedLines = mergeLikelyFragments(normalizedText)
        let structuredSteps = extractStructuredExperienceSteps(from: mergedLines, source: source)

        if !structuredSteps.isEmpty {
            return Array(uniquePreservingOrder(structuredSteps).prefix(5))
        }

        let recoveredHeadlines = extractExperienceHeadlineFallback(from: mergedLines)
        if !recoveredHeadlines.isEmpty {
            return Array(uniquePreservingOrder(recoveredHeadlines).prefix(5))
        }

        let filteredLines = mergedLines.filter(isUsefulCVLine)
        let ranked = filteredLines
            .map { ($0, score(line: $0)) }
            .filter { $0.1 > 0 }
            .map(\.0)

        let unique = uniquePreservingOrder(ranked.isEmpty ? filteredLines : ranked)
        return Array(unique.prefix(5))
    }

    private func extractPDFExperienceBlocks(from lines: [String]) -> [String] {
        let sectionLines = pdfExperienceSectionLines(from: lines)
        let sequentialHeaders = extractSequentialPDFExperienceHeaders(from: sectionLines)

        if !sequentialHeaders.isEmpty {
            return sequentialHeaders
        }

        let richHeaders = extractRichPDFExperienceHeaders(from: sectionLines)

        if !richHeaders.isEmpty {
            return richHeaders
        }

        var results: [String] = []
        var index = 0

        while index < lines.count - 1 {
            let current = cleanup(lines[index])
            let next = cleanup(lines[index + 1])

            guard !current.isEmpty, !next.isEmpty else {
                index += 1
                continue
            }

            if isSectionHeading(current) || isSectionHeading(next) {
                index += 1
                continue
            }

            if isLikelyCompanyHeading(current),
               let experience = buildCompanyFirstPDFExperience(companyLine: current, roleLine: next) {
                results.append(experience)
                index += 2
                continue
            }

            if isLikelyRoleHeading(current),
               let experience = buildRoleFirstPDFExperience(roleLine: current, companyLine: next) {
                results.append(experience)
                index += 2
                continue
            }

            index += 1
        }

        return results
    }

    private func pdfExperienceSectionLines(from lines: [String]) -> [String] {
        guard let startIndex = lines.firstIndex(where: isExperienceSectionHeading) else {
            return lines
        }

        let tail = Array(lines.dropFirst(startIndex + 1))

        if let endOffset = tail.firstIndex(where: isEducationSectionHeading) {
            let linesAfterSection = tail.dropFirst(endOffset + 1)
            let experienceContinuesBelowSidebar = linesAfterSection.contains(where: isLikelyPDFExperienceHeaderStart)

            if !experienceContinuesBelowSidebar {
                return Array(tail.prefix(endOffset))
            }
        }

        return tail
    }

    private func extractSequentialPDFExperienceHeaders(from lines: [String]) -> [String] {
        var results: [String] = []
        var index = 0

        while index < lines.count {
            let current = cleanup(lines[index])

            guard !current.isEmpty else {
                index += 1
                continue
            }

            if isEducationSectionHeading(current)
                || isExperienceSectionHeading(current)
                || isBulletGlyphLine(current)
                || isProfileLikeLine(current) {
                index += 1
                continue
            }

            guard isLikelyPDFExperienceHeaderStart(current) else {
                index += 1
                continue
            }

            if let formatted = formatExplicitPDFExperience(
                current: current,
                next: index + 1 < lines.count ? cleanup(lines[index + 1]) : nil,
                next2: index + 2 < lines.count ? cleanup(lines[index + 2]) : nil
            ) {
                results.append(formatted.value)
                index += formatted.consumed
                continue
            }

            var consumedIndex: Int?
            var candidateLines = [current]

            for lookahead in 1...2 {
                let nextIndex = index + lookahead
                guard nextIndex < lines.count else { break }

                let nextLine = cleanup(lines[nextIndex])
                guard !nextLine.isEmpty else { break }

                if isBulletGlyphLine(nextLine)
                    || isEducationSectionHeading(nextLine)
                    || isExperienceSectionHeading(nextLine)
                    || isProfileLikeLine(nextLine) {
                    break
                }

                candidateLines.append(nextLine)

                if let formatted = formatRichPDFExperienceHeader(from: candidateLines) {
                    results.append(formatted)
                    consumedIndex = nextIndex
                    break
                }
            }

            if let consumedIndex {
                index = consumedIndex + 1
                continue
            }

            if let formatted = formatRichPDFExperienceHeader(from: [current]) {
                results.append(formatted)
            }

            index += 1
        }

        return uniquePreservingOrder(results)
    }

    private func formatExplicitPDFExperience(
        current: String,
        next: String?,
        next2: String?
    ) -> (value: String, consumed: Int)? {
        let safeNext = next.map(cleanup)
        let safeNext2 = next2.map(cleanup)

        if let safeNext,
           isPrimarilyPeriodLine(safeNext),
           isLikelyExperiencePayload(current) || isLikelyExperienceTitle(current) || isLikelyCompanyContext(current),
           let period = extractPeriod(from: safeNext) {
            return (normalizeRichPDFHeader("\(current) \(period)", period: period), 2)
        }

        if let safeNext,
           let safeNext2,
           isLikelyExperienceTitle(current),
           isLikelyCompanyContext(safeNext),
           isPrimarilyPeriodLine(safeNext2),
           let period = extractPeriod(from: safeNext2) {
            let combined = "\(current) \(safeNext) \(period)"
            guard let completePeriod = extractPeriod(from: combined) else {
                return (normalizeRichPDFHeader(combined, period: period), 3)
            }

            return (normalizeRichPDFHeader(combined, period: completePeriod), 3)
        }

        if let safeNext,
           isLikelyExperienceTitle(current),
           isLikelyCompanyContext(safeNext),
           let period = extractPeriod(from: safeNext),
           isCompletePeriodSegment(safeNext, period: period) {
            let combined = "\(current) \(safeNext)"
            return (normalizeRichPDFHeader(combined, period: period), 2)
        }

        return nil
    }

    private func extractRichPDFExperienceHeaders(from lines: [String]) -> [String] {
        let blocks = collectRichPDFHeaderBlocks(from: lines)
        let formatted = blocks.compactMap(formatRichPDFExperienceHeader(from:))
        return uniquePreservingOrder(formatted)
    }

    private func collectRichPDFHeaderBlocks(from lines: [String]) -> [[String]] {
        var blocks: [[String]] = []
        var current: [String] = []

        func flushCurrent() {
            let cleaned = current.map(cleanup).filter { !$0.isEmpty }
            if !cleaned.isEmpty {
                blocks.append(cleaned)
            }
            current.removeAll()
        }

        for rawLine in lines {
            let line = cleanup(rawLine)

            guard !line.isEmpty else {
                flushCurrent()
                continue
            }

            if isEducationSectionHeading(line) || isExperienceSectionHeading(line) {
                flushCurrent()
                continue
            }

            if isBulletGlyphLine(line) {
                flushCurrent()
                continue
            }

            if isProfileLikeLine(line) {
                flushCurrent()
                continue
            }

            if !current.isEmpty,
               let currentPeriod = extractPeriod(from: current.joined(separator: " ")),
               isLikelyPDFExperienceHeaderStart(line),
               !line.contains(currentPeriod) {
                flushCurrent()
            }

            current.append(line)
        }

        flushCurrent()
        return blocks
    }

    private func formatRichPDFExperienceHeader(from block: [String]) -> String? {
        let cleanedLines = block
            .map(cleanup)
            .filter { !$0.isEmpty }

        guard !cleanedLines.isEmpty else { return nil }
        guard cleanedLines.contains(where: isLikelyPDFExperienceHeaderStart) else { return nil }

        let combined = cleanedLines.joined(separator: " ")
        guard let period = extractPeriod(from: combined) else { return nil }
        guard isLikelyExperiencePayload(combined) else { return nil }

        let normalized = normalizeRichPDFHeader(combined, period: period)
        guard normalized.count >= 20 else { return nil }
        return normalized
    }

    private func extractStructuredExperienceSteps(from lines: [String], source: CVImportSource) -> [String] {
        var results: [String] = []
        var index = 0

        while index < lines.count {
            let current = cleanup(lines[index])

            guard !current.isEmpty else {
                index += 1
                continue
            }

            if isEducationLikeLine(current) || isBulletActionLine(current) {
                index += 1
                continue
            }

            if source == .pdf && isProfileLikeLine(current) {
                index += 1
                continue
            }

            if isDateLeadingLine(current) {
                let block = collectExperienceBlock(startingAt: index, in: lines, keepDetailLines: true)

                if let formatted = formatStructuredExperience(from: block) {
                    results.append(formatted)
                }

                index += max(block.count, 1)
                continue
            }

            if let inline = extractInlineStructuredExperience(
                from: current,
                followingLines: Array(lines.dropFirst(index + 1))
            ) {
                results.append(inline)
            }

            index += 1
        }

        return results
    }

    private func collectExperienceBlock(startingAt index: Int, in lines: [String], keepDetailLines: Bool) -> [String] {
        var block: [String] = [cleanup(lines[index])]
        var nextIndex = index + 1

        while nextIndex < lines.count {
            let nextLine = cleanup(lines[nextIndex])

            if nextLine.isEmpty || isDateLeadingLine(nextLine) || isEducationLikeLine(nextLine) {
                break
            }

            if block.count >= 4 {
                break
            }

            if keepDetailLines || !isLikelyDetailLine(nextLine) {
                block.append(nextLine)
            }
            nextIndex += 1
        }

        return block
    }

    private func formatStructuredExperience(from block: [String]) -> String? {
        guard let firstLine = block.first else { return nil }

        let period = extractPeriod(from: firstLine) ?? extractPeriod(from: block.joined(separator: " "))
        guard let period else { return nil }

        let titleCandidate = extractTitleAfterLeadingDate(from: firstLine, period: period)
            ?? block.dropFirst().compactMap { extractTitleCandidate(from: $0) }.first

        guard let titleCandidate else { return nil }

        let summary = extractSummarySentence(
            from: Array(block.dropFirst()),
            fallbackInlineRemainder: inlineRemainderAfterPeriod(in: firstLine, period: period)
        )

        return formatExperience(period: period, title: titleCandidate, summary: summary)
    }

    private func extractInlineStructuredExperience(from line: String, followingLines: [String]) -> String? {
        guard let period = extractPeriod(from: line),
              let title = extractTitleBeforePeriod(from: line, period: period) else {
            return nil
        }

        let summary = extractSummarySentence(
            from: Array(followingLines.prefix(3)),
            fallbackInlineRemainder: inlineRemainderAfterPeriod(in: line, period: period)
        )

        return formatExperience(period: period, title: title, summary: summary)
    }

    private func extractTitleCandidate(from line: String, period: String? = nil) -> String? {
        var candidate = line

        if let period {
            candidate = candidate.replacingOccurrences(
                of: period,
                with: "",
                options: [.caseInsensitive]
            )
        }

        candidate = candidate
            .replacingOccurrences(of: #"^\s*[:\-–|]+\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        candidate = sanitizeTitleCandidate(candidate)

        guard isLikelyExperienceTitle(candidate) else {
            return nil
        }

        return candidate
    }

    private func formatExperience(period: String, title: String, summary: String?) -> String {
        return "\(period) · \(title)"
    }

    private func extractTitleBeforePeriod(from line: String, period: String) -> String? {
        guard let periodRange = line.range(of: period, options: [.caseInsensitive]) else {
            return nil
        }

        let candidate = sanitizeTitleCandidate(cleanup(String(line[..<periodRange.lowerBound])))
        guard isLikelyExperienceTitle(candidate) else {
            return nil
        }

        return candidate
    }

    private func extractTitleAfterLeadingDate(from line: String, period: String) -> String? {
        guard let periodRange = line.range(of: period, options: [.caseInsensitive]) else {
            return nil
        }

        let trailing = cleanup(String(line[periodRange.upperBound...]))
        guard !trailing.isEmpty else {
            return nil
        }

        let candidate = sanitizeTitleCandidate(trimAtFirstDetailBoundary(trailing))
        guard isLikelyExperienceTitle(candidate) else {
            return nil
        }

        return candidate
    }

    private func inlineRemainderAfterPeriod(in line: String, period: String) -> String? {
        guard let periodRange = line.range(of: period, options: [.caseInsensitive]) else {
            return nil
        }

        let remainder = cleanup(String(line[periodRange.upperBound...]))
        guard !remainder.isEmpty else {
            return nil
        }

        return remainder
    }

    private func extractSummarySentence(from detailLines: [String], fallbackInlineRemainder: String?) -> String? {
        let candidateSource = detailLines
            .map(cleanup)
            .filter { !isLikelyExperienceTitle($0) }
            .first(where: isUsefulDetailForSummary)
            ?? fallbackInlineRemainder

        guard let candidateSource else { return nil }
        return summarizeDetail(candidateSource)
    }

    private func extractExperienceHeadlineFallback(from lines: [String]) -> [String] {
        lines.compactMap { line in
            let cleaned = cleanup(line)

            guard !cleaned.isEmpty else { return nil }
            guard !isEducationLikeLine(cleaned) else { return nil }
            guard !isBulletActionLine(cleaned) else { return nil }
            guard !isProfileLikeLine(cleaned) else { return nil }

            guard let period = extractPeriod(from: cleaned),
                  let title = extractTitleBeforePeriod(from: cleaned, period: period)
                    ?? extractTitleAfterLeadingDate(from: cleaned, period: period) else {
                return nil
            }

            return formatExperience(period: period, title: title, summary: nil)
        }
    }

    private func buildCompanyFirstPDFExperience(companyLine: String, roleLine: String) -> String? {
        guard !isEducationLikeLine(companyLine), !isProfileLikeLine(companyLine) else { return nil }
        guard let period = extractPeriod(from: roleLine) else { return nil }

        let company = sanitizeCompanyCandidate(companyLine)
        let role = sanitizeRoleCandidate(
            cleanup(
                roleLine.replacingOccurrences(of: period, with: "", options: [.caseInsensitive])
            )
        )

        guard isLikelyCompanyHeading(company), isLikelyExperienceTitle(role) else { return nil }

        return "\(company) — \(role) — \(period)"
    }

    private func normalizeRichPDFHeader(_ text: String, period: String) -> String {
        var normalized = text
            .replacingOccurrences(of: #"\s+\|\s+"#, with: " — ", options: .regularExpression)
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"Accenture\s+\("#, with: "Accenture (", options: .regularExpression)
            .replacingOccurrences(of: #"\s+\)"#, with: ")", options: .regularExpression)
            .replacingOccurrences(of: #"\s+–\s+"#, with: " – ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+-\s+"#, with: " - ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let periodRange = normalized.range(of: period, options: [.caseInsensitive]) {
            let rawPrefix = normalized[..<periodRange.lowerBound]
                .replacingOccurrences(of: #"[\|\-–—\s]+$"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let prefix = normalizeExperiencePrefix(rawPrefix)
            normalized = "\(prefix) — \(period)"
        }

        return normalized
    }

    private func normalizeExperiencePrefix(_ prefix: String) -> String {
        let cleaned = prefix
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let companyAnchors = [
            " Accenture",
            " Airbus",
            " Thales",
            " Capgemini",
            " DOMINO STAFF",
            " LESER",
            " O2",
            " OPTINERIS",
            " Mairie de",
            " TFN "
        ]

        for anchor in companyAnchors {
            if let range = cleaned.range(of: anchor), range.lowerBound != cleaned.startIndex {
                let title = cleaned[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                let context = cleaned[range.lowerBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty, !context.isEmpty {
                    return "\(title) — \(context)"
                }
            }
        }

        return cleaned
    }

    private func buildRoleFirstPDFExperience(roleLine: String, companyLine: String) -> String? {
        guard !isEducationLikeLine(roleLine), !isProfileLikeLine(roleLine) else { return nil }
        guard let period = extractPeriod(from: companyLine) else { return nil }

        let role = sanitizeRoleCandidate(roleLine)
        let company = sanitizeCompanyCandidate(
            cleanup(
                companyLine.replacingOccurrences(of: period, with: "", options: [.caseInsensitive])
            )
        )

        guard isLikelyExperienceTitle(role) else { return nil }
        guard isLikelyCompanyContext(company) else { return nil }

        return "\(role) — \(company) — \(period)"
    }

    private func isUsefulDetailForSummary(_ line: String) -> Bool {
        let lowercase = line.lowercased()

        if line.count < 12 || line.count > 140 { return false }
        if lowercase.contains("@") || lowercase.contains("http") { return false }
        if lowercase.contains("compétence") || lowercase.contains("skills") { return false }
        if isEducationLikeLine(line) { return false }
        if isLikelyExperienceTitle(line) { return false }

        return true
    }

    private func summarizeDetail(_ detail: String) -> String? {
        let cleaned = trimAtFirstDetailBoundary(detail)
            .replacingOccurrences(of: #"^[•\-–\s]+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return nil }

        var snippet = cleaned

        if let commaRange = snippet.range(of: ",") {
            snippet = String(snippet[..<commaRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let lowered = snippet.lowercased()
        let barePrefixes = [
            "pilotage", "gestion", "coordination", "validation", "conception",
            "migration", "déploiement", "automatisation", "structuration",
            "support", "analyse", "accompagnement", "création", "mise en place"
        ]

        if barePrefixes.contains(where: { lowered.hasPrefix($0) }) {
            return "A \(snippet.prefix(1).lowercased())\(snippet.dropFirst())."
        }

        if lowered.hasPrefix("a ") || lowered.hasPrefix("en ") {
            return "\(snippet.prefix(1).uppercased())\(snippet.dropFirst())."
        }

        return "A \(snippet.prefix(1).lowercased())\(snippet.dropFirst())."
    }

    private func trimAtFirstDetailBoundary(_ text: String) -> String {
        let patterns = [
            #"(\s{2,})"#,
            #"(\s[•\-–]\s)"#,
            #"(\.\s)"#,
            #"(;\s)"#
        ]

        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                return String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sanitizeTitleCandidate(_ text: String) -> String {
        var candidate = text
            .replacingOccurrences(of: #"^\s*[:\-–|]+\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let boundaries = [
            #"(\. )"#,
            #"(; )"#,
            #"(\s[•\-–]\s)"#,
            #"(\s+A\s+(regulated|integrated|collaborated|built|developed|supported|improved|ensured|created|managed|designed|performed|automated)\b)"#,
            #"(\s+avec\s+\d+\s+ans\b)"#,
            #"(\s+habitué[ea]?\b)"#,
            #"(\s+reconnu[ea]?\b)"#,
            #"(\s+dans\s+le\s+secteur\b)"#,
            #"(\s+amélioration\s+continue\b)"#
        ]

        for pattern in boundaries {
            if let range = candidate.range(of: pattern, options: .regularExpression) {
                candidate = String(candidate[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return candidate
    }

    private func sanitizeRoleCandidate(_ text: String) -> String {
        sanitizeTitleCandidate(text)
            .replacingOccurrences(of: #"^\s*[•○◦]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^\s*[-–—|]+\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sanitizeCompanyCandidate(_ text: String) -> String {
        cleanup(text)
            .replacingOccurrences(of: #"^\s*[•○◦]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isEducationLikeLine(_ line: String) -> Bool {
        let lowercase = line.lowercased()
        let educationKeywords = [
            "formation", "formations", "master", "mastère", "mastère", "m1", "m2",
            "licence", "bachelor", "université", "universite", "diplôme", "diplome",
            "certification", "certifications", "certifié", "certifie", "safe",
            "école", "ecole", "mects", "bts", "dut", "doctorat", "mba",
            "baccalauréat", "baccalaureat", "brevet", "lycée", "lycee",
            "obtention", "titre professionnel"
        ]

        return educationKeywords.contains(where: { lowercase.contains($0) })
    }

    private func isBulletActionLine(_ line: String) -> Bool {
        let cleaned = cleanup(line)
        let lowercase = cleaned.lowercased()
        let normalized = normalizedActionCandidate(from: cleaned).lowercased()

        if line.hasPrefix("•") || line.hasPrefix("-") || line.hasPrefix("–") {
            return true
        }

        let actionStarters = [
            "developed", "built", "improved", "supported", "collaborated",
            "performed", "enhanced", "ensured", "created", "implemented",
            "led", "managed", "designed", "developed", "automated",
            "développé", "amélioré", "piloté", "coordonné", "assuré",
            "créé", "mis en place", "conçu", "géré", "animé", "réalisé"
        ]

        return actionStarters.contains(where: { lowercase.hasPrefix($0) || normalized.hasPrefix($0) })
    }

    private func isProfileLikeLine(_ line: String) -> Bool {
        let lowercase = line.lowercased()
        let profileKeywords = [
            "avec 8 ans", "avec plus de", "dans le secteur", "amélioration continue",
            "habituée", "habitué", "reconnue", "reconnu", "environnements exigeants",
            "respect des délais", "rigoureuse", "autonome", "motivée",
            "ingénieure cheffe de projet avec", "soft skills", "profil", "à propos"
        ]

        if profileKeywords.contains(where: { lowercase.contains($0) }) {
            return true
        }

        if lowercase.hasSuffix(".") && extractPeriod(from: line) == nil {
            return true
        }

        return false
    }

    private func isSectionHeading(_ line: String) -> Bool {
        let lowercase = line.lowercased()
        let headings = [
            "expérience", "expériences", "experience", "experiences",
            "parcours", "formation", "formations", "compétences", "competences",
            "skills", "profil", "summary", "résumé", "a propos", "à propos",
            "langues", "centres d'intérêt", "centres d’interet", "certifications"
        ]

        if headings.contains(where: { lowercase == $0 || lowercase.hasPrefix("\($0) ") }) {
            return true
        }

        return false
    }

    private func isExperienceSectionHeading(_ line: String) -> Bool {
        let lowercase = line.lowercased()
        return lowercase.contains("experience")
            || lowercase.contains("expérience")
            || lowercase.contains("parcours professionnel")
            || lowercase == "parcours"
    }

    private func isEducationSectionHeading(_ line: String) -> Bool {
        let lowercase = line.lowercased()
        return lowercase.contains("formation")
            || lowercase.contains("éducation")
            || lowercase.contains("education")
            || lowercase.contains("compétence")
            || lowercase.contains("competence")
            || lowercase.contains("langues")
            || lowercase.contains("certification")
            || lowercase.contains("centres d'intérêt")
            || lowercase.contains("centres d’interet")
    }

    private func isBulletGlyphLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("●") || trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("▪")
    }

    private func isLikelyPDFExperienceHeaderStart(_ line: String) -> Bool {
        let cleaned = cleanup(line)
        guard !cleaned.isEmpty else { return false }
        guard !isSectionHeading(cleaned), !isEducationLikeLine(cleaned), !isProfileLikeLine(cleaned) else { return false }
        guard !isBulletGlyphLine(cleaned) else { return false }

        if isLikelyExperienceTitle(cleaned) {
            return true
        }

        return isLikelyCompanyHeading(cleaned)
    }

    private func isLikelyExperiencePayload(_ line: String) -> Bool {
        let cleaned = cleanup(line)
        guard extractPeriod(from: cleaned) != nil else { return false }

        let containsRole = isLikelyExperienceTitle(cleaned)
        let containsCompany = isLikelyCompanyContext(cleaned) || isLikelyCompanyHeading(cleaned)

        return containsRole || containsCompany
    }

    private func isLikelyCompanyHeading(_ line: String) -> Bool {
        let cleaned = sanitizeCompanyCandidate(line)
        let lowercase = cleaned.lowercased()

        guard !cleaned.isEmpty, cleaned.count <= 90 else { return false }
        guard extractPeriod(from: cleaned) == nil else { return false }
        guard !isSectionHeading(cleaned), !isEducationLikeLine(cleaned), !isProfileLikeLine(cleaned) else { return false }
        guard !isBulletActionLine(cleaned) else { return false }

        let words = cleaned.split(separator: " ")
        let uppercaseWords = words.filter { word in
            let letters = word.filter(\.isLetter)
            return !letters.isEmpty && letters == letters.uppercased()
        }

        let companyHints = [
            "airbus", "thales", "accenture", "continental", "kratos",
            "stmicroelectronics", "space", "defense", "defence", "domino",
            "ocea", "smart building", "union", "l’union", "liebherr"
        ]

        if companyHints.contains(where: { lowercase.contains($0) }) {
            return true
        }

        return !words.isEmpty && uppercaseWords.count >= max(1, words.count - 1)
    }

    private func isLikelyRoleHeading(_ line: String) -> Bool {
        let cleaned = sanitizeRoleCandidate(line)
        guard extractPeriod(from: cleaned) == nil else { return false }
        return isLikelyExperienceTitle(cleaned)
    }

    private func isLikelyCompanyContext(_ line: String) -> Bool {
        let cleaned = sanitizeCompanyCandidate(line)
        let lowercase = cleaned.lowercased()

        guard !cleaned.isEmpty else { return false }
        guard !isSectionHeading(cleaned), !isEducationLikeLine(cleaned), !isProfileLikeLine(cleaned) else { return false }

        let companyHints = [
            "airbus", "thales", "accenture", "continental", "kratos",
            "stmicroelectronics", "mission", "client", "dgac", "domino",
            "ocea", "smart building", "union", "l’union", "liebherr", "pour "
        ]

        return companyHints.contains(where: { lowercase.contains($0) }) || isLikelyCompanyHeading(cleaned)
    }

    private func isPrimarilyPeriodLine(_ line: String) -> Bool {
        let cleaned = cleanup(line)
        guard cleaned.range(of: #"[-–—/]\s*$"#, options: .regularExpression) == nil else {
            return false
        }

        guard let period = extractPeriod(from: cleaned) else { return false }

        let remainder = cleaned
            .replacingOccurrences(of: period, with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: #"\((cdd|cdi|stage|alternance|interim|intérim)\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[\|\-–—\s]+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return remainder.isEmpty
    }

    private func isCompletePeriodSegment(_ line: String, period: String) -> Bool {
        guard let periodRange = line.range(of: period, options: [.caseInsensitive]) else {
            return false
        }

        let suffix = cleanup(String(line[periodRange.upperBound...]))
            .trimmingCharacters(in: CharacterSet(charactersIn: "|–—-/.,;:()[]"))

        guard suffix.isEmpty else { return false }

        let periodLowercase = period.lowercased()
        return periodLowercase.range(of: #"[-–—/]"#, options: .regularExpression) != nil
            || periodLowercase.contains("présent")
            || periodLowercase.contains("present")
            || periodLowercase.contains("aujourd")
            || periodLowercase.contains("today")
            || period.range(of: #"\d{2}/\d{2}/\d{2,4}"#, options: .regularExpression) != nil
    }

    private func normalizedActionCandidate(from line: String) -> String {
        cleanup(line)
            .replacingOccurrences(
                of: #"^\s*((19|20)\d{2}|[A-Za-zéûîôàèù]+\s+(19|20)\d{2}|[A-Za-zéûîôàèù]+\s+\d{4}\s*[-–—/]\s*[A-Za-zéûîôàèù0-9']+)\s*[:·\-–—|]+\s*"#,
                with: "",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isDateLeadingLine(_ line: String) -> Bool {
        line.range(
            of: #"^\s*((19|20)\d{2}|[A-Za-zéûîôàèù\.]+\s+(19|20)\d{2}|\d{2}/\d{2}/\d{2,4})"#,
            options: .regularExpression
        ) != nil
    }

    private func extractPeriod(from line: String) -> String? {
        let month = #"(janv(?:ier)?\.?|févr(?:ier)?\.?|fevr(?:ier)?\.?|mars|avr(?:il)?\.?|mai|juin|juil(?:let)?\.?|ao[uû]t|sept(?:embre)?\.?|oct(?:obre)?\.?|nov(?:embre)?\.?|d[ée]c(?:embre)?\.?)"#
        let current = #"(présent|present|aujourd['’]hui|today)"#
        let patterns = [
            #"\b\d{2}/\d{2}/\d{2,4}\s*(à|a|[-–—/])\s*(\d{2}/\d{2}/\d{2,4}|présent|present|aujourd['’]hui|today)\b"#,
            "\(month)\\s+(19|20)\\d{2}\\s*(à|a|[-–—/])\\s*(\(month)\\s+)?((19|20)\\d{2}|\(current))",
            #"(19|20)\d{2}\s*(à|a|[-–—/])\s*((19|20)\d{2}|présent|present|aujourd['’]hui|today)"#,
            "\(month)\\s+(19|20)\\d{2}\\b",
            #"\b\d{2}/\d{2}/\d{2,4}\b"#,
            #"\b(19|20)\d{2}\b"#
        ]

        for pattern in patterns {
            if let range = line.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                return cleanup(String(line[range]))
            }
        }

        return nil
    }

    private func isLikelyDetailLine(_ line: String) -> Bool {
        let lowercase = line.lowercased()

        if line.count > 110 { return true }
        if line.hasPrefix("•") || line.hasPrefix("-") || line.hasPrefix("–") { return true }
        if lowercase.hasPrefix("mission") || lowercase.hasPrefix("missions") { return true }
        if lowercase.hasPrefix("responsable de") || lowercase.hasPrefix("en charge de") { return true }
        if lowercase.contains("amélioration") || lowercase.contains("coordination de") { return true }

        return false
    }

    private func isLikelyExperienceTitle(_ line: String) -> Bool {
        let lowercase = line.lowercased()

        if line.count < 6 || line.count > 90 { return false }
        if lowercase.contains("@") || lowercase.contains("http") { return false }
        if lowercase.contains("ce que cela montre") { return false }
        if lowercase.contains("compétence") || lowercase.contains("skills") { return false }
        if isEducationLikeLine(line) { return false }
        if isBulletActionLine(line) { return false }
        if isProfileLikeLine(line) { return false }

        let actionLikeFragments = [
            "j'ai", "j’ai", "mise en", "amélioration de", "participation", "gestion de",
            "contribution à", "développement de", "coordination de", "responsable de"
        ]

        if actionLikeFragments.contains(where: { lowercase.contains($0) }) {
            return false
        }

        let titleKeywords = [
            "consultant", "manager", "responsable", "ingénieur", "ingenieur", "développeur",
            "developpeur", "chef", "coordinateur", "coordinatrice", "analyste", "designer",
            "product", "lead", "directeur", "chargé", "chargee", "spécialiste", "specialiste",
            "engineer", "architect", "owner", "qa", "test engineer", "plm",
            "assistante", "assistant", "assistante d’exploitation", "assistante d'exploitation",
            "assistante administrative", "technicien", "technicienne", "technicienne de paie",
            "employée", "employee", "employe", "secrétaire", "secretaire", "agent",
            "agent d’accueil", "agent d'accueil", "gestionnaire de paie",
            "testeur", "paramétreur", "parametreur"
        ]

        return titleKeywords.contains(where: { lowercase.contains($0) })
    }

    private func mergeLikelyFragments(_ lines: [String]) -> [String] {
        var merged: [String] = []

        for line in lines {
            let cleanedLine = cleanup(line)

            guard !cleanedLine.isEmpty else { continue }

            if var last = merged.last,
               shouldMerge(previous: last, current: cleanedLine) {
                merged.removeLast()
                last = "\(last) \(cleanedLine)"
                merged.append(cleanup(last))
            } else {
                merged.append(cleanedLine)
            }
        }

        return merged
    }

    private func shouldMerge(previous: String, current: String) -> Bool {
        if previous.count >= 90 { return false }
        if isLikelyCompanyHeading(previous) && (isLikelyRoleHeading(current) || extractPeriod(from: current) != nil) {
            return false
        }
        if isLikelyRoleHeading(previous) && isLikelyCompanyContext(current) {
            return false
        }
        if beginsLikeNewStep(current) { return false }
        if previous.hasSuffix(".") || previous.hasSuffix(":") { return false }
        return current.count < 55 || previous.count < 45
    }

    private func beginsLikeNewStep(_ line: String) -> Bool {
        let lowercase = line.lowercased()
        if lowercase.range(of: #"^(19|20)\d{2}"#, options: .regularExpression) != nil {
            return true
        }

        let keywords = [
            "expérience", "experience", "formation", "stage", "consultant", "chef",
            "manager", "développeur", "developpeur", "ingénieur", "ingenieur",
            "responsable", "coordinateur", "coordinatrice", "transition", "reconversion"
        ]

        return keywords.contains { lowercase.hasPrefix($0) }
    }

    private func isUsefulCVLine(_ line: String) -> Bool {
        let lowercase = line.lowercased()

        if line.count < 28 || line.count > 170 { return false }
        if lowercase.contains("@") || lowercase.contains("linkedin") || lowercase.contains("http") { return false }
        if lowercase.range(of: #"\b\d{10}\b"#, options: .regularExpression) != nil { return false }
        if isEducationLikeLine(line) { return false }
        if isBulletActionLine(line) { return false }
        if isProfileLikeLine(line) { return false }
        if lowercase == line.uppercased(), line.count < 40 { return false }

        let noisyKeywords = [
            "compétences", "competences", "skills", "langues", "loisirs",
            "contact", "profil", "références", "references"
        ]

        if noisyKeywords.contains(where: { lowercase == $0 || lowercase.hasPrefix("\($0) :") }) {
            return false
        }

        return true
    }

    private func score(line: String) -> Int {
        let lowercase = line.lowercased()
        var score = 0

        if lowercase.range(of: #"(19|20)\d{2}"#, options: .regularExpression) != nil {
            score += 3
        }

        let trajectoryKeywords = [
            "pilotage", "coordination", "transition", "reconversion", "poste",
            "mission", "projet", "responsable", "manager", "consultant",
            "ingénieur", "ingenieur", "développeur", "developpeur", "produit"
        ]

        if trajectoryKeywords.contains(where: { lowercase.contains($0) }) {
            score += 2
        }

        if (40...125).contains(line.count) {
            score += 1
        }

        return score
    }

    private func uniquePreservingOrder(_ lines: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for line in lines {
            let canonical = line.lowercased()
            if seen.insert(canonical).inserted {
                result.append(line)
            }
        }

        return result
    }

    private func cleanup(_ line: String) -> String {
        line
            .replacingOccurrences(of: #"^[•\-–\s]+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
