#if DEBUG
import SwiftUI

/// The paywall Legitima no longer has. Kept under `#if DEBUG` so the StoreKit
/// integration stays readable and runnable in previews without shipping a
/// purchase surface. See README.md.
struct PremiumUnlockCard: View {
    @ObservedObject var purchaseManager: PremiumPurchaseManager
    /// A purchase completed now — celebrate and hand over the first answer.
    let onUnlocked: () -> Void
    /// Access the user already owned — resume, do not celebrate.
    let onRestored: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Label("LEGITIMA PREMIUM", systemImage: "crown.fill")
                .font(.caption.bold())
                .foregroundColor(LegitimaColors.gold)

            Text("Transformez cette analyse\nen préparation concrète")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                benefit(
                    "Réponses prêtes pour l’entretien",
                    subtitle: "Questions difficiles couvertes, mots choisis",
                    icon: "shield.fill",
                    iconColor: Color(light: .rgb(153, 60, 29), dark: .rgb(240, 153, 123)),
                    chipColor: Color(light: .rgb(255, 239, 221), dark: .rgb(46, 39, 28))
                )
                benefit(
                    "Parcours d’entretien guidé",
                    subtitle: "Du récit à la posture, étape par étape",
                    icon: "point.topleft.down.to.point.bottomright.curvepath",
                    iconColor: Color(light: .rgb(24, 95, 165), dark: .rgb(133, 183, 235)),
                    chipColor: Color(light: .rgb(228, 239, 253), dark: .rgb(30, 38, 49))
                )
                benefit(
                    "Plan d'action exportable en PDF",
                    subtitle: "Votre plan d’action pour le jour J",
                    icon: "sparkles",
                    iconColor: Color(light: .rgb(83, 74, 183), dark: .rgb(175, 169, 236)),
                    chipColor: Color(light: .rgb(242, 233, 252), dark: .rgb(39, 33, 48))
                )
            }

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
                .legitimaPrimaryLabel()
            }
            .disabled(!purchaseManager.canPurchase)

            Label(
                purchaseManager.usesSimulatedFallback
                    ? "Simulation locale — aucun débit réel"
                    : "Simulation StoreKit — aucun débit réel",
                systemImage: "checkmark.shield"
            )
            .font(.caption)
            .foregroundColor(LegitimaColors.muted)

            Button("Restaurer mes achats") {
                Task {
                    if await purchaseManager.restore() {
                        onRestored()
                    }
                }
            }
            .font(.subheadline.weight(.semibold))
            .disabled(purchaseManager.isProcessing)

            if let message = purchaseManager.message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(LegitimaColors.gold)
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
        .overlay(RoundedRectangle(cornerRadius: LegitimaRadius.card).stroke(LegitimaColors.gold.opacity(0.3)))
        .clipShape(RoundedRectangle(cornerRadius: LegitimaRadius.card))
    }

    private func benefit(
        _ title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        chipColor: Color
    ) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(chipColor)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .foregroundColor(iconColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(LegitimaColors.muted)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
    }
}

struct PremiumUnlockCard_Previews: PreviewProvider {
    static var previews: some View {
        PremiumUnlockCard(
            purchaseManager: PremiumPurchaseManager(),
            onUnlocked: {},
            onRestored: {}
        )
        .padding()
    }
}
#endif
