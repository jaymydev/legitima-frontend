import SwiftUI

struct RecruitmentTargetRoleCard: View {
    @Binding var targetRole: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Quel poste visez-vous ?")
                    .font(.headline)
                Text("Vous pouvez l’actualiser si votre projet a changé depuis la première analyse.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            TextField("Ex. Responsable de projet", text: $targetRole)
                .textInputAutocapitalization(.sentences)
                .padding(14)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .recruitmentCardStyle()
    }
}

struct RecruitmentChoiceCard: View {
    let question: InterviewQuestion
    @Binding var selection: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RecruitmentQuestionHeading(question: question)

            RecruitmentFlowLayout(spacing: 8) {
                ForEach(question.options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(selection == option ? .white : accent)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 10)
                    .background(
                        selection == option
                            ? accent
                            : Color(red: 232 / 255, green: 247 / 255, blue: 243 / 255)
                    )
                    .clipShape(Capsule())
                }
            }
        }
        .recruitmentCardStyle()
    }
}

struct RecruitmentTextCard: View {
    let question: InterviewQuestion
    @Binding var answer: String
    let minHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RecruitmentQuestionHeading(question: question)

            PlaceholderTextEditor(
                placeholder: "Votre réponse",
                text: $answer,
                primaryColor: Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255),
                minHeight: minHeight
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            AnswerGuidanceView(
                suggestions: question.suggestions,
                answer: answer
            )
        }
        .recruitmentCardStyle()
    }
}

struct RecruitmentExistingDataCard: View {
    let title: String
    let content: String
    let icon: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(accent)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(5)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct RecruitmentQuestionHeading: View {
    let question: InterviewQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(question.title)
                    .font(.headline)
                if !question.required {
                    Text("Facultatif")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Text(question.helper)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

private struct RecruitmentFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let arrangement = arrange(proposal: proposal, subviews: subviews)
        for (index, point) in arrangement.points.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (size: CGSize, points: [CGPoint]) {
        let width = proposal.width ?? 320
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return (CGSize(width: width, height: y + lineHeight), points)
    }
}

private extension View {
    func recruitmentCardStyle() -> some View {
        padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
