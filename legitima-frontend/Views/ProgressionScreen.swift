import SwiftUI

struct ProgressionScreen: View {
    @EnvironmentObject private var userStatus: UserStatus
    @State private var navigateToPremiumFlow = false

    let onBackToResults: () -> Void
    let onRestartAnalysis: () -> Void

    private let primaryText = LegitimaColors.ink
    private let secondaryText = LegitimaColors.muted
    private let buttonColor = LegitimaColors.accentSurface
    private let accentText = LegitimaColors.accent
    private let premiumInk = LegitimaColors.accent

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                VStack(spacing: 22) {
                    heroSection
                    progressStudioCard
                    if !userStatus.isPremium {
                        momentumCard
                        modulesSection
                    }
                    primaryCTA
                    secondaryCTA
                }
                .frame(maxWidth: 760)
                .padding(.horizontal, 22)
                .padding(.top, 26)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(light: .rgb(217, 251, 247), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(244, 240, 229), dark: LegitimaColors.darkBackgroundMid),
                    Color(light: .rgb(234, 241, 246), dark: LegitimaColors.darkBackgroundBottom)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(light: UIColor.white.withAlphaComponent(0.4), dark: UIColor.white.withAlphaComponent(0.04)))
                .frame(width: 280, height: 280)
                .blur(radius: 16)
                .offset(x: -120, y: -240)

            RoundedRectangle(cornerRadius: 120)
                .fill(Color(light: .rgb(250, 231, 214, alpha: 0.45), dark: .rgb(45, 38, 30, alpha: 0.45)))
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(18))
                .blur(radius: 20)
                .offset(x: 130, y: -220)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(userStatus.isPremium ? "PREMIUM ACTIF" : "PREMIUM")
                    .font(.caption.weight(.bold))
                    .foregroundColor(premiumInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(LegitimaColors.surface)
                    .clipShape(Capsule())

                Spacer(minLength: 0)

                Text("\(completedCount)/6")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(buttonColor)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(userStatus.isPremium ? "Premium activé" : "La suite de votre préparation est prête")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundColor(primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                JustifiedText(
                    userStatus.isPremium
                    ? "Vos modules sont prêts. Vous pouvez maintenant entrer dans la préparation guidée."
                    : "Vous avez déjà une lecture stratégique. Le premium sert maintenant à la transformer en réponses, en récit et en posture d’entretien.",
                    color: secondaryText
                )
            }

            heroInsightCard
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    Color(light: UIColor.white.withAlphaComponent(0.94), dark: .rgb(36, 43, 44)),
                    Color(light: .rgb(244, 252, 250, alpha: 0.92), dark: .rgb(33, 40, 41))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: LegitimaRadius.hero)
                .stroke(Color(light: UIColor.white.withAlphaComponent(0.75), dark: UIColor.white.withAlphaComponent(0.08)), lineWidth: 1.2)
        )
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.hero))
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 12)
    }

    private var heroInsightCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(light: .rgb(227, 245, 236), dark: .rgb(30, 44, 37)))
                    .frame(width: 46, height: 46)

                Image(systemName: userStatus.isPremium ? "sparkles" : "lightbulb.fill")
                    .font(.headline)
                    .foregroundColor(accentText)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(userStatus.isPremium ? "Moment clé" : "Lecture clé")
                    .font(.caption.weight(.bold))
                    .foregroundColor(accentText)

                JustifiedText(
                    userStatus.isPremium
                    ? "Le plus utile maintenant est de transformer votre analyse en réponses claires, en récit cohérent et en posture d’entretien."
                    : "Le premium ne vous fait pas repartir de zéro. Il s’appuie sur votre analyse déjà obtenue pour vous faire avancer plus vite.",
                    color: primaryText
                )
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(LegitimaColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: LegitimaRadius.hero)
                .stroke(LegitimaColors.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.hero))
    }

    private var progressStudioCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Feuille de route")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryText)

                    JustifiedText(
                        userStatus.isPremium ? "Voici les étapes que vous allez travailler maintenant." : "Voici ce qui est déjà acquis et ce que la suite va vous aider à construire.",
                        color: secondaryText
                    )
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(completedCount)")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundColor(accentText)

                    Text("étapes actives")
                        .font(.caption)
                        .foregroundColor(secondaryText)
                }
            }

            VStack(spacing: 14) {
                ForEach(Array(stepRows.enumerated()), id: \.element.title) { index, step in
                    timelineRow(step: step, isLast: index == stepRows.count - 1)
                }
            }
        }
        .padding(22)
        .background(LegitimaColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: LegitimaRadius.hero)
                .stroke(Color(light: UIColor.white.withAlphaComponent(0.72), dark: UIColor.white.withAlphaComponent(0.07)), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.hero))
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    private var momentumCard: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text(userStatus.isPremium ? "Ce que vous allez construire maintenant" : "Ce que le premium ajoute à votre analyse")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryText)

                JustifiedText(
                    userStatus.isPremium
                    ? "Réponses difficiles, zones sensibles, fil conducteur, posture finale : tout sert maintenant à rendre votre parcours plus simple à raconter et à défendre."
                    : "Le premium ajoute une vraie mise en forme. Vous ne collectez plus seulement des idées : vous les transformez en préparation utile.",
                    color: primaryText
                )
            }

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                momentumBubble(text: "Réponses")
                momentumBubble(text: "Récit")
                momentumBubble(text: "Posture")
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [
                    Color(light: UIColor.white.withAlphaComponent(0.84), dark: .rgb(36, 43, 44)),
                    Color(light: .rgb(250, 244, 231, alpha: 0.9), dark: .rgb(41, 39, 30))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.hero))
    }

    private func momentumBubble(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(premiumInk)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(LegitimaColors.surface)
            .clipShape(Capsule())
    }

    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(userStatus.isPremium ? "Modules premium" : "Ce que la préparation complète débloque")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(primaryText)

            LazyVStack(spacing: 14) {
                ForEach(moduleCards, id: \.title) { module in
                    moduleCard(module)
                }
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
            HStack {
                    Text(userStatus.isPremium ? "Commencer la préparation guidée" : "Débloquer maintenant la préparation complète")
                    .fontWeight(.bold)

                Spacer(minLength: 0)

                Image(systemName: "arrow.right")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [
                        buttonColor,
                        Color(light: .rgb(26, 88, 91), dark: .rgb(35, 96, 99))
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
            .shadow(color: buttonColor.opacity(0.28), radius: 12, x: 0, y: 8)
        }
        .navigationDestination(isPresented: $navigateToPremiumFlow) {
            PremiumInterviewEntryScreen()
        }
    }

    private var secondaryCTA: some View {
        VStack(spacing: 12) {
            if !userStatus.isPremium, userStatus.canStartAnalysis {
                Button(action: {
                    onRestartAnalysis()
                }) {
                        Text("Relancer une nouvelle analyse")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(accentText)
                }
            }

            Button(action: {
                onBackToResults()
            }) {
                Text("Revenir à mes résultats")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(accentText)
            }
        }
    }

    private var completedCount: Int {
        userStatus.isPremium ? 4 : 3
    }

    private var stepRows: [ProgressStepRow] {
        [
            ProgressStepRow(title: "Compréhension stratégique", note: "Lecture de base obtenue", isCompleted: true),
            ProgressStepRow(title: "Relecture du parcours", note: "Logique du parcours déjà dégagée", isCompleted: true),
            ProgressStepRow(title: "Zones sensibles", note: "Première lecture déjà posée", isCompleted: true),
            ProgressStepRow(title: "Réponse à une objection", note: userStatus.isPremium ? "Maintenant accessible" : "Débloqué avec le premium", isCompleted: userStatus.isPremium),
            ProgressStepRow(title: "Fil conducteur", note: "Récit global à formuler", isCompleted: false),
            ProgressStepRow(title: "Posture d’entretien", note: "Dernière mise en confiance", isCompleted: false)
        ]
    }

    private var moduleCards: [PremiumModuleCard] {
        [
            PremiumModuleCard(
                icon: "bubble.left.and.bubble.right.fill",
                eyebrow: "RÉPONSES DIFFICILES",
                title: "Objections",
                description: "Préparez une réponse plus claire et plus solide à une question sensible.",
                accent: Color(light: .rgb(255, 239, 221), dark: .rgb(46, 39, 28)),
                tone: Color(light: .rgb(138, 86, 45), dark: .rgb(222, 170, 120)),
                isUnlocked: userStatus.isPremium
            ),
            PremiumModuleCard(
                icon: "checkmark.seal.fill",
                eyebrow: "APPUIS CRÉDIBLES",
                title: "Légitimité",
                description: "Transformez vos faits forts en appuis simples, crédibles et rassurants.",
                accent: Color(light: .rgb(228, 239, 253), dark: .rgb(30, 38, 49)),
                tone: Color(light: .rgb(52, 89, 143), dark: .rgb(150, 180, 225)),
                isUnlocked: userStatus.isPremium
            ),
            PremiumModuleCard(
                icon: "point.3.connected.trianglepath.dotted",
                eyebrow: "RÉCIT GLOBAL",
                title: "Fil conducteur",
                description: "Assemblez un récit global simple, cohérent et défendable de votre trajectoire.",
                accent: Color(light: .rgb(255, 247, 225), dark: .rgb(45, 41, 29)),
                tone: Color(light: .rgb(132, 104, 40), dark: .rgb(215, 185, 110)),
                isUnlocked: userStatus.isPremium
            ),
            PremiumModuleCard(
                icon: "sparkles",
                eyebrow: "POSTURE FINALE",
                title: "Préparation entretien",
                description: "Arrivez en entretien avec une posture plus claire, plus stable et plus confiante.",
                accent: Color(light: .rgb(242, 233, 252), dark: .rgb(39, 33, 48)),
                tone: Color(light: .rgb(108, 73, 138), dark: .rgb(190, 160, 220)),
                isUnlocked: userStatus.isPremium
            )
        ]
    }

    private func timelineRow(step: ProgressStepRow, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(step.isCompleted ? buttonColor : LegitimaColors.field)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(step.isCompleted ? buttonColor : secondaryText.opacity(0.35), lineWidth: 1.3)
                        )

                    Image(systemName: step.isCompleted ? "checkmark" : "circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundColor(step.isCompleted ? .white : secondaryText.opacity(0.35))
                }

                if !isLast {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(step.isCompleted ? buttonColor.opacity(0.45) : secondaryText.opacity(0.18))
                        .frame(width: 2, height: 32)
                        .padding(.top, 4)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(step.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(primaryText)

                Text(step.note)
                    .font(.caption)
                    .foregroundColor(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if step.isCompleted {
                Text("prêt")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(accentText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color(light: .rgb(233, 247, 241), dark: .rgb(30, 45, 38)))
                    .clipShape(Capsule())
            }
        }
    }

    private func moduleCard(_ module: PremiumModuleCard) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: LegitimaRadius.card)
                    .fill(Color(light: UIColor.white.withAlphaComponent(0.56), dark: UIColor.white.withAlphaComponent(0.08)))
                    .frame(width: 54, height: 54)

                Image(systemName: module.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(module.tone)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(module.eyebrow)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(module.tone)

                HStack(spacing: 8) {
                    Text(module.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryText)

                    if !module.isUnlocked {
                        Text("bientôt")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(module.tone)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(LegitimaColors.surface)
                            .clipShape(Capsule())
                    }
                }

                JustifiedText(
                    module.description,
                    color: primaryText.opacity(module.isUnlocked ? 1 : 0.84)
                )
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(module.accent.opacity(module.isUnlocked ? 1 : 0.74))
        .overlay(
            RoundedRectangle(cornerRadius: LegitimaRadius.hero)
                .stroke(Color(light: UIColor.white.withAlphaComponent(0.65), dark: UIColor.white.withAlphaComponent(0.07)), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.hero))
        .shadow(color: Color.black.opacity(0.045), radius: 10, x: 0, y: 6)
        .opacity(module.isUnlocked ? 1 : 0.96)
    }
}

private struct ProgressStepRow {
    let title: String
    let note: String
    let isCompleted: Bool
}

private struct PremiumModuleCard {
    let icon: String
    let eyebrow: String
    let title: String
    let description: String
    let accent: Color
    let tone: Color
    let isUnlocked: Bool
}

struct ProgressionScreen_Previews: PreviewProvider {
    static var previews: some View {
        ProgressionScreen(onBackToResults: {}, onRestartAnalysis: {})
            .environmentObject(UserStatus())
    }
}
