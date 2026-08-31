import UIKit

/// Renders the premium synthesis as a paginated A4 PDF, without third-party
/// dependencies. The document is written to the app's temporary directory only
/// when the user asks for the export.
enum PreparationPDFExporter {
    private enum Layout {
        static let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 at 72 dpi
        static let margin: CGFloat = 52
    }

    static func writeTemporaryPDF(for content: PreparationExportContent) -> URL? {
        let data = pdfData(for: content)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(PreparationExportContent.documentName)

        do {
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return url
        } catch {
            return nil
        }
    }

    static func pdfData(for content: PreparationExportContent) -> Data {
        let formatter = UISimpleTextPrintFormatter(attributedText: attributedDocument(for: content))
        formatter.perPageContentInsets = UIEdgeInsets(
            top: Layout.margin,
            left: Layout.margin,
            bottom: Layout.margin,
            right: Layout.margin
        )

        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        renderer.setValue(Layout.pageRect, forKey: "paperRect")
        renderer.setValue(Layout.pageRect, forKey: "printableRect")

        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, Layout.pageRect, nil)
        renderer.prepare(forDrawingPages: NSRange(location: 0, length: renderer.numberOfPages))
        for page in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: page, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()
        return data as Data
    }

    /// La palette d'impression. Fixe et claire : un PDF se lit sur papier ou
    /// sur fond blanc, jamais en mode sombre.
    ///
    /// Le code couleur vient du retour testeur : rouge les points sensibles,
    /// bleu ce qui porte la légitimité — les phrases qu'on peut dire — vert ce
    /// qui est acquis. Le vert était resté vide chez le testeur ; il a
    /// désormais sa donnée, les questions marquées « à l'aise ».
    private enum Palette {
        static let ink = UIColor(red: 47 / 255, green: 49 / 255, blue: 49 / 255, alpha: 1)
        static let accent = UIColor(red: 43 / 255, green: 111 / 255, blue: 113 / 255, alpha: 1)
        static let body = UIColor(red: 62 / 255, green: 67 / 255, blue: 67 / 255, alpha: 1)
        static let muted = UIColor(red: 118 / 255, green: 124 / 255, blue: 124 / 255, alpha: 1)
        static let blue = UIColor(red: 42 / 255, green: 89 / 255, blue: 140 / 255, alpha: 1)
        static let red = UIColor(red: 169 / 255, green: 67 / 255, blue: 46 / 255, alpha: 1)
        static let green = UIColor(red: 62 / 255, green: 122 / 255, blue: 80 / 255, alpha: 1)
    }

    /// Ce qu'un ton devient à l'impression : une étiquette colorée qui annonce
    /// la nature du paragraphe avant sa lecture — comme à l'écran, où « À
    /// dire » et « Comment répondre » se lisent avant la réponse.
    private static func rendering(
        for tone: PreparationExportContent.Tone
    ) -> (label: String?, color: UIColor, text: UIColor) {
        switch tone {
        case .say: return ("À DIRE", Palette.blue, Palette.ink)
        case .guidance: return ("COMMENT RÉPONDRE", Palette.accent, Palette.body)
        case .followUp: return ("RELANCE PROBABLE", Palette.muted, Palette.muted)
        case .avoid: return ("À ÉVITER", Palette.red, Palette.red)
        case .acquired: return (nil, Palette.green, Palette.green)
        case .plain: return (nil, Palette.accent, Palette.body)
        }
    }

    private static func attributedDocument(for content: PreparationExportContent) -> NSAttributedString {
        let document = NSMutableAttributedString()

        document.append(NSAttributedString(
            string: "LEGITIMA — SYNTHÈSE DE PRÉPARATION\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: Palette.accent,
                .kern: 1.2,
            ]
        ))

        document.append(NSAttributedString(
            string: content.title + "\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: Palette.ink,
                .paragraphStyle: paragraphStyle(spacingBefore: 4, spacingAfter: 14),
            ]
        ))

        for block in content.blocks {
            document.append(NSAttributedString(
                string: block.title + "\n",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: block.titleTone == .acquired ? Palette.green : Palette.ink,
                    .paragraphStyle: paragraphStyle(spacingBefore: 14, spacingAfter: 5),
                ]
            ))

            for (index, paragraph) in block.paragraphs.enumerated() {
                let style = rendering(for: paragraph.tone)

                if let label = style.label {
                    // L'étiquette en chip : le fond teinté vient de l'attribut
                    // de fond du run, les espaces font le rembourrage.
                    document.append(NSAttributedString(
                        string: "  \(label)  \n",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 8, weight: .bold),
                            .foregroundColor: style.color,
                            .backgroundColor: style.color.withAlphaComponent(0.12),
                            .kern: 1.0,
                            .paragraphStyle: paragraphStyle(spacingBefore: 4, spacingAfter: 3),
                        ]
                    ))
                }

                let prefix = block.numbered ? "\(index + 1). " : (paragraph.tone == .acquired ? "✓ " : "")
                let bodyStyle = paragraphStyle(spacingBefore: 0, spacingAfter: 6, lineSpacing: 3)
                if !prefix.isEmpty {
                    document.append(NSAttributedString(
                        string: prefix,
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 12),
                            .foregroundColor: style.text,
                            .paragraphStyle: bodyStyle,
                        ]
                    ))
                }

                for segment in paragraph.segments {
                    // La même convention qu'à l'écran : un blanc rempli se lit
                    // comme le reste, en gras ; un blanc vide se voit comme un
                    // trou — souligné et coloré — c'est à la personne de le
                    // compléter, à l'oral s'il le faut. Fondu dans la phrase,
                    // il se lirait comme du texte à dire tel quel.
                    var attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: style.text,
                        .paragraphStyle: bodyStyle,
                    ]
                    switch segment.kind {
                    case .literal:
                        break
                    case .filled:
                        attributes[.font] = UIFont.systemFont(ofSize: 12, weight: .semibold)
                    case .empty:
                        attributes[.foregroundColor] = Palette.accent
                        attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                        attributes[.underlineColor] = Palette.accent
                    }
                    document.append(NSAttributedString(string: segment.text, attributes: attributes))
                }

                document.append(NSAttributedString(
                    string: "\n",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: style.text,
                        .paragraphStyle: bodyStyle,
                    ]
                ))
            }
        }

        return document
    }

    private static func paragraphStyle(
        spacingBefore: CGFloat,
        spacingAfter: CGFloat,
        lineSpacing: CGFloat = 0
    ) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacingBefore = spacingBefore
        style.paragraphSpacing = spacingAfter
        style.lineSpacing = lineSpacing
        return style
    }
}
