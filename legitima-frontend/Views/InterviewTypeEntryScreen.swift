import SwiftUI

/// The first thing someone sees, and the only thing they must answer.
///
/// The app used to open on a blank form about their career: target role, whole
/// career path, sensitive point — then eight seconds of analysis, and only then
/// the question of which interview they were preparing. Testers said the
/// interview type is where the value is, and that a blank field is where people
/// close the app. So it comes first, and it is the only required answer.
///
/// Each type carries one line about who is across the table and what they are
/// after. That line is written here rather than generated: it is the same for
/// everyone, it costs no tokens, and it is what makes Legitima lead instead of
/// asking the user to already know what to fear.
struct InterviewTypeEntryScreen: View {
    let onContinue: (InterviewTypeChoice, Date?, String?, Bool) -> Void

    @EnvironmentObject private var preparationStore: LocalPreparationStore
    @State private var selection: InterviewTypeChoice?
    @State private var hasDate = false
    @State private var interviewDate = Calendar.current.date(
        byAdding: .day,
        value: 7,
        to: .now
    ) ?? .now
    /// Les verticales servies par le catalogue. Vide tant que le réseau n'a
    /// pas répondu — et l'écran reste entier sans elles.
    @State private var metiers: [MetierChoice] = []
    /// Les types où choisir un métier change la page, servis avec le catalogue.
    /// Vide tant que le réseau n'a pas répondu : on n'affiche alors pas de
    /// pastilles, faute de pouvoir affirmer qu'elles serviraient.
    @State private var metierAppliesTo: Set<String> = []
    @State private var selectedMetier: String?
    @State private var encadrement = false

    private let service = InterviewQuestionsService()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(light: .rgb(218, 249, 246), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(247, 242, 232), dark: LegitimaColors.darkBackgroundBottom)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    VStack(spacing: 10) {
                        ForEach(InterviewTypeChoice.allCases) { type in
                            typeCard(type)
                        }
                    }

