import Foundation

@main
struct InterviewPreparationStateTests {
    @MainActor
    static func main() throws {
        try testBackendCatalogDecoding()
        try testProtectedDraftAndResultRestoration()
        testRequiredQuestionValidation()
        testShortAnswersRemainValidButAreFlagged()
        testFreemiumEntryStillUsesLeanOnboarding()
        try testRecruitmentRequestReusesFreemiumContext()
        testPremiumEntryRespectsSavedUseCase()
        testExportContentAssembly()
        try testKickoffContractRoundTrip()
        testDebriefFeedsTheNextPreparation()
        testKickoffSurvivesAndLeadsTheExport()
        testKickoffDistinguishesMissingEndpointFromFailure()
        try testSameUseCaseCanBePreparedAgain()
        try testQuestionnaireStepIsRestoredWhereTheWorkIs()
        print("Interview preparation state tests passed")
    }

    private static func testShortAnswersRemainValidButAreFlagged() {
        let answers = ["role_context": "A"]

        precondition(sampleUseCase.hasAllRequiredAnswers(answers))
        // An untouched field says nothing — no nudge before they have typed.
        precondition(!InterviewAnswerQuality.deservesMoreMaterial(""))
        precondition(!InterviewAnswerQuality.deservesMoreMaterial("   \n "))

        // The fragments the old 4-character guard let through.
        precondition(InterviewAnswerQuality.deservesMoreMaterial("oui bof"))
        precondition(InterviewAnswerQuality.deservesMoreMaterial("Gestion de projet"))
        precondition(
            InterviewAnswerQuality.deservesMoreMaterial(
                "Pilotage de projets et coordination produit"
            )
        )

        // A real answer carrying a specific detail must stay quiet, otherwise
        // the nudge becomes noise and stops being read.
        precondition(
            !InterviewAnswerQuality.deservesMoreMaterial(
                "J'ai piloté la refonte du parcours d'inscription, réduisant l'abandon de 30%"
            )
        )

        // Questions offering options expect a couple of words.
        precondition(
            !InterviewAnswerQuality.deservesMoreMaterial("Entretien RH", expectsShortAnswer: true)
        )
        precondition(InterviewAnswerQuality.deservesMoreMaterial("Entretien RH"))
    }

