import Foundation
import XCTest
@testable import LlegoiOS

private actor CheckoutNetworkFixture {
    private var inputs: [Data] = []

    func request(_ request: URLRequest) throws -> (Data, URLResponse) {
        let body = try JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as! [String: Any]
        let variables = body["variables"] as! [String: Any]
        inputs.append(try JSONSerialization.data(withJSONObject: variables["input"]!, options: .sortedKeys))
        if inputs.count == 1 { throw URLError(.timedOut) }
        let result = #"{"data":{"createOrder":{"id":"test-order","orderNumber":"123","status":"PENDING","subtotal":10,"deliveryFee":1,"total":11,"currency":"CUP","paymentMethod":"pending","paymentStatus":"PENDING","createdAt":"2026-01-01","items":[],"discounts":[],"branch":{"id":"branch","name":"Test"},"business":{"id":"business","name":"Test"}}}}"#
        let response = HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200,
                                       httpVersion: nil, headerFields: nil)!
        return (Data(result.utf8), response)
    }

    func capturedInputs() -> [Data] { inputs }
}

@MainActor
final class CreateOrderRecoveryTests: XCTestCase {
    func testTimeoutThenRestartReusesPayloadAndKeyWithoutInitiatingPayment() async throws {
        let suite = "CreateOrderRecoveryTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: directory) }
        let auth = AuthManager.shared
        let originalToken = auth.accessToken
        let originalUser = auth.userId
        defer { auth.accessToken = originalToken; auth.userId = originalUser }
        auth.accessToken = "test-token"
        auth.userId = "test-user"

        let network = CheckoutNetworkFixture()
        let storage = PendingCheckout(defaults: defaults, directory: directory, synchronize: { true })
        let repository = CreateOrderRepository(pendingCheckout: storage, performRequest: { try await network.request($0) })
        let item = OrderRequestItem(itemType: .product, quantity: 1, productId: "product", comboId: nil,
                                    comboSelections: nil, showcaseId: nil, description: nil)
        let first: Result<CreatedOrder, Error> = await withCheckedContinuation { continuation in
            repository.createOrder(branchId: "branch", items: [item], deliveryAddress: nil,
                                   paymentMethod: "pending", comments: "test", scheduledFor: Date(timeIntervalSince1970: 123456)) {
                continuation.resume(returning: $0)
            }
        }
        guard case .failure = first else { return XCTFail("Expected a timeout") }

        let restarted = CreateOrderRepository(
            pendingCheckout: PendingCheckout(defaults: defaults, directory: directory, synchronize: { true }),
            performRequest: { try await network.request($0) })
        let recovered: Result<CreatedOrder, Error> = await withCheckedContinuation { continuation in
            restarted.recoverPending(userID: "test-user") { continuation.resume(returning: $0) }
        }
        XCTAssertEqual(try recovered.get().id, "test-order")
        let inputs = await network.capturedInputs()
        XCTAssertEqual(inputs.count, 2)
        XCTAssertEqual(inputs.first, inputs.last)
        XCTAssertEqual(restarted.pendingOrder(userID: "test-user")?.id, "test-order")
    }
}
