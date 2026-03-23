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
                                onShowPremiumUpsell: {
                                    router.showPremiumUpsell()
                                }
                            )

                        case .premiumUpsell:
                            PremiumUpsellScreen(
                                onContinueFree: {
                                    router.restartAnalysis()
                                }
                            )
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        switch router.root {
        case .onboarding:
            LeanOnboardingScreen(
                onAnalysisComplete: { response in
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
