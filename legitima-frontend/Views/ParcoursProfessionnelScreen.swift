import SwiftUI

struct ParcoursProfessionnelScreen: View {
    @EnvironmentObject private var premiumDraft: PremiumPreparationDraft
    @State private var posteActuel = ""
    @State private var experiences = ""
    @State private var elementsCles = ""
    @State private var transitions = ""
    @State private var showIncompleteAlert = false
    @State private var showOptionalWarning = false
    @State private var navigate = false

    private let primaryTextColor = Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255)
    private let secondaryTextColor = Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255)
    private let buttonColor = Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255)

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
                VStack(alignment: .leading, spacing: 22) {
                    headerSection
                    framingCard

                    guidedInputCard(
                        index: "1",
                        title: "Votre poste actuel ou dernier poste",
                        helper: "C’est le point d’ancrage principal de votre récit. Une ligne claire suffit.",
                        content: AnyView(
                            TextField(
                                "Ex : Senior PLM Engineer - pilotage migration 3DEXPERIENCE",
                                text: $posteActuel
                            )
                            .font(.subheadline)
                            .foregroundColor(primaryTextColor)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                        )
                    )

                    guidedInputCard(
                        index: "2",
                        title: "Les expériences à retenir",
                        helper: "Ne racontez pas tout. Gardez seulement les 2 ou 3 étapes les plus utiles pour comprendre votre évolution.",
                        content: AnyView(
                            PlaceholderTextEditor(
                                placeholder:
                                    """
                                    Ex :
                                    2019-2022 : Développement logiciel embarqué
                                    2022-2024 : Coordination transverse et validation
                                    2024-2025 : Migration, structuration, sujets complexes
                                    """,
                                text: $experiences,
                                primaryColor: primaryTextColor,
                                minHeight: 110
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        )
                    )

                    guidedInputCard(
                        index: "3",
                        title: "Ce que votre parcours montre de vous",
                        helper: "Pensez compétences, posture, manière d’évoluer. Quelques points simples suffisent.",
                        content: AnyView(
                            PlaceholderTextEditor(
                                placeholder:
                                    """
                                    Ex :
                                    - montée en responsabilité progressive
                                    - aisance dans les contextes techniques complexes
                                    - capacité à structurer et rassurer
                                    """,
                                text: $elementsCles,
                                primaryColor: primaryTextColor,
                                minHeight: 96
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        )
                    )

                    guidedInputCard(
                        index: "4",
                        title: "Les transitions ou zones de rupture",
                        helper: "S’il y a une pause, un bench, une reconversion ou un virage, notez-le simplement sans chercher encore la formulation parfaite.",
                        content: AnyView(
                            PlaceholderTextEditor(
                                placeholder:
                                    """
                                    Ex :
                                    Période de bench en 2025
                                    -> prise de recul
                                    -> clarification du positionnement
                                    -> choix d’évolution assumé
                                    """,
                                text: $transitions,
                                primaryColor: primaryTextColor,
                                minHeight: 96
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        )
                    )

                    dictationHint

                    Button(action: continueFlow) {
                        Text("Suivant")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(buttonColor)
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
        .onAppear {
            if posteActuel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                posteActuel = premiumDraft.anchorRole
            }
        }
        .onChange(of: posteActuel) { _, newValue in
            premiumDraft.anchorRole = newValue
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Parcours professionnel")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(primaryTextColor)

            Text("L’objectif n’est pas de raconter toute votre carrière. L’objectif est de faire ressortir la logique de votre trajectoire.")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
        }
    }

    private var framingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comment remplir cette étape")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(primaryTextColor)

            Text("Avancez en version simple : un poste repère, quelques étapes clés, ce que cela dit de vous, puis les éventuelles ruptures. Vous pourrez affiner ensuite.")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color.white.opacity(0.9))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var dictationHint: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "mic.fill")
                .foregroundColor(buttonColor)

            Text("Vous pouvez aussi utiliser la dictée iPhone pour aller plus vite, puis corriger ensuite les formulations si besoin.")
                .font(.footnote)
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(red: 233 / 255, green: 247 / 255, blue: 241 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func guidedInputCard(
        index: String,
        title: String,
        helper: String,
        content: AnyView
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
                    .foregroundColor(primaryTextColor)
            }

            Text(helper)
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)

            content
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private func continueFlow() {
        if posteActuel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showIncompleteAlert = true
        } else if experiences.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || elementsCles.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || transitions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showOptionalWarning = true
        } else {
            navigate = true
        }
    }
}
