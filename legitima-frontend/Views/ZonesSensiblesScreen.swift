import SwiftUI

struct ZonesSensiblesScreen: View {
    @State private var periodesSensibles = ""
    @State private var explicationBrute = ""

    private let primaryText = Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255)
    private let secondaryText = Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255)
    private let buttonColor = Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 207 / 255, green: 252 / 255, blue: 249 / 255),
                    Color(red: 237 / 255, green: 243 / 255, blue: 243 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ambientBackground

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headerSection
                    framingCard

                    guidedStepCard(
                        index: "1",
                        title: "La phase à expliquer",
                        helper: "Choisissez une seule phase qui vous semble délicate à raconter.",
                        placeholder: "Ex : bench, pause, reconversion, changements fréquents.",
                        text: $periodesSensibles,
                        minHeight: 84
                    )

                    guidedStepCard(
                        index: "2",
                        title: "Ce qui s’est passé, simplement",
                        helper: "Décrivez cette phase avec vos mots. Une version simple suffit.",
                        placeholder: "Ex : cette période peut sembler instable, alors qu’elle correspondait à une vraie transition.",
                        text: $explicationBrute,
                        minHeight: 120
                    )

                    nudgeCard

                    NavigationLink(destination: RequalificationScreen()) {
                        Text("Continuer")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [
                                        buttonColor,
                                        Color(red: 54 / 255, green: 132 / 255, blue: 134 / 255)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: buttonColor.opacity(0.22), radius: 12, x: 0, y: 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ETAPE 3")
                .font(.caption.weight(.bold))
                .foregroundColor(buttonColor.opacity(0.82))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.72))
                .clipShape(Capsule())

            Text("Nommer la phase\na expliquer")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(primaryText)

            Text("Ici, vous posez simplement les faits. La reformulation vient juste après.")
                .font(.subheadline)
                .foregroundColor(secondaryText)
        }
    }

    private var framingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title3)
                    .foregroundColor(buttonColor)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Objectif de cette étape")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryText)

                    Text("Le but n’est pas de bien tourner votre réponse. Le but est juste de nommer la phase et votre lecture actuelle.")
                        .font(.subheadline)
                        .foregroundColor(secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                framingPill("1 phase")
                framingPill("vos mots")
                framingPill("rapide")
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.96),
                    Color(red: 244 / 255, green: 252 / 255, blue: 250 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var ambientBackground: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.34))
                .frame(width: 220, height: 220)
                .blur(radius: 8)
                .offset(x: 150, y: -250)

            Circle()
                .fill(Color(red: 170 / 255, green: 232 / 255, blue: 224 / 255).opacity(0.34))
                .frame(width: 200, height: 200)
                .blur(radius: 10)
                .offset(x: -140, y: 260)
        }
        .allowsHitTesting(false)
    }

    private func framingPill(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(buttonColor.opacity(0.92))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(red: 233 / 255, green: 247 / 255, blue: 241 / 255))
            .clipShape(Capsule())
    }

    private var nudgeCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundColor(buttonColor)

            Text("Restez simple. Une version honnête sera plus utile qu’une formulation déjà trop travaillée.")
                .font(.footnote)
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(red: 233 / 255, green: 247 / 255, blue: 241 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func guidedStepCard(
        index: String,
        title: String,
        helper: String,
        placeholder: String,
        text: Binding<String>,
        minHeight: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text(index)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(buttonColor)
                    .frame(width: 28, height: 28)
                    .background(Color(red: 233 / 255, green: 247 / 255, blue: 241 / 255))
                    .clipShape(Circle())

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryText)
            }

            Text(helper)
                .font(.subheadline)
                .foregroundColor(secondaryText)

            PlaceholderTextEditor(
                placeholder: placeholder,
                text: text,
                primaryColor: primaryText,
                minHeight: minHeight
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 224 / 255, green: 231 / 255, blue: 231 / 255), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

struct ZonesSensiblesScreen_Previews: PreviewProvider {
    static var previews: some View {
        ZonesSensiblesScreen()
    }
}
