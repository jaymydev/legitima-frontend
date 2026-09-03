import SwiftUI

/// Demander des réponses personnalisées, au moment où on le veut.
///
/// C'est l'inverse du formulaire d'accueil que le pivot a supprimé : rien n'est
/// demandé en amont, mais quand la personne demande la personnalisation, on lui
/// demande la matière — car sans elle le serveur ne peut rien affirmer d'elle,
/// et ne le fera pas. Les questions viennent du catalogue, pas du client : le
/// backend peut les changer sans nouvelle version d'app.
struct PersonalizationSheet: View {
    let useCaseID: String
    let onDone: (PreparedInterview) -> Void

    @EnvironmentObject private var slots: SlotStore
    @Environment(\.dismiss) private var dismiss

    @State private var stage: Stage = .loading
    @State private var answers: [String: String] = [:]
    @State private var material = CVMaterial()
    /// Le CV importé reste joignable sans être obligatoire : la matière
    /// appartient à la personne, y compris le droit de ne pas l'envoyer.
    @State private var attachCV = true
    @State private var isImportingCV = false
    @State private var errorMessage: String?

    private let service = InterviewQuestionsService()
    private let materialStore = ProtectedJSONStore<CVMaterial>.cvMaterial

    enum Stage {
        case loading
        case form(InterviewUseCase)
        case generating(InterviewUseCase)
        case unavailable(String)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch stage {
                    case .loading:
                        ProgressView()
                            .tint(LegitimaColors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    case let .form(useCase):
                        form(useCase)
                    case .generating:
                        generating
                    case let .unavailable(message):
                        unavailable(message)
                    }
                }
                .padding(22)
            }
            .background(LegitimaColors.surfaceStrong.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        .task { await loadCatalog() }
        .sheet(isPresented: $isImportingCV) {
            CVImportFlowSheet(
                onUseSummary: { _ in },
                onUseExperiences: { experiences in
                    for (name, value) in SlotAutofill.values(from: experiences) {
                        slots.set(value, for: name)
                    }
                },
                onUseMaterial: { imported in
                    materialStore.save(imported)
                    material = imported
                    attachCV = true
                },
                introText: "Ses détails — projets, chiffres, outils — sont ce qui transforme les consignes en phrases à dire.",
                applyButtonTitle: "Utiliser ce CV"
            )
        }
    }

    // MARK: - Le formulaire

    private func form(_ useCase: InterviewUseCase) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Des réponses à vous")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(LegitimaColors.ink)

                Text("Ce que vous écrivez ici est la seule source : rien ne sera affirmé sur vous qui n'y figure pas. Ce qui manque restera une consigne — jamais une invention.")
                    .font(.subheadline)
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(useCase.questions) { question in
                questionField(question)
            }

            if useCase.acceptsCV {
                cvCard
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                generate(useCase)
            } label: {
                Text("Écrire mes réponses").legitimaPrimaryLabel()
            }
            .disabled(!useCase.hasAllRequiredAnswers(answers))
            .opacity(useCase.hasAllRequiredAnswers(answers) ? 1 : 0.5)

