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
                    Color(red: 218 / 255, green: 249 / 255, blue: 246 / 255),
                    Color(red: 247 / 255, green: 242 / 255, blue: 232 / 255),
                    Color(red: 232 / 255, green: 241 / 255, blue: 245 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quel entretien préparez-vous ?")
                            .font(.system(size: 34, weight: .bold, design: .rounded))

                        Text("Les questions et la synthèse seront adaptées à votre situation.")
                            .foregroundColor(.secondary)
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
                            .foregroundColor(Color(red: 31 / 255, green: 92 / 255, blue: 96 / 255))
                            .background(Color.white.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
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
                    .foregroundColor(Color(red: 31 / 255, green: 92 / 255, blue: 96 / 255))
                    .background(Color(red: 226 / 255, green: 244 / 255, blue: 240 / 255))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 7) {
                    Text(useCase.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(useCase.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(18)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 20))
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