                    if selection != nil {
                        dateSection
                            .transition(.opacity.combined(with: .move(edge: .bottom)))

                        metierSection
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    continueButton

                    privacyNote
                }
                .frame(maxWidth: 720)
                .padding(22)
                .frame(maxWidth: .infinity)
            }
        }
        .animation(LegitimaMotion.reveal, value: selection)
        .onAppear {
            // Le métier ne change pas entre deux préparations : ce qui a été
            // choisi la dernière fois est déjà coché.
            selectedMetier = preparationStore.snapshot.metierID
            encadrement = preparationStore.snapshot.encadrement
        }
        .task {
            // Silencieux en échec : l'écran d'entrée doit rester utilisable
            // sans réseau, le métier est un plus, pas un préalable.
            guard let catalog = try? await service.fetchMetiers() else { return }
            metiers = catalog.catalog
            metierAppliesTo = Set(catalog.appliesTo)
        }
    }

    /// Le métier ne vaut que pour les entretiens qui évaluent une compétence en
    /// vue d'un poste — le serveur dit lesquels. Les questions de spécialité
    /// sont écrites pour ça (« vendez-moi ce stylo ») : dans un bilan, face à
    /// quelqu'un qui a suivi le travail toute l'année, aucune ne serait posée.
    /// Proposer le choix là aurait été promettre un effet qui n'existe pas.
    private var metierApplies: Bool {
        guard let selection else { return false }
        return metierAppliesTo.contains(selection.rawValue)
    }

    /// Facultatif, comme la date. Choisir son métier met trois questions de
    /// sa spécialité en tête de page ; dire qu'on encadre débloque celles qui
    /// ne valent que pour l'encadrement. Rien n'est exigé : la page existe
    /// sans ces réponses.
    ///
    /// L'encadrement, lui, reste proposé partout : on peut avoir une équipe
    /// quel que soit l'entretien qu'on prépare.
    private var metierSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if metierApplies {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Votre métier")
                        .font(.headline)
                        .foregroundColor(LegitimaColors.ink)
                    Text("Facultatif")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(LegitimaColors.muted)
                }

                Text("Trois questions de votre spécialité passeront en tête de vos préparations.")
                    .font(.subheadline)
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)

                if !metiers.isEmpty {
                    RecruitmentFlowLayout(spacing: 8) {
                        ForEach(metiers) { metier in
                            metierChip(metier)
                        }
                    }
                }
            }

            Toggle(isOn: $encadrement) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("J'encadre une équipe")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(LegitimaColors.ink)
                    Text("Ajoute les questions qui ne se posent qu'à qui encadre.")
                        .font(.footnote)
                        .foregroundColor(LegitimaColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(LegitimaColors.accent)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    private func metierChip(_ metier: MetierChoice) -> some View {
        let isSelected = selectedMetier == metier.id
        return Button {
            // Retaper désélectionne : aucun métier n'est aussi une réponse.
            selectedMetier = isSelected ? nil : metier.id
        } label: {
            Text(metier.label)
                .font(.caption.weight(.semibold))
                .foregroundColor(isSelected ? .white : LegitimaColors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? LegitimaColors.accentSurface : LegitimaColors.chip)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LEGITIMA")
                .font(.caption.weight(.bold))
                .foregroundColor(LegitimaColors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(LegitimaColors.surface)
                .clipShape(Capsule())

            Text("Quel entretien préparez-vous ?")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundColor(LegitimaColors.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Nous préparons les questions qu'on va vous poser, et vos réponses.")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundColor(LegitimaColors.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
    }

    private func typeCard(_ type: InterviewTypeChoice) -> some View {
        let isSelected = selection == type

        return Button {
            selection = type
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : LegitimaColors.accent)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 4) {
                    Text(type.title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : LegitimaColors.ink)

                    Text(type.whatToExpect)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? Color.white.opacity(0.9) : LegitimaColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? LegitimaColors.accentSurface : LegitimaColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: LegitimaRadius.card)
                    .stroke(LegitimaColors.hairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    /// Optional on purpose. Someone who has an interview but no date yet must
    /// not be stopped here — the date only buys a reminder.
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quand a lieu cet entretien ?")
                .font(.headline)
                .foregroundColor(LegitimaColors.ink)

            Text("Nous vous enverrons un rappel avant, pour réviser au bon moment.")
                .font(.subheadline)
                .foregroundColor(LegitimaColors.muted)
                .fixedSize(horizontal: false, vertical: true)

            if hasDate {
                DatePicker(
                    "Date de l'entretien",
                    selection: $interviewDate,
                    in: Date.now...,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()

                Button("Je n'ai pas encore la date") {
                    hasDate = false
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(LegitimaColors.accent)
            } else {
                Button {
                    hasDate = true
                } label: {
                    Label("Choisir une date", systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(LegitimaColors.accent)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(LegitimaColors.chip)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    private var continueButton: some View {
        Button {
            guard let selection else { return }
            onContinue(selection, hasDate ? interviewDate : nil, selectedMetier, encadrement)
        } label: {
            Text("Continuer")
                .legitimaPrimaryLabel()
        }
        .disabled(selection == nil)
        .opacity(selection == nil ? 0.5 : 1)
    }

    private var privacyNote: some View {
        Text("Votre préparation reste sur cet appareil. Ce que vous écrivez est envoyé à notre serveur puis à OpenAI, le temps de préparer vos réponses.")
            .font(.footnote)
            .foregroundColor(LegitimaColors.muted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
    }
}

/// The six interviews Legitima prepares.
///
/// `id` matches the backend catalog, so the choice made here survives into the
/// questionnaire without translation. "Je ne sais pas encore" is deliberately
/// absent: someone who cannot name their interview is not who this is for.
enum InterviewTypeChoice: String, CaseIterable, Identifiable {
    case recruitment
    case internalMobility = "internal_mobility"
    case roleEvolution = "role_evolution"
    case annualReview = "annual_review"
    case midYear = "mid_year"
    case performanceReview = "performance_review"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recruitment: return "Entretien de recrutement"
        case .internalMobility: return "Mobilité interne"
        case .roleEvolution: return "Évolution de poste"
        case .annualReview: return "Entretien annuel"
        case .midYear: return "Entretien de mi-année"
        case .performanceReview: return "Entretien de performance"
        }
    }

    /// Who is across the table, and what they are actually after.
    var whatToExpect: String {
        switch self {
        case .recruitment:
            return "En face, un recruteur ou un manager qui cherche à savoir si vous tenez le poste."
        case .internalMobility:
            return "On vous demandera pourquoi vous partez autant que pourquoi vous arrivez."
        case .roleEvolution:
            return "Il faudra montrer que vous faites déjà une partie du poste visé."
        case .annualReview:
            return "Votre manager connaît déjà votre parcours : ce sont vos résultats qui se discutent."
        case .midYear:
            return "Le point d'étape, quand il est encore temps d'ajuster les objectifs."
        case .performanceReview:
            return "Votre travail est évalué : chaque affirmation doit pouvoir être étayée."
        }
    }

    var icon: String {
        switch self {
        case .recruitment: return "briefcase.fill"
        case .internalMobility: return "arrow.left.arrow.right"
        case .roleEvolution: return "arrow.up.right"
        case .annualReview: return "calendar"
        case .midYear: return "flag.checkered"
        case .performanceReview: return "chart.bar.fill"
        }
    }
}
