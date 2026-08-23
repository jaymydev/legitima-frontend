import SwiftUI

/// Two ways to show a prepared question, side by side for the decision.
///
/// The tension is the whole design. `intent` — what the interviewer is really
/// checking — is what lets someone improvise when the question lands
/// differently. It is also the third block of text on a page that has to be
/// read in five minutes, in a corridor.
enum QuestionCardStyle: String, CaseIterable, Identifiable {
    /// Question, intention, réponse : les trois visibles d'emblée.
    case expanded
    /// L'intention repliée derrière un geste, pour tenir la page.
    case compact

    var id: String { rawValue }

    var label: String {
        switch self {
        case .expanded: return "Tout visible"
        case .compact: return "Intention repliée"
        }
    }
}

struct PreparedInterviewScreen: View {
    let preparation: PreparedInterview

    /// Mock scaffolding: lets the two layouts be compared on the device rather
    /// than described. Goes away once one is chosen.
    @State private var style: QuestionCardStyle = .expanded

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

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    styleSwitcher

                    ForEach(Array(preparation.questions.enumerated()), id: \.offset) { index, question in
                        questionCard(index: index, question: question)
                    }

                    actionPlanCard
                }
                .frame(maxWidth: 720)
                .padding(22)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CE QU'ON VA VOUS DEMANDER")
                .font(.caption.weight(.bold))
                .foregroundColor(LegitimaColors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(LegitimaColors.surface)
                .clipShape(Capsule())

            Text(preparation.title)
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundColor(LegitimaColors.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(preparation.questions.count) questions, les plus probables d'abord. Chaque réponse se dit telle quelle.")
                .font(.subheadline)
                .foregroundColor(LegitimaColors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var styleSwitcher: some View {
        Picker("Présentation", selection: $style) {
            ForEach(QuestionCardStyle.allCases) { option in
                Text(option.label).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }

    private func questionCard(index: Int, question: PreparedQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
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

            switch style {
            case .expanded:
                intentLine(question.intent)
                answerBlock(question.answer)
            case .compact:
                answerBlock(question.answer)
                DisclosureGroup("Pourquoi cette question ?") {
                    intentLine(question.intent)
                        .padding(.top, 6)
                }
                .font(.subheadline.weight(.semibold))
                .tint(LegitimaColors.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    private func intentLine(_ intent: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "eye.fill")
                .font(.caption)
                .foregroundColor(LegitimaColors.muted)
            Text(intent)
                .font(.subheadline)
                .foregroundColor(LegitimaColors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The answer is the thing you say, so it gets the weight on the page.
    private func answerBlock(_ answer: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CE QUE VOUS RÉPONDEZ")
                .font(.caption2.weight(.bold))
                .foregroundColor(LegitimaColors.accent)
            JustifiedText(answer, color: LegitimaColors.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(LegitimaColors.chip)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))
    }

    private var actionPlanCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Avant d'entrer", systemImage: "checklist")
                .font(.headline)
                .foregroundColor(LegitimaColors.ink)

            ForEach(Array(preparation.actionPlan.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .frame(width: 24, height: 24)
                        .background(LegitimaColors.chip)
                        .clipShape(Circle())
                    JustifiedText(item, color: LegitimaColors.muted)
                }
            }

            Text("Exporter mon plan d'action")
                .legitimaPrimaryLabel()
                .padding(.top, 4)
                .opacity(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }
}

/// Mock content, written to look like what the model returns for a recruitment.
/// Replaced by the real call once the client talks to /v3/interview/questions.
extension PreparedInterview {
    static let sampleRecruitment = PreparedInterview(
        useCaseID: "recruitment",
        title: "Votre entretien de recrutement",
        questions: [
            PreparedQuestion(
                question: "Parlez-moi de vous.",
                intent: "Il vérifie si vous savez cadrer votre propos sans qu'on vous guide.",
                answer: "Donnez votre métier en une phrase, puis deux étapes qui mènent au poste visé. Terminez sur ce que vous cherchez maintenant."
            ),
            PreparedQuestion(
                question: "Pourquoi ce poste, chez nous ?",
                intent: "Il cherche à savoir si vous avez lu l'annonce ou si vous postulez partout.",
                answer: "Citez une mission précise de l'offre, dites en quoi vous l'avez déjà faite, puis ce qui vous attire dans l'entreprise."
            ),
            PreparedQuestion(
                question: "Quelle est votre principale limite sur ce poste ?",
                intent: "Il teste votre lucidité, pas votre modestie.",
                answer: "Nommez un écart réel avec le poste, dites comment vous le compensez aujourd'hui, et ce que vous faites pour le combler."
            ),
            PreparedQuestion(
                question: "Racontez une situation difficile que vous avez gérée.",
                intent: "Il veut voir votre part personnelle, pas celle de l'équipe.",
                answer: "Décrivez la situation en deux phrases, puis ce que VOUS avez décidé, puis le résultat obtenu."
            ),
            PreparedQuestion(
                question: "Quelles sont vos prétentions salariales ?",
                intent: "Il vérifie que vous êtes dans l'enveloppe avant d'aller plus loin.",
                answer: "Donnez une fourchette, pas un chiffre. Ajoutez qu'elle reste ouverte selon le périmètre exact du poste."
            )
        ],
        actionPlan: [
            "Relisez l'offre et surlignez les trois exigences qui reviennent.",
            "Dites la réponse 1 à voix haute, une fois, en entier.",
            "Préparez une question à leur poser sur les six premiers mois."
        ]
    )
}
