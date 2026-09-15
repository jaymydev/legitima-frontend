import Foundation

/// Ce que l'app dit d'elle-même avant que la personne n'ait rien fait.
///
/// La forme vient d'une référence choisie : un logo posé au centre, un fond
/// calme, rien autour. Sous lui, les phrases se succèdent — chacune paraît,
/// tient le temps d'être lue, cède la place. La dernière est le slogan, et
/// celle-là reste : c'est elle qu'on emporte dans l'écran suivant.
///
/// **La séquence joue en entier à chaque ouverture.** Une version précédente
/// l'abrégeait dès le deuxième lancement, au motif qu'une explication se lit
/// une fois. Décision inversée le 15 septembre 2026 : c'est le seul endroit où
/// l'app se présente, et l'abréger revenait à ne la montrer qu'une fois dans
/// la vie de l'installation.
///
/// Le prix est réel — huit secondes à chaque ouverture, pour quelqu'un qui
/// prépare un entretien et ouvre parfois l'app dans un couloir. Il est payé par
/// le tap : l'écran entier abrège, et le dit au bout de trois secondes.
///
/// La cadence vit ici, hors de la vue, pour deux raisons. Le harnais de test ne
/// compile pas les Views : une durée écrite dans un `@State` ne serait vérifiée
/// par rien. Et deux temps qui se chevauchent superposeraient deux phrases —
/// un défaut qu'on ne voit pas en relisant, seulement en comptant.
struct LaunchIntro: Equatable {
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

    /// Au bout de combien de temps l'écran dit qu'on peut l'abréger. Assez tard
    /// pour ne pas proposer la sortie avant d'avoir rien montré, assez tôt pour
    /// que la deuxième ouverture n'oblige à rien.
    static let skipHint: Double = 3.0

    init() {}

    /// Le logo et le mot-symbole ne sont pas des temps : ils sont là d'un bout
    /// à l'autre, et c'est ce qui tient la composition pendant que le texte
    /// défile dessous.
    var beats: [Beat] {
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
        return dernier + max(Self.minimumBeat, 1.45)
    }

    /// Quand l'écran a fini de céder la place.
    var duration: Double { exitStart + Self.exit }
}
