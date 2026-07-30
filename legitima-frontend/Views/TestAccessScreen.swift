import SwiftUI

struct TestAccessScreen: View {
    let hasSavedWork: Bool
    let onContinueTesting: () -> Void

    @State private var unavailableAction: AccountAction?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(light: .rgb(218, 249, 246), dark: LegitimaColors.darkBackgroundTop),
                    Color(light: .rgb(247, 242, 232), dark: LegitimaColors.darkBackgroundMid),
                    Color(light: .rgb(232, 241, 245), dark: LegitimaColors.darkBackgroundBottom)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 42)

                    VStack(spacing: 12) {
                        Text("Bienvenue sur\nLegitima")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(LegitimaColors.ink)

                        Text("Préparez votre parcours professionnel avec clarté, puis retrouvez votre travail à tout moment.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(LegitimaColors.muted)
                            .padding(.horizontal, 14)
                    }

                    VStack(spacing: 14) {
                        Button(action: onContinueTesting) {
                            VStack(spacing: 4) {
                                Text(hasSavedWork ? "Reprendre en mode test" : "Continuer en mode test")
                                    .fontWeight(.bold)

                                Text(hasSavedWork ? "Votre dernière préparation est disponible" : "20 analyses par jour, sans création de compte")
                                    .font(.caption)
                                    .opacity(0.86)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundColor(.white)
                            .background(LegitimaColors.accentSurface)
                            .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
                        }

                        accountButton(title: "Se connecter", action: .signIn)
                        accountButton(title: "Créer un nouveau compte", action: .createAccount)
                    }
                    .padding(20)
                    .background(LegitimaColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.hero))
                    .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)

                    Text("Le mode test conserve votre préparation sur cet appareil. La synchronisation entre appareils arrivera avec les comptes.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(LegitimaColors.muted)
                        .padding(.horizontal, 20)

                    Spacer(minLength: 30)
                }
                .frame(maxWidth: 620)
                .padding(.horizontal, 22)
                .frame(maxWidth: .infinity)
            }
        }
        .alert(item: $unavailableAction) { action in
            Alert(
                title: Text(action.title),
                message: Text("Cette option sera activée avec la future base de données. Pour l’instant, utilisez le mode test sans créer de compte."),
                dismissButton: .default(Text("Compris"))
            )
        }
    }

    private func accountButton(title: String, action: AccountAction) -> some View {
        Button {
            unavailableAction = action
        } label: {
            HStack {
                Text(title)
                    .fontWeight(.semibold)
                Spacer()
                Text("Bientôt")
                    .font(.caption.weight(.bold))
                    .foregroundColor(LegitimaColors.accent)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .foregroundColor(LegitimaColors.ink)
            .background(LegitimaColors.field)
            .overlay(
                RoundedRectangle(cornerRadius: LegitimaRadius.control)
                    .stroke(LegitimaColors.hairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.control))
        }
    }
}

private enum AccountAction: String, Identifiable {
    case signIn
    case createAccount

    var id: String { rawValue }

    var title: String {
        switch self {
        case .signIn:
            return "Connexion bientôt disponible"
        case .createAccount:
            return "Création de compte bientôt disponible"
        }
    }
}
