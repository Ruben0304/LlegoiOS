import Foundation

enum OrderPermissionPolicy {
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
        // Con la transferencia ya enviada el plazo es del negocio para confirmarla,
        // y al vencer el pedido no se cancela: mostrarlo solo asusta al cliente.
        if status == .paymentInProgress { return false }
        return slaDeadlineStatuses.contains(status.normalizedForContract)
    }

    /// Pedido esperando que el cliente pague. Excluye PAYMENT_IN_PROGRESS: el cliente
    /// ya avisó que pagó y ofrecerle pagar otra vez provoca transferencias dobles.
    static func isAwaitingCustomerPayment(
        status: OrderStatusEnum,
        paymentStatus: PaymentStatusEnum
    ) -> Bool {
        status == .pendingPayment && (paymentStatus == .pending || paymentStatus == .failed)
    }

    static func canInitiateInAppPayment(
        status: OrderStatusEnum,
        paymentStatus: PaymentStatusEnum,
        paymentMethodType: String?
    ) -> Bool {
        guard isAwaitingCustomerPayment(status: status, paymentStatus: paymentStatus),
            let paymentMethodType
        else {
            return false
        }

        let normalizedType = paymentMethodType.lowercased()
        return ["wallet", "stripe", "qvapay", "usdt", "transfer", "transfermovil"].contains(normalizedType)
    }
}
