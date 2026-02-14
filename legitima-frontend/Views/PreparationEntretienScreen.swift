import SwiftUI

struct PreparationEntretienScreen: View {
    @State private var questionsRedoutees = ""
    @State private var forcesPrincipales = ""
    @State private var messagesCles = ""
    @State private var objectionsPossibles = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 207 / 255, green: 252 / 255, blue: 249 / 255),
                    Color(red: 237 / 255, green: 243 / 255, blue: 243 / 255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Préparer votre entretien")
                            .font(.largeTitle.bold())
                            .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                        Text("Clarifier les points sensibles et structurer vos réponses stratégiques.")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
                    }

                    inputCard(
                        title: "Questions que je redoute",
                        description: "Identifiez les questions qui vous mettent sous tension ou que vous craignez particulièrement.",
                        text: $questionsRedoutees,
                        placeholder: "– Question potentielle :\n– Pourquoi elle me met en difficulté :\n– Ce que je crains de mal formuler :",
                        warning: "Identifier clairement vos craintes permet de mieux les maîtriser."
                    )

                    inputCard(
                        title: "Forces principales à mettre en avant",
                        description: "Listez les atouts que vous souhaitez valoriser pendant l’entretien.",
                        text: $forcesPrincipales,
                        placeholder: "– Compétences clés :\n– Expériences différenciantes :\n– Résultats concrets :",
                        warning: "Préciser vos forces améliore la clarté de votre argumentaire."
                    )

                    inputCard(
                        title: "Messages clés à transmettre",
                        description: "Définissez les idées fortes que vous voulez que le recruteur retienne.",
                        text: $messagesCles,
                        placeholder: "– Positionnement actuel :\n– Valeur ajoutée principale :\n– Ce que je veux qu’on retienne de moi :",
                        warning: "Formaliser vos messages vous aide à rester cohérent pendant l’échange."
                    )

                    inputCard(
                        title: "Objections possibles du recruteur",
                        description: "Anticipez les doutes ou réserves que le recruteur pourrait formuler.",
                        text: $objectionsPossibles,
                        placeholder: "– Objection probable :\n– Fait objectif associé :\n– Réponse stratégique préparée :",
                        warning: "Anticiper les objections réduit l’improvisation et renforce votre posture."
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    private func inputCard(
        title: String,
        description: String,
        text: Binding<String>,
        placeholder: String,
        warning: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

            Text(description)
                .font(.subheadline)
                .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))

            ZStack(alignment: .topLeading) {
                TextEditor(text: text)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 224 / 255, green: 231 / 255, blue: 231 / 255), lineWidth: 1)
                    )

                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.subheadline)
                        .foregroundColor(Color(red: 157 / 255, green: 163 / 255, blue: 163 / 255))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }

            if text.wrappedValue.count < 40 {
                Text(warning)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    PreparationEntretienScreen()
}
