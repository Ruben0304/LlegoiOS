import XCTest
import UserNotifications
@testable import LlegoiOS

@MainActor
final class PushNotificationDependencyTests: XCTestCase {
    private var originalStoredToken: String?

    override func setUp() async throws {
        originalStoredToken = UserDefaults.standard.string(forKey: "deviceToken")
    }

    override func tearDown() async throws {
        UserDefaults.standard.set(originalStoredToken, forKey: "deviceToken")
    }

    func test_permissionGrantedRegistersForRemoteNotifications() async {
        let center = FakeNotificationCenter(status: .authorized, granted: true)
        var registrations = 0
        let manager = makeManager(center: center) { registrations += 1 }

        manager.requestPermissionAndRegister()
        await waitForPermissionStatus(.authorized, on: manager)
        XCTAssertEqual(registrations, 1)
        XCTAssertEqual(manager.permissionStatus, .authorized)
    }

    func test_permissionDeniedDoesNotRegister() async {
        let center = FakeNotificationCenter(status: .denied, granted: false)
        var registrations = 0
        let manager = makeManager(center: center) { registrations += 1 }

        manager.requestPermissionAndRegister()
        await waitForPermissionStatus(.denied, on: manager)
        XCTAssertEqual(registrations, 0)
        XCTAssertEqual(manager.permissionStatus, .denied)
    }

    func test_provisionalPermissionRegistersWhenPreviouslyGranted() async {
        let center = FakeNotificationCenter(status: .provisional, granted: true)
        var registrations = 0
        let manager = makeManager(center: center) { registrations += 1 }

        manager.requestPermissionAndRegister()
        await waitForPermissionStatus(.provisional, on: manager)
        XCTAssertEqual(registrations, 1)
        XCTAssertEqual(manager.permissionStatus, .provisional)
    }

    func test_backendRegistrationSuccessMarksTokenRegistered() async {
        let registrar = FakeTokenRegistrar(result: .success(true))
        let manager = PushNotificationManager(
            notificationCenter: FakeNotificationCenter(status: .authorized, granted: true),
            tokenRegistrar: registrar,
            registerRemoteNotifications: {}
        )

        manager.registerDeviceToken(Data([0x01, 0xAF]))
        await Task.yield()
        XCTAssertEqual(registrar.calls.map(\.token), ["01af"])
        XCTAssertTrue(manager.isRegistered)
    }

    func test_backendGraphQLErrorDoesNotMarkTokenRegistered() async {
        let registrar = FakeTokenRegistrar(result: .failure(NSError(domain: "GraphQL", code: 1)))
        let manager = PushNotificationManager(
            notificationCenter: FakeNotificationCenter(status: .authorized, granted: true),
            tokenRegistrar: registrar,
            registerRemoteNotifications: {}
        )

        manager.registerDeviceToken(Data([0x02]))
        await Task.yield()
        XCTAssertFalse(manager.isRegistered)
        XCTAssertEqual(registrar.calls.count, 1)
    }

    func test_registerDeviceTokenMutationContainsTokenPlatformAndJWT() {
        let mutation = ApolloDeviceTokenRegistrar.makeMutation(token: "f00d", jwt: "customer-jwt")

        XCTAssertEqual(LlegoAPI.RegisterDeviceTokenMutation.operationName, "RegisterDeviceToken")
        XCTAssertEqual(mutation.input.token, "f00d")
        if case .some(let jwt) = mutation.jwt {
            XCTAssertEqual(jwt, "customer-jwt")
        } else {
            XCTFail("La mutation debe enviar el JWT del cliente")
        }
    }

    func test_clientPushTypesRouteAndBusinessOrMalformedPayloadsDoNot() {
        let manager = makeManager(center: FakeNotificationCenter(status: .denied, granted: false)) {}
        for type in ["order_status_update", "payment_confirmed_by_business"] {
            manager.handleNotificationTap(userInfo: ["data": ["type": type, "orderId": "ord-42"]])
            XCTAssertEqual(manager.pendingRoute, .order(id: "ord-42"), "tipo: \(type)")
            manager.consumePendingRoute()
        }
        for payload: [AnyHashable: Any] in [
            ["data": ["type": "new_order", "orderId": "ord-business"]],
            ["data": ["type": "order_status_update_business", "orderId": "ord-business"]],
            ["data": ["type": 7, "orderId": "ord-invalid"]],
            ["data": "not-an-object"],
            ["type": "order_status_update", "orderId": ["bad"]],
            [:]
        ] {
            manager.handleNotificationTap(userInfo: payload)
            XCTAssertNil(manager.pendingRoute, "payload malformado o ajeno no debe navegar")
        }
        // Los tipos informativos del backend son válidos, pero no abren un pedido.
        for type in ["kyc", "error_alert"] {
            manager.handleNotificationTap(userInfo: ["data": ["type": type]])
            XCTAssertNil(manager.pendingRoute)
        }
    }

    private func makeManager(center: FakeNotificationCenter, register: @escaping () -> Void) -> PushNotificationManager {
        PushNotificationManager(notificationCenter: center, tokenRegistrar: FakeTokenRegistrar(result: .success(true)), registerRemoteNotifications: register)
    }

    private func waitForPermissionStatus(_ expected: UNAuthorizationStatus, on manager: PushNotificationManager) async {
        for _ in 0..<100 {
            if manager.permissionStatus == expected { return }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

@MainActor
private final class FakeNotificationCenter: UserNotificationCenterClient {
    let status: UNAuthorizationStatus
    let granted: Bool
    var requests: [UNNotificationRequest] = []
    init(status: UNAuthorizationStatus, granted: Bool) { self.status = status; self.granted = granted }
    func getAuthorizationStatus(_ completion: @escaping @Sendable (UNAuthorizationStatus) -> Void) {
        let currentStatus = status
        completion(currentStatus)
    }
    func requestAuthorization(completion: @escaping @Sendable (Bool, Error?) -> Void) {
        let isGranted = granted
        completion(isGranted, nil)
    }
    func setBadgeCount(_ count: Int) {}
    func add(_ request: UNNotificationRequest, completion: (@Sendable (Error?) -> Void)?) { requests.append(request); completion?(nil) }
}

@MainActor
private final class FakeTokenRegistrar: DeviceTokenRegistering {
    let result: Result<Bool, Error>
    var calls: [(token: String, jwt: String?)] = []
    init(result: Result<Bool, Error>) { self.result = result }
    func register(token: String, jwt: String?, completion: @escaping @Sendable (Result<Bool, Error>) -> Void) {
        calls.append((token, jwt)); completion(result)
    }
}

@MainActor
final class LocalDeliveryNotificationTests: XCTestCase {
    func test_deliveryNotificationUsesExpectedContentAndOneSecondTrigger() {
        let center = FakeNotificationCenter(status: .authorized, granted: true)
        LocalDeliveryNotificationSender(notificationCenter: center).sendDeliveryNotification()

        guard let request = center.requests.first else { return XCTFail("No se programó la notificación") }
        XCTAssertEqual(request.content.title, "¡Tu pedido ha llegado! 🎉")
        XCTAssertEqual(request.content.body, "El mensajero está en tu puerta. ¡Disfruta tu pedido!")
        XCTAssertEqual((request.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval, 1)
        XCTAssertEqual(request.content.badge as? Int, 1)
        XCTAssertNotNil(request.content.sound)
    }
}
