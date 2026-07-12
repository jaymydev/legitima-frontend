import SwiftUI

struct ZonesSensiblesScreen: View {
    @State private var periodesSensibles = ""
    @State private var explicationBrute = ""

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

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headerSection
                    framingCard

                    guidedStepCard(
                        index: "1",
                        title: "La zone sensible à traiter",
                        helper: "Choisissez une seule période ou situation qui vous semble difficile à expliquer aujourd’hui.",
                        placeholder: "Ex : période de bench, pause, reconversion, changement fréquent de poste...",
                        text: $periodesSensibles,
                        minHeight: 84
                    )

                    guidedStepCard(
                        index: "2",
                        title: "Expliquez-la simplement",
                        helper: "Décrivez-la avec vos mots, sans chercher encore à la requalifier. Une version brute suffit.",
                        placeholder: "Ex : J’ai peur que cette période donne une impression d’instabilité, alors qu’elle correspondait à une vraie phase de transition.",
                        text: $explicationBrute,
                        minHeight: 120
                    )

                    vocalHintCard
                    nudgeCard

                    NavigationLink(destination: RequalificationScreen()) {
                        Text("Passer à la reformulation guidée")
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
            Text("Identifier une zone sensible")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(primaryText)

            Text("Vous n’avez pas besoin de tout résoudre ici. Donnez seulement la matière brute la plus importante.")
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

            Text("Le but n’est pas que vous requalifiiez seule cette fragilité. Le but est de capturer clairement ce qui bloque, pour pouvoir mieux la reformuler ensuite.")
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

    private var vocalHintCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "mic.fill")
                .foregroundColor(buttonColor)

            Text("Si vous utilisez la dictée iPhone, gardez un message court : idéalement 60 à 90 secondes maximum pour rester claire et éviter une matière trop longue à retraiter.")
                .font(.footnote)
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(red: 233 / 255, green: 247 / 255, blue: 241 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var nudgeCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundColor(buttonColor)

            Text("Restez simple et factuelle. Une version imparfaite mais honnête sera plus utile qu’une tentative déjà trop travaillée.")
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

struct ZonesSensiblesScreen_Previews: PreviewProvider {
    static var previews: some View {
        ZonesSensiblesScreen()
    }
}
