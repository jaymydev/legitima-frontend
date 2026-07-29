import Foundation

/// Persists the simulated Premium unlock so the test purchase keeps working
/// when the StoreKit product is unavailable (e.g. TestFlight builds without
/// an App Store Connect product).
struct SimulatedPremiumUnlockStore {
    static let storageKey = "premium.simulated_unlock"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isUnlocked: Bool {
        defaults.bool(forKey: Self.storageKey)
    }

    func unlock() {
        defaults.set(true, forKey: Self.storageKey)
    }

    func reset() {
        defaults.removeObject(forKey: Self.storageKey)
    }
}
