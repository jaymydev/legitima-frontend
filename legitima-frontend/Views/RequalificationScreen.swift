import SwiftUI

struct RequalificationScreen: View {
    @State private var faiblessePerçue = ""
    @State private var apprentissageReel = ""
    @State private var postureActuelle = ""

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
                    framingCard

                    guidedStepCard(
                        index: "1",
                        title: "Ce que vous craignez comme perception",
                        helper: "Quelle mauvaise lecture du recruteur vous inquiète le plus ?",
                        placeholder: "Ex : J’ai peur qu’on y voie un manque de stabilité ou un parcours mal maîtrisé.",
                        text: $faiblessePerçue,
                        minHeight: 96
                    )

                    guidedStepCard(
                        index: "2",
                        title: "Ce que cette phase a réellement apporté",
                        helper: "Pensez aux faits utiles : apprentissages, décisions prises, recul, compétences renforcées.",
                        placeholder: "Ex : J’ai clarifié mon positionnement, pris du recul, et mieux identifié l’environnement dans lequel je crée le plus de valeur.",
                        text: $apprentissageReel,
                        minHeight: 110
                    )

                    guidedStepCard(
                        index: "3",
                        title: "Ce que vous voulez qu’on comprenne",
                        helper: "En une idée simple, quel message juste voulez-vous laisser sur cette période ?",
                        placeholder: "Ex : Cette phase ne résume pas une faiblesse, mais une transition qui m’a aidée à faire un choix plus cohérent.",
                        text: $postureActuelle,
                        minHeight: 110
                    )

                    nudgeCard

                    NavigationLink(destination: PreparationEntretienScreen()) {
                        Text("Passer à la préparation d’entretien")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(buttonColor)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Commencer la reformulation")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(primaryText)

            Text("Ici, vous préparez les bons appuis pour mieux expliquer cette zone sensible, sans travestir votre parcours.")
                .font(.subheadline)
                .foregroundColor(secondaryText)
        }
    }

    private var framingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Objectif de cette étape")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(primaryText)

            Text("Vous n’avez pas besoin d’écrire une réponse parfaite. L’objectif est seulement de dégager quelques points d’appui pour rendre la reformulation plus simple ensuite.")
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
            Image(systemName: "sparkles")
                .foregroundColor(buttonColor)

            Text("Le bon objectif n’est pas d’effacer la fragilité. Le bon objectif est de préparer une lecture plus juste et plus maîtrisée.")
                .font(.footnote)
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(red: 233 / 255, green: 247 / 255, blue: 241 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

struct RequalificationScreen_Previews: PreviewProvider {
    static var previews: some View {
        RequalificationScreen()
    }
}
