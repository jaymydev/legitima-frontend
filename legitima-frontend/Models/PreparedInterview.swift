import Foundation

/// What `POST /v3/interview/questions` returns.
///
/// A question the person will be asked, what the interviewer is checking behind
/// it, and an answer short enough to say out loud. `intent` is what separates
/// this from a script: if the question comes out differently on the day, it is
/// the thing that lets someone improvise instead of reciting.
struct PreparedQuestion: Codable, Equatable, Identifiable {
    let question: String
    let intent: String
    let answer: String

    var id: String { question }
}

struct PreparedInterview: Codable, Equatable {
    let useCaseID: String
    let title: String
    let questions: [PreparedQuestion]
    let actionPlan: [String]

    private enum CodingKeys: String, CodingKey {
        case title, questions
        case useCaseID = "use_case_id"
        case actionPlan = "action_plan"
    }
}
