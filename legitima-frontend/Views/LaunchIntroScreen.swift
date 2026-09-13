import SwiftUI

/// Le premier écran. Le nom, ce qu'il veut dire, et rien à faire.
///
/// Il reprend le dégradé de l'écran d'entrée pour que le passage de l'un à
/// l'autre ne soit pas une rupture mais une suite. Un tap n'importe où
/// l'abrège : quelqu'un qui rouvre l'app pour la dixième fois n'a pas à
/// attendre qu'on lui réexplique.
struct LaunchIntroScreen: View {
    let intro: LaunchIntro
    let onFinished: () -> Void

    @State private var shown: Set<Int> = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(light: .rgb(218, 249, 246), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(247, 242, 232), dark: LegitimaColors.darkBackgroundBottom)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Le bloc est calé sur l'en-tête de l'écran d'entrée — même marge,
            // même largeur, même position. Au passage de l'un à l'autre, le
            // badge paraît ne pas bouger et le titre se substitue au slogan.
            // Centré verticalement, le fondu croisait deux badges à deux
            // hauteurs et deux textes superposés : on voyait la couture.
            VStack(alignment: .leading, spacing: 0) {
                // L'icône n'a pas de canal alpha : ses coins sont blancs et
                // trancheraient sur le dégradé. Découpée à la forme d'icône
                // iOS, elle se lit comme ce qu'elle est — l'app elle-même.
                Image(LaunchIntro.markAsset)
                    .resizable()
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 84 * 0.2237, style: .continuous))
                    .shadow(color: .black.opacity(0.10), radius: 14, y: 6)
                    .padding(.bottom, 24)
                    .revealed(shown.contains(0))
                    .accessibilityHidden(true)

                Text(LaunchIntro.wordmark)
                    .font(.caption.weight(.bold))
                    .foregroundColor(LegitimaColors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(LegitimaColors.surface)
                    .clipShape(Capsule())
                    .revealed(shown.contains(1))

                Text(LaunchIntro.slogan)
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundColor(LegitimaColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                    .revealed(shown.contains(2))

                if intro.pace == .first {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(LaunchIntro.lines.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.title3)
                                .foregroundColor(LegitimaColors.body)
                                .fixedSize(horizontal: false, vertical: true)
                                .revealed(shown.contains(index + 3))
                        }
                    }
                    .padding(.top, 26)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Tout l'écran est la cible : personne ne doit chercher où appuyer pour
        // passer. Aucun bouton « Passer » — il occuperait le coin au moment
        // précis où l'on veut que le regard aille au texte.
        .contentShape(Rectangle())
        .onTapGesture(perform: onFinished)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(LaunchIntro.slogan) \(intro.pace == .first ? LaunchIntro.lines.joined(separator: " ") : "")")
        .accessibilityHint("Touchez pour passer")
        .onAppear(perform: play)
    }

    /// La séquence vient du modèle : cette vue ne décide d'aucune durée.
    private func play() {
        guard !reduceMotion else {
            // Mouvement réduit : tout est là d'emblée, et l'écran s'efface au
            // même moment qu'il l'aurait fait animé.
            shown = Set(intro.timeline.indices)
            DispatchQueue.main.asyncAfter(deadline: .now() + intro.duration, execute: onFinished)
            return
        }
        for (index, item) in intro.timeline.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + item.delay) {
                withAnimation(.easeOut(duration: LaunchIntro.fade)) {
                    _ = shown.insert(index)
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + intro.duration, execute: onFinished)
    }
}
