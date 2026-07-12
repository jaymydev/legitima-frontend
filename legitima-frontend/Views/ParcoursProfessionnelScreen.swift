import SwiftUI

struct ParcoursProfessionnelScreen: View {
    @State private var posteActuel = ""
    @State private var experiences = ""
    @State private var elementsCles = ""
    @State private var transitions = ""
    @State private var showIncompleteAlert = false
    @State private var showOptionalWarning = false
    @State private var navigate = false

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
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Parcours professionnel")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(primaryTextColor)

                        Text("Décrivez votre trajectoire de façon stratégique pour mettre en avant les choix, acquis et évolutions qui servent votre positionnement.")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Poste actuel ou dernier poste")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryTextColor)

                        TextField("Ex : Senior PLM Engineer – Pilotage migration 3DEXPERIENCE – Management transverse", text: $posteActuel)
                            .font(.subheadline)
                            .foregroundColor(primaryTextColor)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Expériences précédentes")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryTextColor)

                        PlaceholderTextEditor(
                            placeholder:
                                """
                                2018–2021 : Développeuse backend – Secteur bancaire
                                • Refonte API REST
                                • Coordination équipe de 4 personnes
                                • Amélioration performance +30%

                                2021–2022 : Formation Data
                                • Certification Python
                                • Projet personnel IA
                                """,
                            text: $experiences,
                            primaryColor: primaryTextColor,
                            minHeight: 120
                        )
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Éléments clés du parcours")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryTextColor)

                        PlaceholderTextEditor(
                            placeholder:
                                """
                                • Montée progressive en responsabilités
                                • Spécialisation sur les environnements complexes
                                • Capacité à gérer des contextes instables
                                • Leadership transverse
                                """,
                            text: $elementsCles,
                            primaryColor: primaryTextColor,
                            minHeight: 100
                        )
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transitions ou ruptures")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryTextColor)

                        PlaceholderTextEditor(
                            placeholder:
                                """
                                2022 : Période de bench (6 mois)
                                → Formation stratégique
                                → Clarification positionnement
                                → Choix assumé d’évolution
                                """,
                            text: $transitions,
                            primaryColor: primaryTextColor,
                            minHeight: 100
                        )
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)

                    Button(action: {
                        if posteActuel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showIncompleteAlert = true
                        } else if experiences.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    || elementsCles.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    || transitions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showOptionalWarning = true
                        } else {
                            navigate = true
                        }
                    }) {
                        Text("Suivant")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
        }
        .alert("Informations manquantes", isPresented: $showIncompleteAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Le poste actuel ou dernier poste est essentiel pour structurer un récit professionnel clair et stratégique.")
        }
        .alert("Champs incomplets", isPresented: $showOptionalWarning) {
            Button("Modifier les infos", role: .cancel) { }
            Button("Continuer malgré tout") {
                navigate = true
            }
        } message: {
            Text(
                """
                Certains champs n’ont pas été renseignés.
                Le résultat final pourrait être moins précis ou moins stratégique.
                Voulez-vous continuer malgré tout ?
                """
            )
        }
        .navigationDestination(isPresented: $navigate) {
            ZonesSensiblesScreen()
        }
    }
}
