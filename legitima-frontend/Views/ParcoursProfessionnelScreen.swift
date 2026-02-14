import SwiftUI

struct ParcoursProfessionnelScreen: View {
    @State private var posteActuel = ""
    @State private var experiences = ""
    @State private var elementsCles = ""
    @State private var transitions = ""
    @State private var showIncompleteAlert = false
    @State private var showOptionalWarning = false

    private let primaryTextColor = Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255)
    private let secondaryTextColor = Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255)

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
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Parcours professionnel")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(primaryTextColor)

                        Text("Décrivez votre trajectoire de façon stratégique pour mettre en avant les choix, acquis et évolutions qui servent votre positionnement.")
                            .font(.body)
                            .foregroundColor(secondaryTextColor)

                        Rectangle()
                            .fill(secondaryTextColor)
                            .frame(height: 1)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Poste actuel ou dernier poste")
                            .font(.headline)
                            .foregroundColor(primaryTextColor)

                        TextField("Ex : Senior PLM Engineer – Pilotage migration 3DEXPERIENCE – Management transverse", text: $posteActuel)
                            .font(.body)
                            .foregroundColor(primaryTextColor)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Expériences précédentes")
                            .font(.headline)
                            .foregroundColor(primaryTextColor)

                        ZStack(alignment: .topLeading) {
                            if experiences.isEmpty {
                                Text(
                                    """
                                    2018–2021 : Développeuse backend – Secteur bancaire
                                    • Refonte API REST
                                    • Coordination équipe de 4 personnes
                                    • Amélioration performance +30%

                                    2021–2022 : Formation Data
                                    • Certification Python
                                    • Projet personnel IA
                                    """
                                )
                                .font(.body)
                                .foregroundColor(secondaryTextColor.opacity(0.65))
                                .padding(.horizontal, 13)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                            }

                            TextEditor(text: $experiences)
                                .font(.body)
                                .foregroundColor(primaryTextColor)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Éléments clés du parcours")
                            .font(.headline)
                            .foregroundColor(primaryTextColor)

                        ZStack(alignment: .topLeading) {
                            if elementsCles.isEmpty {
                                Text(
                                    """
                                    • Montée progressive en responsabilités
                                    • Spécialisation sur les environnements complexes
                                    • Capacité à gérer des contextes instables
                                    • Leadership transverse
                                    """
                                )
                                .font(.body)
                                .foregroundColor(secondaryTextColor.opacity(0.65))
                                .padding(.horizontal, 13)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                            }

                            TextEditor(text: $elementsCles)
                                .font(.body)
                                .foregroundColor(primaryTextColor)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transitions ou ruptures")
                            .font(.headline)
                            .foregroundColor(primaryTextColor)

                        ZStack(alignment: .topLeading) {
                            if transitions.isEmpty {
                                Text(
                                    """
                                    2022 : Période de bench (6 mois)
                                    → Formation stratégique
                                    → Clarification positionnement
                                    → Choix assumé d’évolution
                                    """
                                )
                                .font(.body)
                                .foregroundColor(secondaryTextColor.opacity(0.65))
                                .padding(.horizontal, 13)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                            }

                            TextEditor(text: $transitions)
                                .font(.body)
                                .foregroundColor(primaryTextColor)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)

                    Button(action: {
                        if posteActuel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showIncompleteAlert = true
                        } else if experiences.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    || elementsCles.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    || transitions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showOptionalWarning = true
                        } else {
                        }
                    }) {
                        Text("Continuer")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))
                            .cornerRadius(12)
                    }
                }
                .padding(24)
            }
        }
        .alert("Informations manquantes", isPresented: $showIncompleteAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Le poste actuel ou dernier poste est essentiel pour structurer un récit professionnel clair et stratégique.")
        }
        .alert("Champs incomplets", isPresented: $showOptionalWarning) {
            Button("Modifier les infos", role: .cancel) { }
            Button("Continuer malgré tout") { }
        } message: {
            Text(
                """
                Certains champs n’ont pas été renseignés.
                Le résultat final pourrait être moins précis ou moins stratégique.
                Voulez-vous continuer malgré tout ?
                """
            )
        }
    }
}

#Preview {
    ParcoursProfessionnelScreen()
}
