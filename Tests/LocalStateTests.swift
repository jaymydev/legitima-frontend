import Foundation

@main
struct LocalStateTests {
    @MainActor
    static func main() throws {
        try testInterviewDatePersistence()
        testInterviewCountdown()
        testInterviewRemindersNeverFireLateOrIntoThePast()
        try testOrphanedStorageIsDeleted()
        try testCatalogContractStillDecodes()
        try testPersonalizationContractRoundTrip()
        try testCVMaterialSurvivesRelaunch()
        testPersonalizationPrefillOnlyRepeatsWhatWasTyped()
        testExportCarriesThePersonalizedAnswers()
        testComfortMarksLeaveTheReport()
        try testTheBankPlanReachesTheReportUntilABetterOneExists()
        print("Local state tests passed")
    }

    /// Le catalogue est ce que le formulaire de personnalisation affiche : ses
    /// questions, leur caractère obligatoire, et la version du questionnaire
    /// que la requête doit renvoyer. Porté depuis les tests d'avant le pivot —
    /// le contrat a survécu, lui.
    private static func testCatalogContractStillDecodes() throws {
        let data = Data(
            """
            {"use_cases": [
              {"id": "recruitment", "title": "Entretien de recrutement",
               "short_title": "Recrutement", "description": "Face au recruteur.",
               "questionnaire_version": "2.1",
               "questions": [
                 {"id": "job_offer", "title": "Collez l'offre", "helper": "Le texte.",
                  "required": true, "input_type": "long_text"},
                 {"id": "achievement", "title": "Une réalisation", "helper": "Facultatif.",
                  "required": false, "input_type": "long_text"}
               ]}
            ]}
            """.utf8
        )

        let catalog = try JSONDecoder().decode(InterviewUseCaseCatalog.self, from: data)
        let useCase = catalog.useCases.first
        precondition(useCase?.id == "recruitment")
        precondition(useCase?.questionnaireVersion == "2.1")
        precondition(useCase?.questions.first?.required == true)

        // C'est ce qui verrouille le bouton « Écrire mes réponses » : seule
        // l'absence d'une réponse obligatoire doit bloquer.
        precondition(useCase?.hasAllRequiredAnswers(["job_offer": "Annonce"]) == true)
        precondition(useCase?.hasAllRequiredAnswers(["job_offer": "  "]) == false)
        precondition(useCase?.hasAllRequiredAnswers(["achievement": "Sans l'annonce"]) == false)
    }

    /// Le contrat V3 de personnalisation : les clés partent en snake_case et la
    /// réponse se décode telle que le backend l'écrit. Une clé qui dérive ici se
    /// paie en 422 silencieux côté route.
    private static func testPersonalizationContractRoundTrip() throws {
        let request = PreparedInterviewRequest(
            useCaseID: "recruitment",
            questionnaireVersion: "2.1",
            answers: [InterviewAnswer(questionID: "job_offer", answer: "Annonce")],
            experiences: [CVExperienceRow(title: "Dev", company: "Legitima", period: "2024")],
            cvText: "texte brut"
        )
        let encoded = String(decoding: try JSONEncoder().encode(request), as: UTF8.self)
        for key in ["use_case_id", "questionnaire_version", "question_id", "cv_text",
                    "\"title\"", "\"company\"", "\"period\""] {
            precondition(encoded.contains(key), "clé manquante dans la requête : \(key)")
        }

        let responseJSON = Data(
            """
            {"use_case_id":"recruitment","title":"Votre entretien",
             "questions":[{"question":"Pourquoi nous ?","intent":"Votre motivation",
                           "answer":"Je vise ce poste.","kind":"sentence"},
                          {"question":"Vos outils ?","intent":"Le concret",
                           "answer":"Citez un outil que vous utilisez.","kind":"guidance"}],
             "action_plan":["Relire l'annonce"]}
            """.utf8
        )
        let prepared = try JSONDecoder().decode(PreparedInterview.self, from: responseJSON)
        precondition(prepared.questions.count == 2)
        precondition(prepared.questions[0].isSentence)
        precondition(!prepared.questions[1].isSentence,
                     "une consigne prise pour une phrase ferait réciter un devoir")
        precondition(prepared.actionPlan == ["Relire l'annonce"])
    }

