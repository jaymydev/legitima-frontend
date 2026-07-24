import SwiftUI

struct InterviewPreparationResultScreen: View {
    let response: InterviewPreparationResponse
    let onChooseAnother: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 222 / 255, green: 248 / 255, blue: 244 / 255),
                    Color(red: 245 / 255, green: 239 / 255, blue: 231 / 255),
                    Color(red: 235 / 255, green: 241 / 255, blue: 247 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(response.title)
                        .font(.system(size: 34, weight: .bold, design: .rounded))

                    resultCard(title: "Votre ligne directrice", content: response.summary)

                    ForEach(Array(response.sections.enumerated()), id: \.offset) { _, section in
                        resultCard(title: section.title, content: section.content)
                    }

                    listCard(
                        title: "Points à faire passer",
                        icon: "quote.bubble.fill",
                        items: response.talkingPoints
                    )
                    listCard(
                        title: "Plan d’action",
                        icon: "checklist",
                        items: response.actionPlan
                    )

                    Button(action: onChooseAnother) {
                        Text("Préparer un autre entretien")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(Color(red: 35 / 255, green: 105 / 255, blue: 109 / 255))
                            .background(Color.white.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(maxWidth: 720)
                .padding(22)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func resultCard(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(content)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func listCard(title: String, icon: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .frame(width: 24, height: 24)
                        .background(Color(red: 226 / 255, green: 244 / 255, blue: 240 / 255))
                        .clipShape(Circle())
                    Text(item)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
