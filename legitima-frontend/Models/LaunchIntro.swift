import Foundation

/// Ce que l'app dit d'elle-même avant que la personne n'ait rien fait.
///
/// Un testeur extérieur a ouvert l'app et s'est trouvé devant une liste de six
/// types d'entretien, sans savoir ce que Legitima était ni pourquoi le nom
/// disait ça. L'écran de lancement est le seul moment où le nom peut vouloir
/// dire quelque chose : ailleurs, il n'y a plus d'occasion.
///
/// La cadence vit ici, hors de la vue, pour deux raisons. Le harnais de test ne
/// compile pas les Views : une durée écrite dans un `@State` ne serait vérifiée
/// par rien. Et une phrase programmée après la fin de l'écran ne s'afficherait
/// jamais — c'est le genre de défaut qu'on ne voit pas en relisant, seulement
/// en comptant.
struct LaunchIntro: Equatable {
    /// Au premier lancement, la séquence complète. Ensuite, le nom et la
    /// promesse seulement : ce qui explique se lit une fois, ce qui identifie
    /// se revoit à chaque ouverture.
    enum Pace: Equatable {
        case first
        case returning
    }

    static let wordmark = "LEGITIMA"
    static let slogan = "Vous avez votre place dans cette pièce."

    /// Les trois phrases retirent chacune une inquiétude : ce n'est pas un
    /// examen, on vous demande ce que vous savez déjà, et les mots resteront
    /// les vôtres.
    static let lines = [
        "Un entretien n'est pas un examen.",
        "C'est une pièce où l'on vous demande de raconter ce que vous savez faire.",
        "Nous préparons les questions. Les réponses sont les vôtres.",
    ]

    /// Un fondu se lit s'il a le temps de finir. En deçà, il clignote.
    static let fade: Double = 0.55

    let pace: Pace

    init(hasLaunchedBefore: Bool) {
        pace = hasLaunchedBefore ? .returning : .first
    }

    /// Ce qui apparaît, et quand.
    ///
    /// Le nom d'abord, la promesse ensuite — puis, au premier lancement
    /// seulement, les trois phrases.
    var timeline: [(text: String, delay: Double)] {
        var items: [(String, Double)] = [
            (Self.wordmark, 0),
            (Self.slogan, 0.55),
        ]
        guard pace == .first else { return items }
        for (index, line) in Self.lines.enumerated() {
            items.append((line, 1.45 + Double(index) * 0.95))
        }
        return items
    }

    /// Quand l'écran s'efface de lui-même.
    ///
    /// Toujours après la dernière apparition, fondu compris : une phrase qu'on
    /// n'a pas le temps de lire ne sert à rien, et une phrase programmée après
    /// la fin ne s'affiche pas du tout.
    var duration: Double {
        let last = timeline.map(\.delay).max() ?? 0
        return last + Self.fade + (pace == .first ? 0.9 : 0.35)
    }
}
