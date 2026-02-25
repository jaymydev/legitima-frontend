import Foundation

final class IAService {

    func analyze(json: String, completion: @escaping (String) -> Void) {

        let mockResponse = """
        {
          "analysis": {
            "strategic_reading": "Profile demonstrates progressive alignment toward strategic roles.",
            "dominant_competencies": "Technical depth, structured thinking, adaptability.",
            "career_logic": "Non-linear evolution driven by responsibility expansion."
          },
          "sensitive_reframing": {
            "identified_fragilities": "Transitions and repositioning phases.",
            "strategic_reinterpretation": "Capability consolidation periods.",
            "rational_reframing": "Intentional strengthening of long-term positioning."
          },
          "narrative": {
            "core_thread": "Engineer evolving from execution to structured strategic impact.",
            "positioning_statement": "Technical expert aligned with business perspective."
          },
          "interview_preparation": {
            "probable_objections": "Why non-linear path?",
            "structured_answers": "Each step expanded scope and competencies."
          },
          "legitimacy_anchor": {
            "objective_strength": "10+ years domain expertise.",
            "final_alignment_statement": "Profile coherent with high-impact engineering roles."
          }
        }
        """

        completion(mockResponse)
    }
}
