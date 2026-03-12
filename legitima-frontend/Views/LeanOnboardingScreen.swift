import SwiftUI

struct LeanOnboardingScreen: View {
    @StateObject private var viewModel = LeanOnboardingViewModel()
    let onAnalysisComplete: (AnalysisResponse) -> Void

    init(onAnalysisComplete: @escaping (AnalysisResponse) -> Void) {
        self.onAnalysisComplete = onAnalysisComplete
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

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reprenez le contrôle de votre récit professionnel.")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                        Text("En moins de 90 secondes, obtenez une lecture stratégique claire.")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
                    }

                    inputCard(
                        label: "Poste visé",
                        field: {
                            TextField("Ex: Product Manager Senior", text: $viewModel.posteVise)
                                .textInputAutocapitalization(.sentences)
                                .autocorrectionDisabled()
                                .padding(14)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                        }
                    )

                    inputCard(
                        label: "Parcours résumé",
                        field: {
                            PlaceholderTextEditor(
                                placeholder: "Résumez les étapes clés de votre parcours, vos compétences et votre logique d'évolution.",
                                text: $viewModel.parcoursResume,
                                primaryColor: Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255),
                                minHeight: 180
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    )

                    inputCard(
                        label: "Zone sensible (optionnel)",
                        field: {
                            TextField("Ex: Changement de secteur en 2024", text: $viewModel.zoneSensible)
                                .textInputAutocapitalization(.sentences)
                                .autocorrectionDisabled()
                                .padding(14)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                        }
                    )

                    Button(action: {
                        viewModel.analyze()
                    }) {
                        Text("Analyser mon parcours")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)

                    if viewModel.isLoading {
                        ProgressView("Analyse en cours...")
                            .padding(.top, 4)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
        }
        .onChange(of: viewModel.analysisResponse) { _, response in
            if let response {
                onAnalysisComplete(response)
            }
        }
    }

    private func inputCard<Content: View>(
        label: String,
        @ViewBuilder field: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.headline)
                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

            field()
        }
        .padding(16)
        .background(Color.white.opacity(0.92))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    LeanOnboardingScreen(onAnalysisComplete: { _ in })
}
