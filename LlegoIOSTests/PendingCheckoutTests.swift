import Foundation
import XCTest
@testable import LlegoiOS

final class PendingCheckoutTests: XCTestCase {
    func testKeySurvivesRestartAndChangesWithCheckout() throws {
        let suite = "PendingCheckoutTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: directory) }
        let payload = Data("order-a".utf8)
        let first = try PendingCheckout(defaults: defaults, directory: directory, synchronize: { true }).key(for: payload, userID: "one", endpoint: "test")
        XCTAssertNotNil(UUID(uuidString: first))
        XCTAssertEqual(PendingCheckout(defaults: defaults, directory: directory, synchronize: { true }).pendingPayload(userID: "one", endpoint: "test")?.payload, payload)
        XCTAssertNil(PendingCheckout(defaults: defaults, directory: directory, synchronize: { true }).pendingPayload(userID: "two", endpoint: "test"))
        XCTAssertEqual(first, try PendingCheckout(defaults: defaults, directory: directory, synchronize: { true }).key(for: payload, userID: "one", endpoint: "test"))
        let changed = try PendingCheckout(defaults: defaults, directory: directory, synchronize: { true }).key(for: Data("order-b".utf8), userID: "one", endpoint: "test")
        XCTAssertNotEqual(first, changed)
        let second = try PendingCheckout(defaults: defaults, directory: directory, synchronize: { true }).key(for: payload, userID: "two", endpoint: "test")
        XCTAssertNotEqual(first, second)
        XCTAssertNotEqual(second, try PendingCheckout(defaults: defaults, directory: directory, synchronize: { true }).key(for: payload, userID: "two", endpoint: "staging"))
        XCTAssertEqual(changed, try PendingCheckout(defaults: defaults, directory: directory, synchronize: { true }).key(for: Data("order-b".utf8), userID: "one", endpoint: "test"))
    }

    func testPaymentIsMarkedOnceAndClearStartsNewCheckout() throws {
        let suite = "PendingCheckoutTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: directory) }
        let payload = Data("order".utf8)
        let checkout = PendingCheckout(defaults: defaults, directory: directory, synchronize: { true })
        let key = try checkout.key(for: payload, userID: "one", endpoint: "test")
        try checkout.rememberOrder(for: key, userID: "one", endpoint: "test", id: "order-id", number: "123")
        XCTAssertEqual(PendingCheckout(defaults: defaults, directory: directory, synchronize: { true }).pendingOrder(userID: "one", endpoint: "test")?.id, "order-id")
        XCTAssertNil(checkout.pendingOrder(userID: "two", endpoint: "test"))
        XCTAssertNil(checkout.pendingOrder(userID: "one", endpoint: "other"))
        XCTAssertFalse(try checkout.markPaymentStarted(for: "other", userID: "one", endpoint: "test"))
        XCTAssertTrue(try checkout.markPaymentStarted(for: key, userID: "one", endpoint: "test"))
        XCTAssertFalse(try PendingCheckout(defaults: defaults, directory: directory, synchronize: { true }).markPaymentStarted(for: key, userID: "one", endpoint: "test"))
        checkout.clear(for: "other", userID: "one", endpoint: "test")
        XCTAssertEqual(key, try checkout.key(for: payload, userID: "one", endpoint: "test"))
        checkout.clear(for: key, userID: "one", endpoint: "test")
        XCTAssertNotEqual(key, try checkout.key(for: payload, userID: "one", endpoint: "test"))
    }
    func testDoesNotStartCheckoutWhenPersistenceFails() throws {
        let suite = "PendingCheckoutTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: directory) }
        let checkout = PendingCheckout(defaults: defaults, directory: directory, synchronize: { false })
        XCTAssertThrowsError(try checkout.key(for: Data("order".utf8), userID: "one", endpoint: "test"))
    }

    func testCorruptStoredPayloadIsNotRecovered() throws {
        let suite = "PendingCheckoutTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: directory) }
        let checkout = PendingCheckout(defaults: defaults, directory: directory, synchronize: { true })
        let key = try checkout.key(for: Data("order".utf8), userID: "one", endpoint: "test")
        try Data("modified".utf8).write(to: directory.appendingPathComponent(key))
        XCTAssertNil(checkout.pendingPayload(userID: "one", endpoint: "test"))
    }

}
