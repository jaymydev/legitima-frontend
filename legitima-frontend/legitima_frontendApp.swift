//
//  legitima_frontendApp.swift
//  legitima-frontend
//
//  Created by MilehanaLiveComm on 11/02/2026.
//

import SwiftUI

@main
struct legitima_frontendApp: App {
    @StateObject private var router = AppRouter()
    @StateObject private var preparationStore = LocalPreparationStore()
    @StateObject private var slotStore = SlotStore()
    private let reminderScheduler = InterviewReminderScheduler()

    /// L'écran de lancement passe une fois, puis se retire pour la session.
    @State private var introFinished = false
    /// Séquence complète au premier lancement, nom et promesse ensuite. Le
    /// drapeau vit dans les préférences : il ne décrit pas une préparation, il
    /// ne relève donc pas du stockage protégé qu'`OrphanedStorage` nettoie.
    private let intro = LaunchIntro(
        hasLaunchedBefore: UserDefaults.standard.bool(forKey: legitima_frontendApp.introSeenKey)
    )
    private static let introSeenKey = "legitima.intro.seen"

    init() {
        OrphanedStorage.removeAll()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                NavigationStack(path: $router.path) {
                    rootView
                        .navigationDestination(for: AppRouter.Route.self) { route in
                            switch route {
                            case let .preparedQuestions(useCaseID):
                                BankPreparationScreen(useCaseID: useCaseID)
                            }
                        }
                }
                .environmentObject(preparationStore)
                .environmentObject(slotStore)
                .environmentObject(router)

                if !introFinished {
                    LaunchIntroScreen(intro: intro) {
                        UserDefaults.standard.set(true, forKey: Self.introSeenKey)
                        introFinished = true
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .animation(LegitimaMotion.reveal, value: introFinished)
        }
    }

    /// Un seul écran d'entrée, une seule destination.
    ///
    /// Le parcours par le CV — formulaire, analyse, kickoff — a disparu avec le
    /// pivot : c'est le type d'entretien qui porte la préparation.
    @ViewBuilder
    private var rootView: some View {
        InterviewTypeEntryScreen(
            onContinue: { type, date, metierID, encadrement in
                preparationStore.updateIntendedUseCase(type.rawValue)
                preparationStore.updateInterviewDate(date)
                preparationStore.updateMetier(metierID)
                preparationStore.updateEncadrement(encadrement)
                // Le rappel était programmé depuis l'écran de saisie du parcours.
                // Il l'est maintenant d'ici, sinon la date ne servirait à rien.
                Task { await reminderScheduler.sync(interviewDate: date) }
                router.showPreparedQuestions(useCaseID: type.rawValue)
            }
        )
    }
}
