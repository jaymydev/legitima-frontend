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

    /// Un paragraphe est fait de segments : le rendu peut ainsi peindre un
    /// blanc non rempli comme un trou — souligné, coloré — au lieu de le
    /// fondre dans la phrase, où il se lirait comme du texte à dire.
    struct Paragraph: Equatable {
        let segments: [TemplateFilling.Segment]
        let tone: Tone

        var text: String { segments.map(\.text).joined() }

        init(_ text: String, tone: Tone = .plain) {
            segments = [.init(text: text, kind: .literal)]
            self.tone = tone
        }

        init(segments: [TemplateFilling.Segment], tone: Tone) {
            self.segments = segments
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
                Paragraph(segments: TemplateFilling.segments(question.answer, filled: filled), tone: .say)
            ]
            if !question.followUp.isEmpty {
                // La relance porte les mêmes balises que le gabarit. Partie
                // brute, elle imprimait « <PRÉTENTION_BASSE> » dans un document
                // relu sans l'app sous la main.
                paragraphs.append(
                    Paragraph(segments: TemplateFilling.segments(question.followUp, filled: filled), tone: .followUp)
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

        // Un seul « Avant d'entrer » : celui de la personnalisation quand elle
        // existe — il est plus spécifique — sinon celui de la banque, écrit à
        // la main. Les deux à la fois feraient six gestes, donc une révision.
        let plan = personalized?.actionPlan.isEmpty == false
            ? personalized?.actionPlan ?? []
            : page.actionPlan
        if !plan.isEmpty {
            assembled.append(Block(
                title: "Avant d'entrer",
                paragraphs: plan.map { Paragraph($0) },
                numbered: true
            ))
        }
        blocks = assembled
    }
}

/// Remplacer les balises d'un gabarit par ce qui a été saisi.
///
/// Partagé entre l'écran et le PDF pour qu'ils ne puissent pas diverger : ce
/// qu'on emporte doit être mot pour mot ce qu'on a lu — et un trou doit se
/// voir comme un trou sur les deux supports. D'où les segments : le découpage
/// dit ce que chaque morceau est, et chaque rendu choisit seulement comment le
/// peindre.
enum TemplateFilling {
    struct Segment: Equatable {
        enum Kind: Equatable {
            /// Le texte du gabarit, tel qu'écrit.
            case literal
            /// Un blanc rempli par la personne : se lit comme le reste, en gras.
            case filled
            /// Un blanc encore vide : son libellé, marqué comme un trou — c'est
            /// à la personne de le compléter, à l'oral s'il le faut.
            case empty
        }

        let text: String
        let kind: Kind
    }

    static func segments(_ template: String, filled: [String: String]) -> [Segment] {
        var output: [Segment] = []
        var remainder = Substring(template)

        func literal(_ text: Substring) {
            if !text.isEmpty { output.append(Segment(text: String(text), kind: .literal)) }
        }

        while let open = remainder.firstIndex(of: "<"),
              let close = remainder[open...].firstIndex(of: ">") {
            literal(remainder[..<open])
            let name = String(remainder[remainder.index(after: open)..<close])
            if let value = filled[name], !value.isEmpty {
                output.append(Segment(text: value, kind: .filled))
            } else {
                output.append(Segment(text: SlotVocabulary.label(for: name), kind: .empty))
            }
            remainder = remainder[remainder.index(after: close)...]
        }

        literal(remainder)
        return output
    }

    static func plainText(_ template: String, filled: [String: String]) -> String {
        segments(template, filled: filled).map(\.text).joined()
    }
}
