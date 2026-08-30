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

    init(page: BankPage, filled: [String: String]) {
        title = "Vos questions d'entretien"
        blocks = page.questions.enumerated().map { index, question in
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
