import Foundation

struct InterviewUseCaseCatalog: Codable, Equatable {
    let useCases: [InterviewUseCase]

    private enum CodingKeys: String, CodingKey {
        case useCases = "use_cases"
    }
}

struct InterviewUseCase: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let shortTitle: String
    let description: String
    let questionnaireVersion: String
    let questions: [InterviewQuestion]

    private enum CodingKeys: String, CodingKey {
        case id, title, description, questions
        case shortTitle = "short_title"
        case questionnaireVersion = "questionnaire_version"
    }

    func hasAllRequiredAnswers(_ answers: [String: String]) -> Bool {
        questions
            .filter(\.required)
            .allSatisfy {
                !(answers[$0.id] ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
            }
    }
}

struct InterviewQuestion: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let helper: String
    let required: Bool
    let inputType: String

    private enum CodingKeys: String, CodingKey {
        case id, title, helper, required
        case inputType = "input_type"
    }
}

struct InterviewAnswer: Codable, Equatable {
    let questionID: String
    let answer: String

    private enum CodingKeys: String, CodingKey {
        case questionID = "question_id"
        case answer
    }
}

struct InterviewPreparationRequest: Codable, Equatable {
    let useCaseID: String
    let questionnaireVersion: String
    let answers: [InterviewAnswer]

    private enum CodingKeys: String, CodingKey {
        case useCaseID = "use_case_id"
        case questionnaireVersion = "questionnaire_version"
        case answers
    }
}

struct InterviewPreparationResponse: Codable, Equatable {
    let useCaseID: String
    let title: String
    let summary: String
    let sections: [InterviewPreparationSection]
    let talkingPoints: [String]
    let actionPlan: [String]

    private enum CodingKeys: String, CodingKey {
        case useCaseID = "use_case_id"
        case title, summary, sections
        case talkingPoints = "talking_points"
        case actionPlan = "action_plan"
    }
}

struct InterviewPreparationSection: Codable, Equatable {
    let title: String
    let content: String
}

struct SavedInterviewPreparation: Codable, Equatable {
    var useCase: InterviewUseCase?
    var answers: [String: String] = [:]
    var result: InterviewPreparationResponse?
    var updatedAt: Date = .now

    var hasWork: Bool {
        useCase != nil && (!answers.isEmpty || result != nil)
    }
}
