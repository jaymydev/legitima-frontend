import SwiftUI

/// The step between the analysis and the guided preparation, shown once. A
/// real backend call builds the first defensible answer while honest staged
/// steps animate. While the kickoff endpoint is not deployed, the screen
/// degrades to a continuity bridge (« rien à re-saisir ») before the flow.
struct PremiumKickoffScreen: View {
    @EnvironmentObject private var preparationStore: LocalPreparationStore

    let onContinue: () -> Void
    var service: InterviewPreparationService = InterviewPreparationService()

    private enum Phase: Equatable {
        case generating
        case ready(PremiumKickoffResponse)
        case bridge
        case failed
    }

    private static let steps = [
        "Analyse relue",
        "Objection principale identifiée",
        "Rédaction de la réponse défendable",
    ]

    @State private var phase: Phase = .generating
    @State private var completedSteps = 0
    @State private var revealStage = 0
    @State private var isTakingLong = false

    /// Kept at their design size but scaling with the text beside them, so the
    /// icon does not shrink relative to its label at accessibility sizes.
    @ScaledMetric(relativeTo: .largeTitle) private var warningIconSize: CGFloat = 44
    @ScaledMetric(relativeTo: .largeTitle) private var successIconSize: CGFloat = 52

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
            case .failed:
                failedView
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

            if isTakingLong {
                Text("C’est un peu plus long que d’habitude. On continue.")
                    .font(.footnote)
                    .foregroundColor(LegitimaColors.muted)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 32)
        .transition(.opacity)
    }

    // MARK: - Failed (network or server, not a missing endpoint)

    private var failedView: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: warningIconSize))
                .foregroundColor(LegitimaColors.gold)

            Text("La génération n’a pas abouti")
                .font(.title3.bold())
                .foregroundColor(LegitimaColors.ink)
                .multilineTextAlignment(.center)

            Text("Vos données sont conservées. Vous pouvez réessayer, ou passer directement à votre préparation guidée.")
                .font(.subheadline)
                .foregroundColor(LegitimaColors.muted)
                .multilineTextAlignment(.center)

            Button {
                retry()
            } label: {
                Text("Réessayer")
                    .legitimaPrimaryLabel()
            }

            Button(action: onContinue) {
                Text("Passer à ma préparation")
                    .legitimaSecondaryLabel()
            }
        }
        .padding(.horizontal, 28)
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
                Label("PREMIÈRE RÉPONSE", systemImage: "shield.fill")
                    .font(.caption.bold())
                    .foregroundColor(LegitimaColors.accent)
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
                    RoundedRectangle(cornerRadius: LegitimaRadius.control)
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
                    RoundedRectangle(cornerRadius: LegitimaRadius.control)
                        .fill(LegitimaColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: LegitimaRadius.control)
                                .stroke(LegitimaColors.accent.opacity(0.25), lineWidth: 1)
                        )
                )
                .revealed(revealStage >= 2)

                VStack(spacing: 10) {
                    Button(action: onContinue) {
                        Text("Préparer les autres réponses")
                            .legitimaPrimaryLabel()
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
                .font(.system(size: successIconSize))
                .foregroundColor(LegitimaColors.accent)
                .transition(.scale(scale: 0.4).combined(with: .opacity))

            Text("Votre préparation continue")
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
                RoundedRectangle(cornerRadius: LegitimaRadius.control)
                    .fill(LegitimaColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: LegitimaRadius.control)
                            .stroke(LegitimaColors.accent.opacity(0.2), lineWidth: 1)
                    )
            )
            .revealed(revealStage >= 1)

            Button(action: onContinue) {
                Text("Commencer ma préparation")
                    .legitimaPrimaryLabel()
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

        // Already computed once: show it straight away rather than spend
        // another call and another wait on the same answer.
        if let saved = preparationStore.snapshot.kickoff {
            phase = .ready(saved)
            return
        }

        let stepBeats = Task {
            try await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { completedSteps = 1 }
            try await Task.sleep(nanoseconds: 800_000_000)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { completedSteps = 2 }
        }

        // The wait is blocking and just-paid-for: say something before it feels
        // broken, rather than leaving a spinner alone for half a minute.
        let longWaitNotice = Task {
            try await Task.sleep(nanoseconds: 12_000_000_000)
            withAnimation(.easeInOut(duration: 0.3)) { isTakingLong = true }
        }

        let startedAt = Date.now
        let request = PremiumKickoffRequest(context: .lean(from: preparationStore.snapshot))

        let outcome: PremiumKickoffOutcome
        do {
            outcome = .ready(try await service.kickoff(request))
        } catch {
            outcome = PremiumKickoffOutcome.classify(error)
        }

        // Keep the generation beat readable even when the backend answers fast.
        let elapsed = Date.now.timeIntervalSince(startedAt)
        if elapsed < 2.4 {
            try? await Task.sleep(nanoseconds: UInt64((2.4 - elapsed) * 1_000_000_000))
        }
        stepBeats.cancel()
        longWaitNotice.cancel()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { completedSteps = 3 }
        try? await Task.sleep(nanoseconds: 400_000_000)

        if case .ready(let kickoff) = outcome {
            preparationStore.saveKickoff(kickoff)
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            switch outcome {
            case .ready(let kickoff): phase = .ready(kickoff)
            case .notDeployed: phase = .bridge
            case .failed: phase = .failed
            }
        }
    }

    private func retry() {
        withAnimation(.easeInOut(duration: 0.25)) {
            phase = .generating
            completedSteps = 0
            isTakingLong = false
        }
        Task { await run() }
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

