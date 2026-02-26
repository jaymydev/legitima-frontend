import SwiftUI

struct FilConducteurScreen: View {
    @State private var resumeGlobal = ""
    @State private var positionnementActuel = ""
    @State private var logiqueEvolution = ""
    @State private var parsedResponse: AnalysisResponse?
    private let iaService = IAService()
    private let jsonBuilder = JSONBuilder()

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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Construire votre fil conducteur")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                        Text("Structurer un récit cohérent et défendable de votre parcours.")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    cardView(
                        title: "Résumé stratégique (5 à 7 lignes)",
                        description: "Racontez votre parcours comme une progression logique et non comme une succession d’événements.",
                        text: $resumeGlobal,
                        placeholder: "– Point de départ :\n– Évolution clé :\n– Compétences consolidées :\n– Positionnement actuel :",
                        warning: resumeGlobal.count < 150 ? "Essayez d’atteindre au moins 150 caractères pour formuler un récit structuré." : nil
                    )

                    cardView(
                        title: "Positionnement actuel",
                        description: "Définissez clairement votre posture professionnelle aujourd’hui.",
                        text: $positionnementActuel,
                        placeholder: "– Rôle cible :\n– Valeur ajoutée principale :\n– Différenciation :",
                        warning: positionnementActuel.count < 50 ? "Essayez d’atteindre au moins 50 caractères pour clarifier votre positionnement." : nil
                    )

                    cardView(
                        title: "Logique d’évolution",
                        description: "Expliquez pourquoi vos choix successifs forment une continuité stratégique.",
                        text: $logiqueEvolution,
                        placeholder: "– Décision clé 1 :\n– Décision clé 2 :\n– Cohérence globale :",
                        warning: logiqueEvolution.count < 50 ? "Essayez d’atteindre au moins 50 caractères pour expliciter la cohérence de vos choix." : nil
                    )

                    Button(action: {
                        let builtJSON = jsonBuilder.buildFilConducteurJSON(
                            resume: resumeGlobal,
                            positionnement: positionnementActuel,
                            logique: logiqueEvolution
                        )

                        iaService.analyze(json: builtJSON) { result in
                            if let data = result.data(using: .utf8) {
                                let decoder = JSONDecoder()
                                if let decoded = try? decoder.decode(AnalysisResponse.self, from: data) {
                                    parsedResponse = decoded
                                }
                            }
                        }
                    }) {
                        Text("Analyser mon fil conducteur")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 43/255, green: 111/255, blue: 113/255))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 12)

                    if let response = parsedResponse {
                        VStack(spacing: 20) {
                            analysisCard(
                                icon: "lightbulb.fill",
                                title: "Compréhension stratégique",
                                content: response.analysis.strategic_reading + "\n\n" + response.analysis.dominant_competencies,
                                backgroundColor: Color.green.opacity(0.12)
                            )

                            analysisCard(
                                icon: "arrow.triangle.branch",
                                title: "Relecture structurée du parcours",
                                content: response.analysis.career_logic + "\n\n" + response.narrative.core_thread,
                                backgroundColor: Color.yellow.opacity(0.15)
                            )

                            analysisCard(
                                icon: "shield.fill",
                                title: "Anticipation des objections",
                                content: response.interview_preparation.probable_objections + "\n\n" + response.interview_preparation.structured_answers,
                                backgroundColor: Color.orange.opacity(0.15)
                            )

                            analysisCard(
                                icon: "checkmark.seal.fill",
                                title: "Ancrage de légitimité",
                                content: response.legitimacy_anchor.objective_strength + "\n\n" + response.legitimacy_anchor.final_alignment_statement,
                                backgroundColor: Color.blue.opacity(0.12)
                            )

                            analysisCard(
                                icon: "sparkles",
                                title: "Synthèse stratégique finale",
                                content:
"""
Vous ne présentez pas un parcours fragmenté.

Vous présentez une trajectoire construite par l’expérience,
renforcée par l’analyse,
et alignée avec votre positionnement actuel.

Votre parcours est défendable.
Il est cohérent.
Il est légitime.
""",
                                backgroundColor: Color.purple.opacity(0.18)
                            )
                        }
                        .animation(.easeInOut(duration: 0.3), value: parsedResponse)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
        }
    }

    private func cardView(
        title: String,
        description: String,
        text: Binding<String>,
        placeholder: String,
        warning: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

            Text(description)
                .font(.subheadline)
                .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))

            PlaceholderTextEditor(
                placeholder: placeholder,
                text: text,
                primaryColor: Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255),
                minHeight: 120
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let warning {
                Text(warning)
                    .font(.caption)
                    .foregroundColor(Color.orange)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private func analysisCard(
        icon: String,
        title: String,
        content: String,
        backgroundColor: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .bold()

                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    FilConducteurScreen()
}

extension AnalysisResponse: Equatable {
    static func == (lhs: AnalysisResponse, rhs: AnalysisResponse) -> Bool {
        lhs.analysis == rhs.analysis &&
        lhs.sensitive_reframing == rhs.sensitive_reframing &&
        lhs.narrative == rhs.narrative &&
        lhs.interview_preparation == rhs.interview_preparation &&
        lhs.legitimacy_anchor == rhs.legitimacy_anchor
    }
}

extension AnalysisSection: Equatable {
    static func == (lhs: AnalysisSection, rhs: AnalysisSection) -> Bool {
        lhs.strategic_reading == rhs.strategic_reading &&
        lhs.dominant_competencies == rhs.dominant_competencies &&
        lhs.career_logic == rhs.career_logic
    }
}

extension SensitiveSection: Equatable {
    static func == (lhs: SensitiveSection, rhs: SensitiveSection) -> Bool {
        lhs.identified_fragilities == rhs.identified_fragilities &&
        lhs.strategic_reinterpretation == rhs.strategic_reinterpretation &&
        lhs.rational_reframing == rhs.rational_reframing
    }
}

extension NarrativeSection: Equatable {
    static func == (lhs: NarrativeSection, rhs: NarrativeSection) -> Bool {
        lhs.core_thread == rhs.core_thread &&
        lhs.positioning_statement == rhs.positioning_statement
    }
}

extension InterviewSection: Equatable {
    static func == (lhs: InterviewSection, rhs: InterviewSection) -> Bool {
        lhs.probable_objections == rhs.probable_objections &&
        lhs.structured_answers == rhs.structured_answers
    }
}

extension LegitimacySection: Equatable {
    static func == (lhs: LegitimacySection, rhs: LegitimacySection) -> Bool {
        lhs.objective_strength == rhs.objective_strength &&
        lhs.final_alignment_statement == rhs.final_alignment_statement
    }
}
