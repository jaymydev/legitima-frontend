import SwiftUI

/// Les questions à préparer, servies par la banque.
///
/// Aucune attente, aucun appel modèle, et une page utile même si la personne n'a
/// rien saisi : c'est ce que la génération ne savait pas faire sans inventer un
/// parcours. Les blancs restent des blancs, et se remplissent quand on veut.
struct BankPreparationScreen: View {
    let useCaseID: String

    @EnvironmentObject private var slots: SlotStore
    @State private var stage: Stage = .loading
    @State private var personalized: PreparedInterview?
    @State private var isPersonalizing = false
    /// Le filtre de confort. Une question de la banque y entre par son
    /// identifiant, une question personnalisée par son texte — elle n'a pas
    /// d'identifiant et « Refaire » la remplace, donc une marque orpheline ne
    /// fait que dormir dans le fichier.
    @State private var comfortable: Set<String> = []

    private let service = InterviewQuestionsService()
    private let seenStore = ProtectedJSONStore<[String]>.seenQuestions
    private let personalizedStore = ProtectedJSONStore<[String: PreparedInterview]>.personalizedPreparations
    private let comfortStore = ProtectedJSONStore<[String]>.comfortMarks

    enum Stage {
        case loading
        case ready(BankPage)
        case failed(String)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(light: .rgb(222, 248, 244), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(245, 239, 231), dark: LegitimaColors.darkBackgroundBottom)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            switch stage {
            case .loading:
                ProgressView().tint(LegitimaColors.accent)
            case let .ready(page):
                content(page)
            case let .failed(message):
                VStack(spacing: 16) {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(LegitimaColors.body)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Réessayer") {
                        stage = .loading
                        Task { await load() }
                    }
                    .font(.headline)
                    .foregroundColor(LegitimaColors.accent)
                }
                .padding(30)
            }
        }
        .task { await load() }
    }

    private func content(_ page: BankPage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CE QU'ON VA VOUS DEMANDER")
                        .font(.caption.weight(.bold))
                        .foregroundColor(LegitimaColors.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(LegitimaColors.surface)
                        .clipShape(Capsule())

                    Text("\(page.questions.count) questions à préparer")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .foregroundColor(LegitimaColors.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Les réponses sont écrites : complétez les blancs quand vous voulez, une seule fois.")
                        .font(.subheadline)
                        .foregroundColor(LegitimaColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ForEach(Array(page.questions.enumerated()), id: \.element.id) { index, question in
                    if comfortable.contains(question.id) {
                        comfortableRow(index: index, title: question.question, key: question.id)
                    } else {
                        card(index: index, question: question)
                    }
                }

                if let personalized {
                    personalizedSection(personalized, startIndex: page.questions.count)
                } else {
                    personalizationInvitation
                }

                // Le document qu'on relit dans la salle d'attente. Généré à la
                // demande, avec les blancs tels qu'ils sont au moment du partage.
                if let url = PreparationPDFExporter.writeTemporaryPDF(
                    for: PreparationExportContent(
                        page: page,
                        filled: slots.values,
                        personalized: personalized,
                        comfortable: comfortable
                    )
                ) {
                    ShareLink(item: url) {
                        Label("Exporter mes réponses", systemImage: "square.and.arrow.up")
                            .legitimaPrimaryLabel()
                    }
                }
            }
            .frame(maxWidth: 720)
            .padding(22)
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $isPersonalizing) {
            PersonalizationSheet(useCaseID: useCaseID) { prepared in
                personalized = prepared
                var saved = personalizedStore.load() ?? [:]
                saved[useCaseID] = prepared
                personalizedStore.save(saved)
            }
            .environmentObject(slots)
        }
    }

    /// L'invitation, sous la banque : la promesse d'origine du produit.
    ///
    /// La banque répond sans rien demander ; ceci est le cran au-dessus, et il
    /// se paie en saisie. Le dire ici — et pas en amont — c'est tout le pivot.
    private var personalizationInvitation: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Aller plus loin", systemImage: "person.text.rectangle")
                .font(.headline)
                .foregroundColor(LegitimaColors.ink)

            Text("Avec votre CV et quelques lignes de vous, nous écrivons des réponses à dire telles quelles — sans jamais rien affirmer que vous n'ayez écrit.")
                .font(.subheadline)
                .foregroundColor(LegitimaColors.muted)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                isPersonalizing = true
            } label: {
                Text("Personnaliser mes réponses")
                    .legitimaPrimaryLabel()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    private func personalizedSection(_ prepared: PreparedInterview, startIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ÉCRIT POUR VOUS")
                    .font(.caption.weight(.bold))
                    .foregroundColor(LegitimaColors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(LegitimaColors.surface)
                    .clipShape(Capsule())

                Text("Depuis ce que vous avez fourni. Une réponse n'affirme que ce que vous avez écrit ; le reste vous dit comment répondre.")
                    .font(.subheadline)
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(Array(prepared.questions.enumerated()), id: \.offset) { index, question in
                if comfortable.contains(question.question) {
                    comfortableRow(
                        index: startIndex + index,
                        title: question.question,
                        key: question.question
                    )
                } else {
                    personalizedCard(index: startIndex + index, question: question)
                }
            }

            if !prepared.actionPlan.isEmpty {
                actionPlanCard(prepared.actionPlan)
            }

            Button {
                isPersonalizing = true
            } label: {
                Label("Refaire avec d'autres informations", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(LegitimaColors.accent)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func personalizedCard(index: Int, question: PreparedQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(index + 1)")
                    .font(.caption.bold())
                    .frame(width: 24, height: 24)
                    .background(LegitimaColors.chip)
                    .clipShape(Circle())
                Text(question.question)
                    .font(.headline)
                    .foregroundColor(LegitimaColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !question.intent.isEmpty {
                Text(question.intent)
                    .font(.footnote.italic())
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                // Une phrase se dit, une consigne se suit : le libellé le dit
                // avant la lecture, pour qu'on sache ce qu'on tient.
                Label(
                    question.isSentence ? "À dire" : "Comment répondre",
                    systemImage: question.isSentence ? "text.quote" : "list.bullet"
                )
                .font(.caption.weight(.bold))
                .foregroundColor(LegitimaColors.accent)

                Text(question.answer)
                    .font(.body)
                    .foregroundColor(LegitimaColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LegitimaColors.chip)
            .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))

            comfortButton(key: question.question)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    /// « J'ai 5 minutes pour réviser » : au plus trois gestes, avant d'entrer.
    private func actionPlanCard(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Avant d'entrer", systemImage: "figure.walk.arrival")
                .font(.headline)
                .foregroundColor(LegitimaColors.ink)

            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1).")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(LegitimaColors.accent)
                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(LegitimaColors.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    private func card(index: Int, question: BankQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(index + 1)")
                    .font(.caption.bold())
                    .frame(width: 24, height: 24)
                    .background(LegitimaColors.chip)
                    .clipShape(Circle())
                Text(question.question)
                    .font(.headline)
                    .foregroundColor(LegitimaColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TemplateAnswerView(template: question.answer)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LegitimaColors.chip)
                .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))

            // La relance porte les mêmes balises que le gabarit. Affichée telle
            // quelle, elle montrait « je suis à <SALAIRE_ACTUEL> » — ce qui se lit
            // comme une variable non remplacée, pas comme un blanc à remplir.
            if !question.followUp.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.footnote)
                        .foregroundColor(LegitimaColors.muted)
                    Text(TemplateFilling.plainText(question.followUp, filled: slots.values))
                        .font(.footnote)
                        .foregroundColor(LegitimaColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !question.avoid.isEmpty {
                Label(question.avoid.capitalizedFirst, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundColor(LegitimaColors.gold)
                    .fixedSize(horizontal: false, vertical: true)
            }

            comfortButton(key: question.id)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    // MARK: - Le filtre de confort

    /// « Si l'utilisateur est à l'aise sur un sujet, on ne le traite pas dans
    /// le rapport final. » Le seul geste qui raccourcit la page au lieu de
    /// l'allonger — et c'est un fait sur la personne qui ne coûte ni saisie ni
    /// vérification : c'est elle qui coche.
    private func comfortButton(key: String) -> some View {
        Button {
            toggleComfort(key)
        } label: {
            Label("Je suis à l'aise sur cette question", systemImage: "checkmark.circle")
                .font(.footnote.weight(.semibold))
                .foregroundColor(LegitimaColors.accent)
        }
        .buttonStyle(.plain)
    }

    /// La question repliée, pas retirée : elle reste lisible et le geste reste
    /// réversible d'un tap. Seul le PDF l'exclut — c'est lui qu'on relit dans
    /// le couloir, et c'est lui que le retour visait.
    private func comfortableRow(index: Int, title: String, key: String) -> some View {
        Button {
            toggleComfort(key)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text("\(index + 1)")
                    .font(.caption.bold())
                    .frame(width: 24, height: 24)
                    .background(LegitimaColors.chip)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(LegitimaColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    Text("À l'aise — ne figurera pas dans le PDF. Touchez pour rouvrir.")
                        .font(.caption)
                        .foregroundColor(LegitimaColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(LegitimaColors.accent)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LegitimaColors.surface.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
        }
        .buttonStyle(.plain)
    }

    private func toggleComfort(_ key: String) {
        withAnimation(LegitimaMotion.reveal) {
            if comfortable.contains(key) {
                comfortable.remove(key)
            } else {
                comfortable.insert(key)
            }
        }
        comfortStore.save(comfortable.sorted())
    }

    private func load() async {
        do {
            // Ce qui a déjà été servi est exclu, pour qu'une seconde préparation
            // ne redonne pas la même page.
            let seen = seenStore.load() ?? []
            let page = try await service.fetchBank(useCaseID: useCaseID, seen: seen)
            seenStore.save(Array((seen + page.questions.map(\.id)).suffix(120)))
            personalized = personalizedStore.load()?[useCaseID]
            comfortable = Set(comfortStore.load() ?? [])
            stage = .ready(page)
        } catch {
            stage = .failed(error.localizedDescription)
        }
    }
}

extension ProtectedJSONStore where Value == [String] {
    static var seenQuestions: Self {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return Self(
            fileURL: base
                .appendingPathComponent("Legitima", isDirectory: true)
                .appendingPathComponent("seen-questions.json")
        )
    }

    /// Comme les blancs : coché une fois, retenu pour les fois suivantes.
    /// Se savoir à l'aise sur « parlez-moi de vous » ne se périme pas d'une
    /// préparation à l'autre.
    static var comfortMarks: Self {
        Self(fileURL: applicationSupportURL.appendingPathComponent("comfort-marks.json"))
    }
}
