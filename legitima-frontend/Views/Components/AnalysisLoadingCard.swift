import SwiftUI

/// The wait during a generation. One breathing orb, one line that actually
/// advances, a percentage, and two skeleton bands — nothing else. The previous
/// version said « wait » three times over (orb, three bouncing dots, bands).
struct AnalysisLoadingCard: View {
    let steps: [String]
    let accent: Color

    /// Typical duration for this call. Only shapes the pacing of the estimate.
    var typicalDuration: TimeInterval = 18

    @State private var progress: Double = 0
    @State private var elapsed: TimeInterval = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                orb

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

            VStack(spacing: 10) {
                SkeletonBand(accent: accent)
                SkeletonBand(width: 220, accent: accent, delay: 0.2)
            }

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

    private var orb: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.16))
                .frame(width: 42, height: 42)
                .scaleEffect(1 + 0.08 * sin(elapsed * 2.6))

            Image(systemName: "sparkles")
                .font(.subheadline)
                .foregroundColor(accent)
        }
    }
}

/// A grey band with a highlight sweeping across it. The old version animated
/// the gradient end-points, which shimmered in place instead of travelling.
private struct SkeletonBand: View {
    var width: CGFloat = .infinity
    let accent: Color
    var delay: Double = 0

    @State private var sweeping = false

    var body: some View {
        RoundedRectangle(cornerRadius: 999)
            .fill(Color(light: .rgb(228, 234, 234), dark: .rgb(52, 60, 61)))
            .frame(maxWidth: width, minHeight: 12, maxHeight: 12, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 999)
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color.white.opacity(0.7), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.45)
                        .offset(x: sweeping ? geo.size.width : -geo.size.width * 0.5)
                }
                .frame(maxWidth: width)
                .mask(RoundedRectangle(cornerRadius: 999))
            }
            .clipShape(RoundedRectangle(cornerRadius: 999))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4).repeatForever(autoreverses: false).delay(delay)
                ) {
                    sweeping = true
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
