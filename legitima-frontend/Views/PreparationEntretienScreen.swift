import SwiftUI

struct PreparationEntretienScreen: View {
    @State private var questionCle = ""
    @State private var forceAppui = ""
    @State private var messagePrioritaire = ""
    @State private var reponseCourte = ""

    private let primaryText = Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255)
    private let secondaryText = Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255)
    private let buttonColor = Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255)

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
                VStack(alignment: .leading, spacing: 22) {
                    headerSection
                    intentionCard

                    guidedStepCard(
                        index: "1",
                        title: "La question prioritaire",
                        helper: "Commencez par une seule question difficile. Inutile de préparer tout l’entretien d’un coup.",
                        placeholder: "Ex : Pourquoi votre parcours semble-t-il si atypique ?",
                        text: $questionCle,
                        minHeight: 84
                    )

                    guidedStepCard(
                        index: "2",
                        title: "Votre meilleur point d’appui",
                        helper: "Choisissez l’élément le plus rassurant ou le plus solide à rappeler.",
                        placeholder: "Ex : Ma capacité à livrer dans des contextes complexes et changeants.",
                        text: $forceAppui,
                        minHeight: 84
                    )

                    guidedStepCard(
                        index: "3",
                        title: "Le message à laisser",
                        helper: "Pensez à la phrase simple que le recruteur devra retenir après cette réponse.",
                        placeholder: "Ex : Mon parcours est cohérent parce qu’il suit une logique d’évolution assumée.",
                        text: $messagePrioritaire,
                        minHeight: 84
                    )

                    guidedStepCard(
                        index: "4",
                        title: "Votre réponse de départ",
                        helper: "Rédigez une première réponse brève. Elle n’a pas besoin d’être parfaite maintenant.",
                        placeholder: "Ex : J’ai eu un parcours non linéaire, mais il m’a permis de renforcer une expertise utile aujourd’hui...",
                        text: $reponseCourte,
                        minHeight: 120
                    )

                    if shouldShowNudge {
                        nudgeCard
                    }

                    NavigationLink(destination: FilConducteurScreen()) {
                        Text("Passer au récit global")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(buttonColor)
                            .cornerRadius(12)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Préparer une réponse forte")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(primaryText)

            Text("Travaillez une question précise pour préparer une réponse claire, calme et crédible.")
                .font(.subheadline)
                .foregroundColor(secondaryText)
        }
    }

    private var intentionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Objectif de cette étape")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(primaryText)

            Text("Ici, vous préparez une réponse locale à une question difficile. Vous ne cherchez pas encore à résumer tout votre parcours.")
                .font(.subheadline)
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color.white.opacity(0.9))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var nudgeCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.orange)

            Text("Une réponse simple et imparfaite vaut mieux qu’un écran vide. Vous clarifierez ensuite le récit global qui relie l’ensemble de votre parcours.")
                .font(.footnote)
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(red: 255 / 255, green: 247 / 255, blue: 225 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var shouldShowNudge: Bool {
        [questionCle, forceAppui, messagePrioritaire, reponseCourte]
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .count < 40
    }

    private func guidedStepCard(
        index: String,
        title: String,
        helper: String,
        placeholder: String,
        text: Binding<String>,
        minHeight: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text(index)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(buttonColor)
                    .frame(width: 28, height: 28)
                    .background(Color(red: 233 / 255, green: 247 / 255, blue: 241 / 255))
                    .clipShape(Circle())

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryText)
            }

            Text(helper)
                .font(.subheadline)
                .foregroundColor(secondaryText)

            PlaceholderTextEditor(
                placeholder: placeholder,
                text: text,
                primaryColor: primaryText,
                minHeight: minHeight
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 224 / 255, green: 231 / 255, blue: 231 / 255), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

struct PreparationEntretienScreen_Previews: PreviewProvider {
    static var previews: some View {
        PreparationEntretienScreen()
    }
}
