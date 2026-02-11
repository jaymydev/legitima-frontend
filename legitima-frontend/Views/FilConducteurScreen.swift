import SwiftUI

struct FilConducteurScreen: View {
    var body: some View {
        VStack {
            Text("Fil conducteur")
            Text("Cette page présente les points clés à structurer pour guider le discours.")
            Text("Elle sert de base simple pour préparer un échange cohérent.")
            Spacer()
            VStack {
                Text("Message central à faire passer")
                Spacer()
                Text("Cohérence globale du parcours")
                Spacer()
                Text("Narration simplifiée de l’expérience")
                Spacer()
                Text("Conclusion à défendre en entretien")
            }
            Spacer()
        }
    }
}

#Preview {
    FilConducteurScreen()
}
