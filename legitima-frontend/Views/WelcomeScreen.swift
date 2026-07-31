import SwiftUI

/// The first thing someone sees. It states the promise and what happens to
/// what they type — nothing else. The two account buttons that used to sit
/// here only ever raised a « bientôt » alert; a control that does nothing is
/// worse than no control, and App Review reads it as an unfinished feature.
struct WelcomeScreen: View {
    let hasSavedWork: Bool
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(light: .rgb(218, 249, 246), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(247, 242, 232), dark: LegitimaColors.darkBackgroundMid),
                    Color(light: .rgb(232, 241, 245), dark: LegitimaColors.darkBackgroundBottom)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 42)

                    VStack(spacing: 12) {
                        Text("Bienvenue sur\nLegitima")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(LegitimaColors.ink)

                        Text("Défendez un parcours atypique en entretien : une lecture stratégique de votre trajectoire, puis les réponses qui vont avec.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(LegitimaColors.muted)
                            .padding(.horizontal, 14)
                    }

                    Button(action: onContinue) {
                        VStack(spacing: 4) {
                            Text(hasSavedWork ? "Reprendre ma préparation" : "Commencer")
                                .fontWeight(.bold)

                            Text(hasSavedWork ? "Votre dernière préparation est disponible" : "Gratuit, sans création de compte")
                                .font(.caption)
                                .opacity(0.86)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(.white)
                        .background(LegitimaColors.accentSurface)
                        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
                    }
                    .padding(20)
                    .background(LegitimaColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.hero))
                    .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)

                    Text("Votre préparation reste sur cet appareil. Ce que vous écrivez est envoyé à notre serveur puis à OpenAI, le temps de produire l'analyse.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(LegitimaColors.muted)
                        .padding(.horizontal, 20)

                    Spacer(minLength: 30)
                }
                .frame(maxWidth: 620)
                .padding(.horizontal, 22)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
