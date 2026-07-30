import SwiftUI

struct PremiumUnlockCard: View {
    @ObservedObject var purchaseManager: PremiumPurchaseManager
    let onUnlocked: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Label("LEGITIMA PREMIUM", systemImage: "crown.fill")
                .font(.caption.bold())
                .foregroundColor(LegitimaColors.gold)

            Text("Transformez cette analyse\nen préparation concrète")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            benefit("Réponses prêtes pour l’entretien", icon: "bubble.left.and.bubble.right.fill")
            benefit("Parcours d’entretien guidé", icon: "point.topleft.down.to.point.bottomright.curvepath")
            benefit("Synthèse premium exportable", icon: "doc.text.fill")

            Text("Achat test simulé • \(purchaseManager.displayPrice)")
                .font(.subheadline.weight(.semibold))

            Button {
                Task {
                    if await purchaseManager.purchase() {
                        onUnlocked()
                    }
                }
            } label: {
                Group {
                    if purchaseManager.isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Débloquer Premium • \(purchaseManager.displayPrice)")
                    }
                }
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(LegitimaColors.accentSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!purchaseManager.canPurchase)

            Label(
                purchaseManager.usesSimulatedFallback
                    ? "Simulation locale — aucun débit réel"
                    : "Simulation StoreKit — aucun débit réel",
                systemImage: "checkmark.shield"
            )
            .font(.caption)
            .foregroundColor(.secondary)

            Button("Restaurer mes achats") {
                Task {
                    if await purchaseManager.restore() {
                        onUnlocked()
                    }
                }
            }
            .font(.subheadline.weight(.semibold))
            .disabled(purchaseManager.isProcessing)

            if let message = purchaseManager.message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(light: .white, dark: .rgb(41, 48, 49)),
                    Color(light: .rgb(249, 245, 235), dark: .rgb(38, 42, 40)),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.orange.opacity(0.25)))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func benefit(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
    }
}
