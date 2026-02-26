import Foundation
import UIKit
import UserNotifications
import Combine
import Apollo

/// Manager para push notifications
/// Maneja registro de device token y procesamiento de notificaciones
@MainActor
final class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()
    
    @Published private(set) var deviceToken: String?
    @Published private(set) var isRegistered = false
    @Published private(set) var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    private let apolloClient = ApolloClientManager.shared.apollo
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Solicita permisos y registra para push notifications
    func requestPermissionAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            Task { @MainActor [weak self] in
                if granted {
                    self?.registerForRemoteNotifications()
                }
                self?.updatePermissionStatus()
            }
        }
    }
    
    /// Actualiza el estado de permisos
    func updatePermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status = settings.authorizationStatus
            Task { @MainActor [weak self] in
                self?.permissionStatus = status
            }
        }
    }
    
    /// Registra el device token con el backend
    func registerDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        
        print("📱 Device Token: \(token)")
        
        // Registrar con el backend
        sendTokenToBackend(token)
    }
    
    /// Procesa una notificación recibida
    func handleNotification(userInfo: [AnyHashable: Any]) {
        guard let data = userInfo["data"] as? [String: Any],
              let type = data["type"] as? String else {
            return
        }
        
        switch type {
        case "NEW_BUSINESS_TYPE":
            // Nuevo tipo de negocio disponible - sincronizar
            Task {
                await BusinessTypeConfigManager.shared.syncWithBackend()
            }
            
        default:
            print("📬 Notificación no manejada: \(type)")
        }
    }
    
    // MARK: - Private Methods
    
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func sendTokenToBackend(_ token: String) {
        let jwt = AuthManager.shared.getAccessToken()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let osVersion = UIDevice.current.systemVersion
        
        let input = LlegoAPI.RegisterDeviceTokenInput(
            token: token,
            platform: .case(.ios),
            appVersion: appVersion.map { .some($0) } ?? .null,
            osVersion: .some(osVersion)
        )
        
        let mutation = LlegoAPI.RegisterDeviceTokenMutation(
            input: input,
            jwt: jwt.map { .some($0) } ?? .null
        )
        
        apolloClient.performCompat(mutation: mutation) { [weak self] result in
            Task { @MainActor [weak self] in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.registerDeviceToken != nil {
                        self?.isRegistered = true
                        print("✅ Device token registrado en backend")
                    } else if let errors = graphQLResult.errors {
                        print("❌ Error registrando token: \(errors)")
                    }
                    
                case .failure(let error):
                    print("❌ Error de red registrando token: \(error)")
                }
            }
        }
    }
}

// MARK: - App Delegate para Push Notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        // Solicitar permisos de push
        Task { @MainActor in
            PushNotificationManager.shared.requestPermissionAndRegister()
        }

        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in
            PushNotificationManager.shared.registerDeviceToken(deviceToken)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Error registrando para push: \(error)")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Notificación recibida en foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        Task { @MainActor in
            PushNotificationManager.shared.handleNotification(userInfo: userInfo)
        }
        
        // Mostrar banner incluso en foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Usuario tocó la notificación
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        Task { @MainActor in
            PushNotificationManager.shared.handleNotification(userInfo: userInfo)
        }
        
        completionHandler()
    }
}
