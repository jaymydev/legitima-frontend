import Combine
import StoreKit

@MainActor
final class PremiumPurchaseManager: ObservableObject {
    static let productID = "com.milehana.legitima.premium.test"

    @Published private(set) var product: Product?
    @Published private(set) var isProcessing = false
    @Published var message: String?

    var displayPrice: String {
        product?.displayPrice ?? "4,99 €"
    }

    func loadProduct() async {
        guard product == nil else { return }
        do {
            product = try await Product.products(for: [Self.productID]).first
            if product == nil {
                message = "Le produit Premium de test est indisponible. Vérifiez la configuration StoreKit du scheme."
            }
        } catch {
            message = "Impossible de charger l’achat Premium de test."
        }
    }

    func purchase() async -> Bool {
        guard let product, !isProcessing else { return false }
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

        do {
            try await AppStore.sync()
            for await entitlement in Transaction.currentEntitlements {
                if case .verified(let transaction) = entitlement,
                   transaction.productID == Self.productID {
                    return true
                }
            }
            message = "Aucun achat Premium test à restaurer."
        } catch {
            message = "La restauration StoreKit n’a pas abouti."
        }
        return false
    }

    func hasPremiumEntitlement() async -> Bool {
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == Self.productID {
                return true
            }
        }
        return false
    }
}
