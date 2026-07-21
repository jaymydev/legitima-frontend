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

private enum CVImportSource {
    case pdf
    case image
}

final class CVImportService {
    func extractSummary(fromPDFAt url: URL) async throws -> CVImportResult {
        guard let document = PDFDocument(url: url), let rawText = document.string else {
            throw CVImportServiceError.unreadableDocument
        }

        return try buildResult(from: rawText, source: .pdf)
    }

    func extractSummary(from image: UIImage) async throws -> CVImportResult {
        guard let cgImage = image.cgImage else {
            throw CVImportServiceError.unreadableDocument
        }

        let recognizedText = try await recognizeText(in: cgImage)
        return try buildResult(from: recognizedText, source: .image)
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
            "certification", "école", "ecole", "mects", "bts", "dut", "doctorat", "mba"
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
            "respect des délais", "rigoureuse", "autonome", "motivée", "opérationnelle",
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
            "skills", "profil", "summary", "résumé", "a propos", "à propos"
        ]

        if headings.contains(where: { lowercase == $0 || lowercase.hasPrefix("\($0) ") }) {
            return true
        }

        return false
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
            "stmicroelectronics", "space", "defense", "defence"
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
            "stmicroelectronics", "mission", "client", "dgac"
        ]

        return companyHints.contains(where: { lowercase.contains($0) }) || isLikelyCompanyHeading(cleaned)
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
            "engineer", "architect", "owner", "scrum", "qa", "test engineer", "plm"
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
