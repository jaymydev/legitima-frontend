import Foundation

/// Foundation-only, testable assembly of the premium synthesis for export.
/// Rendering (PDF) lives in PreparationPDFExporter.
struct PreparationExportContent: Equatable {
    struct Block: Equatable {
        let title: String
        let paragraphs: [String]
        let numbered: Bool
    }

    static let documentName = "Synthese-Legitima.pdf"

    let title: String
    let blocks: [Block]

    init(
        response: InterviewPreparationResponse,
        kickoff: PremiumKickoffResponse? = nil
    ) {
        title = response.title.trimmingCharacters(in: .whitespacesAndNewlines)

        var blocks: [Block] = []

        // The answer generated at purchase leads the document: it is the one
        // the user already knows works, and the PDF is read the night before.
        if let kickoff {
            let objection = kickoff.objection.trimmingCharacters(in: .whitespacesAndNewlines)
            let answer = kickoff.defensibleAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !answer.isEmpty {
                blocks.append(
                    Block(
                        title: "Votre première réponse défendable",
                        paragraphs: objection.isEmpty ? [answer] : ["« \(objection) »", answer],
                        numbered: false
                    )
                )
            }
        }

        let summary = response.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !summary.isEmpty {
            blocks.append(Block(title: "Votre ligne directrice", paragraphs: [summary], numbered: false))
        }

        for section in response.sections {
            let content = section.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty else { continue }
            blocks.append(Block(title: section.title, paragraphs: [content], numbered: false))
        }

        let talkingPoints = Self.cleaned(response.talkingPoints)
        if !talkingPoints.isEmpty {
            blocks.append(Block(title: "Points à faire passer", paragraphs: talkingPoints, numbered: true))
        }

        let actionPlan = Self.cleaned(response.actionPlan)
        if !actionPlan.isEmpty {
            blocks.append(Block(title: "Plan d'action", paragraphs: actionPlan, numbered: true))
        }

        self.blocks = blocks
    }

    private static func cleaned(_ items: [String]) -> [String] {
        items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
