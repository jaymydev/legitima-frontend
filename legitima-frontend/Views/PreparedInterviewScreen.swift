import SwiftUI

struct PreparedInterviewScreen: View {
    let preparation: PreparedInterview

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

            intentLine(question.intent)
            answerBlock(question.answer)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    /// One short line between the question and the answer.
    ///
    /// Folding it away, as one mock did, meant nobody would ever open it — a
    /// collapsed explanation is not read in a corridor. Putting it in full above
    /// the answer delayed the thing the reader came for. Kept visible, kept to a
    /// line: the backend caps it at 80 characters for exactly this place.
    private func intentLine(_ intent: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "eye.fill")
                .font(.caption2)
                .foregroundColor(LegitimaColors.muted)
            Text(intent)
                .font(.footnote)
                .foregroundColor(LegitimaColors.muted)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 34)
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
                intent: "Il vérifie si vous avez vraiment lu l'annonce.",
                answer: "Citez une mission précise de l'offre, dites en quoi vous l'avez déjà faite, puis ce qui vous attire dans l'entreprise."
            ),
            PreparedQuestion(
                question: "Quelle est votre principale limite sur ce poste ?",
                intent: "Il teste votre lucidité, pas votre modestie.",
                answer: "Nommez un écart réel avec le poste, dites comment vous le compensez aujourd'hui, et ce que vous faites pour le combler."
            ),
            PreparedQuestion(
                question: "Racontez une situation difficile que vous avez gérée.",
                intent: "Il veut votre part personnelle, pas celle de l'équipe.",
                answer: "Décrivez la situation en deux phrases, puis ce que VOUS avez décidé, puis le résultat obtenu."
            ),
            PreparedQuestion(
                question: "Quelles sont vos prétentions salariales ?",
                intent: "Il vérifie que vous êtes dans l'enveloppe.",
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
