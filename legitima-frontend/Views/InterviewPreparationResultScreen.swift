import SwiftUI

struct InterviewPreparationResultScreen: View {
    let response: InterviewPreparationResponse
    let onChooseAnother: () -> Void

    @State private var exportURL: URL?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(light: .rgb(222, 248, 244), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(245, 239, 231), dark: LegitimaColors.darkBackgroundMid),
                    Color(light: .rgb(235, 241, 247), dark: LegitimaColors.darkBackgroundBottom)
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

                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Exporter ma synthèse (PDF)", systemImage: "square.and.arrow.up")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(LegitimaColors.accentSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }

                    Button(action: onChooseAnother) {
                        Text("Préparer un autre entretien")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(LegitimaColors.accent)
                            .background(LegitimaColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(maxWidth: 720)
                .padding(22)
                .frame(maxWidth: .infinity)
            }
        }
        .task(id: response) {
            exportURL = PreparationPDFExporter.writeTemporaryPDF(
                for: PreparationExportContent(response: response)
            )
        }
    }

    private func resultCard(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            JustifiedText(content, textStyle: .body, color: .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LegitimaColors.surface)
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
                        .background(LegitimaColors.chip)
                        .clipShape(Circle())
                    JustifiedText(item, textStyle: .body, color: .secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LegitimaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
