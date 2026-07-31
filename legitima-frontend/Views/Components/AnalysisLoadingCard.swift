import SwiftUI

/// The wait during a generation. One breathing orb, one line that actually
/// advances, a percentage, and a single bar — nothing else.
///
/// The bar carries both messages at once: how far along we are, and that work
/// is still happening. Previously a shimmer band swept left to right while the
/// percentage said something entirely different — two elements claiming to
/// report the same thing without agreeing.
struct AnalysisLoadingCard: View {
    let steps: [String]
    let accent: Color

    /// Typical duration for this call. Only shapes the pacing of the estimate.
    ///
    /// Measured against the Starter deployment: `/analyze` answers in 8–9 s.
    /// The former value of 18 s was set when the service slept between calls
    /// and paid a 32 s cold start; it made every normal wait look stalled.
    var typicalDuration: TimeInterval = 10

    @State private var progress: Double = 0
    @State private var elapsed: TimeInterval = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                BreathingOrb(accent: accent)

                Text(currentStep)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(LegitimaColors.ink)
                    .id(currentStep)
                    .transition(.opacity)

                Spacer(minLength: 8)

                Text("\(Int(progress * 100)) %")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundColor(accent)
            }

            ProgressLine(progress: progress, accent: accent)

            if let notice = slowNotice {
                Text(notice)
                    .font(.footnote)
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .padding(18)
        .background(LegitimaColors.surfaceStrong)
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
        .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
        .task { await tick() }
    }

    // MARK: - Progress

    private var currentStep: String {
        guard !steps.isEmpty else { return "" }
        return steps[LoadingProgressEstimate.stepIndex(for: progress, count: steps.count)]
    }

    private var slowNotice: String? {
        LoadingProgressEstimate.slowNotice(elapsed: elapsed)
    }

    private func tick() async {
        let start = Date()
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 250_000_000)
            let now = Date().timeIntervalSince(start)
            withAnimation(.easeInOut(duration: 0.3)) {
                elapsed = now
                progress = LoadingProgressEstimate.progress(
                    elapsed: now,
                    typicalDuration: typicalDuration
                )
            }
        }
    }
}

/// Breathes on its own clock. Deriving the scale from the elapsed time, as the
/// first version did, sampled it four times a second — about ten steps per
/// cycle, which reads as a stuttering pulse rather than a breath.
private struct BreathingOrb: View {
    let accent: Color

    @State private var inhaled = false

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.16))
                .frame(width: 42, height: 42)
                .scaleEffect(inhaled ? 1.08 : 0.92)

            Image(systemName: "sparkles")
                .font(.subheadline)
                .foregroundColor(accent)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                inhaled = true
            }
        }
    }
}

/// Fills to the current progress, with a highlight travelling across the
/// filled part only.
private struct ProgressLine: View {
    let progress: Double
    let accent: Color

    /// Normalised 0→1 sweep. Driving the highlight's offset directly from
    /// `progress` moved the animation's target every 250 ms, which made the
    /// sweep stutter while the bar grew. A phase of its own keeps it smooth
    /// however fast the bar fills.
    @State private var phase: CGFloat = 0

    private let height: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            let filled = max(height, geo.size.width * progress)
            let highlight = geo.size.width * 0.3

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(light: .rgb(228, 234, 234), dark: .rgb(52, 60, 61)))

                Capsule()
                    .fill(accent)
                    .frame(width: filled)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.45), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: highlight)
                            .offset(x: phase * (filled + highlight) - highlight)
                    }
                    .clipShape(Capsule())
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

struct AnalysisLoadingCard_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisLoadingCard(
            steps: [
                "Lecture de votre parcours",
                "Mise en tension des zones sensibles",
                "Construction du fil conducteur",
            ],
            accent: LegitimaColors.accent
        )
        .padding()
        .background(Color(light: .rgb(237, 243, 243), dark: .rgb(20, 28, 29)))
    }
}
