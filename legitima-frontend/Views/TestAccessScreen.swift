import SwiftUI

struct TestAccessScreen: View {
    let hasSavedWork: Bool
    let onContinueTesting: () -> Void

    @State private var unavailableAction: AccountAction?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 218 / 255, green: 249 / 255, blue: 246 / 255),
                    Color(red: 247 / 255, green: 242 / 255, blue: 232 / 255),
                    Color(red: 232 / 255, green: 241 / 255, blue: 245 / 255)
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
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(red: 42 / 255, green: 48 / 255, blue: 48 / 255))

                        Text("Préparez votre parcours professionnel avec clarté, puis retrouvez votre travail à tout moment.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(red: 88 / 255, green: 96 / 255, blue: 96 / 255))
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
                            .background(Color(red: 37 / 255, green: 106 / 255, blue: 110 / 255))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }

                        accountButton(title: "Se connecter", action: .signIn)
                        accountButton(title: "Créer un nouveau compte", action: .createAccount)
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)

                    Text("Le mode test conserve votre préparation sur cet appareil. La synchronisation entre appareils arrivera avec les comptes.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(red: 88 / 255, green: 96 / 255, blue: 96 / 255))
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
                    .foregroundColor(Color(red: 37 / 255, green: 106 / 255, blue: 110 / 255))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .foregroundColor(Color(red: 42 / 255, green: 48 / 255, blue: 48 / 255))
            .background(Color.white.opacity(0.88))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.07), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
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
