import SwiftUI

struct LeanResultScreen: View {
    @EnvironmentObject private var interviewPreparationStore: InterviewPreparationStore
    @EnvironmentObject private var preparationStore: LocalPreparationStore
    let response: AnalysisResponse
    let onContinue: () -> Void
    let onRestartAnalysis: () -> Void

    /// Only the first three cards stagger in. Beyond the fold the movement
    /// would be unseen, and this screen is read, not performed.
    @State private var revealStage = 0

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
                        .revealed(revealStage >= 1)

                    if let days = interviewCountdownDays {
                        interviewCountdownCard(days: days)
                            .revealed(revealStage >= 2)
                    }

                    sectionCard(
                        icon: "lightbulb.fill",
                        title: "Compréhension stratégique",
                        content: response.analysis.strategic_reading + "\n\n" + response.analysis.dominant_competencies,
                        backgroundColor: Color(light: .rgb(227, 245, 236), dark: .rgb(30, 44, 37))
                    )
                    .revealed(revealStage >= 3)

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

                    sectionCard(
                        icon: "shield.fill",
                        title: "Anticipation des objections",
                        content: response.interview_preparation.probable_objections + "\n\n" + response.interview_preparation.structured_answers,
                        backgroundColor: Color(light: .rgb(255, 239, 221), dark: .rgb(46, 39, 28))
                    )

                    sectionCard(
                        icon: "checkmark.seal.fill",
                        title: "Ancrage de légitimité",
                        content: response.legitimacy_anchor.objective_strength + "\n\n" + response.legitimacy_anchor.final_alignment_statement,
                        backgroundColor: Color(light: .rgb(228, 239, 253), dark: .rgb(30, 38, 49))
                    )

                    sectionCard(
                        icon: "sparkles",
                        title: "Synthèse stratégique",
                        content: response.narrative.positioning_statement,
                        backgroundColor: Color(light: .rgb(242, 233, 252), dark: .rgb(39, 33, 48))
                    )

                    HStack {
                        Rectangle().frame(height: 1)
                        Text("LA SUITE").font(.caption.bold())
                        Rectangle().frame(height: 1)
                    }
                    .foregroundColor(LegitimaColors.accent.opacity(0.35))

                    guidedPreparationCard

                    restartSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            for stage in 1...3 {
                withAnimation(LegitimaMotion.reveal.delay(LegitimaMotion.revealDelay(stage - 1))) {
                    revealStage = stage
                }
            }
        }
    }

    /// Reachable from every state of the result screen. It is also the only
    /// way back to the CV import, which lives in the onboarding form.
    private var restartSection: some View {
        Button(action: onRestartAnalysis) {
            Label("Reprendre mon parcours et relancer l'analyse", systemImage: "arrow.counterclockwise")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(LegitimaColors.accent)
                .background(LegitimaColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: LegitimaRadius.control)
                        .stroke(LegitimaColors.accent.opacity(0.4), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))
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
                .foregroundColor(LegitimaColors.accent)

            VStack(alignment: .leading, spacing: 6) {
                Text(InterviewCountdown.label(daysUntil: days))
                    .font(.headline)
                    .foregroundColor(LegitimaColors.ink)

                JustifiedText(
                    "Gardez votre préparation à portée de main pour la révision finale.",
                    color: LegitimaColors.muted
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LegitimaRadius.card)
                .fill(LegitimaColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LegitimaRadius.card)
                .stroke(LegitimaColors.accent.opacity(0.2), lineWidth: 1)
        )
    }

    private var guidedPreparationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("VOTRE PRÉPARATION GUIDÉE", systemImage: "point.3.connected.trianglepath.dotted")
                .font(.caption.bold())
                .foregroundColor(LegitimaColors.accent)

            if let result = interviewPreparationStore.saved.result {
                Text(result.title)
                    .font(.headline)
                    .foregroundColor(LegitimaColors.ink)

                JustifiedText(result.summary, color: LegitimaColors.muted, lineLimit: 4)
            } else {
                Text("Votre préparation guidée vous attend")
                    .font(.headline)
                    .foregroundColor(LegitimaColors.ink)

                JustifiedText(
                    "Quelques questions ciblées sur votre entretien, puis nous générons vos réponses aux objections, votre ancrage de légitimité et votre synthèse finale.",
                    color: LegitimaColors.muted
                )
            }

            Button(action: onContinue) {
                Text(guidedPreparationButtonTitle)
                    .legitimaPrimaryLabel()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: LegitimaRadius.card)
                .fill(LegitimaColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LegitimaRadius.card)
                .stroke(LegitimaColors.accent.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var guidedPreparationButtonTitle: String {
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
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundColor(LegitimaColors.ink)

            Text("Vous avez maintenant une lecture complète de votre trajectoire. La préparation guidée transforme cette matière en réponses pour un entretien précis.")
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

                JustifiedText(heroInsightText, color: LegitimaColors.ink)
            }
        }
        .padding(16)
        .background(LegitimaColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: LegitimaRadius.card)
                .stroke(LegitimaColors.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
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

    private func sectionCard(
        icon: String,
        title: String,
        content: String,
        backgroundColor: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(LegitimaColors.ink)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(LegitimaColors.ink)

                JustifiedText(content, color: LegitimaColors.body)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: LegitimaRadius.card)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LegitimaRadius.card)
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
        .environmentObject(InterviewPreparationStore())
        .environmentObject(LocalPreparationStore())
    }
}
