import SwiftUI

struct RequalificationScreen: View {
    @State private var faiblessePerçue = ""
    @State private var apprentissageReel = ""
    @State private var postureActuelle = ""

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
                    header
                    cardOne
                    cardTwo
                    cardThree
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Requalifier une période sensible")
                .font(.largeTitle.bold())
                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

            Text("Transformer une faiblesse perçue en argument stratégique assumé.")
                .font(.subheadline)
                .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))
        }
    }

    private var cardOne: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ce que je pensais être une faiblesse")
                .font(.headline)
                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

            Text("Décrivez la période ou la situation que vous perceviez comme un point fragile dans votre parcours.")
                .font(.subheadline)
                .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))

            ZStack(alignment: .topLeading) {
                TextEditor(text: $faiblessePerçue)
                    .frame(minHeight: 120)

                if faiblessePerçue.isEmpty {
                    Text("– Période concernée :\n– Pourquoi cela me mettait en difficulté :\n– Ce que je craignais que le recruteur pense :")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255).opacity(0.7))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }

            if faiblessePerçue.count < 40 {
                Text("Essayez de préciser votre perception initiale pour clarifier votre réflexion.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
    }

    private var cardTwo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ce que cela m’a réellement appris")
                .font(.headline)
                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

            Text("Identifiez les compétences, apprentissages ou évolutions réelles issues de cette période.")
                .font(.subheadline)
                .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))

            ZStack(alignment: .topLeading) {
                TextEditor(text: $apprentissageReel)
                    .frame(minHeight: 120)

                if apprentissageReel.isEmpty {
                    Text("– Compétences développées :\n– Apprentissages concrets :\n– Éléments factuels positifs :")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255).opacity(0.7))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }

            if apprentissageReel.count < 40 {
                Text("Essayez de préciser votre perception initiale pour clarifier votre réflexion.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
    }

    private var cardThree: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comment je l’assume aujourd’hui")
                .font(.headline)
                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

            Text("Formulez une version assumée et stratégique que vous pourriez défendre en entretien.")
                .font(.subheadline)
                .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))

            ZStack(alignment: .topLeading) {
                TextEditor(text: $postureActuelle)
                    .frame(minHeight: 120)

                if postureActuelle.isEmpty {
                    Text("– Formulation synthétique :\n– Angle stratégique choisi :\n– Message que je veux faire passer :")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255).opacity(0.7))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }

            if postureActuelle.count < 40 {
                Text("Essayez de préciser votre perception initiale pour clarifier votre réflexion.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    RequalificationScreen()
}
