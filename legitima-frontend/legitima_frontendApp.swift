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

    init() {
        OrphanedStorage.removeAll()
    }

    var body: some Scene {
        WindowGroup {
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
        }
    }

    /// Un seul écran d'entrée, une seule destination.
    ///
    /// Le parcours par le CV — formulaire, analyse, kickoff — a disparu avec le
    /// pivot : c'est le type d'entretien qui porte la préparation.
    @ViewBuilder
    private var rootView: some View {
        InterviewTypeEntryScreen(
            onContinue: { type, date in
                preparationStore.updateIntendedUseCase(type.rawValue)
                preparationStore.updateInterviewDate(date)
                // Le rappel était programmé depuis l'écran de saisie du parcours.
                // Il l'est maintenant d'ici, sinon la date ne servirait à rien.
                Task { await reminderScheduler.sync(interviewDate: date) }
                router.showPreparedQuestions(useCaseID: type.rawValue)
            }
        )
    }
}
