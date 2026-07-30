import Foundation

/// Extracts a short, quotable objection from the freemium analysis so the
/// locked premium cards can tease with the user's own diagnosis instead of
/// generic copy. Foundation-only to keep the logic testable.
enum ObjectionTeaser {
    /// First probable objection as a single short sentence, or nil when the
    /// source text has no usable content. List markers ("-", "•", "1.", "1)")
    /// are stripped and the result is capped at `maxLength` characters.
    static func firstObjection(from probableObjections: String, maxLength: Int = 180) -> String? {
        let firstLine = probableObjections
            .components(separatedBy: .newlines)
            .map(stripListMarker)
            .first { !$0.isEmpty }

        guard let firstLine else { return nil }

        let sentence = firstSentence(of: firstLine)
        guard !sentence.isEmpty else { return nil }

        if sentence.count <= maxLength {
            return sentence
        }
        let cutoff = sentence.index(sentence.startIndex, offsetBy: maxLength - 3)
        return String(sentence[..<cutoff]).trimmingCharacters(in: .whitespaces) + "..."
    }

    private static func stripListMarker(_ line: String) -> String {
        var text = line.trimmingCharacters(in: .whitespaces)
        while let first = text.first, "-•*–".contains(first) {
            text.removeFirst()
            text = text.trimmingCharacters(in: .whitespaces)
        }
        text = text.replacingOccurrences(
            of: #"^\d+[.)]\s*"#,
            with: "",
            options: .regularExpression
        )
        return text.trimmingCharacters(in: .whitespaces)
    }

    private static func firstSentence(of text: String) -> String {
        guard let end = text.firstIndex(where: { "?!.".contains($0) }) else {
            return text
        }
        return String(text[...end]).trimmingCharacters(in: .whitespaces)
    }
}
