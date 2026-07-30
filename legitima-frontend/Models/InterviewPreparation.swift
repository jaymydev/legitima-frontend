import Foundation

enum InterviewAnswerQuality {
    static let recommendedMinimumCharacterCount = 4

    static func isTooShort(_ answer: String) -> Bool {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count < recommendedMinimumCharacterCount
    }
}

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
    let options: [String]
    let suggestions: [String]

    private enum CodingKeys: String, CodingKey {
        case id, title, helper, required, options, suggestions
        case inputType = "input_type"
    }

    init(
        id: String,
        title: String,
        helper: String,
        required: Bool,
        inputType: String,
        options: [String] = [],
        suggestions: [String] = []
    ) {
        self.id = id
        self.title = title
        self.helper = helper
        self.required = required
        self.inputType = inputType
        self.options = options
        self.suggestions = suggestions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        helper = try container.decode(String.self, forKey: .helper)
        required = try container.decode(Bool.self, forKey: .required)
        inputType = try container.decode(String.self, forKey: .inputType)
        options = try container.decodeIfPresent([String].self, forKey: .options) ?? []
        suggestions = try container.decodeIfPresent([String].self, forKey: .suggestions) ?? []
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
    let context: InterviewPreparationContext?

    private enum CodingKeys: String, CodingKey {
        case useCaseID = "use_case_id"
        case questionnaireVersion = "questionnaire_version"
        case answers, context
    }
}

struct InterviewPreparationContext: Codable, Equatable {
    let targetRole: String
    let careerExperiences: String
    let sensitivePoint: String
    let freemiumAnalysis: String

    private enum CodingKeys: String, CodingKey {
        case targetRole = "target_role"
        case careerExperiences = "career_experiences"
        case sensitivePoint = "sensitive_point"
        case freemiumAnalysis = "freemium_analysis"
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
    /// Position in a multi-step flow. Kept with the answers so closing the app
    /// mid-questionnaire does not drop the user back to the first step with
    /// everything already filled in — which reads as lost work.
    var step: Int = 0
    var result: InterviewPreparationResponse?
    var updatedAt: Date = .now

    var hasWork: Bool {
        useCase != nil && (!answers.isEmpty || result != nil)
    }
}

enum QuestionnaireStepRestore {
    /// Where to reopen a saved multi-step flow.
    ///
    /// Never past the first step still missing a required answer. A saved
    /// index alone can point beyond the real work — a partial file, or a
    /// questionnaire whose questions changed — and the user would then reach
    /// the end only to find generation blocked, with nothing telling them
    /// which step is incomplete.
    static func step(
        saved: Int,
        stepCount: Int,
        isComplete: (Int) -> Bool
    ) -> Int {
        guard stepCount > 0 else { return 0 }
        let lastIndex = stepCount - 1
        let firstIncomplete = (0...lastIndex).first { !isComplete($0) } ?? lastIndex
        return min(max(saved, 0), min(firstIncomplete, lastIndex))
    }
}
