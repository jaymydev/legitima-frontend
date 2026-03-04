import SwiftUI

struct ContexteEntretienScreen: View {
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
    
    var isIncomplete: Bool {
        typeEntretien.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || situationActuelle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || posteActuelOuDernier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contexte de l’entretien")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(primaryTextColor)

                        Text("Ces informations permettent de situer précisément le cadre de l’entretien avant de travailler le discours.")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Type d’entretien")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryTextColor)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(secondaryTextColor, lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if typeEntretien == "Recrutement" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("Recrutement")
                                    .foregroundColor(primaryTextColor)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                typeEntretien = "Recrutement"
                            }

                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(secondaryTextColor, lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if typeEntretien == "Mobilité interne" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("Mobilité interne")
                                    .foregroundColor(primaryTextColor)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                typeEntretien = "Mobilité interne"
                            }

                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(secondaryTextColor, lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if typeEntretien == "Évolution de poste" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("Évolution de poste")
                                    .foregroundColor(primaryTextColor)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                typeEntretien = "Évolution de poste"
                            }
                        }
                        .font(.body)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Entreprise / contexte")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryTextColor)

                        TextField("Nom de l’entreprise, secteur, etc.", text: $entrepriseContexte)
                            .font(.subheadline)
                            .foregroundColor(primaryTextColor)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Situation actuelle")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryTextColor)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(secondaryTextColor, lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if situationActuelle == "En poste" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("En poste")
                                    .foregroundColor(primaryTextColor)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                situationActuelle = "En poste"
                            }

                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(secondaryTextColor, lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if situationActuelle == "En recherche d’emploi" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("En recherche d’emploi")
                                    .foregroundColor(primaryTextColor)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                situationActuelle = "En recherche d’emploi"
                            }

                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(secondaryTextColor, lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if situationActuelle == "En reconversion" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("En reconversion")
                                    .foregroundColor(primaryTextColor)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                situationActuelle = "En reconversion"
                            }

                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(secondaryTextColor, lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if situationActuelle == "En formation" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("En formation")
                                    .foregroundColor(primaryTextColor)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                situationActuelle = "En formation"
                            }

                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(secondaryTextColor, lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if situationActuelle == "En période de transition (bench, pause, etc.)" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("En période de transition (bench, pause, etc.)")
                                    .foregroundColor(primaryTextColor)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                situationActuelle = "En période de transition (bench, pause, etc.)"
                            }

                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(secondaryTextColor, lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if situationActuelle == "Autre" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("Autre")
                                    .foregroundColor(primaryTextColor)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                situationActuelle = "Autre"
                            }

                            if situationActuelle == "Autre" {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Précisez votre situation")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(primaryTextColor)

                                    TextField(
                                        "Ex : entrepreneuriat, congé parental, année sabbatique, expatriation, projet personnel…",
                                        text: $autreSituation
                                    )
                                    .font(.subheadline)
                                    .foregroundColor(primaryTextColor)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(secondaryTextColor.opacity(0.35), lineWidth: 1)
                                    )
                                    .cornerRadius(10)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .font(.body)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Poste actuel ou dernier poste")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryTextColor)

                        TextField("Intitulé du poste actuel ou dernier poste occupé", text: $posteActuelOuDernier)
                            .font(.subheadline)
                            .foregroundColor(primaryTextColor)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    }

                    Button(action: {
                        if isIncomplete {
                            showIncompleteAlert = true
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
            Button("Modifier les infos", role: .cancel) {
                
            }
            Button("Continuer avec les infos actuelles", role: .destructive) {
                navigate = true
            }
        } message: {
            Text("Certaines informations n’ont pas été renseignées. Le résultat final risque d’être moins précis ou altéré. Voulez-vous continuer malgré tout ?")
        }
        .navigationDestination(isPresented: $navigate) {
            ParcoursProfessionnelScreen()
        }
    }
}

struct ContexteEntretienScreen_Previews: PreviewProvider {
    static var previews: some View {
        ContexteEntretienScreen()
    }
}
