import SwiftUI

struct LeanResultScreen: View {
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
                        content: lockedPreviewText,
                        backgroundColor: Color(red: 255 / 255, green: 239 / 255, blue: 221 / 255),
                        isLocked: true
                    )

                    sectionCard(
                        icon: "checkmark.seal.fill",
                        title: "Ancrage de légitimité",
                        content: lockedPreviewText,
                        backgroundColor: Color(red: 228 / 255, green: 239 / 255, blue: 253 / 255),
                        isLocked: true
                    )

                    sectionCard(
                        icon: "sparkles",
                        title: "Synthèse stratégique finale",
                        content: lockedPreviewText,
                        backgroundColor: Color(red: 242 / 255, green: 233 / 255, blue: 252 / 255),
                        isLocked: true
                    )

                    Button(action: {
                        onContinue()
                    }) {
                        Text("Continuer")
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

#Preview {
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
    }
}
