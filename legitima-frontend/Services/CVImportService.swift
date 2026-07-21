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

final class CVImportService {
    func extractSummary(fromPDFAt url: URL) async throws -> CVImportResult {
        guard let document = PDFDocument(url: url), let rawText = document.string else {
            throw CVImportServiceError.unreadableDocument
        }

        return try buildResult(from: rawText)
    }

    func extractSummary(from image: UIImage) async throws -> CVImportResult {
        guard let cgImage = image.cgImage else {
            throw CVImportServiceError.unreadableDocument
        }

        let recognizedText = try await recognizeText(in: cgImage)
        return try buildResult(from: recognizedText)
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

    private func buildResult(from rawText: String) throws -> CVImportResult {
        let extractedSteps = extractRelevantSteps(from: rawText)

        guard !extractedSteps.isEmpty else {
            throw CVImportServiceError.noTextDetected
        }

        return CVImportResult(steps: Array(extractedSteps.prefix(5)))
    }

    private func extractRelevantSteps(from rawText: String) -> [String] {
        let normalizedText = rawText
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\t", with: " ")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let mergedLines = mergeLikelyFragments(normalizedText)
        let structuredSteps = extractStructuredExperienceSteps(from: mergedLines)

        if !structuredSteps.isEmpty {
            return Array(uniquePreservingOrder(structuredSteps).prefix(5))
        }

        let filteredLines = mergedLines.filter(isUsefulCVLine)
        let ranked = filteredLines
            .map { ($0, score(line: $0)) }
            .filter { $0.1 > 0 }
            .map(\.0)

        let unique = uniquePreservingOrder(ranked.isEmpty ? filteredLines : ranked)
        return Array(unique.prefix(5))
    }

    private func extractStructuredExperienceSteps(from lines: [String]) -> [String] {
        var results: [String] = []
        var index = 0

        while index < lines.count {
            let current = cleanup(lines[index])

            guard !current.isEmpty else {
                index += 1
                continue
            }

            if isDateLeadingLine(current) {
                let block = collectExperienceBlock(startingAt: index, in: lines)

                if let formatted = formatStructuredExperience(from: block) {
                    results.append(formatted)
                }

                index += max(block.count, 1)
                continue
            }

            if let inline = extractInlineStructuredExperience(from: current) {
                results.append(inline)
            }

            index += 1
        }

        return results
    }

    private func collectExperienceBlock(startingAt index: Int, in lines: [String]) -> [String] {
        var block: [String] = [cleanup(lines[index])]
        var nextIndex = index + 1

        while nextIndex < lines.count {
            let nextLine = cleanup(lines[nextIndex])

            if nextLine.isEmpty || isDateLeadingLine(nextLine) {
                break
            }

            if isLikelyDetailLine(nextLine) {
                nextIndex += 1
                continue
            }

            if block.count >= 2 {
                break
            }

            block.append(nextLine)
            nextIndex += 1
        }

        return block
    }

    private func formatStructuredExperience(from block: [String]) -> String? {
        guard let firstLine = block.first else { return nil }

        let period = extractPeriod(from: firstLine) ?? extractPeriod(from: block.joined(separator: " "))
        guard let period else { return nil }

        let titleCandidate = extractTitleCandidate(from: firstLine, period: period)
            ?? block.dropFirst().compactMap { extractTitleCandidate(from: $0) }.first

        guard let titleCandidate else { return nil }

        return "\(period) · \(titleCandidate)"
    }

    private func extractInlineStructuredExperience(from line: String) -> String? {
        guard let period = extractPeriod(from: line),
              let title = extractTitleCandidate(from: line, period: period) else {
            return nil
        }

        return "\(period) · \(title)"
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

        if let splitRange = candidate.range(of: #"(\. | ; | • | - )"#, options: .regularExpression) {
            candidate = String(candidate[..<splitRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let companySeparator = candidate.range(of: #"(\s{2,}| \| | — | – )"#, options: .regularExpression) {
            let prefix = String(candidate[..<companySeparator.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if isLikelyExperienceTitle(prefix) {
                candidate = prefix
            }
        }

        guard isLikelyExperienceTitle(candidate) else {
            return nil
        }

        return candidate
    }

    private func isDateLeadingLine(_ line: String) -> Bool {
        line.range(
            of: #"^\s*((19|20)\d{2}|[A-Za-zéûîôàèù]+\s+(19|20)\d{2})"#,
            options: .regularExpression
        ) != nil
    }

    private func extractPeriod(from line: String) -> String? {
        let patterns = [
            #"(19|20)\d{2}\s*[-–—/]\s*((19|20)\d{2}|présent|present|aujourd'hui|today)"#,
            #"[A-Za-zéûîôàèù]+\s+(19|20)\d{2}\s*[-–—/]\s*([A-Za-zéûîôàèù]+\s+)?((19|20)\d{2}|présent|present|aujourd'hui|today)"#,
            #"\b(19|20)\d{2}\b"#
        ]

        for pattern in patterns {
            if let range = line.range(of: pattern, options: .regularExpression) {
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
            "product", "lead", "directeur", "chargé", "chargee", "spécialiste", "specialiste"
        ]

        return titleKeywords.contains(where: { lowercase.contains($0) }) || line.split(separator: " ").count <= 8
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
