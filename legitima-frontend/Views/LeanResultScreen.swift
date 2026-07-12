import SwiftUI

struct LeanResultScreen: View {
    @EnvironmentObject private var userStatus: UserStatus
    let response: AnalysisResponse
    let onContinue: () -> Void
    private let lockedPreviewText = """
    Disponible dans la préparation complète.
    Débloquez la suite pour structurer votre récit et préparer vos réponses face au recruteur.
    """

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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Votre lecture stratégique")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                        Text("Une synthèse claire pour consolider votre récit et votre légitimité.")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
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

                    sectionCard(
                        icon: "shield.fill",
                        title: "Anticipation des objections",
                        content: userStatus.isPremium
                            ? response.interview_preparation.probable_objections + "\n\n" + response.interview_preparation.structured_answers
                            : lockedPreviewText,
                        backgroundColor: Color(red: 255 / 255, green: 239 / 255, blue: 221 / 255),
                        isLocked: !userStatus.isPremium
                    )

                    sectionCard(
                        icon: "checkmark.seal.fill",
                        title: "Ancrage de légitimité",
                        content: userStatus.isPremium
                            ? response.legitimacy_anchor.objective_strength + "\n\n" + response.legitimacy_anchor.final_alignment_statement
                            : lockedPreviewText,
                        backgroundColor: Color(red: 228 / 255, green: 239 / 255, blue: 253 / 255),
                        isLocked: !userStatus.isPremium
                    )

                    sectionCard(
                        icon: "sparkles",
                        title: "Synthèse stratégique finale",
                        content: userStatus.isPremium
                            ? unlockedSummary
                            : lockedPreviewText,
                        backgroundColor: Color(red: 242 / 255, green: 233 / 255, blue: 252 / 255),
                        isLocked: !userStatus.isPremium
                    )

                    Button(action: {
                        onContinue()
                    }) {
                        Text(userStatus.isPremium ? "Continuer ma préparation complète" : "Continuer")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.top, 8)

                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
        }
    }

    private var unlockedSummary: String {
        [
            response.analysis.strategic_reading,
            response.narrative.positioning_statement,
            response.legitimacy_anchor.final_alignment_statement
        ]
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .joined(separator: "\n\n")
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

                Text("Vos contenus premium sont maintenant déverrouillés. Consultez-les librement avant de poursuivre la préparation complète.")
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
            onContinue: {}
        )
        .environmentObject(UserStatus())
    }
}
