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

/// Why a kickoff did not produce an answer. The distinction matters: a missing
/// endpoint is a planned degrade the user need not know about, whereas a
/// network or server failure is something they just paid for and lost — they
/// deserve to be told and to be able to retry.
enum PremiumKickoffOutcome: Equatable {
    case ready(PremiumKickoffResponse)
    /// Endpoint not deployed yet — degrade silently to the continuity bridge.
    case notDeployed
    /// Network or server failure — surface it and offer a retry.
    case failed

    static let backendErrorDomain = "LegitimaInterviewPreparation"

    /// HTTP answers that mean « this route does not exist here », as opposed to
    /// « the route exists and something went wrong ».
    private static let missingEndpointCodes: Set<Int> = [404, 405, 501]

    static func classify(_ error: Error) -> PremiumKickoffOutcome {
        let underlying: Error
        if case IAService.IAServiceError.requestFailed(let wrapped) = error {
            underlying = wrapped
        } else {
            underlying = error
        }

        let nsError = underlying as NSError
        guard nsError.domain == backendErrorDomain else { return .failed }
        return missingEndpointCodes.contains(nsError.code) ? .notDeployed : .failed
    }
}

extension InterviewPreparationContext {
    /// The lean data every premium computation starts from. Shared by the
    /// kickoff call and the guided recruitment flow so the premium entry is
    /// always the continuation of the free analysis, never a re-entry. Once a
    /// debrief exists, the next preparation also starts from what the room
    /// actually revealed.
    static func lean(
        from snapshot: PreparationSnapshot,
        now: Date = .now
    ) -> InterviewPreparationContext {
        InterviewPreparationContext(
            targetRole: snapshot.targetRole,
            careerExperiences: snapshot.careerSummary,
            sensitivePoint: snapshot.sensitivePoint,
            freemiumAnalysis: (
                [
                    interviewDeadline(in: snapshot, now: now),
                    snapshot.analysis.map(freemiumSummary),
                ].compactMap { $0 }
                + (snapshot.debrief?.contextLines ?? [])
            )
            .joined(separator: "\n\n")
        )
    }

    /// The deadline leads the context so the generation can prioritise: a day-J
    /// action plan reads differently at 2 days than at 3 weeks. Sent as prose
    /// inside the existing free-text field — the backend schemas forbid unknown
    /// keys, so a structured field needs a coordinated backend release first.
    private static func interviewDeadline(
        in snapshot: PreparationSnapshot,
        now: Date
    ) -> String? {
        guard let date = snapshot.interviewDate,
              let days = InterviewCountdown.daysUntil(date, from: now) else {
            return nil
        }
        return InterviewCountdown.promptLine(daysUntil: days)
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
