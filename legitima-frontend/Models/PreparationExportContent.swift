import Foundation

/// Ce que le PDF emporte. Le rendu vit dans PreparationPDFExporter.
///
/// Les gabarits partent remplis : c'est un document qu'on relit dans la salle
/// d'attente, sans réseau et sans rouvrir l'app, donc des blancs y seraient
/// inutilisables. Ce qui n'est pas rempli garde son libellé — « votre
/// réalisation » — plutôt que la balise brute.
struct PreparationExportContent {
    /// Le code couleur du rapport, demandé par le retour testeur : rouge pour
    /// les points sensibles, bleu pour ce qui porte la légitimité — les
    /// phrases qu'on peut dire — et vert pour ce qui est acquis. Le ton est
    /// une donnée du contenu, pas du rendu : c'est ce qui interdit à l'écran
    /// et au PDF de raconter deux choses différentes.
    enum Tone {
        /// Une phrase à dire telle quelle : la légitimité. Bleu.
        case say
        /// Une consigne sur la façon de répondre, jamais une phrase.
        case guidance
        /// La relance probable derrière la question.
        case followUp
        /// Le point sensible : ce qu'il ne faut pas faire. Rouge.
        case avoid
        /// Ce qui est acquis — les questions marquées « à l'aise ». Vert.
        case acquired
        case plain
    }

    struct Paragraph: Equatable {
        let text: String
        let tone: Tone

        init(_ text: String, tone: Tone = .plain) {
            self.text = text
            self.tone = tone
        }
    }

    struct Block {
        let title: String
        let paragraphs: [Paragraph]
        let numbered: Bool
        /// Le ton du titre. `.acquired` peint « Déjà acquis » en vert.
        var titleTone: Tone = .plain
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
        var assembled = kept.enumerated().map { index, question -> Block in
            var paragraphs = [
                Paragraph(TemplateFilling.plainText(question.answer, filled: filled), tone: .say)
            ]
            if !question.followUp.isEmpty {
                // La relance porte les mêmes balises que le gabarit. Partie
                // brute, elle imprimait « <PRÉTENTION_BASSE> » dans un document
                // relu sans l'app sous la main.
                paragraphs.append(
                    Paragraph(TemplateFilling.plainText(question.followUp, filled: filled), tone: .followUp)
                )
            }
            if !question.avoid.isEmpty {
                paragraphs.append(Paragraph(question.avoid.capitalizedFirst, tone: .avoid))
            }
            return Block(
                title: "\(index + 1). \(question.question)",
                paragraphs: paragraphs,
                numbered: false
            )
        }

        // La numérotation continue celle de la banque : dans la salle
        // d'attente, c'est un seul document qu'on relit, pas deux.
        var acquiredTitles = page.questions
            .filter { comfortable.contains($0.id) }
            .map(\.question)
        if let personalized {
            let keptPersonalized = personalized.questions.filter {
                !comfortable.contains($0.question)
            }
            assembled += keptPersonalized.enumerated().map { index, question in
                Block(
                    title: "\(kept.count + index + 1). \(question.question)",
                    paragraphs: [
                        Paragraph(question.answer, tone: question.isSentence ? .say : .guidance)
                    ],
                    numbered: false
                )
            }
            acquiredTitles += personalized.questions
                .filter { comfortable.contains($0.question) }
                .map(\.question)
        }

        // Le vert : les questions marquées « à l'aise », citées sans être
        // traitées — c'est le contrat du filtre de confort. Les nommer rend le
        // rapport court lisible comme un choix, et se relit dans le couloir
        // comme ce que c'est : du terrain déjà conquis.
        if !acquiredTitles.isEmpty {
            assembled.append(Block(
                title: "Déjà acquis",
                paragraphs: acquiredTitles.map { Paragraph($0, tone: .acquired) },
                numbered: false,
                titleTone: .acquired
            ))
        }

        if let personalized, !personalized.actionPlan.isEmpty {
            assembled.append(Block(
                title: "Avant d'entrer",
                paragraphs: personalized.actionPlan.map { Paragraph($0) },
                numbered: true
            ))
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
