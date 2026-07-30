import SwiftUI
import UIKit

/// Justified body text for card content. SwiftUI's Text cannot justify, so
/// this wraps a UILabel with justified alignment and hyphenation (which keeps
/// French text from opening large gaps between words).
struct JustifiedText: UIViewRepresentable {
    private let text: String
    private let textStyle: UIFont.TextStyle
    private let color: Color
    private let lineLimit: Int

    init(
        _ text: String,
        textStyle: UIFont.TextStyle = .subheadline,
        color: Color,
        lineLimit: Int = 0
    ) {
        self.text = text
        self.textStyle = textStyle
        self.color = color
        self.lineLimit = lineLimit
    }

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        label.numberOfLines = lineLimit
        label.attributedText = attributedText
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView label: UILabel,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0 else {
            return nil
        }
        let fitted = label.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        return CGSize(width: width, height: fitted.height)
    }

    private var attributedText: NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .justified
        paragraph.hyphenationFactor = 0.9
        paragraph.lineBreakMode = .byWordWrapping

        return NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: textStyle),
                .foregroundColor: UIColor(color),
                .paragraphStyle: paragraph,
            ]
        )
    }
}
