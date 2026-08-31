import Foundation

/// Une réponse personnalisée, telle que /v3/interview/questions la renvoie.
///
/// `kind` est la moitié honnête du contrat : une phrase à dire (`sentence`)
/// n'est promise que si la matière fournie l'appuie — une passe de
/// vérification côté serveur rétrograde tout ce qui affirme sans source.
/// Sans matière, tout est consigne (`guidance`), et c'est dit tel quel.
struct PreparedQuestion: Codable, Equatable {
    let question: String
    /// Ce que la personne en face vérifie vraiment. Une phrase, lue en passant.
    let intent: String
    let answer: String
    let kind: String

    var isSentence: Bool { kind == "sentence" }
}

struct PreparedInterview: Codable, Equatable {
    let useCaseID: String
    let title: String
    let questions: [PreparedQuestion]
    /// Au plus trois gestes à faire avant d'entrer — le bloc « j'ai 5 minutes ».
    let actionPlan: [String]

    private enum CodingKeys: String, CodingKey {
        case title, questions
        case useCaseID = "use_case_id"
        case actionPlan = "action_plan"
    }
}

struct PreparedInterviewRequest: Encodable {
    let useCaseID: String
    let questionnaireVersion: String
    let answers: [InterviewAnswer]
    let experiences: [CVExperienceRow]
    let cvText: String

    private enum CodingKeys: String, CodingKey {
        case answers, experiences
        case useCaseID = "use_case_id"
        case questionnaireVersion = "questionnaire_version"
        case cvText = "cv_text"
    }
}

/// La matière du CV, gardée sur l'appareil après un import.
///
/// `/cv/parse` renvoie deux choses : les lignes intitulé/société/période, et le
/// texte brut extrait. Les lignes remplissent des blancs tout de suite ; le
/// texte, lui, ne sert qu'à la personnalisation — il ne repart vers le serveur
/// qu'au moment où la personne la demande, jamais avant.
struct CVMaterial: Codable, Equatable {
    var rawText: String = ""
    var experiences: [CVExperienceRow] = []

    var isEmpty: Bool {
        rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && experiences.isEmpty
    }
}

extension ProtectedJSONStore where Value == CVMaterial {
    static var cvMaterial: Self {
        Self(fileURL: applicationSupportURL.appendingPathComponent("cv-material.json"))
    }
}

/// Les préparations personnalisées, une par type d'entretien.
///
/// Gardées pour que fermer l'app ne coûte pas la génération — elle a demandé
/// une minute et quelques centimes de tokens, la page doit se rouvrir telle
/// quelle dans la salle d'attente.
extension ProtectedJSONStore where Value == [String: PreparedInterview] {
    static var personalizedPreparations: Self {
        Self(fileURL: applicationSupportURL.appendingPathComponent("personalized.json"))
    }
}

/// Préremplir le questionnaire de personnalisation avec les blancs déjà remplis.
///
/// Les questions ouvertes — « racontez une réalisation » — demandent ce que les
/// balises <RÉALISATION>, <CE_QUE_J_AI_FAIT> et <RÉSULTAT> contiennent déjà.
/// Redemander ce qui a été saisi serait exactement la friction que le pivot a
/// retirée ; le brouillon reste modifiable, rien n'est envoyé sans relecture.
enum PersonalizationPrefill {
    /// Les questions du catalogue qui demandent une réalisation racontée.
    private static let achievementQuestionIDs: Set<String> = [
        "achievement", "current_achievement", "result_to_highlight",
    ]

    static func draft(questionID: String, slots: [String: String]) -> String {
        guard achievementQuestionIDs.contains(questionID) else { return "" }
        return ["RÉALISATION", "CE_QUE_J_AI_FAIT", "RÉSULTAT"]
            .compactMap { slot in
                let value = (slots[slot] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? nil : value
            }
            .joined(separator: ". ")
    }
}
