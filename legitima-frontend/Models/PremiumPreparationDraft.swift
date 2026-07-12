import Combine
import Foundation

final class PremiumPreparationDraft: ObservableObject {
    @Published var anchorRole: String = ""

    func reset() {
        anchorRole = ""
    }
}
