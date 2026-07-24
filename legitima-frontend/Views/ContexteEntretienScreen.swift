import SwiftUI

struct ContexteEntretienScreen: View {
    @EnvironmentObject private var premiumDraft: PremiumPreparationDraft
    @State private var entrepriseContexte = ""
    @State private var situationActuelle = "En poste"
    @State private var autreSituation = ""
    @State private var showIncompleteAlert = false
    @State private var navigate = false

    private let selectionBlue = Color(red: 118 / 255, green: 157 / 255, blue: 189 / 255)
    private let primaryTextColor = Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255)
    private let secondaryTextColor = Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255)
    private let buttonColor = Color(red: 43 / 255, green: 111 / 255, blue: 113 / 255)

    private var isIncomplete: Bool {
        situationActuelle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
                        title: "Le contexte à garder en tête",
                        helper: "Quelques mots suffisent pour situer l’entreprise, le secteur ou le type d’environnement. Cette info est optionnelle.",
                        content: AnyView(
                            TextField(
                                "",
                                text: $entrepriseContexte,
                                prompt: Text("Ex : ESN, industrie, startup, contexte international...")
                                    .foregroundColor(secondaryTextColor.opacity(0.82))
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
                        )
                    )

                    guidedSelectionCard(
                        index: "2",
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
                                        "",
                                        text: $autreSituation,
                                        prompt: Text("Ex : projet personnel, expatriation, congé parental...")
                                            .foregroundColor(secondaryTextColor.opacity(0.82))
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

                    Button(action: continueFlow) {
                        Text("Passer au parcours professionnel")
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
            Button("Modifier les infos", role: .cancel) { }
            Button("Continuer malgré tout", role: .destructive) {
                navigate = true
            }
        } message: {
            Text("Votre situation actuelle aide à personnaliser la suite. Vous pouvez continuer, mais la préparation sera un peu moins précise.")
        }
        .navigationDestination(isPresented: $navigate) {
            ParcoursProfessionnelScreen()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ETAPE 1")
                .font(.caption.weight(.bold))
                .foregroundColor(buttonColor.opacity(0.82))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.72))
                .clipShape(Capsule())

            Text("Poser le cadre\nde votre entretien")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(primaryTextColor)

            Text("Ici, on pose seulement le cadre. Trois repères simples suffisent pour rendre la suite plus juste et plus rapide.")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
        }
    }

    private var framingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "scope")
                    .font(.title3)
                    .foregroundColor(buttonColor)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Le bon niveau d’effort")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryTextColor)

                    Text("Ne cherchez pas à être exhaustive. Le but est seulement de cadrer l’entretien, pas de raconter déjà tout votre parcours.")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                framingPill("type d’entretien")
                framingPill("situation")
                framingPill("contexte optionnel")
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
                .offset(x: 150, y: -260)

            Circle()
                .fill(Color(red: 170 / 255, green: 232 / 255, blue: 224 / 255).opacity(0.34))
                .frame(width: 200, height: 200)
                .blur(radius: 10)
                .offset(x: -150, y: 260)
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
        premiumDraft.anchorRole = ""

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
