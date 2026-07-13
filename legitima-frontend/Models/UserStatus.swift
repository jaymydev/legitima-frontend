import Combine
import Foundation

@MainActor
final class UserStatus: ObservableObject {
    private enum StorageKeys {
        static let remainingFreeAnalyses = "user_status.remaining_free_analyses"
        static let quotaDayStamp = "user_status.quota_day_stamp"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let freeDailyLimit: Int

    @Published var isPremium: Bool = false
    @Published var hasSeenPremiumUnlock: Bool = false
    @Published var remainingFreeAnalyses: Int

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        freeDailyLimit: Int = 2
    ) {
        self.defaults = defaults
        self.calendar = calendar
        self.freeDailyLimit = freeDailyLimit

        let storedRemaining = defaults.object(forKey: StorageKeys.remainingFreeAnalyses) as? Int ?? freeDailyLimit
        remainingFreeAnalyses = storedRemaining

        #if DEBUG
        resetDevelopmentQuota()
        #else
        refreshFreeQuotaIfNeeded()
        #endif
    }

    var canStartAnalysis: Bool {
        isPremium || remainingFreeAnalyses > 0
    }

    var freeQuotaLabel: String {
        if isPremium {
            return "Analyses premium actives"
        }

        if remainingFreeAnalyses <= 0 {
            return "0 analyse gratuite restante aujourd'hui"
        }

        return remainingFreeAnalyses == 1
            ? "1 analyse gratuite restante aujourd'hui"
            : "\(remainingFreeAnalyses) analyses gratuites restantes aujourd'hui"
    }

    func activatePremium() {
        isPremium = true
        hasSeenPremiumUnlock = true
    }

    func consumeFreeAnalysisIfNeeded() {
        refreshFreeQuotaIfNeeded()
        guard !isPremium, remainingFreeAnalyses > 0 else { return }
        remainingFreeAnalyses -= 1
        persistQuota()
    }

    func dismissPremiumUnlock() {
        hasSeenPremiumUnlock = false
    }

    func refreshFreeQuotaIfNeeded() {
        guard !isPremium else { return }

        let todayStamp = dayStamp(for: Date())
        let storedStamp = defaults.string(forKey: StorageKeys.quotaDayStamp)

        if storedStamp != todayStamp {
            defaults.set(todayStamp, forKey: StorageKeys.quotaDayStamp)
            remainingFreeAnalyses = freeDailyLimit
            persistQuota()
        } else if defaults.object(forKey: StorageKeys.remainingFreeAnalyses) == nil {
            persistQuota()
        }
    }

    private func persistQuota() {
        defaults.set(remainingFreeAnalyses, forKey: StorageKeys.remainingFreeAnalyses)
    }

    private func resetDevelopmentQuota() {
        let todayStamp = dayStamp(for: Date())
        defaults.set(todayStamp, forKey: StorageKeys.quotaDayStamp)
        remainingFreeAnalyses = freeDailyLimit
        persistQuota()
    }

    private func dayStamp(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
