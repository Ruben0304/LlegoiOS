import Foundation

enum OrderPermissionPolicy {
    private static let paymentEnabledStatuses: Set<OrderStatusEnum> = [
        .accepted,
        .modifiedByStore,
    ]

    private static let trackingEnabledStatuses: Set<OrderStatusEnum> = [
        .preparing,
        .readyForPickup,
        .onTheWay,
    ]

    static func canAcceptModifications(status: OrderStatusEnum) -> Bool {
        status == .modifiedByStore
    }

    static func canShowTracking(status: OrderStatusEnum) -> Bool {
        trackingEnabledStatuses.contains(status)
    }

    static func canShowTransferPaymentShortcut(
        status: OrderStatusEnum,
        paymentStatus: PaymentStatusEnum
    ) -> Bool {
        paymentEnabledStatuses.contains(status) && paymentStatus != .completed
    }

    static func canInitiateInAppPayment(
        status: OrderStatusEnum,
        paymentStatus: PaymentStatusEnum,
        paymentMethodType: String?
    ) -> Bool {
        guard paymentEnabledStatuses.contains(status), paymentStatus != .completed else {
            return false
        }

        guard let paymentMethodType else {
            return false
        }

        let normalizedType = paymentMethodType.lowercased()
        return ["wallet", "stripe", "qvapay", "usdt"].contains(normalizedType)
    }
}
