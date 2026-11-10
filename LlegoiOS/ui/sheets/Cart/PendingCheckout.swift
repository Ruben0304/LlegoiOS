import CryptoKit
import Foundation

final class PendingCheckout {
    private struct Record: Codable {
        let fingerprint: String
        let key: String
        var paymentStarted: Bool?
        var owner: String?
        var orderID: String?
        var orderNumber: String?
    }

    private let defaults: UserDefaults
    private let storageKey = "pending_checkout_v1"
    private let directory: URL
    private let synchronize: () -> Bool

    init(defaults: UserDefaults = .standard, directory: URL? = nil, synchronize: (() -> Bool)? = nil) {
        self.defaults = defaults
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PendingCheckout", isDirectory: true)
        self.synchronize = synchronize ?? { defaults.synchronize() }
    }

    func key(for payload: Data, userID: String, endpoint: String) throws -> String {
        let identity = try JSONEncoder().encode([userID, endpoint])
        let storageKey = storageKey + "." + digest(identity)
        let fingerprint = SHA256.hash(data: identity + payload).map { String(format: "%02x", $0) }.joined()
        if let data = defaults.data(forKey: storageKey),
           var record = try? JSONDecoder().decode(Record.self, from: data),
           record.fingerprint == fingerprint {
            try savePayload(payload, key: record.key)
            if record.owner == nil {
                record.owner = digest(identity)
            }
            try saveRecord(record, storageKey: storageKey)
            return record.key
        }
        let previous = defaults.data(forKey: storageKey).flatMap { try? JSONDecoder().decode(Record.self, from: $0) }
        let record = Record(fingerprint: fingerprint, key: UUID().uuidString, paymentStarted: false,
                            owner: digest(identity))
        try savePayload(payload, key: record.key)
        try saveRecord(record, storageKey: storageKey)
        if let previous, UUID(uuidString: previous.key) != nil {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(previous.key))
        }
        return record.key
    }

    private func saveRecord(_ record: Record, storageKey: String) throws {
        defaults.set(try JSONEncoder().encode(record), forKey: storageKey)
        guard synchronize() else { throw CocoaError(.fileWriteUnknown) }
    }

    private func savePayload(_ payload: Data, key: String) throws {
        guard UUID(uuidString: key) != nil else { throw CocoaError(.fileWriteInvalidFileName) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try payload.write(to: directory.appendingPathComponent(key),
                          options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    func pendingPayload(userID: String, endpoint: String) -> (key: String, payload: Data)? {
        guard let identity = try? JSONEncoder().encode([userID, endpoint]),
              let data = defaults.data(forKey: storageKey + "." + digest(identity)),
              let record = try? JSONDecoder().decode(Record.self, from: data),
              record.owner == digest(identity), UUID(uuidString: record.key) != nil,
              let payload = try? Data(contentsOf: directory.appendingPathComponent(record.key)),
              digest(identity + payload) == record.fingerprint else { return nil }
        return (record.key, payload)
    }

    func rememberOrder(for key: String, userID: String, endpoint: String, id: String, number: String) throws {
        let identity = try JSONEncoder().encode([userID, endpoint])
        let storageKey = storageKey + "." + digest(identity)
        guard let data = defaults.data(forKey: storageKey),
              var record = try? JSONDecoder().decode(Record.self, from: data),
              record.key == key else { throw CocoaError(.fileNoSuchFile) }
        record.orderID = id
        record.orderNumber = number
        try saveRecord(record, storageKey: storageKey)
    }

    func pendingOrder(userID: String, endpoint: String) -> (id: String, number: String)? {
        guard let identity = try? JSONEncoder().encode([userID, endpoint]),
              let data = defaults.data(forKey: storageKey + "." + digest(identity)),
              let record = try? JSONDecoder().decode(Record.self, from: data),
              record.owner == digest(identity),
              let id = record.orderID, let number = record.orderNumber else { return nil }
        return (id, number)
    }

    private func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    func markPaymentStarted(for key: String, userID: String, endpoint: String) throws -> Bool {
        let identity = try JSONEncoder().encode([userID, endpoint])
        let storageKey = storageKey + "." + digest(identity)
        guard let data = defaults.data(forKey: storageKey),
              var record = try? JSONDecoder().decode(Record.self, from: data),
              record.key == key,
              record.paymentStarted != true else { return false }
        record.paymentStarted = true
        try saveRecord(record, storageKey: storageKey)
        return true
    }

    /// Borra todos los checkouts pendientes (de cualquier usuario); se usa al cerrar sesión.
    func clearAll() {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(storageKey) {
            defaults.removeObject(forKey: key)
        }
        try? FileManager.default.removeItem(at: directory)
    }

    func clear(for key: String, userID: String, endpoint: String) {
        guard let identity = try? JSONEncoder().encode([userID, endpoint]) else { return }
        let storageKey = storageKey + "." + digest(identity)
        guard let data = defaults.data(forKey: storageKey),
              let record = try? JSONDecoder().decode(Record.self, from: data),
              record.key == key else { return }
        defaults.removeObject(forKey: storageKey)
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(key))
    }
}
