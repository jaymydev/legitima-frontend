import Foundation

final class JSONBuilder {

    func buildFilConducteurJSON(
        resume: String,
        positionnement: String,
        logique: String
    ) -> String {

        let escapedResume = resume.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedPositionnement = positionnement.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedLogique = logique.replacingOccurrences(of: "\"", with: "\\\"")

        return """
        {
          "meta": {
            "version": "1.0",
            "language": "fr",
            "target_market": "US",
            "interview_type": "recruitment"
          },
          "narrative_positioning": {
            "short_summary": "\(escapedResume)",
            "current_positioning": "\(escapedPositionnement)",
            "evolution_logic": "\(escapedLogique)"
          }
        }
        """
    }
}