    /// La matière du CV se garde d'une ouverture à l'autre : la personnalisation
    /// peut être demandée un autre jour que l'import.
    private static func testCVMaterialSurvivesRelaunch() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ProtectedJSONStore<CVMaterial>(
            fileURL: directory.appendingPathComponent("cv-material.json")
        )

        precondition(CVMaterial().isEmpty)
        let material = CVMaterial(
            rawText: "Développeur — Legitima\n- refonte du site, équipe de 8",
            experiences: [CVExperienceRow(title: "Développeur", company: "Legitima", period: "2024")]
        )
        store.save(material)
        precondition(store.load() == material)
    }

    private static func testPersonalizationPrefillOnlyRepeatsWhatWasTyped() {
        let slots = [
            "RÉALISATION": "la refonte du site",
            "RÉSULTAT": "livré dans les délais",
            "MISSION_DE_L_OFFRE": "piloter le planning",
        ]

        let draft = PersonalizationPrefill.draft(questionID: "achievement", slots: slots)
        precondition(draft == "la refonte du site. livré dans les délais")
        // La mission vient de l'annonce, pas de la personne : la préremplir dans
        // « racontez une réalisation » lui ferait affirmer ce qu'elle n'a pas dit.
        precondition(!draft.contains("piloter le planning"))

        // Un identifiant hors des questions ouvertes ne se préremplit jamais.
        precondition(PersonalizationPrefill.draft(questionID: "job_offer", slots: slots).isEmpty)
        precondition(PersonalizationPrefill.draft(questionID: "achievement", slots: [:]).isEmpty)
    }

    private static func testExportCarriesThePersonalizedAnswers() {
        let page = BankPage(
            useCaseID: "recruitment",
            questions: [BankQuestion(id: "q1", question: "Parlez-moi de vous", answer: "Je suis <MÉTIER>.")]
        )
        let personalized = PreparedInterview(
            useCaseID: "recruitment",
            title: "Votre entretien",
            questions: [
                PreparedQuestion(question: "Pourquoi nous ?", intent: "", answer: "Je vise ce poste.", kind: "sentence"),
                PreparedQuestion(question: "Vos outils ?", intent: "", answer: "Citez un outil.", kind: "guidance"),
            ],
            actionPlan: ["Relire l'annonce", "Préparer une question"]
        )

        let content = PreparationExportContent(
            page: page,
            filled: ["MÉTIER": "développeur"],
            personalized: personalized
        )

        // La numérotation continue celle de la banque : un seul document.
        precondition(content.blocks.count == 4)
        precondition(content.blocks[0].paragraphs[0].text == "Je suis développeur.")
        // Le code couleur du rapport est une donnée du contenu : bleu ce qui
        // se dit, jamais une consigne peinte en phrase.
        precondition(content.blocks[0].paragraphs[0].tone == .say)
        precondition(content.blocks[1].title == "2. Pourquoi nous ?")
        precondition(content.blocks[1].paragraphs == [.init("Je vise ce poste.", tone: .say)])
        // Une consigne est marquée comme telle : imprimée nue, elle se lirait
        // comme une phrase à dire.
        precondition(content.blocks[2].paragraphs[0].tone == .guidance)
        precondition(content.blocks[3].title == "Avant d'entrer")
        precondition(content.blocks[3].numbered)

        // Sans personnalisation, le document est celui d'avant.
        precondition(PreparationExportContent(page: page, filled: [:]).blocks.count == 1)
    }

    /// Le filtre de confort : ce sur quoi la personne se sait à l'aise sort du
    /// rapport final — c'est lui qu'on relit en cinq minutes dans le couloir.
    private static func testComfortMarksLeaveTheReport() {
        let page = BankPage(
            useCaseID: "recruitment",
            questions: [
                BankQuestion(id: "q1", question: "Parlez-moi de vous", answer: "Je suis <MÉTIER>."),
                BankQuestion(id: "q2", question: "Vos prétentions ?", answer: "Entre <PRÉTENTION_BASSE> et <PRÉTENTION_HAUTE>."),
            ]
        )
        let personalized = PreparedInterview(
            useCaseID: "recruitment",
            title: "Votre entretien",
            questions: [
                PreparedQuestion(question: "Pourquoi nous ?", intent: "", answer: "Je vise ce poste.", kind: "sentence"),
                PreparedQuestion(question: "Vos outils ?", intent: "", answer: "Citez un outil.", kind: "guidance"),
            ],
            actionPlan: ["Relire l'annonce"]
        )

        // La banque se filtre par identifiant, le personnalisé par son texte —
        // il n'a pas d'identifiant, et « Refaire » le remplace.
        let content = PreparationExportContent(
            page: page,
            filled: [:],
            personalized: personalized,
            comfortable: ["q1", "Pourquoi nous ?"]
        )

        precondition(content.blocks.count == 4)
        // La numérotation se resserre : un document qui saute du 2 au 5 se lit
        // comme un document auquel il manque des pages.
        precondition(content.blocks[0].title == "1. Vos prétentions ?")
        precondition(content.blocks[1].title == "2. Vos outils ?")
        // Le vert du code couleur : ce qui est marqué à l'aise est cité — pas
        // traité — dans un bloc « Déjà acquis ».
        precondition(content.blocks[2].title == "Déjà acquis")
        precondition(content.blocks[2].titleTone == .acquired)
        precondition(content.blocks[2].paragraphs == [
            .init("Parlez-moi de vous", tone: .acquired),
            .init("Pourquoi nous ?", tone: .acquired),
        ])
        // Le plan d'action reste : être à l'aise sur une question ne dispense
        // pas des gestes d'avant d'entrer.
        precondition(content.blocks[3].title == "Avant d'entrer")

        // Une marque qui ne correspond plus à rien — question remplacée par
        // « Refaire », page de banque différente — ne retire rien, et ne
        // s'invente pas non plus un acquis.
        let stale = PreparationExportContent(
            page: page,
            filled: [:],
            personalized: personalized,
            comfortable: ["q99", "Une question disparue ?"]
        )
        precondition(stale.blocks.count == 5)
        precondition(!stale.blocks.contains { $0.title == "Déjà acquis" })

        // Tout marquer vide le rapport des questions ; c'est le choix de la
        // personne, pas une erreur à rattraper dans son dos.
        let all = PreparationExportContent(
            page: page,
            filled: [:],
            personalized: personalized,
            comfortable: ["q1", "q2", "Pourquoi nous ?", "Vos outils ?"]
        )
        precondition(all.blocks.map(\.title) == ["Déjà acquis", "Avant d'entrer"])

        // Le rouge et la relance : le point sensible porte son ton, et la
        // relance part remplie — brute, elle imprimait « <PRÉTENTION_BASSE> »
        // dans un document relu sans l'app sous la main.
        let salary = BankPage(
            useCaseID: "recruitment",
            questions: [BankQuestion(
                id: "q3",
                question: "Vos prétentions ?",
                answer: "Entre <PRÉTENTION_BASSE> et <PRÉTENTION_HAUTE>.",
                followUp: "Et si on vous propose <PRÉTENTION_BASSE> ?",
                avoid: "ne donnez jamais votre plancher."
            )]
        )
        let colored = PreparationExportContent(page: salary, filled: ["PRÉTENTION_BASSE": "42 000 €"])
        precondition(colored.blocks[0].paragraphs[1].text == "Et si on vous propose 42 000 € ?")
        precondition(colored.blocks[0].paragraphs[1].tone == .followUp)
        precondition(colored.blocks[0].paragraphs[2] == .init("Ne donnez jamais votre plancher.", tone: .avoid))

        // Un trou reste un trou jusque dans le document : le blanc rempli est
        // marqué rempli, le blanc vide est marqué vide — c'est ce qui permet
        // au PDF de le peindre comme quelque chose à compléter à l'oral, et
        // non comme du texte à dire tel quel.
        precondition(colored.blocks[0].paragraphs[0].segments == [
            .init(text: "Entre ", kind: .literal),
            .init(text: "42 000 €", kind: .filled),
            .init(text: " et ", kind: .literal),
            .init(text: "le haut de votre fourchette", kind: .empty),
            .init(text: ".", kind: .literal),
        ])
    }

    /// « J'ai 5 minutes pour réviser » : le chemin banque a son « Avant
    /// d'entrer », et le plan personnalisé — plus spécifique — le remplace.
    /// Jamais les deux : six gestes ne sont plus un plan, c'est une révision.
    private static func testTheBankPlanReachesTheReportUntilABetterOneExists() throws {
        // Le champ vient d'un backend qui peut ne pas encore le servir : une
        // page sans plan vaut mieux que pas de page.
        let legacy = try JSONDecoder().decode(
            BankPage.self,
            from: Data(#"{"use_case_id":"recruitment","questions":[]}"#.utf8)
        )
        precondition(legacy.actionPlan.isEmpty)

        let served = try JSONDecoder().decode(
            BankPage.self,
            from: Data("""
            {"use_case_id":"recruitment","questions":[],
             "action_plan":["Relisez l'annonce.","Gardez une question à poser."]}
            """.utf8)
        )
        precondition(served.actionPlan.count == 2)

        let page = BankPage(
            useCaseID: "recruitment",
            questions: [BankQuestion(id: "q1", question: "Parlez-moi de vous", answer: "Je suis <MÉTIER>.")],
            actionPlan: ["Relisez l'annonce.", "Gardez une question à poser."]
        )

        // Banque seule : son plan part dans le document.
        let bankOnly = PreparationExportContent(page: page, filled: [:])
        precondition(bankOnly.blocks.map(\.title) == ["1. Parlez-moi de vous", "Avant d'entrer"])
        precondition(bankOnly.blocks[1].paragraphs.map(\.text) == page.actionPlan)
        precondition(bankOnly.blocks[1].numbered)

        // Une personnalisation existe : son plan prend la place, seul.
        let personalized = PreparedInterview(
            useCaseID: "recruitment",
            title: "Votre entretien",
            questions: [PreparedQuestion(question: "Pourquoi nous ?", intent: "", answer: "Citez l'annonce.", kind: "guidance")],
            actionPlan: ["Relire votre réalisation."]
        )
        let both = PreparationExportContent(page: page, filled: [:], personalized: personalized)
        let plans = both.blocks.filter { $0.title == "Avant d'entrer" }
        precondition(plans.count == 1)
        precondition(plans[0].paragraphs.map(\.text) == ["Relire votre réalisation."])
    }

    /// The orphaned file held a copy of the analysis — the user's career
    /// history. Dropping the writing code without deleting it would have left
    /// personal data on every device that ran the old build.
    private static func testOrphanedStorageIsDeleted() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let kept = directory.appendingPathComponent("preparation.json")
        try Data("{}".utf8).write(to: kept)

        for name in OrphanedStorage.fileNames {
            try Data("{}".utf8).write(to: directory.appendingPathComponent(name))
        }

        OrphanedStorage.removeAll(in: directory)

        for name in OrphanedStorage.fileNames {
            precondition(
                !FileManager.default.fileExists(atPath: directory.appendingPathComponent(name).path),
                "\(name) doit être supprimé : il contient des données de carrière"
            )
        }
        precondition(
            FileManager.default.fileExists(atPath: kept.path),
            "le nettoyage ne doit toucher que les fichiers orphelins"
        )

        // Running on a device that never had the old build must not throw.
        OrphanedStorage.removeAll(in: directory)
    }

    private static func testInterviewRemindersNeverFireLateOrIntoThePast() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!

        func day(_ d: Int, hour: Int = 12) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 9, day: d, hour: hour))!
        }

        // Interview on the 20th, seen from the 1st: both reminders scheduled.
        let full = InterviewReminderPlan.reminders(
            interviewDate: day(20), now: day(1), calendar: calendar
        )
        precondition(full.count == 2)
        precondition(full.allSatisfy { calendar.component(.hour, from: $0.fireDate) == 9 },
                     "un rappel à l'heure de saisie réveillerait quelqu'un en pleine nuit")
        precondition(calendar.component(.day, from: full[0].fireDate) == 17)
        precondition(calendar.component(.day, from: full[1].fireDate) == 19)
        precondition(full[1].title.contains("demain"))
        precondition(full[1].body.contains("synthèse"), "la veille, l'artefact est la synthèse")

        // Two days out: the J-3 window has passed, only the eve remains.
        let late = InterviewReminderPlan.reminders(
            interviewDate: day(20), now: day(18), calendar: calendar
        )
        precondition(late.count == 1)
        precondition(late[0].title.contains("demain"))

        // Interview today, or already past: reminding someone about an
        // interview they have had is worse than saying nothing.
        precondition(InterviewReminderPlan.reminders(
            interviewDate: day(20), now: day(20), calendar: calendar).isEmpty)
        precondition(InterviewReminderPlan.reminders(
            interviewDate: day(20), now: day(25), calendar: calendar).isEmpty)

        // Date cleared: nothing to schedule.
        precondition(InterviewReminderPlan.reminders(
            interviewDate: nil, now: day(1), calendar: calendar).isEmpty)

        // Every identifier the plan can produce must be cancellable, or moving
        // the interview earlier leaves a reminder pointing at a dead day.
        let ids = Set(InterviewReminderPlan.allIdentifiers)
        precondition(full.allSatisfy { ids.contains($0.id) })
        precondition(ids.count == 2)
    }

    @MainActor
    private static func testInterviewDatePersistence() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = ProtectedJSONStore<PreparationSnapshot>(
            fileURL: directory.appendingPathComponent("preparation.json")
        )
        let store = LocalPreparationStore(storage: storage)

        precondition(store.snapshot.interviewDate == nil)

        let interviewDate = Calendar.current.date(byAdding: .day, value: 5, to: .now)!
        store.updateInterviewDate(interviewDate)

        let restored = LocalPreparationStore(storage: storage)
        precondition(restored.snapshot.interviewDate != nil)

        restored.updateInterviewDate(nil)
        precondition(LocalPreparationStore(storage: storage).snapshot.interviewDate == nil)

        // The declared interview intent persists and can be cleared.
        precondition(store.snapshot.intendedUseCaseID == nil)
        store.updateIntendedUseCase("annual_review")
        precondition(
            LocalPreparationStore(storage: storage).snapshot.intendedUseCaseID == "annual_review"
        )
        store.updateIntendedUseCase(nil)
        precondition(LocalPreparationStore(storage: storage).snapshot.intendedUseCaseID == nil)

        // Un état écrit par une version antérieure doit encore se décoder.
        // Le pivot a retiré le parcours, le point sensible, l'analyse et le
        // kickoff : ces clés traînent sur les appareils qui ont vu l'ancienne
        // app, et les ignorer vaut mieux que perdre la date d'entretien qui,
        // elle, survit.
        let legacyJSON = Data(
            """
            {"targetRole":"Rôle","careerSummary":"Résumé","sensitivePoint":"",
             "analysis":null,"debrief":null,"kickoff":null,"updatedAt":0}
            """.utf8
        )
        let legacy = try JSONDecoder().decode(PreparationSnapshot.self, from: legacyJSON)
        precondition(legacy.interviewDate == nil)
        precondition(legacy.intendedUseCaseID == nil)
        // Les champs arrivés après coup se décodent absents sans rien casser.
        precondition(legacy.metierID == nil)
        precondition(!legacy.encadrement)

        // Le métier et l'encadrement se gardent d'une fois sur l'autre : son
        // métier ne change pas entre deux préparations.
        store.updateMetier("cybersecurite")
        store.updateEncadrement(true)
        let withMetier = LocalPreparationStore(storage: storage)
        precondition(withMetier.snapshot.metierID == "cybersecurite")
        precondition(withMetier.snapshot.encadrement)
        store.updateMetier(nil)
        precondition(LocalPreparationStore(storage: storage).snapshot.metierID == nil)

        // Le catalogue des métiers d'un backend antérieur — sans libellés —
        // se décode en liste vide plutôt qu'en erreur.
        let emptyCatalog = try JSONDecoder().decode(
            MetierCatalog.self,
            from: Data(#"{"metiers":["commerce"]}"#.utf8)
        )
        precondition(emptyCatalog.catalog.isEmpty)
        // Sans `applies_to` non plus : un backend antérieur ne dit pas où le
        // métier s'applique, et l'écran n'en propose alors aucun plutôt que
        // d'en promettre l'effet à tort.
        precondition(emptyCatalog.appliesTo.isEmpty)
        let catalog = try JSONDecoder().decode(
            MetierCatalog.self,
            from: Data(
                #"{"metiers":["data"],"catalog":[{"id":"data","label":"Data"}],"applies_to":["recruitment","role_evolution"]}"#.utf8
            )
        )
        precondition(catalog.catalog == [MetierChoice(id: "data", label: "Data")])
        precondition(catalog.appliesTo == ["recruitment", "role_evolution"])

        // Le catalogue dit désormais où un CV sert. Absent d'un backend
        // antérieur, il vaut faux : on ne propose pas la pièce jointe, donc on
        // ne transmet rien — le choix qui ne peut pas nuire.
        let sansChamp = try JSONDecoder().decode(
            InterviewUseCase.self,
            from: Data(#"{"id":"annual_review","title":"T","short_title":"S","description":"D","questionnaire_version":"2.1","questions":[]}"#.utf8)
        )
        precondition(sansChamp.acceptsCV == false)
        let avecChamp = try JSONDecoder().decode(
            InterviewUseCase.self,
            from: Data(#"{"id":"recruitment","title":"T","short_title":"S","description":"D","questionnaire_version":"2.1","questions":[],"accepts_cv":true}"#.utf8)
        )
        precondition(avecChamp.acceptsCV == true)

        try? FileManager.default.removeItem(at: directory)
    }

    private static func testInterviewCountdown() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        precondition(InterviewCountdown.daysUntil(now, from: now) == 0)
        precondition(
            InterviewCountdown.daysUntil(calendar.date(byAdding: .day, value: 1, to: today)!, from: now) == 1
        )
        precondition(
            InterviewCountdown.daysUntil(calendar.date(byAdding: .day, value: 12, to: today)!, from: now) == 12
        )
        precondition(
            InterviewCountdown.daysUntil(calendar.date(byAdding: .day, value: -1, to: today)!, from: now) == nil
        )

        precondition(InterviewCountdown.label(daysUntil: 0) == "Votre entretien a lieu aujourd'hui")
        precondition(InterviewCountdown.label(daysUntil: 1) == "Votre entretien a lieu demain")
        precondition(InterviewCountdown.label(daysUntil: 5) == "Votre entretien a lieu dans 5 jours")
    }
}
