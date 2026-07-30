import SwiftUI

struct InterviewUseCaseSelectionScreen: View {
    @StateObject private var viewModel = InterviewUseCasesViewModel()

    let savedPreparation: SavedInterviewPreparation
    let onSelect: (InterviewUseCase) -> Void
    let onResume: (SavedInterviewPreparation) -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(light: .rgb(218, 249, 246), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(247, 242, 232), dark: LegitimaColors.darkBackgroundMid),
                    Color(light: .rgb(232, 241, 245), dark: LegitimaColors.darkBackgroundBottom)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quel entretien préparez-vous ?")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))

                        Text("Les questions et la synthèse seront adaptées à votre situation.")
                            .foregroundColor(LegitimaColors.muted)
                    }

                    if savedPreparation.hasWork {
                        Button {
                            onResume(savedPreparation)
                        } label: {
                            Label(
                                savedPreparation.result == nil
                                    ? "Reprendre mon questionnaire"
                                    : "Revoir ma dernière préparation",
                                systemImage: "clock.arrow.circlepath"
                            )
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .foregroundColor(LegitimaColors.accent)
                            .background(LegitimaColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
                        }
                    }

                    if viewModel.isLoading && viewModel.useCases.isEmpty {
                        ProgressView("Chargement des parcours…")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        ForEach(viewModel.useCases) { useCase in
                            useCaseCard(useCase)
                        }
                        .disabled(viewModel.isLoading)
                        .opacity(viewModel.isLoading ? 0.7 : 1)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)

                            Button("Réessayer") {
                                Task { await viewModel.load() }
                            }
                            .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: 720)
                .padding(22)
                .frame(maxWidth: .infinity)
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private func useCaseCard(_ useCase: InterviewUseCase) -> some View {
        Button {
            onSelect(useCase)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon(for: useCase.id))
                    .font(.title2)
                    .frame(width: 48, height: 48)
                    .foregroundColor(LegitimaColors.accent)
                    .background(LegitimaColors.chip)
                    .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))

                VStack(alignment: .leading, spacing: 7) {
                    Text(useCase.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    JustifiedText(useCase.description, color: LegitimaColors.muted)
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundColor(LegitimaColors.muted)
            }
            .padding(18)
            .background(LegitimaColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
        }
    }

    private func icon(for useCaseID: String) -> String {
        switch useCaseID {
        case "recruitment": return "person.crop.circle.badge.checkmark"
        case "internal_mobility": return "arrow.left.arrow.right.circle"
        case "role_evolution": return "arrow.up.right.circle"
        case "mid_year": return "calendar.badge.clock"
        case "annual_review": return "calendar.circle"
        case "performance_review": return "chart.line.uptrend.xyaxis"
        default: return "text.bubble"
        }
    }
}
