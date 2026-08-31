import Combine
import SwiftUI

/// Une pile à une seule destination.
///
/// Le routeur portait auparavant trois racines et trois routes, pour un
/// parcours qui passait par la saisie du parcours, l'analyse, le kickoff puis
/// le choix du type d'entretien. Le type d'entretien étant devenu le premier
/// écran, il ne reste qu'à ouvrir les questions.
@MainActor
final class AppRouter: ObservableObject {
    enum Route: Hashable {
        case preparedQuestions(String)
    }

    @Published var path: [Route] = []

    func showPreparedQuestions(useCaseID: String) {
        path = [.preparedQuestions(useCaseID)]
    }

    func backToStart() {
        path.removeAll()
    }
}
