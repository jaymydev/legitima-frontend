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
    @StateObject private var interviewPreparationStore = InterviewPreparationStore()
    @StateObject private var slotStore = SlotStore()

    init() {
        OrphanedStorage.removeAll()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                rootView
                    .navigationDestination(for: AppRouter.Route.self) { route in
                        switch route {
                        case .kickoff:
                            PremiumKickoffScreen(
                                onContinue: {
                                    router.continueFromKickoff()
                                }
                            )
                        case .interviewEntry:
                            PremiumInterviewEntryScreen()
                        case let .preparedQuestions(useCaseID):
                            BankPreparationScreen(useCaseID: useCaseID)
                        }
                    }
            }
            .environmentObject(preparationStore)
            .environmentObject(interviewPreparationStore)
            .environmentObject(slotStore)
            .environmentObject(router)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        switch router.root {
        case .access:
            // Maquette du pivot : le choix du type d'entretien devient le
            // premier écran. `onContinue` enregistre le choix et la date, et
            // s'arrête là — la suite du tunnel n'est pas encore écrite.
            InterviewTypeEntryScreen(
                onContinue: { type, date in
                    preparationStore.updateIntendedUseCase(type.rawValue)
                    preparationStore.updateInterviewDate(date)
                    router.showPreparedQuestions(useCaseID: type.rawValue)
                }
            )

        case .onboarding:
            LeanOnboardingScreen(
                onAnalysisComplete: { response in
                    preparationStore.saveAnalysis(response)
                    router.showResult(response)
                }
            )

        case .result(let response):
            LeanResultScreen(
                response: response,
                onContinue: {
                    // The kickoff is the first defensible answer, and it is
                    // worth one screen exactly once. Someone coming back to
                    // review their preparation goes straight to the work.
                    if preparationStore.snapshot.kickoff == nil,
                       interviewPreparationStore.saved.result == nil {
                        router.showKickoff()
                    } else {
                        router.showInterviewEntry()
                    }
                },
                onRestartAnalysis: {
                    preparationStore.beginNewAnalysis()
                    router.restartAnalysis()
                }
            )

        }
    }
}
