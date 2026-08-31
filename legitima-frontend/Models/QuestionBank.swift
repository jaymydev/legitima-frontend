import Foundation

/// Une question de la banque, avec son gabarit à balises.
///
/// Le gabarit arrive avec ses balises intactes : il est rempli sur l'appareil.
/// C'est ce qui permet à quelqu'un d'écrire son salaire dans une réponse sans
/// que ce salaire ait besoin d'atteindre le serveur.
struct BankQuestion: Codable, Equatable, Identifiable {
    let id: String
    let question: String
    let answer: String
    let followUp: String
    let avoid: String

    private enum CodingKeys: String, CodingKey {
        case id, question, answer, avoid
        case followUp = "follow_up"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        question = try container.decode(String.self, forKey: .question)
        answer = try container.decode(String.self, forKey: .answer)
        followUp = try container.decodeIfPresent(String.self, forKey: .followUp) ?? ""
        avoid = try container.decodeIfPresent(String.self, forKey: .avoid) ?? ""
    }

    init(id: String, question: String, answer: String, followUp: String = "", avoid: String = "") {
        self.id = id
        self.question = question
        self.answer = answer
        self.followUp = followUp
        self.avoid = avoid
    }
}

struct BankPage: Codable, Equatable {
    let useCaseID: String
    let questions: [BankQuestion]

    private enum CodingKeys: String, CodingKey {
        case questions
        case useCaseID = "use_case_id"
    }
}

/// Le vocabulaire arrêté des balises, et ce qu'on montre à leur place.
///
/// Fermé volontairement : une balise inventée ne pourrait jamais se remplir,
/// puisque rien ne saurait quoi y mettre ni comment la nommer à l'écran.
enum SlotVocabulary {
    static let labels: [String: String] = [
        "PRÉNOM": "votre prénom",
        "MÉTIER": "votre métier",
        "NOMBRE_ANNÉES_EXPÉRIENCE": "vos années d'expérience",
        "POSTE_ACTUEL": "votre poste actuel",
        "ENTREPRISE_ACTUELLE": "votre entreprise",
        "ANCIENNETÉ": "votre ancienneté",
        "POSTE_PRÉCÉDENT": "votre poste précédent",
        "ENTREPRISE_PRÉCÉDENTE": "votre entreprise précédente",
        "POSTE_VISÉ": "le poste visé",
        "ENTREPRISE_VISÉE": "l'entreprise visée",
        "SITE_VISÉ": "le site visé",
        "ÉQUIPE_VISÉE": "l'équipe visée",
        "MISSION_DE_L_OFFRE": "la mission de l'annonce",
        "RÉALISATION": "votre réalisation",
        "RÉALISATION_2": "une autre réalisation",
        "CE_QUE_J_AI_FAIT": "ce que vous avez fait",
        "RÉSULTAT": "le résultat obtenu",
        "RÉSULTAT_2": "un autre résultat",
        "CHIFFRE": "un chiffre",
        "CHIFFRE_2": "un autre chiffre",
        "DIFFICULTÉ": "la difficulté rencontrée",
        "COMPÉTENCE": "une compétence",
        "COMPÉTENCE_2": "une autre compétence",
        "OUTIL": "un outil ou une méthode",
        "CE_QUI_VOUS_ATTIRE": "ce qui vous attire",
        "OBJECTIF": "un objectif",
        "OBJECTIF_2": "un autre objectif",
        "AVANCEMENT": "où vous en êtes",
        "AVANCEMENT_2": "où vous en êtes",
        "POINT_À_AMÉLIORER": "votre axe de progrès",
        "PRÉTENTION_BASSE": "le bas de votre fourchette",
        "PRÉTENTION_HAUTE": "le haut de votre fourchette",
        "SALAIRE_ACTUEL": "votre salaire actuel",
        "PLANCHER": "votre minimum absolu",
        "AVANTAGE": "ce qui compte en plus du salaire",
        "AVANTAGE_2": "un autre élément",
        "AUGMENTATION_DEMANDÉE": "l'augmentation visée",
        "PRÉAVIS": "votre préavis",
    ]

    /// Les balises qui ne doivent jamais apparaître dans une phrase dite à voix
    /// haute. `<PLANCHER>` sert à la personne, pas à sa réponse : savoir son
    /// minimum change sa façon de parler, le dire le lui coûterait.
    static let neverSpoken: Set<String> = ["PLANCHER"]

    static func label(for slot: String) -> String {
        labels[slot] ?? slot.lowercased().replacingOccurrences(of: "_", with: " ")
    }

    static func slots(in template: String) -> [String] {
        let pattern = try! NSRegularExpression(pattern: "<([A-ZÉÈÀÎÔÛ_0-9]+)>")
        let range = NSRange(template.startIndex..., in: template)
        var found: [String] = []
        for match in pattern.matches(in: template, range: range) {
            guard let r = Range(match.range(at: 1), in: template) else { continue }
            let name = String(template[r])
            if !found.contains(name) { found.append(name) }
        }
        return found
    }
}
