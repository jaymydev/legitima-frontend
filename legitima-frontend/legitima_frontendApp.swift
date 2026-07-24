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
    @StateObject private var userStatus = UserStatus()
    @StateObject private var premiumDraft = PremiumPreparationDraft()
    @StateObject private var preparationStore = LocalPreparationStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                rootView
                    .navigationDestination(for: AppRouter.Route.self) { route in
                        switch route {
                        case .progression:
                            ProgressionScreen(
                                onBackToResults: {
                                    router.backToResults()
                                },
                                onRestartAnalysis: {
                                    preparationStore.beginNewAnalysis()
                                    router.restartAnalysis()
                                }
                            )
                        }
                    }
            }
            .environmentObject(userStatus)
            .environmentObject(premiumDraft)
            .environmentObject(preparationStore)
            .environmentObject(router)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        switch router.root {
        case .access:
            TestAccessScreen(
                hasSavedWork: preparationStore.hasSavedWork,
                onContinueTesting: {
                    if let analysis = preparationStore.snapshot.analysis {
                        premiumDraft.baseAnalysis = analysis
                    }
                    router.enterTestMode(savedAnalysis: preparationStore.snapshot.analysis)
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
                    router.showProgression()
                }
            )
        }
    }
}
