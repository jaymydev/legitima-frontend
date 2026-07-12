import Combine

@MainActor
final class UserStatus: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var hasSeenPremiumUnlock: Bool = false
    @Published var remainingFreeAnalyses: Int = 3

    var canStartAnalysis: Bool {
        isPremium || remainingFreeAnalyses > 0
    }

    func activatePremium() {
        isPremium = true
        hasSeenPremiumUnlock = true
    }

    func consumeFreeAnalysisIfNeeded() {
        guard !isPremium, remainingFreeAnalyses > 0 else { return }
        remainingFreeAnalyses -= 1
    }

    func dismissPremiumUnlock() {
        hasSeenPremiumUnlock = false
    }
}
