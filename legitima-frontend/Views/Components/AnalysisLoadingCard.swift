import SwiftUI

struct AnalysisLoadingCard: View {
    let title: String
    let subtitle: String
    let accent: Color

    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                loadingOrb

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(LegitimaColors.ink)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(LegitimaColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                loadingDot(delay: 0)
                loadingDot(delay: 0.18)
                loadingDot(delay: 0.36)
            }

            VStack(spacing: 10) {
                shimmerLine(maxWidth: 320)
                shimmerLine(maxWidth: 240)
                shimmerLine(maxWidth: 280)
            }
        }
        .padding(18)
        .background(LegitimaColors.surfaceStrong)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(light: .rgb(225, 232, 232), dark: .rgb(52, 60, 61)), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.18), radius: 28, x: 0, y: 14)
        .onAppear {
            isAnimating = true
        }
    }

    private var loadingOrb: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.16))
                .frame(width: 50, height: 50)
                .scaleEffect(isAnimating ? 1.08 : 0.92)
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: isAnimating
                )

            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundColor(accent)
        }
    }

    private func loadingDot(delay: Double) -> some View {
        Circle()
            .fill(accent.opacity(0.88))
            .frame(width: 9, height: 9)
            .scaleEffect(isAnimating ? 1 : 0.45)
            .opacity(isAnimating ? 1 : 0.35)
            .animation(
                .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
    }

    private func shimmerLine(maxWidth: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 999)
            .fill(
                LinearGradient(
                    colors: [
                        accent.opacity(0.10),
                        Color(light: UIColor.white.withAlphaComponent(0.95), dark: UIColor.white.withAlphaComponent(0.25)),
                        accent.opacity(0.18)
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(maxWidth: maxWidth, minHeight: 12, maxHeight: 12, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(
                .linear(duration: 1.1).repeatForever(autoreverses: true),
                value: isAnimating
            )
    }
}

struct AnalysisLoadingCard_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisLoadingCard(
            title: "Analyse en cours",
            subtitle: "Nous transformons votre matiere brute en une lecture strategique claire.",
            accent: LegitimaColors.accent
        )
        .padding()
        .background(Color(red: 237 / 255, green: 243 / 255, blue: 243 / 255))
    }
}
