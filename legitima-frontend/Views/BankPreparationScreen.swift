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

    private let service = InterviewQuestionsService()
    private let seenStore = ProtectedJSONStore<[String]>.seenQuestions

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
                    card(index: index, question: question)
                }

                // Le document qu'on relit dans la salle d'attente. Généré à la
                // demande, avec les blancs tels qu'ils sont au moment du partage.
                if let url = PreparationPDFExporter.writeTemporaryPDF(
                    for: PreparationExportContent(page: page, filled: slots.values)
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    private func load() async {
        do {
            // Ce qui a déjà été servi est exclu, pour qu'une seconde préparation
            // ne redonne pas la même page.
            let seen = seenStore.load() ?? []
            let page = try await service.fetchBank(useCaseID: useCaseID, seen: seen)
            seenStore.save(Array((seen + page.questions.map(\.id)).suffix(120)))
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
}
