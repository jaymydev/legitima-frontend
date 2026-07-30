import SwiftUI

struct AnswerGuidanceView: View {
    let suggestions: [String]
    let answer: String
    /// Questions offering options expect a couple of words — never nudge there.
    var expectsShortAnswer: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !suggestions.isEmpty {
                Label("Idées pour répondre", systemImage: "lightbulb")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(LegitimaColors.muted)

                ForEach(suggestions, id: \.self) { suggestion in
                    Text("• \(suggestion)")
                        .font(.caption)
                        .foregroundColor(LegitimaColors.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if InterviewAnswerQuality.deservesMoreMaterial(
                answer,
                expectsShortAnswer: expectsShortAnswer
            ) {
                // Says how the machine works, not what the answer is worth.
                // « Votre réponse est très courte » judged the person's work;
                // stating that the final answer is built from these words lets
                // them look back at what they wrote and conclude for
                // themselves. No warning triangle either — this is an
                // invitation, not a fault.
                Label(
                    "Votre réponse finale se construira à partir d’ici. Un exemple concret ou un chiffre donnerait plus de matière.",
                    systemImage: "text.badge.plus"
                )
                .font(.caption)
                .foregroundColor(LegitimaColors.gold)
                .accessibilityIdentifier("short-answer-warning")
            }
        }
    }
}
