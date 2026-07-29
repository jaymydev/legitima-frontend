import SwiftUI

struct LeanResultScreen: View {
    @EnvironmentObject private var userStatus: UserStatus
    @EnvironmentObject private var purchaseManager: PremiumPurchaseManager
    @EnvironmentObject private var interviewPreparationStore: InterviewPreparationStore
    @EnvironmentObject private var preparationStore: LocalPreparationStore
    let response: AnalysisResponse
    let onContinue: () -> Void
    let onRestartAnalysis: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 246 / 255, green: 252 / 255, blue: 249 / 255),
                    Color(red: 238 / 255, green: 246 / 255, blue: 247 / 255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    resultHeroSection

                    if let days = interviewCountdownDays {
                        interviewCountdownCard(days: days)
                    }

                    if userStatus.hasSeenPremiumUnlock {
                        premiumUnlockBanner
                    }

                    sectionCard(
                        icon: "lightbulb.fill",
                        title: "Compréhension stratégique",
                        content: response.analysis.strategic_reading + "\n\n" + response.analysis.dominant_competencies,
                        backgroundColor: Color(red: 227 / 255, green: 245 / 255, blue: 236 / 255)
                    )

                    if !userStatus.isPremium {
                        HStack {
                            Rectangle().frame(height: 1)
                            Text("POUR ALLER PLUS LOIN").font(.caption.bold())
                            Rectangle().frame(height: 1)
                        }
                        .foregroundColor(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255).opacity(0.35))
                    }

                    sectionCard(
                        icon: "arrow.triangle.branch",
                        title: "Relecture structurée du parcours",
                        content: response.analysis.career_logic + "\n\n" + response.narrative.core_thread,
                        backgroundColor: Color(red: 255 / 255, green: 247 / 255, blue: 225 / 255)
                    )

                    sectionCard(
                        icon: "exclamationmark.bubble.fill",
                        title: "Requalification des zones sensibles",
                        content: response.sensitive_reframing.identified_fragilities + "\n\n" + response.sensitive_reframing.strategic_reinterpretation + "\n\n" + response.sensitive_reframing.rational_reframing,
                        backgroundColor: Color(red: 255 / 255, green: 236 / 255, blue: 228 / 255)
                    )

                    if userStatus.isPremium {
                        premiumPreparationCard
                    } else {
                        sectionCard(
                            icon: "shield.fill",
                            title: "Anticipation des objections",
                            content: "La préparation complète génère les objections probables de votre interlocuteur et des réponses défendables, construites à partir de votre fil conducteur.",
                            backgroundColor: Color(red: 255 / 255, green: 239 / 255, blue: 221 / 255),
                            isLocked: true
                        )

                        sectionCard(
                            icon: "checkmark.seal.fill",
                            title: "Ancrage de légitimité",
                            content: "La préparation complète ancre votre légitimité : des arguments objectifs pour assumer votre parcours face à votre interlocuteur.",
                            backgroundColor: Color(red: 228 / 255, green: 239 / 255, blue: 253 / 255),
                            isLocked: true
                        )

                        sectionCard(
                            icon: "sparkles",
                            title: "Synthèse stratégique finale",
                            content: "La préparation complète se termine par une synthèse actionnable : points à faire passer et plan d'action pour le jour J.",
                            backgroundColor: Color(red: 242 / 255, green: 233 / 255, blue: 252 / 255),
                            isLocked: true
                        )

                        PremiumUnlockCard(
                            purchaseManager: purchaseManager,
                            onUnlocked: {
                                userStatus.activatePremium()
                                onContinue()
                            }
                        )

                        freeRetrySection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
        }
        .task {
            await purchaseManager.loadProduct()
        }
    }

    private var freeRetrySection: some View {
        VStack(spacing: 10) {
            Button(action: onRestartAnalysis) {
                Label("Refaire une analyse gratuite", systemImage: "arrow.counterclockwise")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))
                    .background(Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255).opacity(0.4), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!userStatus.canStartAnalysis)
            .opacity(userStatus.canStartAnalysis ? 1 : 0.5)

            Text(userStatus.freeQuotaLabel)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 4)
    }

    private var interviewCountdownDays: Int? {
        guard let date = preparationStore.snapshot.interviewDate else { return nil }
        return InterviewCountdown.daysUntil(date)
    }

    private func interviewCountdownCard(days: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "calendar")
                .font(.title3)
                .foregroundColor(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))

            VStack(alignment: .leading, spacing: 6) {
                Text(InterviewCountdown.label(daysUntil: days))
                    .font(.headline)
                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                Text(
                    userStatus.isPremium
                        ? "Gardez votre préparation à portée de main pour la révision finale."
                        : "Transformez cette lecture en réponses prêtes avant le jour J."
                )
                .font(.subheadline)
                .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255).opacity(0.2), lineWidth: 1)
        )
    }

    private var premiumPreparationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("VOTRE PRÉPARATION PREMIUM", systemImage: "crown.fill")
                .font(.caption.bold())
                .foregroundColor(Color(red: 185 / 255, green: 132 / 255, blue: 43 / 255))

            if let result = interviewPreparationStore.saved.result {
                Text(result.title)
                    .font(.headline)
                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                Text(result.summary)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Votre préparation guidée vous attend")
                    .font(.headline)
                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                Text("Quelques questions ciblées sur votre entretien, puis nous générons vos réponses aux objections, votre ancrage de légitimité et votre synthèse finale.")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: onContinue) {
                Text(premiumPreparationButtonTitle)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(red: 185 / 255, green: 132 / 255, blue: 43 / 255).opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var premiumPreparationButtonTitle: String {
        if interviewPreparationStore.saved.result != nil {
            return "Revoir ma préparation"
        }
        return interviewPreparationStore.saved.answers.isEmpty
            ? "Commencer ma préparation"
            : "Reprendre ma préparation"
    }

    private var resultHeroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LECTURE STRATÉGIQUE")
                .font(.caption.weight(.bold))
                .foregroundColor(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.82))
                .clipShape(Capsule())

            Text("Votre parcours commence à prendre forme")
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

            Text("Vous avez maintenant une première lecture solide. La préparation complète sert à transformer cette matière en récit, en réponses et en posture d’entretien.")
                .font(.subheadline)
                .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
                .fixedSize(horizontal: false, vertical: true)

            insightHighlightCard
        }
    }

    private var insightHighlightCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 227 / 255, green: 245 / 255, blue: 236 / 255))
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.headline)
                    .foregroundColor(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Le point clé")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))

                Text(heroInsightText)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.9))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var heroInsightText: String {
        let trimmed = response.analysis.strategic_reading.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Votre analyse pose déjà une base de cohérence. La suite sert à la rendre plus facile à expliquer et à défendre."
        }

        let cleaned = trimmed.replacingOccurrences(of: "\n", with: " ")
        if cleaned.count <= 180 {
            return cleaned
        }

        let cutoffIndex = cleaned.index(cleaned.startIndex, offsetBy: 177)
        return String(cleaned[..<cutoffIndex]) + "..."
    }

    private var premiumUnlockBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.title3)
                .foregroundColor(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))

            VStack(alignment: .leading, spacing: 6) {
                Text("Préparation complète activée")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                Text("Votre accès premium est actif. Reprenez votre préparation guidée quand vous êtes prêt.")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
            }

            Spacer(minLength: 0)

            Button(action: {
                userStatus.dismissPremiumUnlock()
            }) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
                    .padding(8)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 226 / 255, green: 247 / 255, blue: 239 / 255))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255).opacity(0.18), lineWidth: 1)
        )
    }

    private func sectionCard(
        icon: String,
        title: String,
        content: String,
        backgroundColor: Color,
        isLocked: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                    }

                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
                }

                Text(content)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 62 / 255, green: 67 / 255, blue: 67 / 255))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .opacity(isLocked ? 0.65 : 1)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct LeanResultScreen_Previews: PreviewProvider {
    static var previews: some View {
        LeanResultScreen(
            response: AnalysisResponse(
                analysis: AnalysisSection(
                    strategic_reading: "Lecture stratégique",
                    dominant_competencies: "Compétences dominantes",
                    career_logic: "Logique de parcours"
                ),
                sensitive_reframing: SensitiveSection(
                    identified_fragilities: "Fragilités identifiées",
                    strategic_reinterpretation: "Réinterprétation stratégique",
                    rational_reframing: "Reformulation rationnelle"
                ),
                narrative: NarrativeSection(
                    core_thread: "Fil narratif central",
                    positioning_statement: "Positionnement final"
                ),
                interview_preparation: InterviewSection(
                    probable_objections: "Objections probables",
                    structured_answers: "Réponses structurées"
                ),
                legitimacy_anchor: LegitimacySection(
                    objective_strength: "Forces objectives",
                    final_alignment_statement: "Alignement final"
                )
            ),
            onContinue: {},
            onRestartAnalysis: {}
        )
        .environmentObject(UserStatus())
        .environmentObject(PremiumPurchaseManager())
        .environmentObject(InterviewPreparationStore())
        .environmentObject(LocalPreparationStore())
    }
}
