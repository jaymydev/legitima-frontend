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
                    Color(light: .rgb(246, 252, 249), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(238, 246, 247), dark: LegitimaColors.darkBackgroundBottom)
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
                        backgroundColor: Color(light: .rgb(227, 245, 236), dark: .rgb(30, 44, 37))
                    )

                    if !userStatus.isPremium {
                        HStack {
                            Rectangle().frame(height: 1)
                            Text("POUR ALLER PLUS LOIN").font(.caption.bold())
                            Rectangle().frame(height: 1)
                        }
                        .foregroundColor(LegitimaColors.accent.opacity(0.35))
                    }

                    sectionCard(
                        icon: "arrow.triangle.branch",
                        title: "Relecture structurée du parcours",
                        content: response.analysis.career_logic + "\n\n" + response.narrative.core_thread,
                        backgroundColor: Color(light: .rgb(255, 247, 225), dark: .rgb(45, 41, 29))
                    )

                    sectionCard(
                        icon: "exclamationmark.bubble.fill",
                        title: "Requalification des zones sensibles",
                        content: response.sensitive_reframing.identified_fragilities + "\n\n" + response.sensitive_reframing.strategic_reinterpretation + "\n\n" + response.sensitive_reframing.rational_reframing,
                        backgroundColor: Color(light: .rgb(255, 236, 228), dark: .rgb(46, 36, 31))
                    )

                    if userStatus.isPremium {
                        premiumPreparationCard
                    } else {
                        sectionCard(
                            icon: "shield.fill",
                            title: "Anticipation des objections",
                            content: objectionTeaserContent,
                            backgroundColor: Color(light: .rgb(255, 239, 221), dark: .rgb(46, 39, 28)),
                            isLocked: true
                        )

                        sectionCard(
                            icon: "checkmark.seal.fill",
                            title: "Ancrage de légitimité",
                            content: "La préparation complète ancre votre légitimité : des arguments objectifs pour assumer votre parcours face à votre interlocuteur.",
                            backgroundColor: Color(light: .rgb(228, 239, 253), dark: .rgb(30, 38, 49)),
                            isLocked: true
                        )

                        sectionCard(
                            icon: "sparkles",
                            title: "Synthèse stratégique finale",
                            content: "La préparation complète se termine par une synthèse actionnable : points à faire passer et plan d'action pour le jour J.",
                            backgroundColor: Color(light: .rgb(242, 233, 252), dark: .rgb(39, 33, 48)),
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
                    .foregroundColor(LegitimaColors.accent)
                    .background(LegitimaColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(LegitimaColors.accent.opacity(0.4), lineWidth: 1)
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

    /// Locked-card copy: quotes the user's own probable objection when the free
    /// analysis surfaced one, and adds urgency when an interview date is set.
    private var objectionTeaserContent: String {
        guard let objection = ObjectionTeaser.firstObjection(
            from: response.interview_preparation.probable_objections
        ) else {
            return "La préparation complète génère les objections probables de votre interlocuteur et des réponses défendables, construites à partir de votre fil conducteur."
        }

        if let days = interviewCountdownDays {
            return "\(InterviewCountdown.label(daysUntil: days)). Cette objection probable n'a pas encore de réponse préparée : « \(objection) »\n\nLa préparation complète construit vos réponses défendables avant le jour J."
        }

        return "Une objection probable pour votre profil : « \(objection) »\n\nLa préparation complète construit la réponse défendable, et couvre les autres objections identifiées."
    }

    private func interviewCountdownCard(days: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "calendar")
                .font(.title3)
                .foregroundColor(LegitimaColors.accent)

            VStack(alignment: .leading, spacing: 6) {
                Text(InterviewCountdown.label(daysUntil: days))
                    .font(.headline)
                    .foregroundColor(LegitimaColors.ink)

                Text(
                    userStatus.isPremium
                        ? "Gardez votre préparation à portée de main pour la révision finale."
                        : "Transformez cette lecture en réponses prêtes avant le jour J."
                )
                .font(.subheadline)
                .foregroundColor(LegitimaColors.muted)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LegitimaColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(LegitimaColors.accent.opacity(0.2), lineWidth: 1)
        )
    }

    private var premiumPreparationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("VOTRE PRÉPARATION PREMIUM", systemImage: "crown.fill")
                .font(.caption.bold())
                .foregroundColor(LegitimaColors.gold)

            if let result = interviewPreparationStore.saved.result {
                Text(result.title)
                    .font(.headline)
                    .foregroundColor(LegitimaColors.ink)

                Text(result.summary)
                    .font(.subheadline)
                    .foregroundColor(LegitimaColors.muted)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Votre préparation guidée vous attend")
                    .font(.headline)
                    .foregroundColor(LegitimaColors.ink)

                Text("Quelques questions ciblées sur votre entretien, puis nous générons vos réponses aux objections, votre ancrage de légitimité et votre synthèse finale.")
                    .font(.subheadline)
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: onContinue) {
                Text(premiumPreparationButtonTitle)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LegitimaColors.accentSurface)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LegitimaColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(LegitimaColors.gold.opacity(0.25), lineWidth: 1)
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
                .foregroundColor(LegitimaColors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(LegitimaColors.surface)
                .clipShape(Capsule())

            Text("Votre parcours commence à prendre forme")
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .foregroundColor(LegitimaColors.ink)

            Text("Vous avez maintenant une première lecture solide. La préparation complète sert à transformer cette matière en récit, en réponses et en posture d’entretien.")
                .font(.subheadline)
                .foregroundColor(LegitimaColors.muted)
                .fixedSize(horizontal: false, vertical: true)

            insightHighlightCard
        }
    }

    private var insightHighlightCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(light: .rgb(227, 245, 236), dark: .rgb(30, 44, 37)))
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.headline)
                    .foregroundColor(LegitimaColors.accent)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Le point clé")
                    .font(.caption.weight(.bold))
                    .foregroundColor(LegitimaColors.accent)

                Text(heroInsightText)
                    .font(.subheadline)
                    .foregroundColor(LegitimaColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(LegitimaColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LegitimaColors.hairline, lineWidth: 1)
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
                .foregroundColor(LegitimaColors.accent)

            VStack(alignment: .leading, spacing: 6) {
                Text("Préparation complète activée")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(LegitimaColors.ink)

                Text("Votre accès premium est actif. Reprenez votre préparation guidée quand vous êtes prêt.")
                    .font(.subheadline)
                    .foregroundColor(LegitimaColors.muted)
            }

            Spacer(minLength: 0)

            Button(action: {
                userStatus.dismissPremiumUnlock()
            }) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundColor(LegitimaColors.muted)
                    .padding(8)
                    .background(LegitimaColors.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(light: .rgb(226, 247, 239), dark: .rgb(28, 44, 38)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(LegitimaColors.accent.opacity(0.18), lineWidth: 1)
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
                .foregroundColor(LegitimaColors.ink)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                    }

                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(LegitimaColors.ink)
                }

                Text(content)
                    .font(.subheadline)
                    .foregroundColor(LegitimaColors.body)
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
                .stroke(LegitimaColors.hairline, lineWidth: 1)
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
