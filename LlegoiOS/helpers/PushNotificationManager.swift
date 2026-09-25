import Foundation
import UIKit
import UserNotifications
import Combine
import Apollo

/// Destino de navegación pendiente originado al tocar una push
enum PushRoute: Equatable {
    case order(id: String)
}

/// Manager para push notifications
/// Maneja registro de device token y procesamiento de notificaciones
@MainActor
final class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()
    
    @Published private(set) var deviceToken: String?
    @Published private(set) var isRegistered = false
    @Published private(set) var permissionStatus: UNAuthorizationStatus = .notDetermined
    /// Se mantiene hasta que la UI lo consume, así no se pierde si la push
    /// se tocó con la app cerrada y la vista raíz aún no estaba montada
    @Published private(set) var pendingRoute: PushRoute?
    
    private let apolloClient = ApolloClientManager.shared.apollo
    private let tokenStorageKey = "deviceToken"
    private var cancellables = Set<AnyCancellable>()
    private var wasAuthenticated = false

    /// Envío del token al backend. Reemplazable en tests para no tocar la red.
    lazy var sendToken: (_ token: String, _ jwt: String?) -> Void = { [unowned self] token, jwt in
        self.sendTokenToBackend(token, jwt: jwt)
    }
    
    private override init() {
        super.init()
        observeAuthChanges()
        observeAppActivation()
        loadStoredToken()
    }
    
    // MARK: - Public Methods
    
    /// Al arrancar: si el permiso ya fue concedido, registra en APNs para refrescar el token.
    /// No muestra el diálogo del sistema; eso se hace en un momento con contexto (primer pedido).
    func registerIfAlreadyAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status = settings.authorizationStatus
            Task { @MainActor [weak self] in
                self?.permissionStatus = status
                switch status {
                case .authorized, .provisional, .ephemeral:
                    self?.registerForRemoteNotifications()
                default:
                    break
                }
            }
        }
    }

    /// Solicita permisos y registra para push notifications.
    /// Si el usuario ya respondió antes, el sistema no vuelve a mostrar el diálogo.
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
        UserDefaults.standard.set(token, forKey: tokenStorageKey)
        
        // Registrar con el backend
        sendToken(token, AuthManager.shared.getAccessToken())
    }
    
    /// Notificación recibida con la app en foreground: solo efectos secundarios, sin navegar
    func handleForegroundNotification(userInfo: [AnyHashable: Any]) {
        let payload = parseNotificationPayload(from: userInfo)
        guard let type = payload.type else { return }
        performSideEffects(for: type)
    }

    /// El usuario tocó la notificación: efectos secundarios + navegación
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        let payload = parseNotificationPayload(from: userInfo)
        guard let type = payload.type else { return }
        performSideEffects(for: type)

        // Tipos que el backend envía al cliente (LlegoBackend: orders_service,
        // payments_service, business_types/mutations). "new_order" y
        // "order_status_update_business" son para negocios y no se manejan aquí.
        switch type {
        case "order_status_update", "payment_confirmed_by_business":
            guard let orderId = payload.orderId, !orderId.isEmpty else { return }
            pendingRoute = .order(id: orderId)

        case "NEW_BUSINESS_TYPE", "UPDATED_BUSINESS_TYPE":
            break

        default:
            print("📬 Notificación no manejada: \(type)")
        }
    }

    /// La UI llama esto después de navegar al destino pendiente
    func consumePendingRoute() {
        pendingRoute = nil
    }

    private func performSideEffects(for type: String) {
        if type == "NEW_BUSINESS_TYPE" || type == "UPDATED_BUSINESS_TYPE" {
            // Nuevo tipo de negocio disponible - sincronizar
            Task {
                await BusinessTypeConfigManager.shared.syncWithBackend()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    private func observeAppActivation() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { _ in
                UNUserNotificationCenter.current().setBadgeCount(0)
            }
            .store(in: &cancellables)
    }

    private func observeAuthChanges() {
        AuthManager.shared.$isAuthenticated
            .removeDuplicates()
            .sink { [weak self] isAuthenticated in
                guard let self else { return }
                defer { self.wasAuthenticated = isAuthenticated }

                if isAuthenticated {
                    self.registerStoredToken(jwt: AuthManager.shared.getAccessToken())
                } else if self.wasAuthenticated {
                    // Logout: re-registrar sin JWT desvincula el token del usuario en el backend
                    // (userId = null) pero lo mantiene activo para pushes generales.
                    // No usar getAccessToken() aquí: durante signOut() el Keychain aún tiene el JWT.
                    self.registerStoredToken(jwt: nil)
                }
            }
            .store(in: &cancellables)
    }

    private func loadStoredToken() {
        if let token = UserDefaults.standard.string(forKey: tokenStorageKey), !token.isEmpty {
            deviceToken = token
        }
    }

    private func registerStoredToken(jwt: String?) {
        guard let token = deviceToken, !token.isEmpty else { return }
        sendToken(token, jwt)
    }

    private func parseNotificationPayload(from userInfo: [AnyHashable: Any]) -> (type: String?, orderId: String?) {
        let dataPayload = userInfo["data"] as? [String: Any]
        let type = (dataPayload?["type"] as? String) ?? (userInfo["type"] as? String)
        let orderId = (dataPayload?["orderId"] as? String)
            ?? (dataPayload?["order_id"] as? String)
            ?? (userInfo["orderId"] as? String)
            ?? (userInfo["order_id"] as? String)
        return (type, orderId)
    }
    
    private func sendTokenToBackend(_ token: String, jwt: String?) {
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

        // Solo re-registrar si ya hay permiso; el diálogo se pide al confirmar el primer pedido
        Task { @MainActor in
            PushNotificationManager.shared.registerIfAlreadyAuthorized()
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
            PushNotificationManager.shared.handleForegroundNotification(userInfo: userInfo)
        }
        
        // Mostrar banner incluso en foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Usuario tocó la notificación
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        Task { @MainActor in
            PushNotificationManager.shared.handleNotificationTap(userInfo: userInfo)
        }
        
        completionHandler()
    }
}
