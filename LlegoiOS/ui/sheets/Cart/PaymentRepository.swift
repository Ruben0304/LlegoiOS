import Foundation
import Apollo

class PaymentRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // MARK: - Helpers

    private func mapPaymentAttempt(_ data: LlegoAPI.InitiatePaymentMutation.Data.InitiatePayment.PaymentAttempt) -> PaymentAttemptModel {
        PaymentAttemptModel(
            id: data.id,
            orderId: data.orderId,
            paymentMethodId: data.paymentMethodId,
            subtotal: data.subtotal,
            deliveryFee: data.deliveryFee,
            includesDeliveryFee: data.includesDeliveryFee,
            taxAmount: data.taxAmount,
            discountAmount: data.discountAmount,
            commissionAmount: data.commissionAmount,
            totalAmount: data.totalAmount,
            currency: data.currency,
            status: data.status.rawValue,
            stripePaymentIntentId: data.stripePaymentIntentId,
            stripeClientSecret: data.stripeClientSecret,
            sendsSmsNotification: data.sendsSmsNotification,
            proofUrl: data.proofUrl,
            customerConfirmedAt: data.customerConfirmedAt,
            businessConfirmedAt: data.businessConfirmedAt
        )
    }

    private func mapConfirmPaymentSent(_ data: LlegoAPI.ConfirmPaymentSentMutation.Data.ConfirmPaymentSent) -> PaymentAttemptModel {
        PaymentAttemptModel(
            id: data.id,
            orderId: data.orderId,
            paymentMethodId: data.paymentMethodId,
            subtotal: data.subtotal,
            deliveryFee: data.deliveryFee,
            includesDeliveryFee: data.includesDeliveryFee,
            taxAmount: data.taxAmount,
            discountAmount: data.discountAmount,
            commissionAmount: data.commissionAmount,
            totalAmount: data.totalAmount,
            currency: data.currency,
            status: data.status.rawValue,
            stripePaymentIntentId: nil,
            stripeClientSecret: nil,
            sendsSmsNotification: data.sendsSmsNotification,
            proofUrl: data.proofUrl,
            customerConfirmedAt: data.customerConfirmedAt,
            businessConfirmedAt: data.businessConfirmedAt
        )
    }

    private func mapConfirmShortcut(_ data: LlegoAPI.ConfirmTransferByShortcutMutation.Data.ConfirmTransferByShortcut) -> PaymentAttemptModel {
        PaymentAttemptModel(
            id: data.id,
            orderId: data.orderId,
            paymentMethodId: data.paymentMethodId,
            subtotal: data.subtotal,
            deliveryFee: data.deliveryFee,
            includesDeliveryFee: data.includesDeliveryFee,
            taxAmount: data.taxAmount,
            discountAmount: data.discountAmount,
            commissionAmount: data.commissionAmount,
            totalAmount: data.totalAmount,
            currency: data.currency,
            status: data.status.rawValue,
            stripePaymentIntentId: nil,
            stripeClientSecret: nil,
            sendsSmsNotification: data.sendsSmsNotification,
            proofUrl: data.proofUrl,
            customerConfirmedAt: data.customerConfirmedAt,
            businessConfirmedAt: data.businessConfirmedAt
        )
    }

    private func mapGetPaymentAttempt(_ data: LlegoAPI.GetPaymentAttemptQuery.Data.PaymentAttempt) -> PaymentAttemptModel {
        PaymentAttemptModel(
            id: data.id,
            orderId: data.orderId,
            paymentMethodId: data.paymentMethodId,
            subtotal: data.subtotal,
            deliveryFee: data.deliveryFee,
            includesDeliveryFee: data.includesDeliveryFee,
            taxAmount: data.taxAmount,
            discountAmount: data.discountAmount,
            commissionAmount: data.commissionAmount,
            totalAmount: data.totalAmount,
            currency: data.currency,
            status: data.status.rawValue,
            stripePaymentIntentId: data.stripePaymentIntentId,
            stripeClientSecret: data.stripeClientSecret,
            sendsSmsNotification: data.sendsSmsNotification,
            proofUrl: data.proofUrl,
            customerConfirmedAt: data.customerConfirmedAt,
            businessConfirmedAt: data.businessConfirmedAt
        )
    }

    // MARK: - Initiate Payment

    func initiatePayment(
        orderId: String,
        paymentMethodId: String,
        jwt: String,
        includeDeliveryFee: Bool = true,
        sendsSmsNotification: Bool = false
    ) async throws -> InitiatePaymentResultModel {
        return try await withCheckedThrowingContinuation { continuation in
            let mutation = LlegoAPI.InitiatePaymentMutation(
                orderId: orderId,
                paymentMethodId: paymentMethodId,
                jwt: jwt,
                includeDeliveryFee: includeDeliveryFee,
                sendsSmsNotification: sendsSmsNotification
            )

            apolloClient.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (initiate payment):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error al iniciar pago"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.initiatePayment else {
                        print("⚠️ Initiate payment devolvió nil")
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                        ))
                        return
                    }

                    let paymentAttempt = self.mapPaymentAttempt(data.paymentAttempt)
                    let result = InitiatePaymentResultModel(
                        paymentAttempt: paymentAttempt,
                        instructions: data.instructions
                    )

                    print("✅ Payment initiated: \(paymentAttempt.id), sendsSms: \(paymentAttempt.sendsSmsNotification)")
                    continuation.resume(returning: result)

                case .failure(let error):
                    print("❌ Error initiating payment: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Confirm Payment Sent

    func confirmPaymentSent(
        paymentAttemptId: String,
        proofUrl: String,
        jwt: String
    ) async throws -> PaymentAttemptModel {
        return try await withCheckedThrowingContinuation { continuation in
            let mutation = LlegoAPI.ConfirmPaymentSentMutation(
                paymentAttemptId: paymentAttemptId,
                proofUrl: proofUrl,
                jwt: jwt
            )

            apolloClient.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (confirm payment sent):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error al confirmar pago"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.confirmPaymentSent else {
                        print("⚠️ Confirm payment sent devolvió nil")
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                        ))
                        return
                    }

                    let paymentAttempt = self.mapConfirmPaymentSent(data)
                    print("✅ Payment confirmed: \(paymentAttempt.id)")
                    continuation.resume(returning: paymentAttempt)

                case .failure(let error):
                    print("❌ Error confirming payment: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Confirm Transfer By Shortcut

    func confirmTransferByShortcut(
        paymentAttemptId: String,
        jwt: String,
        transferId: String? = nil
    ) async throws -> PaymentAttemptModel {
        return try await withCheckedThrowingContinuation { continuation in
            let mutation = LlegoAPI.ConfirmTransferByShortcutMutation(
                paymentAttemptId: paymentAttemptId,
                jwt: jwt,
                transferId: transferId.map { .some($0) } ?? .none
            )

            apolloClient.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (confirm transfer by shortcut):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Transferencia no encontrada aún"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.confirmTransferByShortcut else {
                        print("⚠️ confirmTransferByShortcut devolvió nil")
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                        ))
                        return
                    }

                    let paymentAttempt = self.mapConfirmShortcut(data)
                    print("✅ Transfer confirmed by shortcut: \(paymentAttempt.id), status: \(paymentAttempt.status)")
                    continuation.resume(returning: paymentAttempt)

                case .failure(let error):
                    print("❌ Error confirming transfer by shortcut: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Get Payment Attempt

    func getPaymentAttempt(
        id: String,
        jwt: String
    ) async throws -> PaymentAttemptModel {
        return try await withCheckedThrowingContinuation { continuation in
            let query = LlegoAPI.GetPaymentAttemptQuery(id: id, jwt: jwt)

            apolloClient.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (get payment attempt):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error al obtener pago"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.paymentAttempt else {
                        print("⚠️ Get payment attempt devolvió nil")
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No se encontró el intento de pago"]
                        ))
                        return
                    }

                    let paymentAttempt = self.mapGetPaymentAttempt(data)
                    print("✅ Payment attempt fetched: \(paymentAttempt.id)")
                    continuation.resume(returning: paymentAttempt)

                case .failure(let error):
                    print("❌ Error fetching payment attempt: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