    private static func testBackendCatalogDecoding() throws {
        let data = """
        {
          "use_cases": [
            {
              "id": "mid_year",
              "title": "Entretien de mi-année",
              "short_title": "Mi-année",
              "description": "Faire le point.",
              "questionnaire_version": "1.0",
              "questions": [
                {
                  "id": "role_context",
                  "title": "Quel est votre rôle ?",
                  "helper": "Résumez votre périmètre.",
                  "required": true,
                  "input_type": "long_text",
                  "options": []
                }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        let catalog = try JSONDecoder().decode(InterviewUseCaseCatalog.self, from: data)
        precondition(catalog.useCases.first?.id == "mid_year")
        precondition(catalog.useCases.first?.questions.first?.required == true)
    }

    @MainActor
    private static func testProtectedDraftAndResultRestoration() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = ProtectedJSONStore<SavedInterviewPreparation>(
            fileURL: directory.appendingPathComponent("interview.json")
        )
        let useCase = sampleUseCase
        let store = InterviewPreparationStore(storage: storage)

        store.startNew(useCase: useCase)
        store.saveDraft(useCase: useCase, answers: ["role_context": "Responsable produit"])
        store.saveResult(sampleResult)

        let restored = InterviewPreparationStore(storage: storage)
        precondition(restored.saved.hasWork)
        precondition(restored.saved.useCase == useCase)
        precondition(restored.saved.answers["role_context"] == "Responsable produit")
        precondition(restored.saved.result == sampleResult)

        restored.clear()
        precondition(!InterviewPreparationStore(storage: storage).saved.hasWork)
        try? FileManager.default.removeItem(at: directory)
    }

    private static func testRequiredQuestionValidation() {
        precondition(!sampleUseCase.hasAllRequiredAnswers([:]))
        precondition(!sampleUseCase.hasAllRequiredAnswers(["optional": "Texte facultatif"]))
        precondition(
            sampleUseCase.hasAllRequiredAnswers(["role_context": "Responsable produit"])
        )
    }

    @MainActor
    private static func testFreemiumEntryStillUsesLeanOnboarding() {
        let router = AppRouter()

        router.enterTestMode(savedAnalysis: nil)
        guard case .onboarding = router.root else {
            preconditionFailure("Empty test sessions must open LeanOnboarding")
        }

        router.enterTestMode(savedAnalysis: sampleLeanAnalysis)
        guard case .result(let restored) = router.root else {
            preconditionFailure("Saved analyses must reopen their result")
        }
        precondition(restored == sampleLeanAnalysis)

        router.showPremiumInterviewEntry()
        precondition(
            router.path == [.premiumInterviewEntry],
            "Premium results must open the guided preparation directly"
        )
    }

    private static func testRecruitmentRequestReusesFreemiumContext() throws {
        let request = InterviewPreparationRequest(
            useCaseID: "recruitment",
            questionnaireVersion: "1.1",
            answers: [
                InterviewAnswer(questionID: "interview_stage", answer: "Entretien manager"),
                InterviewAnswer(questionID: "desired_takeaway", answer: "Ma légitimité"),
            ],
            context: InterviewPreparationContext(
                targetRole: "Responsable produit",
                careerExperiences: "Coordination de projets",
                sensitivePoint: "Transition",
                freemiumAnalysis: "Parcours cohérent"
            )
        )

        let encoded = try JSONEncoder().encode(request)
        let object = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        let context = object?["context"] as? [String: String]

        precondition(context?["target_role"] == "Responsable produit")
        precondition(context?["career_experiences"] == "Coordination de projets")
        precondition(object?["file"] == nil)
        precondition(object?["cv"] == nil)
    }

    private static func testExportContentAssembly() {
        let content = PreparationExportContent(response: sampleResult)

        precondition(content.title == "Préparation mi-année")
        precondition(content.blocks.count == 4)
        precondition(content.blocks[0].title == "Votre ligne directrice")
        precondition(content.blocks[0].paragraphs == ["Bilan factuel."])
        precondition(content.blocks[1].title == "Avancement")
        precondition(content.blocks[2].title == "Points à faire passer")
        precondition(content.blocks[2].numbered)
        precondition(content.blocks[3].title == "Plan d'action")

        // Empty and whitespace-only material must be dropped, not exported blank.
        let sparse = InterviewPreparationResponse(
            useCaseID: "recruitment",
            title: " Préparation ",
            summary: "  ",
            sections: [InterviewPreparationSection(title: "Vide", content: " \n ")],
            talkingPoints: ["  ", "Un seul point"],
            actionPlan: []
        )
        let sparseContent = PreparationExportContent(response: sparse)
        precondition(sparseContent.title == "Préparation")
        precondition(sparseContent.blocks.count == 1)
        precondition(sparseContent.blocks[0].title == "Points à faire passer")
        precondition(sparseContent.blocks[0].paragraphs == ["Un seul point"])
    }

    private static func testKickoffContractRoundTrip() throws {
        let response = try JSONDecoder().decode(
            PremiumKickoffResponse.self,
            from: Data("""
            {
              "objection": "Pourquoi quitter la gestion de projet après 8 ans ?",
              "defensible_answer": "Je ne quitte pas la gestion de projet, j'en élargis le périmètre."
            }
            """.utf8)
        )
        precondition(response.objection.hasPrefix("Pourquoi"))
        precondition(response.defensibleAnswer.hasPrefix("Je ne quitte pas"))

        // The kickoff reuses the lean context; without a saved analysis the
        // freemium summary must stay empty rather than crash or invent data.
        let snapshot = PreparationSnapshot(
            targetRole: "Product Manager",
            careerSummary: "8 ans de gestion de projet IT",
            sensitivePoint: "Reconversion tardive"
        )
        let context = InterviewPreparationContext.lean(from: snapshot)
        precondition(context.targetRole == "Product Manager")
        precondition(context.freemiumAnalysis.isEmpty)

        // The interview deadline travels to the backend inside the context
        // blob, and leads it so the generation can prioritise.
        let reference = Date(timeIntervalSince1970: 1_780_000_000)
        var dated = snapshot
        dated.interviewDate = reference.addingTimeInterval(6 * 24 * 3600)
        let datedContext = InterviewPreparationContext.lean(from: dated, now: reference)
        precondition(datedContext.freemiumAnalysis == "Échéance : l'entretien a lieu dans 6 jours.")

        dated.interviewDate = reference.addingTimeInterval(-3 * 24 * 3600)
        let pastContext = InterviewPreparationContext.lean(from: dated, now: reference)
        precondition(pastContext.freemiumAnalysis.isEmpty)

        precondition(InterviewCountdown.promptLine(daysUntil: 0).contains("aujourd'hui"))
        precondition(InterviewCountdown.promptLine(daysUntil: 1).contains("demain"))

        let body = try JSONEncoder().encode(PremiumKickoffRequest(context: context))
        let json = String(decoding: body, as: UTF8.self)
        precondition(json.contains("\"context\""))
        precondition(json.contains("\"target_role\""))
        precondition(json.contains("\"freemium_analysis\""))
    }

    private static func testDebriefFeedsTheNextPreparation() {
        let interviewDay = Date(timeIntervalSince1970: 1_780_000_000)

        // The interview day itself stays a countdown day: a single date must
        // never drive both the countdown and the debrief prompt.
        precondition(InterviewCountdown.daysSince(interviewDay, from: interviewDay) == nil)
        precondition(InterviewCountdown.daysUntil(interviewDay, from: interviewDay) == 0)

        let dayAfter = interviewDay.addingTimeInterval(24 * 3600)
        precondition(InterviewCountdown.daysSince(interviewDay, from: dayAfter) == 1)
        precondition(InterviewCountdown.pastLabel(daysSince: 1) == "Votre entretien a eu lieu hier")
        precondition(InterviewCountdown.pastLabel(daysSince: 3).contains("il y a 3 jours"))

        // An empty debrief must not be treated as recorded material.
        precondition(!InterviewDebrief().hasContent)
        precondition(!InterviewDebrief(difficultQuestions: "   ").hasContent)
        precondition(InterviewDebrief(whatWorked: "Le fil conducteur").hasContent)

        var snapshot = PreparationSnapshot(targetRole: "Product Manager")
        snapshot.debrief = InterviewDebrief(
            difficultQuestions: "  Pourquoi ce trou de 6 mois ?  ",
            whatWorked: "Le récit de la transition"
        )

        let context = InterviewPreparationContext.lean(from: snapshot, now: dayAfter)
        precondition(context.freemiumAnalysis.contains("Pourquoi ce trou de 6 mois ?"))
        precondition(!context.freemiumAnalysis.contains("  Pourquoi"))
        precondition(context.freemiumAnalysis.contains("Le récit de la transition"))
    }

    private static func testKickoffSurvivesAndLeadsTheExport() {
        let kickoff = PremiumKickoffResponse(
            objection: "Pourquoi quitter la gestion de projet ?",
            defensibleAnswer: "Je ne la quitte pas, j'en élargis le périmètre."
        )

        // It must round-trip through the snapshot: that is what makes it
        // survive leaving the kickoff screen and relaunching the app.
        var snapshot = PreparationSnapshot(targetRole: "Product Manager")
        snapshot.kickoff = kickoff
        let encoded = try! JSONEncoder().encode(snapshot)
        let decoded = try! JSONDecoder().decode(PreparationSnapshot.self, from: encoded)
        precondition(decoded.kickoff == kickoff)

        // And it leads the exported PDF, ahead of the guided synthesis.
        let content = PreparationExportContent(response: sampleResult, kickoff: kickoff)
        precondition(content.blocks.count == 5)
        precondition(content.blocks[0].title == "Votre première réponse défendable")
        precondition(content.blocks[0].paragraphs.count == 2)
        precondition(content.blocks[0].paragraphs[0].hasPrefix("« Pourquoi"))
        precondition(content.blocks[1].title == "Votre ligne directrice")

        // No kickoff, or a blank one, must not add an empty block.
        precondition(PreparationExportContent(response: sampleResult).blocks.count == 4)
        let blank = PremiumKickoffResponse(objection: "Une objection", defensibleAnswer: "   ")
        precondition(PreparationExportContent(response: sampleResult, kickoff: blank).blocks.count == 4)
    }

    private static func testKickoffDistinguishesMissingEndpointFromFailure() {
        func backendError(_ code: Int) -> Error {
            IAService.IAServiceError.requestFailed(
                NSError(domain: PremiumKickoffOutcome.backendErrorDomain, code: code)
            )
        }

        // Route absent: the planned degrade, the user need not be told.
        for code in [404, 405, 501] {
            precondition(PremiumKickoffOutcome.classify(backendError(code)) == .notDeployed)
        }

        // Route exists, something broke: they just paid, so say so.
        for code in [500, 502, 503, 422] {
            precondition(PremiumKickoffOutcome.classify(backendError(code)) == .failed)
        }

        // Network failures and timeouts are never a missing endpoint — a 404
        // from some other domain must not be mistaken for our backend's.
        precondition(
            PremiumKickoffOutcome.classify(
                IAService.IAServiceError.requestFailed(URLError(.timedOut))
            ) == .failed
        )
        precondition(
            PremiumKickoffOutcome.classify(URLError(.notConnectedToInternet)) == .failed
        )
        precondition(
            PremiumKickoffOutcome.classify(
                NSError(domain: NSURLErrorDomain, code: 404)
            ) == .failed
        )
    }

    @MainActor
    private static func testSameUseCaseCanBePreparedAgain() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storage = ProtectedJSONStore<SavedInterviewPreparation>(
            fileURL: directory.appendingPathComponent("interview.json")
        )
        let useCase = sampleUseCase
        let store = InterviewPreparationStore(storage: storage)

        // A first preparation, carried through to a result.
        store.startNew(useCase: useCase)
        store.saveDraft(useCase: useCase, answers: ["role_context": "Premier entretien"])
        store.saveResult(sampleResult)
        precondition(store.saved.result != nil)

        // The second interview of the same kind, at another company, is the
        // most likely next preparation — and used to be the one impossible to
        // run, because resetting only happened on a *different* use case.
        store.startNew(useCase: useCase)
        precondition(store.saved.useCase == useCase)
        precondition(store.saved.answers.isEmpty, "les réponses précédentes doivent être effacées")
        precondition(store.saved.result == nil, "l'ancien résultat ne doit plus court-circuiter le routage")
        precondition(!store.saved.hasWork)

        // The reset must survive a relaunch, otherwise the old result comes
        // back and the routing lands on it again.
        precondition(!InterviewPreparationStore(storage: storage).saved.hasWork)

        // And with the result cleared, the routing sends the user to the
        // questionnaire rather than back to the previous preparation.
        let destination = PremiumEntryRouting.destination(
            for: store.saved,
            intendedUseCaseID: nil,
            recruitmentUseCaseID: "recruitment"
        )
        guard case .questionnaire(let routed) = destination else {
            preconditionFailure("attendu : le questionnaire, pas l'ancien résultat")
        }
        precondition(routed == useCase)
    }

    @MainActor
    private static func testQuestionnaireStepIsRestoredWhereTheWorkIs() throws {
        // Everything up to step 2 answered: reopen exactly where they left off.
        precondition(
            QuestionnaireStepRestore.step(saved: 2, stepCount: 4, isComplete: { $0 < 2 }) == 2
        )

        // Saved index points past a gap — a partial file, or questions that
        // changed. Without clamping the user reaches the end and generation is
        // silently blocked, with nothing saying which step is incomplete.
        precondition(
            QuestionnaireStepRestore.step(saved: 3, stepCount: 4, isComplete: { $0 == 0 }) == 1
        )

        // Out-of-range values must never reach the title arrays, which have
        // four entries and would crash the screen on open.
        precondition(QuestionnaireStepRestore.step(saved: 99, stepCount: 4, isComplete: { _ in true }) == 3)
        precondition(QuestionnaireStepRestore.step(saved: -5, stepCount: 4, isComplete: { _ in true }) == 0)
        precondition(QuestionnaireStepRestore.step(saved: 2, stepCount: 0, isComplete: { _ in true }) == 0)

        // A fully answered questionnaire reopens on the last step, not past it.
        precondition(
            QuestionnaireStepRestore.step(saved: 3, stepCount: 4, isComplete: { _ in true }) == 3
        )

        // And the step round-trips through storage alongside the answers.
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storage = ProtectedJSONStore<SavedInterviewPreparation>(
            fileURL: directory.appendingPathComponent("interview.json")
        )
        let store = InterviewPreparationStore(storage: storage)
        store.startNew(useCase: sampleUseCase)
        store.saveDraft(useCase: sampleUseCase, answers: ["role_context": "Une réponse"])
        store.saveStep(2)
        precondition(InterviewPreparationStore(storage: storage).saved.step == 2)

        // Starting fresh resets the position along with the answers.
        store.startNew(useCase: sampleUseCase)
        precondition(store.saved.step == 0)
    }

    private static func testPremiumEntryRespectsSavedUseCase() {
        let recruitmentID = "recruitment"
        let recruitmentUseCase = InterviewUseCase(
            id: recruitmentID,
            title: "Entretien de recrutement",
            shortTitle: "Recrutement",
            description: "Préparer un récit clair.",
            questionnaireVersion: "1.0",
            questions: []
        )

        // Nothing saved, no intent: first purchase defaults to recruitment.
        guard case .startUseCase(let defaultID) = PremiumEntryRouting.destination(
            for: SavedInterviewPreparation(),
            intendedUseCaseID: nil,
            recruitmentUseCaseID: recruitmentID
        ), defaultID == recruitmentID else {
            preconditionFailure("Empty state should start recruitment")
        }

        // Nothing saved but an intent declared in onboarding: honor it.
        guard case .startUseCase(let intendedID) = PremiumEntryRouting.destination(
            for: SavedInterviewPreparation(),
            intendedUseCaseID: "annual_review",
            recruitmentUseCaseID: recruitmentID
        ), intendedID == "annual_review" else {
            preconditionFailure("Declared intent should steer the first entry")
        }

        // A saved non-recruitment choice is respected even with no answer yet,
        // and wins over a diverging intent.
        var midYearSelected = SavedInterviewPreparation(useCase: sampleUseCase)
        guard case .questionnaire(let useCase) = PremiumEntryRouting.destination(
            for: midYearSelected,
            intendedUseCaseID: "recruitment",
            recruitmentUseCaseID: recruitmentID
        ), useCase.id == "mid_year" else {
            preconditionFailure("Saved use case must not be overridden")
        }

        // Same with answers in progress.
        midYearSelected.answers = ["role_context": "Responsable produit"]
        guard case .questionnaire = PremiumEntryRouting.destination(
            for: midYearSelected,
            intendedUseCaseID: nil,
            recruitmentUseCaseID: recruitmentID
        ) else { preconditionFailure("In-progress questionnaire should resume") }

        // A saved recruitment choice resumes the recruitment flow.
        guard case .recruitment(let resumed) = PremiumEntryRouting.destination(
            for: SavedInterviewPreparation(useCase: recruitmentUseCase),
            intendedUseCaseID: "annual_review",
            recruitmentUseCaseID: recruitmentID
        ), resumed.id == recruitmentID else {
            preconditionFailure("Saved recruitment choice should resume recruitment")
        }

        // A completed preparation always lands on its result.
        var completed = SavedInterviewPreparation(useCase: sampleUseCase)
        completed.result = sampleResult
        guard case .result(let result) = PremiumEntryRouting.destination(
            for: completed,
            intendedUseCaseID: "annual_review",
            recruitmentUseCaseID: recruitmentID
        ), result.useCaseID == "mid_year" else {
            preconditionFailure("Completed preparation should land on its result")
        }

        // The onboarding intent options map to premium use-case IDs.
        precondition(InterviewIntentOption.all.count == 5)
        precondition(InterviewIntentOption.all.first?.useCaseID == recruitmentID)
        precondition(InterviewIntentOption.all.last?.useCaseID == nil)
    }

    private static let sampleUseCase = InterviewUseCase(
        id: "mid_year",
        title: "Entretien de mi-année",
        shortTitle: "Mi-année",
        description: "Faire le point.",
        questionnaireVersion: "1.0",
        questions: [
            InterviewQuestion(
                id: "role_context",
                title: "Quel est votre rôle ?",
                helper: "Résumez votre périmètre.",
                required: true,
                inputType: "long_text",
                options: []
            ),
            InterviewQuestion(
                id: "optional",
                title: "Un obstacle ?",
                helper: "Facultatif.",
                required: false,
                inputType: "long_text",
                options: []
            ),
        ]
    )

    private static let sampleResult = InterviewPreparationResponse(
        useCaseID: "mid_year",
        title: "Préparation mi-année",
        summary: "Bilan factuel.",
        sections: [
            InterviewPreparationSection(title: "Avancement", content: "Objectifs en cours.")
        ],
        talkingPoints: ["Présenter les résultats."],
        actionPlan: ["Définir les priorités."]
    )

    private static let sampleLeanAnalysis = AnalysisResponse(
        analysis: AnalysisSection(
            strategic_reading: "Lecture",
            dominant_competencies: "Compétences",
            career_logic: "Logique"
        ),
        sensitive_reframing: SensitiveSection(
            identified_fragilities: "Fragilité",
            strategic_reinterpretation: "Réinterprétation",
            rational_reframing: "Reformulation"
        ),
        narrative: NarrativeSection(
            core_thread: "Fil",
            positioning_statement: "Positionnement"
        ),
        interview_preparation: InterviewSection(
            probable_objections: "Objections",
            structured_answers: "Réponses"
        ),
        legitimacy_anchor: LegitimacySection(
            objective_strength: "Force",
            final_alignment_statement: "Alignement"
        )
    )
}
