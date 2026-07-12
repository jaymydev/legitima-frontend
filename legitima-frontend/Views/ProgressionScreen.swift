import SwiftUI

struct ProgressionScreen: View {
    @EnvironmentObject private var userStatus: UserStatus
    @State private var navigateToPremiumFlow = false

    let onBackToResults: () -> Void

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
                VStack(spacing: 24) {
                    headerSection
                    completionCard
                    narrativeCard
                    modulesSection
                    primaryCTA
                    secondaryCTA
                }
                .frame(maxWidth: 720)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(userStatus.isPremium ? "Votre préparation complète peut commencer" : "Votre récit commence à prendre forme")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(primaryText)
                .multilineTextAlignment(.center)

            Text(
                userStatus.isPremium
                ? "Vous avez maintenant accès au parcours guidé pour transformer votre analyse en réponses concrètes."
                : "Vous avez obtenu une première lecture stratégique. La suite aide à en faire une vraie préparation d’entretien."
            )
            .font(.subheadline)
            .foregroundColor(secondaryText)
            .multilineTextAlignment(.center)
        }
    }

    private var completionCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("\(completedCount) / 6 étapes activées")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(primaryText)

                Spacer(minLength: 0)

                Text(userStatus.isPremium ? "Préparation complète" : "Lecture stratégique")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(buttonColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 233 / 255, green: 247 / 255, blue: 241 / 255))
                    .clipShape(Capsule())
            }

            VStack(spacing: 12) {
                ForEach(stepRows, id: \.title) { step in
                    stepRow(step)
                }
            }
        }
        .padding(22)
        .background(Color.white.opacity(0.9))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
    }

    private var narrativeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(userStatus.isPremium ? "La prochaine étape" : "Ce qui vient ensuite")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(primaryText)

            Text(
                userStatus.isPremium
                ? "Vous n’avez plus à prouver que votre parcours a de la valeur. Vous allez maintenant apprendre à l’expliquer avec plus de clarté, de cohérence et d’assurance."
                : "La lecture stratégique vous donne une base. La préparation complète vous aide ensuite à formuler vos réponses et votre fil conducteur sans repartir de zéro."
            )
            .font(.body)
            .foregroundColor(primaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .background(Color.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(userStatus.isPremium ? "Modules de préparation" : "Ce que la préparation complète débloque")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(primaryText)

            ForEach(moduleCards, id: \.title) { module in
                moduleCard(module)
            }
        }
    }

    private var primaryCTA: some View {
        Button(action: {
            if userStatus.isPremium {
                navigateToPremiumFlow = true
            } else {
                userStatus.activatePremium()
                onBackToResults()
            }
        }) {
            Text(userStatus.isPremium ? "Commencer la préparation guidée" : "Débloquer la préparation complète")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(buttonColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .navigationDestination(isPresented: $navigateToPremiumFlow) {
            ContexteEntretienScreen()
        }
    }

    private var secondaryCTA: some View {
        Button(action: {
            onBackToResults()
        }) {
            Text("Revenir à mes résultats")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(buttonColor)
        }
    }

    private var completedCount: Int {
        userStatus.isPremium ? 4 : 3
    }

    private var stepRows: [ProgressStepRow] {
        [
            ProgressStepRow(title: "Compréhension stratégique", isCompleted: true),
            ProgressStepRow(title: "Relecture du parcours", isCompleted: true),
            ProgressStepRow(title: "Requalification des zones sensibles", isCompleted: true),
            ProgressStepRow(title: "Anticipation des objections", isCompleted: userStatus.isPremium),
            ProgressStepRow(title: "Construction du fil conducteur", isCompleted: false),
            ProgressStepRow(title: "Préparation complète de l’entretien", isCompleted: false)
        ]
    }

    private var moduleCards: [PremiumModuleCard] {
        [
            PremiumModuleCard(
                icon: "bubble.left.and.bubble.right.fill",
                title: "Objections",
                description: "Préparez les questions difficiles avec des réponses plus calmes, plus claires et plus solides.",
                accent: Color(red: 255 / 255, green: 239 / 255, blue: 221 / 255),
                isUnlocked: userStatus.isPremium
            ),
            PremiumModuleCard(
                icon: "checkmark.seal.fill",
                title: "Légitimité",
                description: "Transformez vos faits forts en appuis simples, crédibles et rassurants.",
                accent: Color(red: 228 / 255, green: 239 / 255, blue: 253 / 255),
                isUnlocked: userStatus.isPremium
            ),
            PremiumModuleCard(
                icon: "point.3.connected.trianglepath.dotted",
                title: "Fil conducteur",
                description: "Assemblez un récit simple, cohérent et défendable de votre trajectoire.",
                accent: Color(red: 255 / 255, green: 247 / 255, blue: 225 / 255),
                isUnlocked: userStatus.isPremium
            ),
            PremiumModuleCard(
                icon: "sparkles",
                title: "Préparation entretien",
                description: "Arrivez en entretien avec une posture plus claire et plus confiante.",
                accent: Color(red: 242 / 255, green: 233 / 255, blue: 252 / 255),
                isUnlocked: userStatus.isPremium
            )
        ]
    }

    private func stepRow(_ step: ProgressStepRow) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(step.isCompleted ? buttonColor : secondaryText.opacity(0.7))

            Text(step.title)
                .font(.subheadline)
                .foregroundColor(primaryText)

            Spacer(minLength: 0)
        }
    }

    private func moduleCard(_ module: PremiumModuleCard) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: module.icon)
                .font(.title3)
                .foregroundColor(primaryText)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(module.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryText)

                    if !module.isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(secondaryText)
                    }
                }

                Text(module.description)
                    .font(.subheadline)
                    .foregroundColor(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(module.accent.opacity(module.isUnlocked ? 1 : 0.62))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .opacity(module.isUnlocked ? 1 : 0.88)
    }
}

private struct ProgressStepRow {
    let title: String
    let isCompleted: Bool
}

private struct PremiumModuleCard {
    let icon: String
    let title: String
    let description: String
    let accent: Color
    let isUnlocked: Bool
}

struct ProgressionScreen_Previews: PreviewProvider {
    static var previews: some View {
        ProgressionScreen(
            onBackToResults: {}
        )
        .environmentObject(UserStatus())
    }
}
