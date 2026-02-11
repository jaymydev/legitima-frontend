import SwiftUI

struct ContexteEntretienScreen: View {
    @State private var typeEntretien = "Recrutement"
    @State private var entrepriseContexte = ""
    @State private var situationActuelle = "En poste"
    @State private var autreSituation = ""
    @State private var posteActuelOuDernier = ""
    @State private var showIncompleteAlert = false
    private let selectionBlue = Color(red: 118 / 255, green: 157 / 255, blue: 189 / 255)
    
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
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contexte de l’entretien")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                        Text("Ces informations permettent de situer précisément le cadre de l’entretien avant de travailler le discours.")
                            .font(.body)
                            .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))

                        Rectangle()
                            .fill(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
                            .frame(height: 1)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Type d’entretien")
                            .font(.headline)
                            .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255), lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if typeEntretien == "Recrutement" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("Recrutement")
                                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                typeEntretien = "Recrutement"
                            }

                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255), lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if typeEntretien == "Mobilité interne" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("Mobilité interne")
                                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                typeEntretien = "Mobilité interne"
                            }

                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255), lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if typeEntretien == "Évolution de poste" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("Évolution de poste")
                                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
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
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Entreprise / contexte")
                            .font(.headline)
                            .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                        TextField("Nom de l’entreprise, secteur, etc.", text: $entrepriseContexte)
                            .font(.body)
                            .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Situation actuelle")
                            .font(.headline)
                            .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255), lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if situationActuelle == "En poste" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("En poste")
                                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                situationActuelle = "En poste"
                            }

                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255), lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if situationActuelle == "En recherche d’emploi" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("En recherche d’emploi")
                                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                situationActuelle = "En recherche d’emploi"
                            }

                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255), lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if situationActuelle == "En reconversion" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("En reconversion")
                                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                situationActuelle = "En reconversion"
                            }

                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255), lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if situationActuelle == "En formation" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("En formation")
                                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                situationActuelle = "En formation"
                            }

                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255), lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if situationActuelle == "En période de transition (bench, pause, etc.)" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("En période de transition (bench, pause, etc.)")
                                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                situationActuelle = "En période de transition (bench, pause, etc.)"
                            }

                            HStack(spacing: 10) {
                                Circle()
                                    .stroke(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255), lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        if situationActuelle == "Autre" {
                                            Circle()
                                                .fill(selectionBlue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text("Autre")
                                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                situationActuelle = "Autre"
                            }

                            if situationActuelle == "Autre" {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Précisez votre situation")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                                    TextField(
                                        "Ex : entrepreneuriat, congé parental, année sabbatique, expatriation, projet personnel…",
                                        text: $autreSituation
                                    )
                                    .font(.body)
                                    .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255).opacity(0.35), lineWidth: 1)
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
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Poste actuel ou dernier poste")
                            .font(.headline)
                            .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

                        TextField("Intitulé du poste actuel ou dernier poste occupé", text: $posteActuelOuDernier)
                            .font(.body)
                            .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        if isIncomplete {
                            showIncompleteAlert = true
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
            Button("Modifier les infos", role: .cancel) { }
            Button("Continuer avec les infos actuelles") { }
        } message: {
            Text("Certaines informations n’ont pas été renseignées. Le résultat final risque d’être moins précis ou altéré. Voulez-vous continuer malgré tout ?")
        }
    }
}

struct ContexteEntretienScreen_Previews: PreviewProvider {
    static var previews: some View {
        ContexteEntretienScreen()
    }
}
