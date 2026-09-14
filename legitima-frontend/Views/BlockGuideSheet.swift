import SwiftUI

/// Ce que chaque bloc d'une carte est, montré plutôt que raconté.
///
/// Chaque ligne reprend le pictogramme, la couleur et l'étiquette exacts du
/// bloc qu'elle explique — ils viennent tous de `Tone`, comme la carte
/// elle-même. Une explication qui montrerait un autre signe que celui de
/// l'écran porterait à faux.
struct BlockGuideSheet: View {
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(BlockGuide.title)
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundColor(LegitimaColors.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(BlockGuide.subtitle)
                    .font(.subheadline)
                    .foregroundColor(LegitimaColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(BlockGuide.entries.enumerated()), id: \.offset) { _, entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Label(entry.label, systemImage: entry.symbol)
                                .font(.caption.weight(.bold))
                                .foregroundColor(couleur(entry.tone))

                            Text(entry.explanation)
                                .font(.subheadline)
                                .foregroundColor(LegitimaColors.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .legitimaCard()
                    }
                }
                .padding(.top, 24)

                Button(action: onClose) {
                    Text("J'ai compris")
                        .legitimaPrimaryLabel()
                }
                .padding(.top, 26)
            }
            .frame(maxWidth: 640)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        // Le même fond que les autres écrans : les blocs blancs s'y détachent.
        // Sur `surfaceStrong`, blanc sur blanc, ils se lisaient comme du texte
        // courant — l'explication perdait la forme qu'elle explique.
        .background(
            LinearGradient(
                colors: [
                    Color(light: .rgb(218, 249, 246), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(247, 242, 232), dark: LegitimaColors.darkBackgroundBottom)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    /// Les mêmes couleurs que sur la carte : l'accent pour ce qui se dit, le
    /// discret pour la relance, l'or pour ce qui coûte cher.
    private func couleur(_ tone: PreparationExportContent.Tone) -> Color {
        switch tone {
        case .avoid: return LegitimaColors.gold
        case .followUp: return LegitimaColors.muted
        default: return LegitimaColors.accent
        }
    }
}
