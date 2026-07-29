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
                    Color(light: .rgb(207, 252, 249), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(237, 243, 243), dark: LegitimaColors.darkBackgroundBottom)
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
                            .foregroundColor(LegitimaColors.ink)

                        Text("Obtenez une lecture stratégique claire, en moins de 90 secondes.")
                            .font(.subheadline)
                            .foregroundColor(LegitimaColors.muted)
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
                                    .foregroundColor(LegitimaColors.muted.opacity(0.82))
                            )
                                .textInputAutocapitalization(.sentences)
                                .autocorrectionDisabled()
                                .foregroundColor(LegitimaColors.ink)
                                .padding(14)
                                .background(LegitimaColors.field)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(LegitimaColors.hairline, lineWidth: 1)
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
                                    primaryColor: LegitimaColors.ink,
                                    minHeight: 180
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(LegitimaColors.hairline, lineWidth: 1)
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
                                    .foregroundColor(LegitimaColors.accent)
                                    .background(Color(light: .rgb(239, 250, 249), dark: .rgb(31, 44, 43)))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(LegitimaColors.accent.opacity(0.22), lineWidth: 1)
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
                                    .foregroundColor(LegitimaColors.muted.opacity(0.82))
                            )
                                .textInputAutocapitalization(.sentences)
                                .autocorrectionDisabled()
                                .foregroundColor(LegitimaColors.ink)
                                .padding(14)
                                .background(LegitimaColors.field)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(LegitimaColors.hairline, lineWidth: 1)
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
                                    .tint(LegitimaColors.accent)

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
                            .background(LegitimaColors.accentSurface)
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
                .foregroundColor(LegitimaColors.ink)

            if let helper {
                Text(helper)
                    .font(.subheadline)
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            field()
        }
        .padding(16)
        .background(LegitimaColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private var quotaCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: userStatus.isPremium ? "sparkles" : "timer")
                .foregroundColor(LegitimaColors.accent)

            VStack(alignment: .leading, spacing: 6) {
                Text(userStatus.isPremium ? "Accès premium" : "Mode test")
                    .font(.headline)
                    .foregroundColor(LegitimaColors.ink)

                Text(
                    userStatus.isPremium
                    ? "Vos analyses premium sont disponibles sans limite quotidienne."
                    : "Le mode test inclut jusqu'à 20 analyses réussies par jour."
                )
                .font(.subheadline)
                .foregroundColor(LegitimaColors.muted)
                .fixedSize(horizontal: false, vertical: true)

                Text(userStatus.freeQuotaLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(LegitimaColors.accent)
            }
        }
        .padding(16)
        .background(LegitimaColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LegitimaColors.hairline, lineWidth: 1)
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
                accent: LegitimaColors.accent
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
