import SwiftUI

struct FilConducteurScreen: View {
    let onReset: () -> Void

    @State private var pointDepart = ""
    @State private var forceCentrale = ""
    @State private var logiqueEvolution = ""
    @State private var parsedResponse: AnalysisResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    private let iaService = IAService()
    private let primaryText = Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255)
    private let secondaryText = Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255)
    private let buttonColor = Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255)

    init(onReset: @escaping () -> Void = {}) {
        self.onReset = onReset
    }

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

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        headerSection
                        framingCard

                        guidedStepCard(
                            index: "1",
                            title: "Votre point de départ",
                            helper: "En une phrase simple, quel est le point de départ global de votre trajectoire ?",
                            placeholder: "Ex : J’ai construit mon parcours dans des environnements techniques exigeants, avec une montée progressive en responsabilité.",
                            text: $pointDepart,
                            minHeight: 96
                        )

                        guidedStepCard(
                            index: "2",
                            title: "La force qui relie votre parcours",
                            helper: "Choisissez l’idée centrale qui relie vos étapes entre elles.",
                            placeholder: "Ex : Ma capacité à structurer des sujets complexes et à rassurer dans des contextes instables.",
                            text: $forceCentrale,
                            minHeight: 96
                        )

                        guidedStepCard(
                            index: "3",
                            title: "Pourquoi cette évolution est logique",
                            helper: "Expliquez pourquoi l’ensemble de vos choix raconte une continuité plutôt qu’une succession d’épisodes isolés.",
                            placeholder: "Ex : Chaque étape m’a rapprochée d’un positionnement plus stratégique et plus transversal.",
                            text: $logiqueEvolution,
                            minHeight: 96
                        )

                        if shouldShowNudge {
                            nudgeCard
                        }

                        Button(action: analyzeNarrative) {
                            Text("Générer un premier fil conducteur")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(buttonColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        .padding(.top, 4)

                        if isLoading {
                            ProgressView("Analyse en cours...")
                                .padding(.top, 2)
                        }

                        if let response = parsedResponse {
                            resultSection(response)
                                .id("analysisResult")
                                .animation(.easeInOut(duration: 0.3), value: parsedResponse)
                        }

                        Button(action: onReset) {
                            Text("Relancer une analyse")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(buttonColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    .padding(.bottom, 24)
                }
                .onChange(of: parsedResponse) { _, newValue in
                    if newValue != nil {
                        withAnimation {
                            proxy.scrollTo("analysisResult", anchor: .top)
                        }
                    }
                }
            }
        }
        .alert("Erreur", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Une erreur est survenue.")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Clarifier votre fil conducteur")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(primaryText)

            Text("Après la réponse ponctuelle, clarifiez maintenant la logique globale qui relie l’ensemble de votre parcours.")
                .font(.subheadline)
                .foregroundColor(secondaryText)
        }
    }

    private var framingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Objectif de cette étape")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(primaryText)

            Text("L’écran précédent servait à préparer une réponse précise. Ici, vous travaillez autre chose : le récit d’ensemble qui donne de la cohérence à tout votre parcours.")
                .font(.subheadline)
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color.white.opacity(0.9))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var nudgeCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundColor(buttonColor)

            Text("Ne cherchez pas la formulation parfaite tout de suite. Ici, vous ne préparez pas une réponse isolée, mais la logique d’ensemble de votre parcours.")
                .font(.footnote)
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(red: 233 / 255, green: 247 / 255, blue: 241 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var shouldShowNudge: Bool {
        [pointDepart, forceCentrale, logiqueEvolution]
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .count < 60
    }

    private func guidedStepCard(
        index: String,
        title: String,
        helper: String,
        placeholder: String,
        text: Binding<String>,
        minHeight: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text(index)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(buttonColor)
                    .frame(width: 28, height: 28)
                    .background(Color(red: 233 / 255, green: 247 / 255, blue: 241 / 255))
                    .clipShape(Circle())

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryText)
            }

            Text(helper)
                .font(.subheadline)
                .foregroundColor(secondaryText)

            PlaceholderTextEditor(
                placeholder: placeholder,
                text: text,
                primaryColor: primaryText,
                minHeight: minHeight
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private func resultSection(_ response: AnalysisResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Votre première reformulation")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(primaryText)

            narrativeResultCard(
                icon: "lightbulb.fill",
                title: "Lecture stratégique",
                content: response.analysis.strategic_reading,
                backgroundColor: Color(red: 227 / 255, green: 245 / 255, blue: 236 / 255)
            )

            narrativeResultCard(
                icon: "point.3.connected.trianglepath.dotted",
                title: "Fil narratif central",
                content: response.narrative.core_thread,
                backgroundColor: Color(red: 255 / 255, green: 247 / 255, blue: 225 / 255)
            )

            narrativeResultCard(
                icon: "text.quote",
                title: "Positionnement formulé",
                content: response.narrative.positioning_statement,
                backgroundColor: Color(red: 228 / 255, green: 239 / 255, blue: 253 / 255)
            )

            narrativeResultCard(
                icon: "sparkles",
                title: "Conclusion défendable",
                content: response.legitimacy_anchor.final_alignment_statement,
                backgroundColor: Color(red: 242 / 255, green: 233 / 255, blue: 252 / 255)
            )
        }
    }

    private func narrativeResultCard(
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

    private func analyzeNarrative() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let request = AnalyzeRequest(
                    input: FilConducteurRequest(
                        meta: .init(
                            version: "1.0",
                            language: "fr",
                            target_market: "US",
                            interview_type: "recruitment"
                        ),
                        narrative_positioning: .init(
                            short_summary: pointDepart,
                            current_positioning: forceCentrale,
                            evolution_logic: logiqueEvolution
                        )
                    )
                )

                let response = try await iaService.analyze(request: request)
                parsedResponse = response
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

struct FilConducteurScreen_Previews: PreviewProvider {
    static var previews: some View {
        FilConducteurScreen()
    }
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
