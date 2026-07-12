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
                                onUnlockPremium: {
                                    router.backToResults()
                                },
                                onContinueFree: {
                                    router.restartAnalysis()
                                }
                            )
                        }
                    }
            }
            .environmentObject(userStatus)
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
