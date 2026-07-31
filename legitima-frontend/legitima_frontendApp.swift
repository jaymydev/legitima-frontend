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
    @StateObject private var premiumDraft = PremiumPreparationDraft()
    @StateObject private var preparationStore = LocalPreparationStore()
    @StateObject private var interviewPreparationStore = InterviewPreparationStore()

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
                        }
                    }
            }
            .environmentObject(premiumDraft)
            .environmentObject(preparationStore)
            .environmentObject(interviewPreparationStore)
            .environmentObject(router)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        switch router.root {
        case .access:
            WelcomeScreen(
                hasSavedWork: preparationStore.hasSavedWork,
                onContinue: {
                    if let analysis = preparationStore.snapshot.analysis {
                        premiumDraft.baseAnalysis = analysis
                    }
                    router.enterApp(savedAnalysis: preparationStore.snapshot.analysis)
                }
            )

        case .onboarding:
            LeanOnboardingScreen(
                onAnalysisComplete: { response in
                    premiumDraft.baseAnalysis = response
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
