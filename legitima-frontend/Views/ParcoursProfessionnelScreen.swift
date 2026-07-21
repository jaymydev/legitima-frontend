import SwiftUI
import UIKit

struct ParcoursProfessionnelScreen: View {
    @EnvironmentObject private var premiumDraft: PremiumPreparationDraft
    @State private var posteActuel = ""
    @State private var etapesCles = ""
    @State private var transitions = ""
    @State private var showIncompleteAlert = false
    @State private var showOptionalWarning = false
    @State private var isShowingCVImportFlow = false
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
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ambientBackground

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
                                "",
                                text: $posteActuel,
                                prompt: Text("Ex : Senior PLM Engineer - pilotage migration 3DEXPERIENCE")
                                    .foregroundColor(secondaryTextColor.opacity(0.82))
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
                        title: "Les 2 ou 3 étapes qui comptent",
                        helper: "Gardez seulement les étapes les plus utiles pour comprendre votre évolution et ce qu’elle dit de vous.",
                        content: AnyView(
                            VStack(alignment: .leading, spacing: 12) {
                                PlaceholderTextEditor(
                                    placeholder:
                                        """
                                        Ex :
                                        2019-2022 : Développement logiciel embarqué
                                        2022-2024 : Coordination transverse et validation
                                        2024-2025 : Migration, structuration, sujets complexes

                                        Ce que cela montre :
                                        - montée en responsabilité progressive
                                        - aisance dans les contextes techniques complexes
                                        - capacité à structurer et rassurer
                                        """,
                                    text: $etapesCles,
                                    primaryColor: primaryTextColor,
                                    minHeight: 150
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                Button(action: {
                                    dismissKeyboard()
                                    isShowingCVImportFlow = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Importer un CV pour préremplir")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundColor(buttonColor)
                                    .background(Color(red: 239 / 255, green: 250 / 255, blue: 249 / 255))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(buttonColor.opacity(0.22), lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                                }
                            }
                        )
                    )

                    guidedInputCard(
                        index: "3",
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

                    Button(action: continueFlow) {
                        Text("Suivant")
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
        .sheet(isPresented: $isShowingCVImportFlow) {
            CVImportFlowSheet(
                onUseSummary: { importedSummary in
                    etapesCles = importedSummary
                },
                introText: "Nous allons extraire les étapes les plus utiles de votre parcours pour vous aider à choisir les expériences pertinentes.",
                applyButtonTitle: "Utiliser ces étapes",
                reviewFootnote: "Vous pourrez encore garder, supprimer ou reformuler certaines étapes dans cet écran."
            )
        }
        .onAppear {
            if posteActuel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                posteActuel = premiumDraft.anchorRole
            }

            if etapesCles.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                etapesCles = premiumDraft.careerKeySteps
            }

            if transitions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                transitions = premiumDraft.careerTransitions
            }
        }
        .onChange(of: posteActuel) { _, newValue in
            premiumDraft.anchorRole = newValue
        }
        .onChange(of: etapesCles) { _, newValue in
            premiumDraft.careerKeySteps = newValue
        }
        .onChange(of: transitions) { _, newValue in
            premiumDraft.careerTransitions = newValue
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ETAPE 2")
                .font(.caption.weight(.bold))
                .foregroundColor(buttonColor.opacity(0.82))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.72))
                .clipShape(Capsule())

            Text("Faire émerger\nla logique du parcours")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(primaryTextColor)

            Text("L’objectif n’est pas de raconter toute votre carrière. L’objectif est de faire ressortir la logique de votre trajectoire.")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
        }
    }

    private var framingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.title3)
                    .foregroundColor(buttonColor)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Comment remplir cette étape")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryTextColor)

                    Text("Avancez en version simple : un poste repère, quelques étapes clés, ce que cela dit de vous, puis les éventuelles ruptures. Vous pourrez affiner ensuite.")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                framingPill("2 ou 3 étapes")
                framingPill("étapes utiles")
                framingPill("ruptures utiles")
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
        let trimmedEtapes = etapesCles.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTransitions = transitions.trimmingCharacters(in: .whitespacesAndNewlines)

        if posteActuel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showIncompleteAlert = true
        } else if trimmedEtapes.isEmpty || trimmedTransitions.isEmpty {
            showOptionalWarning = true
        } else {
            navigate = true
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
