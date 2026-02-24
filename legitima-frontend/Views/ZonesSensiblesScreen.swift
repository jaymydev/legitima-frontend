import SwiftUI

struct ZonesSensiblesScreen: View {
    @State private var periodesSensibles = ""
    @State private var explicationBrute = ""
    @State private var relectureStrategique = ""
    @State private var reformulationAssumee = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "CFFCF9"), Color(hex: "EDF3F3")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    card(
                        title: "Périodes sensibles identifiées",
                        description: "Indiquez les périodes de votre parcours qui vous semblent fragiles ou difficiles à expliquer.",
                        text: $periodesSensibles,
                        placeholder: "– Période concernée :\n– Contexte :\n– Pourquoi cela vous met en difficulté :",
                        warning: "Ce point mérite d’être approfondi pour renforcer votre récit."
                    )

                    card(
                        title: "Explication actuelle (brute)",
                        description: "Comment expliquez-vous aujourd’hui cette période, sans filtre stratégique ?",
                        text: $explicationBrute,
                        placeholder: "– Ce que je dis généralement :\n– Ce que je ressens encore :\n– Ce que j’évite de mentionner :",
                        warning: "Ce point mérite d’être approfondi pour renforcer votre récit."
                    )

                    card(
                        title: "Relecture stratégique",
                        description: "Comment pourriez-vous relire cette période de manière factuelle et constructive ?",
                        text: $relectureStrategique,
                        placeholder: "– Compétences développées :\n– Apprentissages réels :\n– Éléments objectifs positifs :",
                        warning: "Ce point mérite d’être approfondi pour renforcer votre récit."
                    )

                    card(
                        title: "Reformulation assumée",
                        description: "Formulez une version claire et assumée que vous pourriez défendre en entretien.",
                        text: $reformulationAssumee,
                        placeholder: "– Formulation synthétique :\n– Angle choisi :\n– Message que je veux faire passer :",
                        warning: "Ce point mérite d’être approfondi pour renforcer votre récit."
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Identifier vos zones sensibles")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(Color(hex: "2F3131"))

            Text("Pour transformer les fragilités en maîtrise narrative.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "5B5F5F"))
        }
    }

    private func card(
        title: String,
        description: String,
        text: Binding<String>,
        placeholder: String,
        warning: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(Color(hex: "2F3131"))

            Text(description)
                .font(.subheadline)
                .foregroundStyle(Color(hex: "5B5F5F"))

            PlaceholderTextEditor(
                placeholder: placeholder,
                text: text,
                primaryColor: Color(hex: "2F3131"),
                minHeight: 120
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "DDE3E3"), lineWidth: 1)
            )

            if text.wrappedValue.count < 30 {
                Text(warning)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

#Preview {
    ZonesSensiblesScreen()
}
