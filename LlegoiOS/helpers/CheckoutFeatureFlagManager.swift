import Combine
import Foundation

@MainActor
final class CheckoutFeatureFlagManager: ObservableObject {
    static let shared = CheckoutFeatureFlagManager()

    @Published private(set) var storePickupEnabled: Bool
    @Published private(set) var storePickupAllowedBranchIds: Set<String>

    private let defaults = UserDefaults.standard
    private let enabledKey = "llego_flag_store_pickup_enabled"
    private let allowedBranchesKey = "llego_flag_store_pickup_allowed_branch_ids"

    private init() {
        if defaults.object(forKey: enabledKey) == nil {
            #if DEBUG
                defaults.set(true, forKey: enabledKey)
            #else
                defaults.set(false, forKey: enabledKey)
            #endif
        }
        storePickupEnabled = defaults.bool(forKey: enabledKey)
        storePickupAllowedBranchIds = Set(defaults.stringArray(forKey: allowedBranchesKey) ?? [])
    }

    func isPickupEnabled(for branchId: String?) -> Bool {
        guard storePickupEnabled else { return false }
        guard !storePickupAllowedBranchIds.isEmpty else { return true }
        guard let branchId else { return false }
        return storePickupAllowedBranchIds.contains(branchId)
    }
}
