import Foundation

/// Ce que l'app dit d'elle-même avant que la personne n'ait rien fait.
///
/// La forme vient d'une référence choisie : un logo posé au centre, un fond
/// calme, rien autour. Sous lui, les phrases se succèdent — chacune paraît,
/// tient le temps d'être lue, cède la place. La dernière est le slogan, et
/// celle-là reste : c'est elle qu'on emporte dans l'écran suivant.
///
/// La cadence vit ici, hors de la vue, pour deux raisons. Le harnais de test ne
/// compile pas les Views : une durée écrite dans un `@State` ne serait vérifiée
/// par rien. Et deux temps qui se chevauchent superposeraient deux phrases —
/// un défaut qu'on ne voit pas en relisant, seulement en comptant.
struct LaunchIntro: Equatable {
    /// Au premier lancement, la séquence complète. Ensuite, le logo et le
    /// slogan seulement : ce qui explique se lit une fois, ce qui identifie se
    /// revoit à chaque ouverture.
    enum Pace: Equatable {
        case first
        case returning
    }

    /// Le jeu d'images tiré de l'icône d'app. Un `AppIcon.appiconset` n'est pas
    /// chargeable à l'exécution — iOS le compile à part — d'où cette copie
    /// redimensionnée, qui pèse 232 Ko contre 1,3 Mo pour l'originale seule.
    static let markAsset = "LegitimaMark"
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
    static let fade: Double = 0.38
    /// Le temps de lecture minimal d'un temps, fondus compris. Une phrase qui
    /// paraît et disparaît plus vite ne se lit pas, elle se devine.
    static let minimumBeat: Double = 1.1

    /// L'arrivée du logo : il monte à sa taille en dépassant un peu, comme un
    /// objet qui se pose. C'est le seul endroit de l'app où le mouvement a le
    /// droit d'être démonstratif — ailleurs, il explique.
    static let entrance: Double = 0.66
    /// La sortie : le logo s'ouvre et se dissout, ce qui lit comme un passage
    /// *dans* l'app plutôt que comme un écran qu'on retire.
    static let exit: Double = 0.52
    /// Ce que le logo vaut au départ et à l'arrivée, en proportion.
    static let entranceScale: Double = 0.72
    static let exitScale: Double = 1.22

    /// Un temps de la séquence : un texte qui paraît, puis cède la place.
    /// `end` à `nil` veut dire qu'il reste jusqu'au bout.
    struct Beat: Equatable {
        let text: String
        let start: Double
        let end: Double?
    }

    let pace: Pace

    init(hasLaunchedBefore: Bool) {
        pace = hasLaunchedBefore ? .returning : .first
    }

    /// Le logo et le mot-symbole ne sont pas des temps : ils sont là d'un bout
    /// à l'autre, et c'est ce qui tient la composition pendant que le texte
    /// défile dessous.
    var beats: [Beat] {
        guard pace == .first else {
            return [Beat(text: Self.slogan, start: 0, end: nil)]
        }
        var items: [Beat] = []
        // Le premier temps attend que le logo ait fini d'arriver : deux
        // mouvements simultanés se gênent, et c'est le logo qu'on veut voir.
        var t = Self.entrance + 0.25
        // L'écart entre deux temps dépasse la durée du fondu. En deçà, la
        // phrase sortante est encore visible quand la suivante paraît : les
        // deux se superposent au même endroit et l'écran devient illisible.
        // Vu à la capture avant d'être écrit ici.
        let tenue = 1.25
        let ecart = Self.fade + 0.07
        for line in Self.lines {
            items.append(Beat(text: line, start: t, end: t + tenue))
            t += tenue + ecart
        }
        items.append(Beat(text: Self.slogan, start: t, end: nil))
        return items
    }

    /// Quand la sortie commence.
    ///
    /// Le dernier temps est le slogan, et il doit tenir au moins aussi
    /// longtemps que les autres : au retour, il est la seule chose à lire, et
    /// une version trop pressée l'affichait sans laisser le temps de le voir.
    var exitStart: Double {
        let dernier = beats.last?.start ?? 0
        return dernier + max(Self.minimumBeat, pace == .first ? 1.45 : 1.25)
    }

    /// Quand l'écran a fini de céder la place.
    var duration: Double { exitStart + Self.exit }
}
