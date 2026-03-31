import Combine
import Foundation

@MainActor
final class PickupSelectionManager {
    static let shared = PickupSelectionManager()

    private let defaults = UserDefaults.standard
    private let keyPrefix = "llego_pickup_selection_v1"

    private init() {}

    func loadSelection(for userId: String?) -> PickupSelection? {
        guard let key = scopedKey(for: userId), let data = defaults.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(PickupSelection.self, from: data)
    }

    func saveSelection(_ selection: PickupSelection?, for userId: String?) {
        guard let key = scopedKey(for: userId) else { return }
        guard let selection else {
            defaults.removeObject(forKey: key)
            return
        }
        guard let data = try? JSONEncoder().encode(selection) else { return }
        defaults.set(data, forKey: key)
    }

    private func scopedKey(for userId: String?) -> String? {
        guard let userId, !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return "\(keyPrefix)_\(userId)"
    }
}
