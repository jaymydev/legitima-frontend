import SwiftUI

struct RequalificationScreen: View {
    var body: some View {
        VStack {
            Text("Requalification du profil")
            Text("Cette section permet de clarifier votre positionnement et de mettre en valeur les éléments clés de votre profil.")

            Spacer()

            VStack {
                Text("Positionnement cible")
                Text("Reformulation du parcours")
                Text("Compétences clés mises en avant")
                Text("Éléments différenciants")
            }

            Spacer()
        }
    }
}

#Preview {
    RequalificationScreen()
}
