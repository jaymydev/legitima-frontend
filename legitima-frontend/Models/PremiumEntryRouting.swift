import Foundation

/// The interview-type intent a user can declare from the free onboarding.
/// The free analysis itself stays type-agnostic; the intent only steers the
/// premium entry and lets copy speak to the right conversation.
struct InterviewIntentOption: Equatable {
    /// Matching premium use-case ID, or nil for "not decided yet".
    let useCaseID: String?
    let label: String

    static let all: [InterviewIntentOption] = [
        InterviewIntentOption(useCaseID: "recruitment", label: "Recrutement"),
        InterviewIntentOption(useCaseID: "internal_mobility", label: "Mobilité interne"),
        InterviewIntentOption(useCaseID: "role_evolution", label: "Évolution de poste"),
        InterviewIntentOption(useCaseID: "annual_review", label: "Entretien annuel"),
        InterviewIntentOption(useCaseID: nil, label: "Je ne sais pas encore"),
    ]
}

/// Where the premium entry screen should land, resolved from the saved
/// preparation and the intent declared in onboarding. Priority: a completed
/// result, then the saved use-case choice (even before any answer is typed,
/// so re-entering premium never overrides the user's selection), then the
/// declared intent, and recruitment only as the last default.
enum PremiumEntryDestination {
    case result(InterviewPreparationResponse)
    case recruitment(InterviewUseCase)
    case questionnaire(InterviewUseCase)
    /// No saved work: load the catalog and begin this use case.
    case startUseCase(id: String)
}

enum PremiumEntryRouting {
    static func destination(
        for saved: SavedInterviewPreparation,
        intendedUseCaseID: String?,
        recruitmentUseCaseID: String
    ) -> PremiumEntryDestination {
        if let result = saved.result {
            return .result(result)
        }

        if let useCase = saved.useCase {
            return useCase.id == recruitmentUseCaseID
                ? .recruitment(useCase)
                : .questionnaire(useCase)
        }

        return .startUseCase(id: intendedUseCaseID ?? recruitmentUseCaseID)
    }
}
