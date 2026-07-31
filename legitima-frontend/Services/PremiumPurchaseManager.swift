#if DEBUG
import Combine
import Foundation
import StoreKit

/// Legitima ships free, so nothing in the app calls this. It is kept out of
/// the Release binary by `#if DEBUG` and demonstrable from the Xcode preview
/// of `PremiumUnlockCard` against `Products.storekit`. See README.md.
@MainActor
final class PremiumPurchaseManager: ObservableObject {
    static let productID = "com.milehana.legitima.premium.test"

    @Published private(set) var product: Product?
    @Published private(set) var isProcessing = false
    @Published var message: String?

    private let simulatedUnlockStore: SimulatedPremiumUnlockStore
    private var didAttemptLoad = false

    init(simulatedUnlockStore: SimulatedPremiumUnlockStore = SimulatedPremiumUnlockStore()) {
        self.simulatedUnlockStore = simulatedUnlockStore
    }

    var displayPrice: String {
        product?.displayPrice ?? "4,99 €"
    }

    /// True when the StoreKit product is unavailable (e.g. TestFlight without
    /// App Store Connect product) and the purchase runs as a local simulation.
    var usesSimulatedFallback: Bool {
        didAttemptLoad && product == nil
    }

    var canPurchase: Bool {
        !isProcessing && (product != nil || usesSimulatedFallback)
    }

    func loadProduct() async {
        guard product == nil else { return }
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            product = nil
        }
        didAttemptLoad = true
    }

    func purchase() async -> Bool {
        guard !isProcessing else { return false }

        guard let product else {
            return simulatePurchase()
        }

        isProcessing = true
        message = nil
        defer { isProcessing = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    message = "La transaction StoreKit n’a pas pu être vérifiée."
                    return false
                }
                await transaction.finish()
                simulatedUnlockStore.unlock()
                return true
            case .pending:
                message = "L’achat test est en attente de validation."
                return false
            case .userCancelled:
                return false
            @unknown default:
                message = "Résultat StoreKit non reconnu."
                return false
            }
        } catch {
            message = "L’achat test n’a pas abouti. Vous pouvez réessayer."
            return false
        }
    }

    func restore() async -> Bool {
        isProcessing = true
        message = nil
        defer { isProcessing = false }

        if product != nil {
            do {
                try await AppStore.sync()
            } catch {
                // Sync can fail in test environments; entitlements below stay authoritative.
            }
            for await entitlement in Transaction.currentEntitlements {
                if case .verified(let transaction) = entitlement,
                   transaction.productID == Self.productID {
                    simulatedUnlockStore.unlock()
                    return true
                }
            }
        }

        if simulatedUnlockStore.isUnlocked {
            return true
        }

        message = "Aucun achat Premium test à restaurer."
        return false
    }

    func hasPremiumEntitlement() async -> Bool {
        if simulatedUnlockStore.isUnlocked {
            return true
        }
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == Self.productID {
                return true
            }
        }
        return false
    }

    private func simulatePurchase() -> Bool {
        guard usesSimulatedFallback else {
            message = "Le produit Premium de test est indisponible. Vérifiez la configuration StoreKit du scheme."
            return false
        }
        simulatedUnlockStore.unlock()
        message = nil
        return true
    }
}
#endif
