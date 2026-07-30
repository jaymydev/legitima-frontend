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

/// Motion is used to explain, never to decorate: the user is preparing a
/// stressful conversation. These are the only two curves in the app.
enum LegitimaMotion {
    /// Content arriving — card entrances, phase changes.
    static let reveal = Animation.spring(response: 0.45, dampingFraction: 0.85)
    /// Direct response to a tap — selection, step changes.
    static let control = Animation.spring(response: 0.3, dampingFraction: 0.8)

    /// Delay for the nth card in a staggered entrance.
    static func revealDelay(_ index: Int) -> Double {
        0.06 + Double(index) * 0.09
    }
}

extension View {
    /// Staggered card entrance: fade in while sliding up. Promoted from
    /// PremiumKickoffScreen, where the pacing was first tuned.
    func revealed(_ isRevealed: Bool) -> some View {
        opacity(isRevealed ? 1 : 0)
            .offset(y: isRevealed ? 0 : 14)
    }

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
