import Foundation

@MainActor
final class DeviceIDManager {
    static let shared = DeviceIDManager()

    private let account = "llego_ai_device_id"
    private let fallbackKey = "llego_ai_device_id_fallback"
    private let service = (Bundle.main.bundleIdentifier ?? "com.llego.app") + ".device"

    private init() {}

    func getDeviceId() -> String? {
        if let existing = KeychainHelper.read(service: service, account: account),
           !existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return existing
        }

        if let fallback = UserDefaults.standard.string(forKey: fallbackKey),
           !fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if KeychainHelper.save(fallback, service: service, account: account) {
                UserDefaults.standard.removeObject(forKey: fallbackKey)
            }
            return fallback
        }

        let generated = UUID().uuidString.lowercased()
        if KeychainHelper.save(generated, service: service, account: account) {
            return generated
        }

        UserDefaults.standard.set(generated, forKey: fallbackKey)
        return generated
    }
}
