import Foundation
import XCTest
@testable import LlegoiOS

final class OrderPermissionPolicyTests: XCTestCase {
    func testInAppPaymentOnlyForTransferAndUsdt() {
        for type in ["transfer", "transfermovil", "usdt"] {
            XCTAssertTrue(
                OrderPermissionPolicy.canInitiateInAppPayment(
                    status: .pendingPayment, paymentStatus: .pending, paymentMethodType: type),
                type)
        }
    }

    func testRemovedMethodsCannotBePaidInApp() {
        for type in ["wallet", "stripe", "qvapay", "cash"] {
            XCTAssertFalse(
                OrderPermissionPolicy.canInitiateInAppPayment(
                    status: .pendingPayment, paymentStatus: .pending, paymentMethodType: type),
                type)
        }
    }
}
