import SwiftUI

struct AnswerGuidanceView: View {
    let suggestions: [String]
    let answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !suggestions.isEmpty {
                Label("Idées pour répondre", systemImage: "lightbulb")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                ForEach(suggestions, id: \.self) { suggestion in
                    Text("• \(suggestion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if InterviewAnswerQuality.isTooShort(answer) {
                Label(
                    "Votre réponse est très courte. Vous pouvez continuer, mais votre discours final pourrait être moins pertinent.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundColor(.orange)
                .accessibilityIdentifier("short-answer-warning")
            }
        }
    }
}
