import Foundation

enum OrderPermissionPolicy {
    private static let paymentEnabledStatuses: Set<OrderStatusEnum> = [
        .pendingPayment
    ]

    private static let trackingEnabledStatuses: Set<OrderStatusEnum> = [
        .preparing,
        .readyForPickup,
        .onTheWay,
    ]



    private static let slaDeadlineStatuses: Set<OrderStatusEnum> = [
        .pendingAcceptance,
        .modifiedByStore,
        .rejectedByStore,
        .awaitingDeliveryAcceptance,
        .pendingPayment,
    ]

    static func canAcceptModifications(status: OrderStatusEnum) -> Bool {
        status.normalizedForContract == .modifiedByStore
    }

    static func canShowTracking(status: OrderStatusEnum) -> Bool {
        trackingEnabledStatuses.contains(status.normalizedForContract)
    }



    static func shouldShowDeadline(status: OrderStatusEnum) -> Bool {
        slaDeadlineStatuses.contains(status.normalizedForContract)
    }

    static func isTimedOutCancellation(status: OrderStatusEnum, deadlineAt: Date?) -> Bool {
        guard status.normalizedForContract == .cancelled, let deadlineAt else {
            return false
        }
        return deadlineAt <= Date()
    }

    static func canShowTransferPaymentShortcut(
        status: OrderStatusEnum,
        paymentStatus: PaymentStatusEnum
    ) -> Bool {
        paymentEnabledStatuses.contains(status.normalizedForContract) && paymentStatus != .completed
    }

    static func canInitiateInAppPayment(
        status: OrderStatusEnum,
        paymentStatus: PaymentStatusEnum,
        paymentMethodType: String?
    ) -> Bool {
        guard paymentEnabledStatuses.contains(status.normalizedForContract),
            paymentStatus == .pending || paymentStatus == .failed
        else {
            return false
        }

        guard let paymentMethodType else {
            return false
        }

        let normalizedType = paymentMethodType.lowercased()
        return ["wallet", "stripe", "qvapay", "usdt", "transfer", "transfermovil"].contains(normalizedType)
    }
}
