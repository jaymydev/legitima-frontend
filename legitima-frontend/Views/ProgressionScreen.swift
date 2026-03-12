import SwiftUI

struct ProgressionScreen: View {
    @Environment(\.dismiss) private var dismiss

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
                VStack(spacing: 28) {
                    headerSection
                    progressSection
                    pedagogicalSection
                    primaryCTA
                    secondaryCTA
                }
                .frame(maxWidth: 680)
                .padding(.horizontal, 24)
                .padding(.vertical, 36)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Votre récit commence à prendre forme")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(primaryText)
                .multilineTextAlignment(.center)

            Text("Vous venez d’obtenir une lecture stratégique de votre parcours.")
                .font(.subheadline)
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 6) {
                Text("3 / 6 étapes complétées")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryText)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 14) {
                progressionRow(symbol: "✓", text: "Compréhension stratégique")
                progressionRow(symbol: "✓", text: "Relecture du parcours")
                progressionRow(symbol: "✓", text: "Anticipation des objections")
            }

            VStack(alignment: .leading, spacing: 14) {
                progressionRow(symbol: "○", text: "Requalification des zones sensibles")
                progressionRow(symbol: "○", text: "Construction du fil conducteur")
                progressionRow(symbol: "○", text: "Préparation complète de l’entretien")
            }
        }
        .padding(22)
        .background(Color.white.opacity(0.88))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
    }

    private var pedagogicalSection: some View {
        Text("La plupart des candidats arrivent en entretien avec un CV.\n\nMais ce qui fait la différence n’est pas le document.\n\nC’est la capacité à expliquer son parcours avec clarté, cohérence et légitimité.")
            .font(.body)
            .foregroundColor(primaryText)
            .multilineTextAlignment(.center)
            .padding(20)
            .background(Color.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var primaryCTA: some View {
        Button(action: {
            print("Navigate to PremiumUpsellScreen")
        }) {
            Text("Structurer ma préparation complète")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(buttonColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var secondaryCTA: some View {
        Button(action: {
            dismiss()
        }) {
            Text("Revenir à mes résultats")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(buttonColor)
        }
        .padding(.top, -8)
    }

    private func progressionRow(symbol: String, text: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(symbol)
                .font(.body.weight(.semibold))
                .foregroundColor(symbol == "✓" ? buttonColor : secondaryText)

            Text(text)
                .font(.subheadline)
                .foregroundColor(primaryText)

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ProgressionScreen()
}

struct ProgressionScreen_Previews: PreviewProvider {
    static var previews: some View {
        ProgressionScreen()
    }
}
