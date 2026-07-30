import Foundation

/// Drives the wait indicator. Foundation-only so the pacing can be tested
/// without a view.
///
/// The backend reports no progress — analyse and preparation are single
/// requests that answer when they are done. So the percentage is estimated
/// from elapsed time on a decelerating curve with a hard ceiling: it never
/// claims more than it knows, never reaches 100 % while still waiting, and
/// never goes backwards. The displayed step is derived from the same value,
/// so the words and the number cannot disagree.
enum LoadingProgressEstimate {
    /// Highest fraction the estimate will ever show while waiting.
    static let ceiling = 0.92

    static func progress(
        elapsed: TimeInterval,
        typicalDuration: TimeInterval
    ) -> Double {
        guard elapsed > 0, typicalDuration > 0 else { return 0 }
        let tau = typicalDuration / 2.2
        return ceiling * (1 - exp(-elapsed / tau))
    }

    /// Index of the step to show for a given progress value.
    static func stepIndex(for progress: Double, count: Int) -> Int {
        guard count > 1 else { return 0 }
        switch progress {
        case ..<0.35:
            return 0
        case ..<0.70:
            return min(1, count - 1)
        default:
            return count - 1
        }
    }

    /// Said once past 12 s, then replaced past 30 s. A cold start on the
    /// hosting side is the normal case here, so staying silent would read as
    /// a freeze.
    static func slowNotice(elapsed: TimeInterval) -> String? {
        switch elapsed {
        case ..<12:
            return nil
        case ..<30:
            return "C’est un peu plus long que d’habitude. On continue."
        default:
            return "Le serveur met plus de temps à répondre. Vos informations sont conservées."
        }
    }
}
