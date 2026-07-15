import SwiftUI

struct PreparationEntretienScreen: View {
    @State private var questionCle = ""
    @State private var forceAppui = ""
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
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ambientBackground

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headerSection
                    intentionCard

                    guidedStepCard(
                        index: "1",
                        title: "La question prioritaire",
                        helper: "Commencez par une seule question difficile.",
                        placeholder: "Ex : Pourquoi votre parcours semble-t-il si atypique ?",
                        text: $questionCle,
                        minHeight: 84
                    )

                    guidedStepCard(
                        index: "2",
                        title: "Votre point d’appui principal",
                        helper: "Choisissez l’élément le plus solide à rappeler.",
                        placeholder: "Ex : Ma capacité à livrer dans des contextes complexes et changeants.",
                        text: $forceAppui,
                        minHeight: 84
                    )

                    guidedStepCard(
                        index: "3",
                        title: "Votre première réponse",
                        helper: "Rédigez une version courte. Elle doit répondre à la question, s’appuyer sur un fait fort et laisser une idée claire.",
                        placeholder: "Ex : mon parcours n’a pas été linéaire, mais il a renforcé une expertise utile aujourd’hui et m’a permis de clarifier un positionnement plus cohérent.",
                        text: $reponseCourte,
                        minHeight: 120
                    )

                    if shouldShowNudge {
                        nudgeCard
                    }

                    NavigationLink(destination: FilConducteurScreen()) {
                        Text("Recevoir ma synthèse premium")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [
                                        buttonColor,
                                        Color(red: 54 / 255, green: 132 / 255, blue: 134 / 255)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: buttonColor.opacity(0.22), radius: 12, x: 0, y: 8)
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
        VStack(alignment: .leading, spacing: 14) {
            Text("ETAPE 5")
                .font(.caption.weight(.bold))
                .foregroundColor(buttonColor.opacity(0.82))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.72))
                .clipShape(Capsule())

            Text("Préparer une réponse\nclaire et solide")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(primaryText)

            Text("Choisissez une seule question difficile et préparez une première réponse exploitable tout de suite.")
                .font(.subheadline)
                .foregroundColor(secondaryText)
        }
    }

    private var intentionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                    .font(.title3)
                    .foregroundColor(buttonColor)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Objectif de cette étape")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryText)

                    Text("Ici, vous préparez une réponse précise à une question sensible. La synthèse globale viendra ensuite, sans nouvel effort de saisie.")
                        .font(.subheadline)
                        .foregroundColor(secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                framingPill("1 question")
                framingPill("1 point d’appui")
                framingPill("1 réponse courte")
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.96),
                    Color(red: 244 / 255, green: 252 / 255, blue: 250 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var nudgeCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.orange)

            Text("Une réponse simple vaut mieux qu’une réponse parfaite. Le plus important ici est d’avoir une base claire.")
                .font(.footnote)
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(red: 255 / 255, green: 247 / 255, blue: 225 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var shouldShowNudge: Bool {
        [questionCle, forceAppui, reponseCourte]
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .count < 40
    }

    private var ambientBackground: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.34))
                .frame(width: 220, height: 220)
                .blur(radius: 8)
                .offset(x: 150, y: -250)

            Circle()
                .fill(Color(red: 170 / 255, green: 232 / 255, blue: 224 / 255).opacity(0.34))
                .frame(width: 200, height: 200)
                .blur(radius: 10)
                .offset(x: -140, y: 260)
        }
        .allowsHitTesting(false)
    }

    private func framingPill(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(buttonColor.opacity(0.92))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(red: 233 / 255, green: 247 / 255, blue: 241 / 255))
            .clipShape(Capsule())
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
