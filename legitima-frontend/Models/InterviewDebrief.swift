import Foundation

/// What the user brings back from the interview room. Captured the day after,
/// it is the second premium usage: the material that makes the next
/// preparation sharper than a cold start.
struct InterviewDebrief: Codable, Equatable {
    var difficultQuestions: String = ""
    var whatWorked: String = ""
    var recordedAt: Date = .now

    var hasContent: Bool {
        !difficultQuestions.trimmed.isEmpty || !whatWorked.trimmed.isEmpty
    }

    /// Prose for the generation context of the next preparation, so the
    /// questions that actually landed badly get worked on first.
    var contextLines: [String] {
        var lines: [String] = []
        if !difficultQuestions.trimmed.isEmpty {
            lines.append("Lors d'un entretien précédent, ces questions ont mis la personne en difficulté : \(difficultQuestions.trimmed)")
        }
        if !whatWorked.trimmed.isEmpty {
            lines.append("Ce qui a bien fonctionné : \(whatWorked.trimmed)")
        }
        return lines
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
