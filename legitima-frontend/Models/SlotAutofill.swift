import Foundation

/// Remplir des blancs à partir de ce que la personne a déjà donné.
///
/// Rien n'est deviné sur elle : on recopie ce qui est écrit dans son CV ou dans
/// l'annonce qu'elle a collée. Le seul calcul est arithmétique — compter des
/// années entre deux dates qu'elle a fournies — et le résultat reste modifiable.
enum SlotAutofill {

    /// Ce qu'un CV lu par /cv/parse permet de remplir sans rien demander.
    ///
    /// Les lignes arrivent de la plus récente à la plus ancienne, ce qui est
    /// l'ordre dans lequel le parseur les trie.
    static func values(from experiences: [CVExperienceRow], now: Date = .now) -> [String: String] {
        var values: [String: String] = [:]
        guard let current = experiences.first else { return values }

        assign(&values, "POSTE_ACTUEL", current.title)
        assign(&values, "ENTREPRISE_ACTUELLE", current.company)

        if experiences.count > 1 {
            assign(&values, "POSTE_PRÉCÉDENT", experiences[1].title)
            assign(&values, "ENTREPRISE_PRÉCÉDENTE", experiences[1].company)
        }

        let currentYear = Calendar.current.component(.year, from: now)
        if let start = firstYear(in: current.period), currentYear >= start {
            assign(&values, "ANCIENNETÉ", yearsLabel(currentYear - start))
        }
        // La plus ancienne période donne le début de carrière. C'est un calcul,
        // pas une supposition : les deux bornes viennent du CV.
        let earliest = experiences.compactMap { firstYear(in: $0.period) }.min()
        if let earliest, currentYear >= earliest {
            assign(&values, "NOMBRE_ANNÉES_EXPÉRIENCE", yearsLabel(currentYear - earliest))
        }
        return values
    }

    /// Les missions candidates d'une annonce collée.
    ///
    /// Découpées à la main plutôt qu'envoyées à un modèle : une annonce est
    /// presque toujours à puces, l'extraction est fiable, et surtout la personne
    /// choisit — donc rien ne peut être inventé sur ce qu'elle sait faire.
    static func missions(in offer: String) -> [String] {
        var lines: [String] = []
        for raw in offer.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            // Tout ce qui suit « profil recherché » décrit le candidat, pas le
            // poste. Y puiser ferait dire « ce qui m'a arrêté, c'est 5 ans
            // minimum d'expérience » — et surtout, ce serait présenter une
            // exigence comme un fait sur la personne.
            if isCandidateSection(line) { break }
            lines.append(stripBullet(line))
        }

        let usable = lines.filter { line in
            // Assez longue pour dire quelque chose, assez courte pour tenir dans
            // une réponse, et jamais l'intitulé de l'annonce.
            line.count >= 20 && line.count <= 120 && !line.hasSuffix(":") && !isJobTitle(line)
        }

        // Une mission française s'écrit à l'infinitif : « Cadrer », « Piloter ».
        // Quand l'annonce respecte cette forme, on ne garde que celles-là.
        let infinitives = usable.filter(startsWithInfinitive)
        let chosen = infinitives.isEmpty ? usable : infinitives

        var seen = Set<String>()
        return chosen.filter { seen.insert($0.lowercased()).inserted }.prefix(6).map { $0 }
    }

    private static func stripBullet(_ line: String) -> String {
        var text = line
        while let first = text.first, "-–—•*·▪".contains(first) {
            text = String(text.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return text
    }

    private static func isCandidateSection(_ line: String) -> Bool {
        // Sans accents des deux côtés : beaucoup d'annonces sont saisies dans des
        // outils qui les perdent, et « Profil recherche » doit couper autant que
        // « Profil recherché ». Vu à l'essai : sans ça, « 5 ans minimum
        // d'expérience » remontait parmi les missions.
        let lowered = folded(line)
        return ["profil recherche", "votre profil", "profil :", "competences requises",
                "ce que nous recherchons", "qualifications", "prerequis", "profil souhaite"]
            .contains { lowered.contains($0) }
    }

    private static func folded(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
    }

    private static func isJobTitle(_ line: String) -> Bool {
        let lowered = line.lowercased()
        return ["(h/f)", "(f/h)", " cdi", " cdd", "alternance", "stage "].contains { lowered.contains($0) }
    }

    private static func startsWithInfinitive(_ line: String) -> Bool {
        guard let word = line.split(separator: " ").first?.lowercased() else { return false }
        guard word.count >= 5 else { return false }
        return word.hasSuffix("er") || word.hasSuffix("ir") || word.hasSuffix("re")
    }

    private static func assign(_ values: inout [String: String], _ slot: String, _ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        values[slot] = trimmed
    }

    private static func firstYear(in period: String) -> Int? {
        guard let match = period.range(of: #"(19|20)\d{2}"#, options: .regularExpression) else {
            return nil
        }
        return Int(period[match])
    }

    private static func yearsLabel(_ years: Int) -> String {
        years <= 1 ? "1 an" : "\(years) ans"
    }
}

extension SlotVocabulary {
    /// Les blancs qu'un CV importé peut remplir.
    static let filledByCV: Set<String> = [
        "POSTE_ACTUEL", "ENTREPRISE_ACTUELLE", "POSTE_PRÉCÉDENT",
        "ENTREPRISE_PRÉCÉDENTE", "ANCIENNETÉ", "NOMBRE_ANNÉES_EXPÉRIENCE",
    ]

    /// Le blanc qu'une annonce collée peut remplir.
    static let filledByOffer = "MISSION_DE_L_OFFRE"
}
