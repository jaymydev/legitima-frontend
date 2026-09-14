import Foundation

/// Ce que chaque bloc d'une carte est, dit une fois.
///
/// Un testeur extérieur n'a compris ni les conseils ni les avertissements à
/// l'écran, alors qu'il les trouvait clairs dans le PDF. Nommer les blocs a
/// réglé la moitié du problème : on sait maintenant *que* ce sont trois choses
/// différentes. Il restait à dire *lesquelles*.
///
/// L'explication vit ici, pas dans la vue, et elle se construit depuis
/// `Tone.bankCard` : elle ne peut donc pas expliquer un bloc que la carte ne
/// montre pas, ni en oublier un que la carte ajoute.
struct BlockGuide: Equatable {
    struct Entry: Equatable {
        let tone: PreparationExportContent.Tone
        /// Une phrase. Quelqu'un qui ouvre l'app pour préparer un entretien ne
        /// lit pas un mode d'emploi.
        let explanation: String

        var label: String { tone.label ?? "" }
        var symbol: String { tone.symbol ?? "" }
    }

    static let title = "Trois choses par question"
    static let subtitle =
        "Chaque question tient en trois blocs. Ils ne se lisent pas de la même façon."

    static let entries: [Entry] = PreparationExportContent.Tone.bankCard.map { tone in
        Entry(tone: tone, explanation: explanation(for: tone))
    }

    private static func explanation(for tone: PreparationExportContent.Tone) -> String {
        switch tone {
        case .say:
            return "La phrase à prononcer, telle quelle. Les mots soulignés sont des blancs : remplissez-les une fois, ils se reportent sur toutes les questions."
        case .guidance:
            return "Ce n'est pas une phrase à dire mais une façon de répondre : la matière est à vous."
        case .followUp:
            return "Ce qu'on vous répondra si la question revient — et quoi dire à ce moment-là."
        case .avoid:
            return "Le réflexe qui coûte cher sur cette question précise. Se lit avant l'entretien, jamais pendant."
        case .acquired, .plain:
            return ""
        }
    }
}
