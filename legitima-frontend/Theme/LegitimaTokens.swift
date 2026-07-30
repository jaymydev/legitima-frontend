import SwiftUI

/// Three corner radii, one per role. The codebase had drifted to eight values
/// (14, 16, 17, 18, 20, 22, 24, 26, 28) that encoded no hierarchy — two cards
/// sitting in the same stack could differ by a single point.
enum LegitimaRadius {
    /// Buttons, fields, chips — anything the user acts on.
    static let control: CGFloat = 14
    /// Content cards.
    static let card: CGFloat = 18
    /// Full-width feature panels that lead a screen.
    static let hero: CGFloat = 24
}

/// Standard vertical rhythm inside cards.
enum LegitimaSpacing {
    static let cardPadding: CGFloat = 18
    static let controlPadding: CGFloat = 16
}

extension View {
    /// Filled call to action. Replaces five hand-rolled heights (12, 14, 15,
    /// 16 and 18 points of vertical padding) with one.
    func legitimaPrimaryLabel() -> some View {
        fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding(LegitimaSpacing.controlPadding)
            .foregroundColor(.white)
            .background(LegitimaColors.accentSurface)
            .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))
    }

    /// Quiet alternative sitting under a primary action.
    func legitimaSecondaryLabel() -> some View {
        fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(LegitimaSpacing.controlPadding)
            .foregroundColor(LegitimaColors.accent)
            .background(LegitimaColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))
    }
    /// The shared content-card treatment: leading-aligned, padded, rounded.
    func legitimaCard(
        padding: CGFloat = LegitimaSpacing.cardPadding,
        radius: CGFloat = LegitimaRadius.card,
        background: Color = LegitimaColors.surface
    ) -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}
