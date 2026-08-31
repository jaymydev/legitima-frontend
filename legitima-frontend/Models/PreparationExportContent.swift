import Foundation

/// Ce que le PDF emporte. Le rendu vit dans PreparationPDFExporter.
///
/// Les gabarits partent remplis : c'est un document qu'on relit dans la salle
/// d'attente, sans réseau et sans rouvrir l'app, donc des blancs y seraient
/// inutilisables. Ce qui n'est pas rempli garde son libellé — « votre
/// réalisation » — plutôt que la balise brute.
struct PreparationExportContent {
    struct Block {
        let title: String
        let paragraphs: [String]
        let numbered: Bool
    }

    static let documentName = "preparation-entretien.pdf"

    let title: String
    let blocks: [Block]

    /// `comfortable` est le filtre de confort : ce sur quoi la personne se
    /// sait à l'aise sort du document — c'est lui qu'on relit en cinq minutes,
    /// et chaque question retirée rend les autres plus lisibles. Une question
    /// de la banque y figure par son identifiant, une personnalisée par son
    /// texte. La numérotation se resserre : un document relu dans le couloir
    /// qui saute du 2 au 5 se lit comme un document auquel il manque des pages.
    init(
        page: BankPage,
        filled: [String: String],
        personalized: PreparedInterview? = nil,
        comfortable: Set<String> = []
    ) {
        title = "Vos questions d'entretien"
        let kept = page.questions.filter { !comfortable.contains($0.id) }
        var assembled = kept.enumerated().map { index, question in
            var paragraphs = [TemplateFilling.plainText(question.answer, filled: filled)]
            if !question.followUp.isEmpty {
                paragraphs.append(question.followUp)
            }
            if !question.avoid.isEmpty {
                paragraphs.append("À éviter : " + question.avoid)
            }
            return Block(
                title: "\(index + 1). \(question.question)",
                paragraphs: paragraphs,
                numbered: false
            )
        }

        // La numérotation continue celle de la banque : dans la salle
        // d'attente, c'est un seul document qu'on relit, pas deux.
        if let personalized {
            let keptPersonalized = personalized.questions.filter {
                !comfortable.contains($0.question)
            }
            assembled += keptPersonalized.enumerated().map { index, question in
                Block(
                    title: "\(kept.count + index + 1). \(question.question)",
                    paragraphs: [
                        question.isSentence ? question.answer : "Comment répondre : " + question.answer
                    ],
                    numbered: false
                )
            }
            if !personalized.actionPlan.isEmpty {
                assembled.append(Block(
                    title: "Avant d'entrer",
                    paragraphs: personalized.actionPlan,
                    numbered: true
                ))
            }
        }
        blocks = assembled
    }
}

/// Remplacer les balises d'un gabarit par ce qui a été saisi.
///
/// Partagé entre l'écran et le PDF pour qu'ils ne puissent pas diverger : ce
/// qu'on emporte doit être mot pour mot ce qu'on a lu.
enum TemplateFilling {
    static func plainText(_ template: String, filled: [String: String]) -> String {
        var output = ""
        var remainder = Substring(template)

        while let open = remainder.firstIndex(of: "<"),
              let close = remainder[open...].firstIndex(of: ">") {
            output += remainder[..<open]
            let name = String(remainder[remainder.index(after: open)..<close])
            output += filled[name] ?? SlotVocabulary.label(for: name)
            remainder = remainder[remainder.index(after: close)...]
        }

        return output + remainder
    }
}
