import Foundation
import SwiftUI
import Combine

enum UpdateType {
    case none
    case optional  // Actualización disponible pero no obligatoria
    case required  // Versión instalada < minVersion
    case maintenance  // Servidor en mantenimiento
}

@MainActor
class AppUpdateViewModel: ObservableObject {
    static let shared = AppUpdateViewModel()

    @Published var showUpdateAlert = false
    @Published var updateType: UpdateType = .none
    @Published var appConfig: AppConfigData?
    @Published var isChecking = false

    private let repository = AppUpdateRepository()
    private var checkTimer: Timer?
    private let checkInterval: TimeInterval = 3600 // Verificar cada hora

    private init() {}

    // MARK: - Check for Updates
    func checkForUpdates(force: Bool = false) {
        guard !isChecking else { return }

        Task {
            isChecking = true
            defer { isChecking = false }

            do {
                let config = try await repository.fetchAppConfig()
                self.appConfig = config

                // Verificar mantenimiento primero
                if config.maintenanceEnabled {
                    updateType = .maintenance
                    showUpdateAlert = true
                    return
                }

                let currentVersion = getCurrentAppVersion()
                let minVersion = config.minVersion
                let latestVersion = config.currentVersion

                print("📱 Versión actual: \(currentVersion)")
                print("📱 Versión mínima: \(minVersion)")
                print("📱 Versión disponible: \(latestVersion)")

                // Verificar si es necesario actualizar
                if compareVersions(currentVersion, minVersion) == .orderedAscending {
                    // Versión instalada < versión mínima = ACTUALIZACIÓN OBLIGATORIA
                    updateType = .required
                    showUpdateAlert = true
                    print("⚠️ Actualización OBLIGATORIA requerida")
                } else if compareVersions(currentVersion, latestVersion) == .orderedAscending {
                    // Versión instalada < versión disponible = actualización opcional
                    // Solo mostrar si no la han descartado antes
                    if force || !hasUserDismissedUpdate(version: latestVersion) {
                        updateType = .optional
                        showUpdateAlert = true
                        print("ℹ️ Actualización opcional disponible")
                    }
                } else {
                    updateType = .none
                    print("✅ App está actualizada")
                }
            } catch {
                print("❌ Error al verificar actualizaciones: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Start Periodic Check
    func startPeriodicCheck() {
        // Verificar inmediatamente al inicio
        checkForUpdates()

        // Configurar timer para verificaciones periódicas
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForUpdates()
            }
        }
    }

    // MARK: - Stop Periodic Check
    func stopPeriodicCheck() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    // MARK: - User Actions
    func openAppStore() {
        guard let config = appConfig,
              let url = URL(string: config.storeUrl) else {
            print("❌ URL de App Store no válida")
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func dismissOptionalUpdate() {
        guard updateType == .optional,
              let version = appConfig?.currentVersion else {
            return
        }

        // Guardar que el usuario descartó esta versión
        saveUserDismissedUpdate(version: version)
        showUpdateAlert = false
        updateType = .none
    }

    func dismissMaintenance() {
        guard updateType == .maintenance else {
            return
        }

        showUpdateAlert = false
        updateType = .none
    }

    // MARK: - Version Comparison
    private func getCurrentAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        return version1.compare(version2, options: .numeric)
    }

    // MARK: - User Defaults
    private func hasUserDismissedUpdate(version: String) -> Bool {
        let key = "dismissedUpdate_\(version)"
        return UserDefaults.standard.bool(forKey: key)
    }

    private func saveUserDismissedUpdate(version: String) {
        let key = "dismissedUpdate_\(version)"
        UserDefaults.standard.set(true, forKey: key)
    }

    // MARK: - Computed Properties
    var updateTitle: String {
        switch updateType {
        case .required:
            return "Actualización Requerida"
        case .optional:
            return "Actualización Disponible"
        case .maintenance:
            return "Mantenimiento"
        case .none:
            return ""
        }
    }

    var updateMessage: String {
        switch updateType {
        case .required:
            return appConfig?.updateMessage ?? "Se requiere actualizar a la versión \(appConfig?.currentVersion ?? "") para continuar usando la app."
        case .optional:
            return appConfig?.updateMessage ?? "Una nueva versión (\(appConfig?.currentVersion ?? "")) está disponible en el App Store."
        case .maintenance:
            return appConfig?.maintenanceMessage ?? "La aplicación está en mantenimiento. Por favor, intenta más tarde."
        case .none:
            return ""
        }
    }

    var changelog: String? {
        return appConfig?.changelog
    }

    var canDismiss: Bool {
        return updateType == .optional || updateType == .maintenance
    }
}
