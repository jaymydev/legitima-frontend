import SwiftUI

struct ZonesSensiblesScreen: View {
    var body: some View {
        VStack {
            Text("Zones sensibles")
            Text("Cette section regroupe les points de vigilance à traiter avec précaution dans les échanges.")

            Spacer()

            VStack {
                Text("Questions délicates")
                Text("Points faibles du profil")
                Text("Sujets à éviter")
                Text("Angles de reformulation")
            }

            Spacer()
        }
    }
}

#Preview {
    ZonesSensiblesScreen()
}
