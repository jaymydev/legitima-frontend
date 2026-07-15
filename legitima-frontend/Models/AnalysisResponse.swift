import Foundation

struct AnalysisResponse: Codable, Equatable {
    let analysis: AnalysisSection
    let sensitive_reframing: SensitiveSection
    let narrative: NarrativeSection
    let interview_preparation: InterviewSection
    let legitimacy_anchor: LegitimacySection
}

struct AnalysisSection: Codable, Equatable {
    let strategic_reading: String
    let dominant_competencies: String
    let career_logic: String
}

struct SensitiveSection: Codable, Equatable {
    let identified_fragilities: String
    let strategic_reinterpretation: String
    let rational_reframing: String
}

struct NarrativeSection: Codable, Equatable {
    let core_thread: String
    let positioning_statement: String
}

struct InterviewSection: Codable, Equatable {
    let probable_objections: String
    let structured_answers: String
}

struct LegitimacySection: Codable, Equatable {
    let objective_strength: String
    let final_alignment_statement: String
}
