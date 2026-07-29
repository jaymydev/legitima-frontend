import SwiftUI
import UIKit

extension UIColor {
    /// 0-255 component helper for the palette definitions below.
    static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, alpha: CGFloat = 1) -> UIColor {
        UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
    }
}

extension Color {
    /// Resolves to a different color depending on the interface style.
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

/// Adaptive palette for the light-first Legitima design and its dark counterpart.
/// Screens keep their exact V1 light values; dark values share a common identity.
enum LegitimaColors {
    // MARK: Text

    static let ink = Color(light: .rgb(47, 49, 49), dark: .rgb(233, 237, 236))
    static let body = Color(light: .rgb(62, 67, 67), dark: .rgb(206, 213, 212))
    static let muted = Color(light: .rgb(91, 95, 95), dark: .rgb(160, 170, 169))

    // MARK: Accents

    /// Teal for text, icons, and tints — brightened in dark mode for contrast.
    static let accent = Color(light: .rgb(43, 111, 113), dark: .rgb(121, 197, 198))
    /// Teal for filled controls carrying white labels — stays deep in dark mode.
    static let accentSurface = Color(light: .rgb(43, 111, 113), dark: .rgb(45, 116, 118))
    static let gold = Color(light: .rgb(185, 132, 43), dark: .rgb(222, 179, 106))

    // MARK: Surfaces

    static let surface = Color(light: .rgb(255, 255, 255, alpha: 0.92), dark: .rgb(36, 43, 44))
    static let surfaceStrong = Color(light: .white, dark: .rgb(41, 48, 49))
    static let field = Color(light: .white, dark: .rgb(46, 54, 55))
    static let chip = Color(light: .rgb(226, 244, 240), dark: .rgb(33, 47, 44))
    static let hairline = Color(
        light: UIColor.black.withAlphaComponent(0.06),
        dark: UIColor.white.withAlphaComponent(0.09)
    )

    // MARK: Screen background gradient stops (shared dark identity)

    static let darkBackgroundTop = UIColor.rgb(15, 23, 24)
    static let darkBackgroundMid = UIColor.rgb(20, 28, 29)
    static let darkBackgroundBottom = UIColor.rgb(25, 32, 33)
}
