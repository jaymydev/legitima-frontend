import SwiftUI

/// Le premier écran : le logo au centre, et le texte qui défile dessous.
///
/// La zone de texte a une hauteur fixe. Sans elle, une phrase plus longue que
/// la précédente pousserait le logo vers le haut à chaque temps — le repère
/// censé tenir la composition serait le seul élément qui bouge.
///
/// Un tap n'importe où abrège : quelqu'un qui rouvre l'app pour la dixième fois
/// n'a pas à attendre qu'on lui réexplique.
struct LaunchIntroScreen: View {
    let intro: LaunchIntro
    let onFinished: () -> Void

    @State private var identiteVisible = false
    @State private var tempsVisible: Int?
    @State private var echelle: Double = LaunchIntro.entranceScale
    @State private var sortie = false
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

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                // L'icône n'a pas de canal alpha : ses coins sont blancs et
                // trancheraient sur le dégradé. Découpée à la forme d'icône
                // iOS, elle se lit comme ce qu'elle est — l'app elle-même.
                Image(LaunchIntro.markAsset)
                    .resizable()
                    .frame(width: 104, height: 104)
                    .clipShape(RoundedRectangle(cornerRadius: 104 * 0.2237, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
                    .scaleEffect(echelle)
                    .accessibilityHidden(true)

                Text(LaunchIntro.wordmark)
                    .font(.footnote.weight(.bold))
                    .kerning(3.2)
                    .foregroundColor(LegitimaColors.accent)
                    .padding(.top, 20)

                // Hauteur fixe : le logo ne bouge pas d'un temps à l'autre.
                ZStack {
                    ForEach(Array(intro.beats.enumerated()), id: \.offset) { index, beat in
                        Text(beat.text)
                            .font(beat.text == LaunchIntro.slogan
                                  ? .system(.title2, design: .rounded).weight(.heavy)
                                  : .body)
                            .foregroundColor(beat.text == LaunchIntro.slogan
                                             ? LegitimaColors.ink
                                             : LegitimaColors.body)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(tempsVisible == index ? 1 : 0)
                    }
                }
                .frame(height: 108, alignment: .top)
                .padding(.top, 34)
                .padding(.horizontal, 8)

                Spacer(minLength: 0)
            }
            .opacity(identiteVisible && !sortie ? 1 : 0)
            .frame(maxWidth: 460)
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity)
        }
        // Tout l'écran est la cible : personne ne doit chercher où appuyer pour
        // passer. Aucun bouton « Passer » — il occuperait un coin au moment
        // précis où l'on veut que le regard reste au centre.
        .contentShape(Rectangle())
        .onTapGesture(perform: onFinished)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(
            ([LaunchIntro.wordmark] + intro.beats.map(\.text)).joined(separator: ". ")
        )
        .accessibilityHint("Touchez pour passer")
        .onAppear(perform: play)
    }

    /// La séquence vient du modèle : cette vue ne décide d'aucune durée.
    private func play() {
        guard !reduceMotion else {
            // Mouvement réduit : ni ressort ni dissolution. Le contenu est là,
            // et l'écran cède la place au même moment qu'il l'aurait fait.
            identiteVisible = true
            echelle = 1
            tempsVisible = intro.beats.indices.last
            DispatchQueue.main.asyncAfter(deadline: .now() + intro.duration, execute: onFinished)
            return
        }

        // L'arrivée : le logo monte à sa taille en dépassant un peu. C'est le
        // seul mouvement démonstratif de l'app, et il est à sa place — on
        // présente quelque chose avant de s'en servir.
        withAnimation(.easeOut(duration: LaunchIntro.fade)) { identiteVisible = true }
        withAnimation(.spring(response: LaunchIntro.entrance, dampingFraction: 0.62)) {
            echelle = 1
        }

        for (index, beat) in intro.beats.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + beat.start) {
                withAnimation(.easeInOut(duration: LaunchIntro.fade)) { tempsVisible = index }
            }
            if let end = beat.end {
                DispatchQueue.main.asyncAfter(deadline: .now() + end) {
                    withAnimation(.easeInOut(duration: LaunchIntro.fade)) {
                        // Ne effacer que si un temps suivant n'a pas déjà pris
                        // la main : sinon un tap tardif rallumerait le vide.
                        if tempsVisible == index { tempsVisible = nil }
                    }
                }
            }
        }
        // La sortie : le logo s'ouvre et se dissout. L'écran ne se retire pas,
        // on entre dedans.
        DispatchQueue.main.asyncAfter(deadline: .now() + intro.exitStart) {
            withAnimation(.easeIn(duration: LaunchIntro.exit)) {
                echelle = LaunchIntro.exitScale
                sortie = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + intro.duration, execute: onFinished)
    }
}
