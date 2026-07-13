import Foundation

struct FilConducteurRequest: Encodable {
    let meta: Meta
    let narrative_positioning: NarrativePositioning

    struct Meta: Encodable {
        let version: String
        let language: String
        let target_market: String
        let interview_type: String
    }

    struct NarrativePositioning: Encodable {
        let short_summary: String
        let current_positioning: String
        let evolution_logic: String
    }
}

struct AnalyzeRequest: Encodable {
    let input: FilConducteurRequest
}

enum AnalyzePromptPolicy {
    static func frenchOnlyEvolutionLogic(_ value: String) -> String {
        let instruction = "Consigne de sortie : répondez exclusivement en français."
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            return instruction
        }

        return "\(trimmedValue)\n\n\(instruction)"
    }
}
