import Foundation

struct ProfileLocalCache {
    struct Snapshot: Codable {
        var fullName: String?
        var email: String?
        var customerLevelRaw: Int?
        var currentPoints: Int?
        var nextLevelPoints: Int?
        var latitude: Double?
        var longitude: Double?
        var address: String?

        init(
            fullName: String? = nil,
            email: String? = nil,
            customerLevelRaw: Int? = nil,
            currentPoints: Int? = nil,
            nextLevelPoints: Int? = nil,
            latitude: Double? = nil,
            longitude: Double? = nil,
            address: String? = nil
        ) {
            self.fullName = fullName
            self.email = email
            self.customerLevelRaw = customerLevelRaw
            self.currentPoints = currentPoints
            self.nextLevelPoints = nextLevelPoints
            self.latitude = latitude
            self.longitude = longitude
            self.address = address
        }
    }

    private static let storageKey = "llego_profile_snapshot_v1"

    static func load() -> Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    static func save(_ snapshot: Snapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func update(_ updateBlock: (inout Snapshot) -> Void) {
        var snapshot = load() ?? Snapshot()
        updateBlock(&snapshot)
        save(snapshot)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
