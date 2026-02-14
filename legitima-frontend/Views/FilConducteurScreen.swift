import SwiftUI

struct FilConducteurScreen: View {
    @State private var resumeGlobal = ""
    @State private var positionnementActuel = ""
    @State private var logiqueEvolution = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 207 / 255, green: 252 / 255, blue: 249 / 255),
                    Color(red: 237 / 255, green: 243 / 255, blue: 243 / 255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Construire votre fil conducteur")
                            .font(.largeTitle.bold())
                            .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                        Text("Structurer un récit cohérent et défendable de votre parcours.")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    cardView(
                        title: "Résumé stratégique (5 à 7 lignes)",
                        description: "Racontez votre parcours comme une progression logique et non comme une succession d’événements.",
                        text: $resumeGlobal,
                        placeholder: "– Point de départ :\n– Évolution clé :\n– Compétences consolidées :\n– Positionnement actuel :",
                        warning: resumeGlobal.count < 150 ? "Essayez d’atteindre au moins 150 caractères pour formuler un récit structuré." : nil
                    )

                    cardView(
                        title: "Positionnement actuel",
                        description: "Définissez clairement votre posture professionnelle aujourd’hui.",
                        text: $positionnementActuel,
                        placeholder: "– Rôle cible :\n– Valeur ajoutée principale :\n– Différenciation :",
                        warning: positionnementActuel.count < 50 ? "Essayez d’atteindre au moins 50 caractères pour clarifier votre positionnement." : nil
                    )

                    cardView(
                        title: "Logique d’évolution",
                        description: "Expliquez pourquoi vos choix successifs forment une continuité stratégique.",
                        text: $logiqueEvolution,
                        placeholder: "– Décision clé 1 :\n– Décision clé 2 :\n– Cohérence globale :",
                        warning: logiqueEvolution.count < 50 ? "Essayez d’atteindre au moins 50 caractères pour expliciter la cohérence de vos choix." : nil
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
        }
    }

    private func cardView(
        title: String,
        description: String,
        text: Binding<String>,
        placeholder: String,
        warning: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

            Text(description)
                .font(.subheadline)
                .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))

            ZStack(alignment: .topLeading) {
                TextEditor(text: text)
                    .frame(minHeight: 120)
                    .padding(4)
                    .scrollContentBackground(.hidden)
                    .background(Color.white)

                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.subheadline)
                        .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255).opacity(0.7))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let warning {
                Text(warning)
                    .font(.caption)
                    .foregroundColor(Color.orange)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    FilConducteurScreen()
}
