import SwiftUI

struct PremiumUpsellScreen: View {
    let onContinueFree: () -> Void

    private let primaryText = Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255)
    private let secondaryText = Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255)
    private let buttonColor = Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255)

    private let features = [
        ("checkmark.seal.fill", "Préparation complète aux objections"),
        ("point.3.connected.trianglepath.dotted", "Construction guidée du fil conducteur"),
        ("text.bubble.fill", "Réponses structurées pour les questions difficiles"),
        ("brain.head.profile", "Simulation mentale d'entretien"),
        ("sparkles", "Ancrage de légitimité avant l'entretien")
    ]

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
                VStack(spacing: 24) {
                    headerSection
                    benefitsCard
                    primaryCTA
                    secondaryCTA
                }
                .frame(maxWidth: 680)
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Passez à la préparation complète")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(primaryText)

            Text("Transformez votre lecture stratégique en une préparation solide pour vos entretiens.")
                .font(.subheadline)
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Ce que vous débloquez")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(primaryText)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(features, id: \.1) { symbol, text in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: symbol)
                            .font(.body.weight(.semibold))
                            .foregroundColor(buttonColor)
                            .frame(width: 20)

                        Text(text)
                            .font(.subheadline)
                            .foregroundColor(primaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(22)
        .background(Color.white.opacity(0.9))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
    }

    private var primaryCTA: some View {
        Button(action: {
            print("PAYWALL_CLICK_PREMIUM_PREPARATION")
        }) {
            Text("Débloquer ma préparation complète")
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
            print("PAYWALL_CONTINUE_FREE")
            onContinueFree()
        }) {
            Text("Continuer en version gratuite")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(buttonColor)
        }
    }
}

#Preview {
    PremiumUpsellScreen(onContinueFree: {})
}
