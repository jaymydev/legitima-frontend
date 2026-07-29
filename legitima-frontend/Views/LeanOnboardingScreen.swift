import SwiftUI
import UIKit

struct LeanOnboardingScreen: View {
    @EnvironmentObject private var userStatus: UserStatus
    @EnvironmentObject private var preparationStore: LocalPreparationStore
    @StateObject private var viewModel = LeanOnboardingViewModel()
    @State private var isShowingCVImportFlow = false
    @State private var hasInterviewDate = false
    @State private var interviewDate = Date()
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
                        helper: "Indiquez simplement le rôle que vous ciblez aujourd'hui.",
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
                        label: "Indiquez les 3 à 5 étapes clés de votre parcours",
                        helper: "Gardez seulement les expériences utiles. Ne collez pas votre CV complet.",
                        field: {
                            VStack(alignment: .leading, spacing: 12) {
                                PlaceholderTextEditor(
                                    placeholder: "Ex : 2019-2022 pilotage de projets techniques, 2022-2024 coordination produit, 2025 période de transition puis repositionnement.",
                                    text: $viewModel.parcoursResume,
                                    primaryColor: Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255),
                                    minHeight: 180
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                Button(action: {
                                    dismissKeyboard()
                                    isShowingCVImportFlow = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Importer un CV (PDF ou photo)")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundColor(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))
                                    .background(Color(red: 239 / 255, green: 250 / 255, blue: 249 / 255))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255).opacity(0.22), lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                                }
                            }
                        }
                    )

                    inputCard(
                        label: "Point à expliquer en entretien (optionnel)",
                        helper: "Ex : chômage, transition, bench ou burn-out.",
                        field: {
                            TextField(
                                "",
                                text: $viewModel.zoneSensible,
                                prompt: Text("Ex : chômage en 2025, bench de 6 mois, reconversion ou burn-out")
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
                        label: "Date de l'entretien (optionnel)",
                        helper: "Elle nous sert à rythmer votre préparation jusqu'au jour J.",
                        field: {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle("J'ai déjà une date d'entretien", isOn: $hasInterviewDate.animation())
                                    .font(.subheadline)
                                    .tint(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))

                                if hasInterviewDate {
                                    DatePicker(
                                        "Date de l'entretien",
                                        selection: $interviewDate,
                                        in: Calendar.current.startOfDay(for: Date())...,
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                }
                            }
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
            let saved = preparationStore.snapshot
            if viewModel.posteVise.isEmpty {
                viewModel.posteVise = saved.targetRole
            }
            if viewModel.parcoursResume.isEmpty {
                viewModel.parcoursResume = saved.careerSummary
            }
            if viewModel.zoneSensible.isEmpty {
                viewModel.zoneSensible = saved.sensitivePoint
            }
            if let savedDate = saved.interviewDate {
                hasInterviewDate = true
                interviewDate = savedDate
            }
        }
        .onChange(of: viewModel.posteVise) { _, _ in saveDraft() }
        .onChange(of: viewModel.parcoursResume) { _, _ in saveDraft() }
        .onChange(of: viewModel.zoneSensible) { _, _ in saveDraft() }
        .onChange(of: hasInterviewDate) { _, _ in saveInterviewDate() }
        .onChange(of: interviewDate) { _, _ in saveInterviewDate() }
        .sheet(isPresented: $isShowingCVImportFlow) {
            CVImportFlowSheet { importedSummary in
                viewModel.parcoursResume = importedSummary
            }
        }
    }

    private func inputCard<Content: View>(
        label: String,
        helper: String? = nil,
        @ViewBuilder field: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.headline)
                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

            if let helper {
                Text(helper)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
                    .fixedSize(horizontal: false, vertical: true)
            }

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
                Text(userStatus.isPremium ? "Accès premium" : "Mode test")
                    .font(.headline)
                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                Text(
                    userStatus.isPremium
                    ? "Vos analyses premium sont disponibles sans limite quotidienne."
                    : "Le mode test inclut jusqu'à 20 analyses réussies par jour."
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
                subtitle: "Nous relisons votre parcours, votre cible et votre point à expliquer pour faire ressortir une première lecture stratégique.",
                accent: Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255)
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }

    private func startAnalysis() {
        userStatus.refreshFreeQuotaIfNeeded()

        guard userStatus.canStartAnalysis else {
            viewModel.errorMessage = "Vous avez atteint vos 20 analyses de test pour aujourd'hui. Votre travail reste disponible et le quota sera réinitialisé demain."
            return
        }

        dismissKeyboard()
        viewModel.analyze()
    }

    private func saveDraft() {
        preparationStore.saveDraft(
            targetRole: viewModel.posteVise,
            careerSummary: viewModel.parcoursResume,
            sensitivePoint: viewModel.zoneSensible
        )
    }

    private func saveInterviewDate() {
        preparationStore.updateInterviewDate(hasInterviewDate ? interviewDate : nil)
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
