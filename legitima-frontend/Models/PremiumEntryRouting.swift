import Foundation

/// Where the premium entry screen should land, resolved from the saved
/// preparation. The saved use-case choice always wins — even before any
/// answer is typed — so re-entering premium never overrides the user's
/// selection. Recruitment is only the default when nothing was chosen yet,
/// because the free flow carries no interview-type choice of its own.
enum PremiumEntryDestination {
    case result(InterviewPreparationResponse)
    case recruitment(InterviewUseCase)
    case questionnaire(InterviewUseCase)
    case startRecruitment
}

enum PremiumEntryRouting {
    static func destination(
        for saved: SavedInterviewPreparation,
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

        return .startRecruitment
    }
}
