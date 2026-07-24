# StoreKit Premium simulation

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
