import SwiftUI

/// The 30 seconds after purchase. The buy triggers a real backend call that
/// builds the first defensible answer while honest staged steps animate.
/// While the kickoff endpoint is not deployed, the screen degrades to a
/// continuity bridge (« rien à re-saisir ») before the guided flow.
struct PremiumKickoffScreen: View {
    @EnvironmentObject private var preparationStore: LocalPreparationStore

    let onContinue: () -> Void
    var service: InterviewPreparationService = InterviewPreparationService()

    private enum Phase: Equatable {
        case generating
        case ready(PremiumKickoffResponse)
        case bridge
    }

    private static let steps = [
        "Analyse relue",
        "Objection principale identifiée",
        "Rédaction de la réponse défendable",
    ]

    @State private var phase: Phase = .generating
    @State private var completedSteps = 0
    @State private var revealStage = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(light: .rgb(218, 249, 246), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(247, 242, 232), dark: LegitimaColors.darkBackgroundBottom)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            switch phase {
            case .generating:
                generatingView
            case .ready(let kickoff):
                readyView(kickoff)
            case .bridge:
                bridgeView
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await run() }
    }

    // MARK: - Generating

    private var generatingView: some View {
        VStack(spacing: 26) {
            ProgressView()
                .controlSize(.large)
                .tint(LegitimaColors.accent)

            Text("Construction de votre première réponse défendable…")
                .font(.title3.bold())
                .foregroundColor(LegitimaColors.ink)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 10) {
                        stepIndicator(for: index)
                        Text(step)
                            .font(.subheadline)
                            .foregroundColor(
                                index < completedSteps
                                    ? LegitimaColors.ink
                                    : LegitimaColors.muted
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 32)
        .transition(.opacity)
    }

    @ViewBuilder
    private func stepIndicator(for index: Int) -> some View {
        if index < completedSteps {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(LegitimaColors.accent)
                .transition(.scale(scale: 0.4).combined(with: .opacity))
        } else if index == completedSteps {
            ProgressView()
                .controlSize(.small)
                .tint(LegitimaColors.accent)
        } else {
            Image(systemName: "circle.dotted")
                .foregroundColor(LegitimaColors.muted.opacity(0.6))
        }
    }

    // MARK: - Ready (first deliverable)

    private func readyView(_ kickoff: PremiumKickoffResponse) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Label("LEGITIMA PREMIUM", systemImage: "crown.fill")
                    .font(.caption.bold())
                    .foregroundColor(LegitimaColors.gold)
                    .frame(maxWidth: .infinity)

                Text("Votre première réponse défendable")
                    .font(.title2.bold())
                    .foregroundColor(LegitimaColors.ink)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 8) {
                    Text("L’OBJECTION PROBABLE")
                        .font(.caption.bold())
                        .foregroundColor(Color(light: .rgb(153, 60, 29), dark: .rgb(240, 153, 123)))
                    JustifiedText("« \(kickoff.objection) »", color: LegitimaColors.ink)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(light: .rgb(255, 239, 221), dark: .rgb(46, 39, 28)))
                )
                .revealed(revealStage >= 1)

                VStack(alignment: .leading, spacing: 8) {
                    Text("VOTRE RÉPONSE DÉFENDABLE")
                        .font(.caption.bold())
                        .foregroundColor(LegitimaColors.accent)
                    JustifiedText(kickoff.defensibleAnswer, color: LegitimaColors.ink)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LegitimaColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(LegitimaColors.accent.opacity(0.25), lineWidth: 1)
                        )
                )
                .revealed(revealStage >= 2)

                VStack(spacing: 10) {
                    Button(action: onContinue) {
                        Text("Préparer les autres réponses")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(LegitimaColors.accentSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Text("La préparation guidée couvre les autres objections, votre ancrage et votre synthèse finale.")
                        .font(.caption)
                        .foregroundColor(LegitimaColors.muted)
                        .multilineTextAlignment(.center)
                }
                .revealed(revealStage >= 3)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
        }
        .transition(.opacity)
        .onAppear(perform: startReveal)
    }

    // MARK: - Bridge (fallback while the kickoff endpoint is not deployed)

    private var bridgeView: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundColor(LegitimaColors.accent)
                .transition(.scale(scale: 0.4).combined(with: .opacity))

            Text("Premium activé")
                .font(.title2.bold())
                .foregroundColor(LegitimaColors.ink)

            Text("On repart de votre analyse. Rien à re-saisir.")
                .font(.subheadline)
                .foregroundColor(LegitimaColors.muted)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 10) {
                bridgeRow(bridgeTargetRoleLabel)
                bridgeRow("Parcours et zone sensible conservés")
                if let days = interviewDays {
                    bridgeRow(InterviewCountdown.label(daysUntil: days))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(LegitimaColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(LegitimaColors.accent.opacity(0.2), lineWidth: 1)
                    )
            )
            .revealed(revealStage >= 1)

            Button(action: onContinue) {
                Text("Commencer ma préparation")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(LegitimaColors.accentSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .revealed(revealStage >= 2)
        }
        .padding(.horizontal, 24)
        .transition(.opacity)
        .onAppear(perform: startReveal)
    }

    private func bridgeRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.footnote.bold())
                .foregroundColor(LegitimaColors.accent)
            Text(text)
                .font(.subheadline)
                .foregroundColor(LegitimaColors.ink)
        }
    }

    private var bridgeTargetRoleLabel: String {
        let role = preparationStore.snapshot.targetRole
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return role.isEmpty ? "Poste visé conservé" : "Poste visé : \(role)"
    }

    private var interviewDays: Int? {
        preparationStore.snapshot.interviewDate.flatMap { InterviewCountdown.daysUntil($0) }
    }

    // MARK: - Flow

    private func run() async {
        guard case .generating = phase else { return }

        let stepBeats = Task {
            try await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { completedSteps = 1 }
            try await Task.sleep(nanoseconds: 800_000_000)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { completedSteps = 2 }
        }

        let startedAt = Date.now
        let request = PremiumKickoffRequest(context: .lean(from: preparationStore.snapshot))
        let kickoff = try? await service.kickoff(request)

        // Keep the generation beat readable even when the backend answers fast.
        let elapsed = Date.now.timeIntervalSince(startedAt)
        if elapsed < 2.4 {
            try? await Task.sleep(nanoseconds: UInt64((2.4 - elapsed) * 1_000_000_000))
        }
        stepBeats.cancel()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { completedSteps = 3 }
        try? await Task.sleep(nanoseconds: 400_000_000)

        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            phase = kickoff.map(Phase.ready) ?? .bridge
        }
    }

    private func startReveal() {
        revealStage = 0
        for stage in 1...3 {
            withAnimation(
                .spring(response: 0.45, dampingFraction: 0.8)
                    .delay(0.15 + Double(stage - 1) * 0.2)
            ) {
                revealStage = stage
            }
        }
    }
}

private extension View {
    /// Staggered card entrance: fade in while sliding up.
    func revealed(_ isRevealed: Bool) -> some View {
        opacity(isRevealed ? 1 : 0)
            .offset(y: isRevealed ? 0 : 14)
    }
}
