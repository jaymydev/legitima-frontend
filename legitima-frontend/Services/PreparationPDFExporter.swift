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

    private static func attributedDocument(for content: PreparationExportContent) -> NSAttributedString {
        let ink = UIColor(red: 47 / 255, green: 49 / 255, blue: 49 / 255, alpha: 1)
        let accent = UIColor(red: 43 / 255, green: 111 / 255, blue: 113 / 255, alpha: 1)
        let body = UIColor(red: 62 / 255, green: 67 / 255, blue: 67 / 255, alpha: 1)

        let document = NSMutableAttributedString()

        document.append(NSAttributedString(
            string: "LEGITIMA — SYNTHÈSE DE PRÉPARATION\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: accent,
                .kern: 1.2,
            ]
        ))

        document.append(NSAttributedString(
            string: content.title + "\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: ink,
                .paragraphStyle: paragraphStyle(spacingBefore: 4, spacingAfter: 14),
            ]
        ))

        for block in content.blocks {
            document.append(NSAttributedString(
                string: block.title + "\n",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: accent,
                    .paragraphStyle: paragraphStyle(spacingBefore: 12, spacingAfter: 5),
                ]
            ))

            for (index, paragraph) in block.paragraphs.enumerated() {
                let text = block.numbered ? "\(index + 1). \(paragraph)\n" : paragraph + "\n"
                document.append(NSAttributedString(
                    string: text,
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: body,
                        .paragraphStyle: paragraphStyle(spacingBefore: 0, spacingAfter: 6, lineSpacing: 3),
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
