//
//  legitima_frontendApp.swift
//  legitima-frontend
//
//  Created by MilehanaLiveComm on 11/02/2026.
//

import SwiftUI

@main
struct legitima_frontendApp: App {
    @State private var analysisResponse: AnalysisResponse?

    var body: some Scene {
        WindowGroup {
            NavigationStack {

                if let response = analysisResponse {
                    LeanResultScreen(response: response)

                } else {
                    LeanOnboardingScreen(
                        onAnalysisComplete: { response in
                            analysisResponse = response
                        }
                    )
                }

            }
        }
    }
}
