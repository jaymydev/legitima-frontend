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
    @StateObject private var interviewPreparationStore = InterviewPreparationStore()

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
            .environmentObject(interviewPreparationStore)
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
                    router.enterTestMode()
                }
            )

        case .interviewUseCases:
            InterviewUseCaseSelectionScreen(
                savedPreparation: interviewPreparationStore.saved,
                onSelect: { useCase in
                    if useCase.id == "recruitment" {
                        router.startRecruitment(savedAnalysis: preparationStore.snapshot.analysis)
                    } else {
                        interviewPreparationStore.start(useCase: useCase)
                        router.startInterviewQuestionnaire(useCase)
                    }
                },
                onResume: { saved in
                    guard let useCase = saved.useCase else { return }
                    if let result = saved.result {
                        router.showInterviewPreparationResult(result)
                    } else {
                        router.startInterviewQuestionnaire(useCase)
                    }
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

        case .interviewQuestionnaire(let useCase):
            InterviewQuestionnaireScreen(
                useCase: useCase,
                store: interviewPreparationStore,
                onComplete: { response in
                    userStatus.consumeFreeAnalysisIfNeeded()
                    router.showInterviewPreparationResult(response)
                },
                onBack: {
                    router.showInterviewUseCases()
                }
            )

        case .interviewPreparationResult(let response):
            InterviewPreparationResultScreen(
                response: response,
                onChooseAnother: {
                    router.showInterviewUseCases()
                }
            )
        }
    }
}
