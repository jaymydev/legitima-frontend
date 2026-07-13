import SwiftUI
import UIKit

struct LeanOnboardingScreen: View {
    @EnvironmentObject private var userStatus: UserStatus
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

                        Text("Obtenez une lecture stratégique claire, en moins de 90 secondes.")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
                    }

                    quotaCard

                    inputCard(
                        label: "Poste visé",
                        field: {
                            TextField(
                                "",
                                text: $viewModel.posteVise,
                                prompt: Text("Ex : Product Manager Senior")
                                    .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255).opacity(0.82))
                            )
                                .textInputAutocapitalization(.sentences)
                                .autocorrectionDisabled()
                                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
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
                            TextField(
                                "",
                                text: $viewModel.zoneSensible,
                                prompt: Text("Ex : Changement de secteur en 2024")
                                    .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255).opacity(0.82))
                            )
                                .textInputAutocapitalization(.sentences)
                                .autocorrectionDisabled()
                                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
                                .padding(14)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                        }
                    )

                    Button(action: startAnalysis) {
                        Text("Analyser mon parcours")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)

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
            .disabled(viewModel.isLoading)
            .allowsHitTesting(!viewModel.isLoading)

            if viewModel.isLoading {
                loadingModal
                    .transition(.opacity)
            }
        }
        .onChange(of: viewModel.analysisResponse) { _, response in
            if let response {
                userStatus.consumeFreeAnalysisIfNeeded()
                onAnalysisComplete(response)
            }
        }
        .onAppear {
            userStatus.refreshFreeQuotaIfNeeded()
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

    private var quotaCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: userStatus.isPremium ? "sparkles" : "timer")
                .foregroundColor(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))

            VStack(alignment: .leading, spacing: 6) {
                Text(userStatus.isPremium ? "Accès premium" : "Accès freemium")
                    .font(.headline)
                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                Text(
                    userStatus.isPremium
                    ? "Vos analyses premium sont disponibles sans limite quotidienne."
                    : "Le mode gratuit inclut jusqu'à 2 analyses par jour."
                )
                .font(.subheadline)
                .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
                .fixedSize(horizontal: false, vertical: true)

                Text(userStatus.freeQuotaLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var loadingModal: some View {
        ZStack {
            Color.black.opacity(0.52)
                .ignoresSafeArea()

            AnalysisLoadingCard(
                title: "Analyse en cours",
                subtitle: "Nous relisons votre parcours, votre cible et votre zone sensible pour faire ressortir une première lecture stratégique.",
                accent: Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255)
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }

    private func startAnalysis() {
        userStatus.refreshFreeQuotaIfNeeded()

        guard userStatus.canStartAnalysis else {
            viewModel.errorMessage = "Vous avez atteint vos 2 analyses gratuites pour aujourd'hui. Revenez demain ou passez au premium."
            return
        }

        dismissKeyboard()
        viewModel.analyze()
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct LeanOnboardingScreen_Previews: PreviewProvider {
    static var previews: some View {
        LeanOnboardingScreen(onAnalysisComplete: { _ in })
    }
}
