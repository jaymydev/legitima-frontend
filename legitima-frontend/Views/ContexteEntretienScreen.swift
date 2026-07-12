import SwiftUI

struct ContexteEntretienScreen: View {
    @EnvironmentObject private var premiumDraft: PremiumPreparationDraft
    @State private var typeEntretien = "Recrutement"
    @State private var entrepriseContexte = ""
    @State private var situationActuelle = "En poste"
    @State private var autreSituation = ""
    @State private var posteActuelOuDernier = ""
    @State private var showIncompleteAlert = false
    @State private var navigate = false

    private let selectionBlue = Color(red: 118 / 255, green: 157 / 255, blue: 189 / 255)
    private let primaryTextColor = Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255)
    private let secondaryTextColor = Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255)
    private let buttonColor = Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255)

    private var isIncomplete: Bool {
        typeEntretien.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        situationActuelle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        posteActuelOuDernier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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

                    guidedSelectionCard(
                        index: "1",
                        title: "Le type d’entretien",
                        helper: "Choisissez simplement le cadre principal dans lequel vous allez devoir vous présenter."
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            optionRow("Recrutement", selection: $typeEntretien)
                            optionRow("Mobilité interne", selection: $typeEntretien)
                            optionRow("Évolution de poste", selection: $typeEntretien)
                        }
                    }

                    guidedInputCard(
                        index: "2",
                        title: "Le contexte à garder en tête",
                        helper: "Quelques mots suffisent pour situer l’entreprise, le secteur ou le type d’environnement.",
                        content: AnyView(
                            TextField("Ex : ESN, industrie, startup, contexte international...", text: $entrepriseContexte)
                                .font(.subheadline)
                                .foregroundColor(primaryTextColor)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        )
                    )

                    guidedSelectionCard(
                        index: "3",
                        title: "Votre situation aujourd’hui",
                        helper: "Choisissez la situation qui décrit le mieux votre réalité actuelle."
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            optionRow("En poste", selection: $situationActuelle)
                            optionRow("En recherche d’emploi", selection: $situationActuelle)
                            optionRow("En reconversion", selection: $situationActuelle)
                            optionRow("En formation", selection: $situationActuelle)
                            optionRow("En période de transition (bench, pause, etc.)", selection: $situationActuelle)
                            optionRow("Autre", selection: $situationActuelle)

                            if situationActuelle == "Autre" {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Précisez en une ligne")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(primaryTextColor)

                                    TextField(
                                        "Ex : projet personnel, expatriation, congé parental...",
                                        text: $autreSituation
                                    )
                                    .font(.subheadline)
                                    .foregroundColor(primaryTextColor)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .padding(.top, 4)
                            }
                        }
                    }

                    guidedInputCard(
                        index: "4",
                        title: "Votre point d’ancrage professionnel",
                        helper: "Renseignez votre poste actuel ou votre dernier poste. C’est le repère principal de la suite du récit.",
                        content: AnyView(
                            TextField("Ex : Product Owner, Senior PLM Engineer, PMO...", text: $posteActuelOuDernier)
                                .font(.subheadline)
                                .foregroundColor(primaryTextColor)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        )
                    )

                    Button(action: continueFlow) {
                        Text("Passer au parcours professionnel")
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
            Button("Modifier les infos", role: .cancel) { }
            Button("Continuer malgré tout", role: .destructive) {
                navigate = true
            }
        } message: {
            Text("Le poste et la situation actuelle aident à personnaliser la suite. Vous pouvez continuer, mais la préparation sera un peu moins précise.")
        }
        .navigationDestination(isPresented: $navigate) {
            ParcoursProfessionnelScreen()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Situer votre entretien")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(primaryTextColor)

            Text("Ici, on pose seulement le cadre. Quatre repères simples suffisent pour préparer la suite.")
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

            Text("Ne cherchez pas à être exhaustive. Le but est seulement de préciser le type d’entretien, votre contexte, votre situation actuelle et votre point d’ancrage professionnel.")
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

    private func optionRow(_ label: String, selection: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Circle()
                .stroke(secondaryTextColor, lineWidth: 1.5)
                .frame(width: 18, height: 18)
                .overlay {
                    if selection.wrappedValue == label {
                        Circle()
                            .fill(selectionBlue)
                            .frame(width: 10, height: 10)
                    }
                }

            Text(label)
                .foregroundColor(primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selection.wrappedValue = label
        }
    }

    private func guidedSelectionCard<Content: View>(
        index: String,
        title: String,
        helper: String,
        @ViewBuilder content: () -> Content
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

            content()
                .font(.body)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
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
        premiumDraft.anchorRole = posteActuelOuDernier.trimmingCharacters(in: .whitespacesAndNewlines)

        if isIncomplete {
            showIncompleteAlert = true
        } else {
            navigate = true
        }
    }
}

struct ContexteEntretienScreen_Previews: PreviewProvider {
    static var previews: some View {
        ContexteEntretienScreen()
    }
}
