import SwiftUI

struct FilConducteurScreen: View {
    @EnvironmentObject private var premiumDraft: PremiumPreparationDraft
    @EnvironmentObject private var router: AppRouter

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
                    framingCard

                    if let analysis = premiumDraft.baseAnalysis {
                        synthesisCards(analysis)
                    } else {
                        emptyStateCard
                    }

                    Button(action: handleReset) {
                        Text("Recommencer")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
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
                            .foregroundColor(.white)
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
            Text("ETAPE 6")
                .font(.caption.weight(.bold))
                .foregroundColor(buttonColor.opacity(0.82))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.72))
                .clipShape(Capsule())

            Text("Recevoir votre\nsynthèse premium")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(primaryText)

            Text("Ici, vous ne remplissez plus rien. Vous récupérez une version plus exploitable de votre analyse pour l’entretien.")
                .font(.subheadline)
                .foregroundColor(secondaryText)
        }
    }

    private var framingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.title3)
                    .foregroundColor(buttonColor)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ce que vous récupérez ici")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryText)

                    Text("Cette étape rassemble ce que vous pourrez réutiliser pour vous présenter, défendre votre parcours et garder une ligne claire en entretien.")
                        .font(.subheadline)
                        .foregroundColor(secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                framingPill("récit global")
                framingPill("positionnement")
                framingPill("légitimité")
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

    @ViewBuilder
    private func synthesisCards(_ response: AnalysisResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            synthesisCard(
                icon: "point.3.connected.trianglepath.dotted",
                title: "Fil conducteur",
                content: response.narrative.core_thread,
                backgroundColor: Color(red: 255 / 255, green: 247 / 255, blue: 225 / 255)
            )

            synthesisCard(
                icon: "text.quote",
                title: "Positionnement à reprendre",
                content: response.narrative.positioning_statement,
                backgroundColor: Color(red: 228 / 255, green: 239 / 255, blue: 253 / 255)
            )

            synthesisCard(
                icon: "bubble.left.and.bubble.right.fill",
                title: "Réponse d’appui à retenir",
                content: response.interview_preparation.structured_answers,
                backgroundColor: Color(red: 255 / 255, green: 239 / 255, blue: 221 / 255)
            )

            synthesisCard(
                icon: "checkmark.seal.fill",
                title: "Angle de légitimité",
                content: response.legitimacy_anchor.final_alignment_statement,
                backgroundColor: Color(red: 242 / 255, green: 233 / 255, blue: 252 / 255)
            )

            synthesisCard(
                icon: "sparkles",
                title: "Ce que vous pouvez défendre",
                content: response.legitimacy_anchor.objective_strength,
                backgroundColor: Color(red: 227 / 255, green: 245 / 255, blue: 236 / 255)
            )
        }
    }

    private func synthesisCard(
        icon: String,
        title: String,
        content: String,
        backgroundColor: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(primaryText)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryText)

                Text(content)
                    .font(.subheadline)
                    .foregroundColor(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Synthèse indisponible")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(primaryText)

            Text("La matière premium n’a pas encore été transmise à cet écran. Revenez à vos résultats puis relancez la suite de la préparation.")
                .font(.subheadline)
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color.white.opacity(0.94))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
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

    private func handleReset() {
        router.restartAnalysis()
    }
}

struct FilConducteurScreen_Previews: PreviewProvider {
    static var previews: some View {
        FilConducteurScreen()
            .environmentObject(PremiumPreparationDraft())
            .environmentObject(AppRouter())
    }
}
