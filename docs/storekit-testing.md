# StoreKit Premium simulation

> **Document historique.** Legitima ne comporte plus d'achat intégré. Le code
> StoreKit est conservé sous `#if DEBUG`, donc absent du binaire livré : voir
> la section correspondante du [README](../README.md). Cette note décrit
> comment l'exercer en local.

The shared `legitima-frontend` scheme uses `legitima-frontend/Products.storekit`.
It defines one local non-consumable product:

- product ID: `com.milehana.legitima.premium.test`
- localized price: `4,99 €`
- no real payment is processed

Run the app from the shared scheme and tap **Débloquer Premium** to display the
StoreKit test purchase sheet. Use Xcode's StoreKit transaction manager to inspect
or delete the local transaction and repeat the flow.

The app unlocks Premium only after a verified StoreKit transaction. Cancellation
keeps the freemium state, pending purchases display a message, and **Restaurer mes
achats** calls `AppStore.sync()` before checking current entitlements.

## Simulated fallback (TestFlight)

StoreKit configuration files only apply when the app is launched through the
Xcode scheme. On TestFlight (or any build where the test product cannot be
loaded), the purchase automatically falls back to a **local simulation**:

- **Débloquer Premium** unlocks Premium locally, without any payment;
- the unlock is persisted (`premium.simulated_unlock` in UserDefaults) and
  restored at launch and by **Restaurer mes achats**;
- the card shows "Simulation locale — aucun débit réel" in that mode.

When a real product exists in App Store Connect, the StoreKit flow takes over
again automatically.
