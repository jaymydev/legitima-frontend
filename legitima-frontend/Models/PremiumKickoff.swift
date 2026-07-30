import Foundation

/// First premium deliverable (moment T, option « première valeur immédiate ») :
/// the purchase triggers a real backend computation that quotes the probable
/// objection and answers it, from the lean context alone — before any guided
/// question is asked.
struct PremiumKickoffRequest: Codable, Equatable {
    let context: InterviewPreparationContext
}

struct PremiumKickoffResponse: Codable, Equatable {
    let objection: String
    let defensibleAnswer: String

    private enum CodingKeys: String, CodingKey {
        case objection
        case defensibleAnswer = "defensible_answer"
    }
}

extension InterviewPreparationContext {
    /// The lean data every premium computation starts from. Shared by the
    /// kickoff call and the guided recruitment flow so the premium entry is
    /// always the continuation of the free analysis, never a re-entry.
    static func lean(from snapshot: PreparationSnapshot) -> InterviewPreparationContext {
        InterviewPreparationContext(
            targetRole: snapshot.targetRole,
            careerExperiences: snapshot.careerSummary,
            sensitivePoint: snapshot.sensitivePoint,
            freemiumAnalysis: snapshot.analysis.map(freemiumSummary) ?? ""
        )
    }

    static func freemiumSummary(_ response: AnalysisResponse) -> String {
        [
            response.analysis.strategic_reading,
            response.analysis.dominant_competencies,
            response.analysis.career_logic,
            response.sensitive_reframing.strategic_reinterpretation,
            response.narrative.core_thread,
            response.interview_preparation.probable_objections,
            response.interview_preparation.structured_answers,
            response.legitimacy_anchor.objective_strength,
        ].joined(separator: "\n\n")
    }
}
