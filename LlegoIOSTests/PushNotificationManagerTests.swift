import XCTest
@testable import LlegoiOS

// Tests del manejo de push: navegación por tipo (contrato con LlegoBackend) y
// re-registro del token en login/logout. El envío al backend se reemplaza por un
// closure que captura las llamadas, sin tocar la red.

@MainActor
final class PushNotificationManagerTests: XCTestCase {

    private var manager: PushNotificationManager!
    private var sentTokens: [(token: String, jwt: String?)] = []
    private var originalSender: ((String, String?) -> Void)!
    private var originalAuthenticated = false
    private var originalStoredToken: String?

    override func setUp() async throws {
        manager = PushNotificationManager.shared
        originalSender = manager.sendToken
        originalAuthenticated = AuthManager.shared.isAuthenticated
        originalStoredToken = UserDefaults.standard.string(forKey: "deviceToken")

        manager.sendToken = { [unowned self] token, jwt in
            self.sentTokens.append((token, jwt))
        }
        // Estado conocido: sin sesión y sin ruta pendiente
        AuthManager.shared.isAuthenticated = false
        manager.consumePendingRoute()
        sentTokens = []
    }

    override func tearDown() async throws {
        manager.consumePendingRoute()
        AuthManager.shared.isAuthenticated = originalAuthenticated
        manager.sendToken = originalSender
        UserDefaults.standard.set(originalStoredToken, forKey: "deviceToken")
    }

    // MARK: - Tap: navegación a pedido

    func test_tap_orderStatusUpdate_withNestedData_routesToOrder() {
        manager.handleNotificationTap(userInfo: [
            "aps": ["alert": ["title": "En camino"]],
            "data": ["type": "order_status_update", "orderId": "ord-1", "status": "ON_THE_WAY"],
        ])
        XCTAssertEqual(manager.pendingRoute, .order(id: "ord-1"))
    }

    func test_tap_orderStatusUpdate_withTopLevelKeys_routesToOrder() {
        manager.handleNotificationTap(userInfo: ["type": "order_status_update", "orderId": "ord-2"])
        XCTAssertEqual(manager.pendingRoute, .order(id: "ord-2"))
    }

    func test_tap_acceptsSnakeCaseOrderId() {
        manager.handleNotificationTap(userInfo: ["data": ["type": "order_status_update", "order_id": "ord-3"]])
        XCTAssertEqual(manager.pendingRoute, .order(id: "ord-3"))
    }

    func test_tap_paymentConfirmedByBusiness_routesToOrder() {
        manager.handleNotificationTap(userInfo: [
            "data": ["type": "payment_confirmed_by_business", "orderId": "ord-4", "orderNumber": "1042"],
        ])
        XCTAssertEqual(manager.pendingRoute, .order(id: "ord-4"))
    }

    func test_tap_orderUpdateWithoutOrderId_doesNotRoute() {
        manager.handleNotificationTap(userInfo: ["data": ["type": "order_status_update"]])
        XCTAssertNil(manager.pendingRoute)
    }

    func test_tap_orderUpdateWithEmptyOrderId_doesNotRoute() {
        manager.handleNotificationTap(userInfo: ["data": ["type": "order_status_update", "orderId": ""]])
        XCTAssertNil(manager.pendingRoute)
    }

    // MARK: - Tap: tipos que no navegan

    func test_tap_businessPushTypes_areIgnored() {
        for type in ["new_order", "order_status_update_business", "payment_proof_submitted"] {
            manager.handleNotificationTap(userInfo: ["data": ["type": type, "orderId": "ord-x"]])
            XCTAssertNil(manager.pendingRoute, "\(type) es para negocios y no debe navegar en la app de clientes")
        }
    }

    func test_tap_withoutType_doesNotRoute() {
        manager.handleNotificationTap(userInfo: ["data": ["orderId": "ord-5"]])
        XCTAssertNil(manager.pendingRoute)
    }

    // MARK: - Foreground: nunca navega

    func test_foreground_orderStatusUpdate_doesNotRoute() {
        manager.handleForegroundNotification(userInfo: [
            "data": ["type": "order_status_update", "orderId": "ord-6"],
        ])
        XCTAssertNil(manager.pendingRoute)
    }

    func test_foreground_paymentConfirmed_doesNotRoute() {
        manager.handleForegroundNotification(userInfo: [
            "data": ["type": "payment_confirmed_by_business", "orderId": "ord-7"],
        ])
        XCTAssertNil(manager.pendingRoute)
    }

    // MARK: - Ruta pendiente

    func test_consumePendingRoute_clearsRoute() {
        manager.handleNotificationTap(userInfo: ["data": ["type": "order_status_update", "orderId": "ord-8"]])
        XCTAssertNotNil(manager.pendingRoute)
        manager.consumePendingRoute()
        XCTAssertNil(manager.pendingRoute)
    }

    func test_latestTap_replacesPendingRoute() {
        manager.handleNotificationTap(userInfo: ["data": ["type": "order_status_update", "orderId": "old"]])
        manager.handleNotificationTap(userInfo: ["data": ["type": "order_status_update", "orderId": "new"]])
        XCTAssertEqual(manager.pendingRoute, .order(id: "new"))
    }

    // MARK: - Registro del token

    func test_registerDeviceToken_encodesAsLowercaseHex_andSendsIt() {
        manager.registerDeviceToken(Data([0x00, 0x0F, 0xAB, 0xCD]))

        XCTAssertEqual(manager.deviceToken, "000fabcd")
        XCTAssertEqual(sentTokens.last?.token, "000fabcd")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "deviceToken"), "000fabcd")
    }

    func test_login_reRegistersToken() {
        manager.registerDeviceToken(Data([0x01, 0x02]))
        sentTokens = []

        AuthManager.shared.isAuthenticated = true

        XCTAssertEqual(sentTokens.count, 1)
        XCTAssertEqual(sentTokens.first?.token, "0102")
    }

    func test_logout_reRegistersTokenWithoutJWT() {
        manager.registerDeviceToken(Data([0x0A, 0x0B]))
        AuthManager.shared.isAuthenticated = true
        sentTokens = []

        AuthManager.shared.isAuthenticated = false

        XCTAssertEqual(sentTokens.count, 1, "El logout debe re-registrar el token una vez")
        XCTAssertEqual(sentTokens.first?.token, "0a0b")
        XCTAssertNil(sentTokens.first?.jwt, "Sin JWT: el backend desvincula el token del usuario")
    }

    func test_staying_loggedOut_doesNotSendToken() {
        manager.registerDeviceToken(Data([0x0C]))
        sentTokens = []

        AuthManager.shared.isAuthenticated = false

        XCTAssertTrue(sentTokens.isEmpty)
    }
}
