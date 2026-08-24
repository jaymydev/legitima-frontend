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

/// What the client sends to `POST /v3/interview/questions`.
///
/// `answers` and `experiences` may both be empty — a performance review needs
/// neither. That is the pivot's promise, so nothing here may quietly require
/// them back.
struct PreparedInterviewRequest: Encodable {
    let useCaseID: String
    let questionnaireVersion: String
    let answers: [PreparedInterviewAnswer]
    let experiences: [PreparedInterviewExperience]

    private enum CodingKeys: String, CodingKey {
        case answers, experiences
        case useCaseID = "use_case_id"
        case questionnaireVersion = "questionnaire_version"
    }
}

struct PreparedInterviewAnswer: Encodable {
    let questionID: String
    let answer: String

    private enum CodingKeys: String, CodingKey {
        case answer
        case questionID = "question_id"
    }
}

struct PreparedInterviewExperience: Encodable {
    let title: String
    let company: String
    let period: String
}
