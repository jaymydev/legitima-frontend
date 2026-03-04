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

                    NavigationLink(destination: PreparationEntretienScreen()) {
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Requalifier une période sensible")
                .font(.largeTitle)
                .fontWeight(.bold)
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
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

            Text("Décrivez la période ou la situation que vous perceviez comme un point fragile dans votre parcours.")
                .font(.subheadline)
                .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))

            PlaceholderTextEditor(
                placeholder: "– Période concernée :\n– Pourquoi cela me mettait en difficulté :\n– Ce que je craignais que le recruteur pense :",
                text: $faiblessePerçue,
                primaryColor: Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255),
                minHeight: 120
            )

            if faiblessePerçue.count < 40 {
                Text("Essayez de préciser votre perception initiale pour clarifier votre réflexion.")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private var cardTwo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ce que cela m’a réellement appris")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

            Text("Identifiez les compétences, apprentissages ou évolutions réelles issues de cette période.")
                .font(.subheadline)
                .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))

            PlaceholderTextEditor(
                placeholder: "– Compétences développées :\n– Apprentissages concrets :\n– Éléments factuels positifs :",
                text: $apprentissageReel,
                primaryColor: Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255),
                minHeight: 120
            )

            if apprentissageReel.count < 40 {
                Text("Essayez de préciser votre perception initiale pour clarifier votre réflexion.")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private var cardThree: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comment je l’assume aujourd’hui")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255))

            Text("Formulez une version assumée et stratégique que vous pourriez défendre en entretien.")
                .font(.subheadline)
                .foregroundColor(Color(red: 91 / 255, green: 95 / 255, blue: 95 / 255))

            PlaceholderTextEditor(
                placeholder: "– Formulation synthétique :\n– Angle stratégique choisi :\n– Message que je veux faire passer :",
                text: $postureActuelle,
                primaryColor: Color(red: 47 / 255, green: 49 / 255, blue: 49 / 255),
                minHeight: 120
            )

            if postureActuelle.count < 40 {
                Text("Essayez de préciser votre perception initiale pour clarifier votre réflexion.")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    RequalificationScreen()
}