            Text("Envoyé à notre serveur puis à OpenAI, le temps d'écrire vos réponses. Rien n'y est conservé.")
                .font(.footnote)
                .foregroundColor(LegitimaColors.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func questionField(_ question: InterviewQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(question.title)
                    .font(.headline)
                    .foregroundColor(LegitimaColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !question.required {
                    Text("Facultatif")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(LegitimaColors.muted)
                }
            }

            if !question.helper.isEmpty {
                Text(question.helper)
                    .font(.footnote)
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            PlaceholderTextEditor(
                placeholder: "Écrivez ici",
                text: binding(for: question.id),
                primaryColor: LegitimaColors.ink,
                minHeight: question.inputType == "short_text" ? 44 : 110
            )
            .overlay(
                RoundedRectangle(cornerRadius: LegitimaRadius.control)
                    .stroke(LegitimaColors.fieldBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    private var cvCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if material.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Votre CV")
                        .font(.headline)
                        .foregroundColor(LegitimaColors.ink)
                    Text("Facultatif")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(LegitimaColors.muted)
                }

                Text("Ses détails — projets, chiffres, outils — sont ce qui transforme les consignes en phrases à dire.")
                    .font(.footnote)
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    isImportingCV = true
                } label: {
                    Label("Importer mon CV", systemImage: "doc.text")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(LegitimaColors.accent)
                }
            } else {
                Toggle(isOn: $attachCV) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Joindre mon CV")
                            .font(.headline)
                            .foregroundColor(LegitimaColors.ink)
                        Text("Celui importé pour remplir vos blancs. Il nourrit vos réponses sans quitter votre téléphone autrement.")
                            .font(.footnote)
                            .foregroundColor(LegitimaColors.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(LegitimaColors.accent)

                Button {
                    isImportingCV = true
                } label: {
                    Label("Remplacer par un autre CV", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(LegitimaColors.accent)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    // MARK: - La génération

    private var generating: some View {
        VStack(spacing: 16) {
            AnalysisLoadingCard(
                steps: [
                    "Lecture de ce que vous avez écrit",
                    "Écriture de vos réponses",
                    "Vérification : rien d'affirmé sans source",
                ],
                accent: LegitimaColors.accent,
                typicalDuration: 30
            )

            Text("Une réponse n'affirme que ce que vous avez écrit. Le reste vous dit comment répondre, sans parler à votre place.")
                .font(.footnote)
                .foregroundColor(LegitimaColors.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 40)
    }

    private func unavailable(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text(message)
                .font(.subheadline)
                .foregroundColor(LegitimaColors.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Réessayer") {
                stage = .loading
                Task { await loadCatalog() }
            }
            .font(.headline)
            .foregroundColor(LegitimaColors.accent)
        }
        .padding(.top, 60)
    }

    private func loadCatalog() async {
        guard case .loading = stage else { return }
        material = materialStore.load() ?? CVMaterial()
        do {
            guard let useCase = try await service.fetchUseCase(id: useCaseID) else {
                stage = .unavailable("Ce type d'entretien n'est plus proposé. Fermez puis rouvrez l'app pour retrouver la liste à jour.")
                return
            }
            for question in useCase.questions where (answers[question.id] ?? "").isEmpty {
                answers[question.id] = PersonalizationPrefill.draft(
                    questionID: question.id,
                    slots: slots.values
                )
            }
            stage = .form(useCase)
        } catch {
            stage = .unavailable(error.localizedDescription)
        }
    }

    /// Le CV ne part que là où il sert. Le serveur l'écarte avant le prompt
    /// pour les trois bilans et l'évolution de poste : l'envoyer y ferait
    /// traverser l'Atlantique à un parcours pour qu'il finisse à la poubelle.
    private func joindLeCV(_ useCase: InterviewUseCase) -> Bool {
        useCase.acceptsCV && attachCV
    }

    private func generate(_ useCase: InterviewUseCase) {
        errorMessage = nil
        stage = .generating(useCase)

        let payload = PreparedInterviewRequest(
            useCaseID: useCase.id,
            questionnaireVersion: useCase.questionnaireVersion,
            answers: useCase.questions.compactMap { question in
                let answer = (answers[question.id] ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return answer.isEmpty ? nil : InterviewAnswer(questionID: question.id, answer: answer)
            },
            // Deux conditions, pas une. Masquer la carte sans couper l'envoi
            // aurait corrigé l'apparence en laissant le parcours partir quand
            // même — c'est la transmission qu'on veut éviter, pas son affichage.
            experiences: joindLeCV(useCase) ? material.experiences : [],
            cvText: joindLeCV(useCase) ? material.rawText : ""
        )

        Task {
            do {
                let prepared = try await service.personalize(payload)
                onDone(prepared)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                stage = .form(useCase)
            }
        }
    }

    private func binding(for questionID: String) -> Binding<String> {
        Binding(
            get: { answers[questionID] ?? "" },
            set: { answers[questionID] = $0 }
        )
    }
}
