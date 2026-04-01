import Apollo
import Foundation

enum CashKycEvalStatus: Equatable {
    case notRequired
    case pendingEvidence
    case submitted
    case approved
    case rejected
    case needsReview
    case insufficientData
    case error
    case expired
    case unknown(String)

    init(rawValue: String?) {
        let value = (rawValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch value {
        case "not_required": self = .notRequired
        case "pending_evidence": self = .pendingEvidence
        case "submitted": self = .submitted
        case "approved": self = .approved
        case "rejected": self = .rejected
        case "needs_review": self = .needsReview
        case "insufficient_data": self = .insufficientData
        case "error": self = .error
        case "expired": self = .expired
        default: self = .unknown(value.isEmpty ? "unknown" : value)
        }
    }
}

enum CashCoverageStatus: Equatable {
    case eligibleCovered
    case eligibleUncovered
    case blocked
    case unknown(String)

    init(rawValue: String?) {
        let value = (rawValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch value {
        case "eligible_covered": self = .eligibleCovered
        case "eligible_uncovered": self = .eligibleUncovered
        case "blocked": self = .blocked
        default: self = .unknown(value.isEmpty ? "unknown" : value)
        }
    }
}

struct CashKycDecisionSnapshot: Equatable {
    let allowCash: Bool
    let appCoversCash: Bool
    let kycEvalStatus: CashKycEvalStatus
    let cashCoverageStatus: CashCoverageStatus
    let reasonCodes: [String]
    let expiresAt: Date?
    let nextAction: String?
    let correlationId: String?
    let verificationId: String?
    let backendMessage: String?
    let providerErrorCode: String?
    let providerError: String?
    let evidenceRefs: CashKycEvidenceRefs?
}

struct CashKycEvidenceRefs: Equatable {
    let selfieWithId: String?
    let identityDocumentFront: String?
}

struct CashKycAccountContext: Equatable {
    let merchantId: String
    let branchId: String?
}

class PaymentRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // MARK: - Helpers

    private func mapPaymentAttempt(
        _ data: LlegoAPI.InitiatePaymentMutation.Data.InitiatePayment.PaymentAttempt
    ) -> PaymentAttemptModel {
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

    private func mapConfirmPaymentSent(
        _ data: LlegoAPI.ConfirmPaymentSentMutation.Data.ConfirmPaymentSent
    ) -> PaymentAttemptModel {
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

    private func mapConfirmShortcut(
        _ data: LlegoAPI.ConfirmTransferByShortcutMutation.Data.ConfirmTransferByShortcut
    ) -> PaymentAttemptModel {
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

    private func mapGetPaymentAttempt(_ data: LlegoAPI.GetPaymentAttemptQuery.Data.PaymentAttempt)
        -> PaymentAttemptModel
    {
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
        let mutation = LlegoAPI.InitiatePaymentMutation(
            orderId: orderId,
            paymentMethodId: paymentMethodId,
            jwt: jwt,
            includeDeliveryFee: includeDeliveryFee,
            sendsSmsNotification: sendsSmsNotification
        )

        let graphQLResult = try await apolloClient.perform(mutation: mutation)

        if let errors = graphQLResult.errors {
            print("❌ GraphQL Errors (initiate payment):")
            errors.forEach { print("  - \($0.localizedDescription)") }
            throw NSError(
                domain: "GraphQL",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: errors.first?.localizedDescription
                        ?? "Error al iniciar pago"
                ]
            )
        }

        guard let data = graphQLResult.data?.initiatePayment else {
            print("⚠️ Initiate payment devolvió nil")
            throw NSError(
                domain: "GraphQL",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
            )
        }

        let paymentAttempt = mapPaymentAttempt(data.paymentAttempt)
        print(
            "✅ Payment initiated: \(paymentAttempt.id), sendsSms: \(paymentAttempt.sendsSmsNotification)"
        )
        return InitiatePaymentResultModel(
            paymentAttempt: paymentAttempt, instructions: data.instructions)
    }

    // MARK: - Confirm Payment Sent

    func confirmPaymentSent(
        paymentAttemptId: String,
        proofUrl: String,
        jwt: String
    ) async throws -> PaymentAttemptModel {
        let mutation = LlegoAPI.ConfirmPaymentSentMutation(
            paymentAttemptId: paymentAttemptId,
            proofUrl: proofUrl,
            jwt: jwt
        )

        let graphQLResult = try await apolloClient.perform(mutation: mutation)

        if let errors = graphQLResult.errors {
            print("❌ GraphQL Errors (confirm payment sent):")
            errors.forEach { print("  - \($0.localizedDescription)") }
            throw NSError(
                domain: "GraphQL",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: errors.first?.localizedDescription
                        ?? "Error al confirmar pago"
                ]
            )
        }

        guard let data = graphQLResult.data?.confirmPaymentSent else {
            print("⚠️ Confirm payment sent devolvió nil")
            throw NSError(
                domain: "GraphQL",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
            )
        }

        let paymentAttempt = mapConfirmPaymentSent(data)
        print("✅ Payment confirmed: \(paymentAttempt.id)")
        return paymentAttempt
    }

    // MARK: - Confirm Transfer By Shortcut

    func confirmTransferByShortcut(
        paymentAttemptId: String,
        jwt: String,
        transferId: String? = nil
    ) async throws -> PaymentAttemptModel {
        let mutation = LlegoAPI.ConfirmTransferByShortcutMutation(
            paymentAttemptId: paymentAttemptId,
            jwt: jwt,
            transferId: transferId.map { .some($0) } ?? .none
        )

        let graphQLResult = try await apolloClient.perform(mutation: mutation)

        if let errors = graphQLResult.errors {
            print("❌ GraphQL Errors (confirm transfer by shortcut):")
            errors.forEach { print("  - \($0.localizedDescription)") }
            throw NSError(
                domain: "GraphQL",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: errors.first?.localizedDescription
                        ?? "Transferencia no encontrada aún"
                ]
            )
        }

        guard let data = graphQLResult.data?.confirmTransferByShortcut else {
            print("⚠️ confirmTransferByShortcut devolvió nil")
            throw NSError(
                domain: "GraphQL",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
            )
        }

        let paymentAttempt = mapConfirmShortcut(data)
        print(
            "✅ Transfer confirmed by shortcut: \(paymentAttempt.id), status: \(paymentAttempt.status)"
        )
        return paymentAttempt
    }

    // MARK: - Get Payment Attempt

    func getPaymentAttempt(
        id: String,
        jwt: String
    ) async throws -> PaymentAttemptModel {
        return try await withCheckedThrowingContinuation { [apolloClient] continuation in
            let query = LlegoAPI.GetPaymentAttemptQuery(id: id, jwt: jwt)

            apolloClient.fetchCompat(
                query: query, cachePolicy: .fetchIgnoringCacheData,
                resultHandler: { result in
                    switch result {
                    case .success(let graphQLResult):
                        if let errors = graphQLResult.errors {
                            print("❌ GraphQL Errors (get payment attempt):")
                            errors.forEach { print("  - \($0.localizedDescription)") }
                            continuation.resume(
                                throwing: NSError(
                                    domain: "GraphQL",
                                    code: -1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: errors.first?
                                            .localizedDescription ?? "Error al obtener pago"
                                    ]
                                ))
                            return
                        }

                        guard let data = graphQLResult.data?.paymentAttempt else {
                            print("⚠️ Get payment attempt devolvió nil")
                            continuation.resume(
                                throwing: NSError(
                                    domain: "GraphQL",
                                    code: -2,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            "No se encontró el intento de pago"
                                    ]
                                ))
                            return
                        }

                        let paymentAttempt = PaymentAttemptModel(
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
                        print("✅ Payment attempt fetched: \(paymentAttempt.id)")
                        continuation.resume(returning: paymentAttempt)

                    case .failure(let error):
                        print("❌ Error fetching payment attempt: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                })
        }
    }

    // MARK: - Cash KYC (raw GraphQL, schema-tolerant)

    func cashKycPolicy(orderId: String, jwt: String) async throws -> CashKycDecisionSnapshot {
        let query = """
            query CashKycPolicy($orderId: String!, $jwt: String!) {
              cashKycPolicy(orderId: $orderId, jwt: $jwt) {
                kycRequired
                policyVersion
                minConfidence
                ttlDays
                allowCash: allowCashNow
                appCoversCash: appCoversCashNow
              }
            }
            """
        let data = try await performRawGraphQL(
            query: query, variables: ["orderId": orderId, "jwt": jwt], jwt: jwt)
        guard let node = data["cashKycPolicy"] as? [String: Any] else {
            throw graphQLError("No se recibió política KYC cash")
        }
        return parseCashKycDecision(node)
    }

    func cashKycStatus(paymentAttemptId: String, jwt: String) async throws
        -> CashKycDecisionSnapshot
    {
        let query = """
            query CashKycStatus($paymentAttemptId: String!, $jwt: String!) {
              cashKycStatus(paymentAttemptId: $paymentAttemptId, jwt: $jwt) {
                allowCash
                appCoversCash
                kycEvalStatus
                cashCoverageStatus
                reasonCodes
                expiresAt
                nextAction
                verificationId
                providerErrorCode
                providerError
              }
            }
            """
        let data = try await performRawGraphQL(
            query: query,
            variables: ["paymentAttemptId": paymentAttemptId, "jwt": jwt],
            jwt: jwt
        )
        guard let node = data["cashKycStatus"] as? [String: Any] else {
            throw graphQLError("No se recibió estado KYC cash")
        }
        return parseCashKycDecision(node)
    }

    func startCashKycEvaluation(
        paymentAttemptId: String,
        identityDocumentFrontBase64: String,
        selfieLiveBase64: String,
        deviceContext: [String: Any],
        transactionContext: [String: Any],
        jwt: String
    ) async throws -> CashKycDecisionSnapshot {
        let mutation = """
            mutation StartCashKycEvaluation($input: StartCashKycInput!, $jwt: String!) {
              startCashKycEvaluation(input: $input, jwt: $jwt) {
                verificationId
                allowCash
                appCoversCash
                kycEvalStatus
                cashCoverageStatus
                reasonCodes
                nextAction
                correlationId
                providerErrorCode
                providerError
              }
            }
            """
        let identityDocumentFrontRef = try await uploadKycEvidenceRef(
            jpegBase64: identityDocumentFrontBase64,
            jwt: jwt,
            label: "identity_document_front"
        )
        let selfieLiveRef = try await uploadKycEvidenceRef(
            jpegBase64: selfieLiveBase64,
            jwt: jwt,
            label: "selfie_live"
        )

        let input: [String: Any] = [
            "paymentAttemptId": paymentAttemptId,
            "identityDocumentFrontRef": identityDocumentFrontRef,
            "selfieLiveRef": selfieLiveRef,
            "deviceContext": deviceContext,
        ]
        _ = transactionContext

        let data = try await performRawGraphQL(
            query: mutation,
            variables: ["input": input, "jwt": jwt],
            jwt: jwt
        )
        guard let payload = data["startCashKycEvaluation"] as? [String: Any] else {
            throw graphQLError("No se recibió respuesta al enviar evidencia KYC")
        }
        let startDecision = parseCashKycDecision(payload)
        do {
            return try await cashKycStatus(paymentAttemptId: paymentAttemptId, jwt: jwt)
        } catch {
            return startDecision
        }
    }

    func retryCashKycEvaluation(verificationId: String, jwt: String) async throws
        -> CashKycDecisionSnapshot
    {
        let mutation = """
            mutation RetryCashKycEvaluation($verificationId: String!, $jwt: String!) {
              retryCashKycEvaluation(verificationId: $verificationId, jwt: $jwt) {
                verificationId
                allowCash
                appCoversCash
                kycEvalStatus
                cashCoverageStatus
                nextAction
                providerErrorCode
                providerError
              }
            }
            """
        let data = try await performRawGraphQL(
            query: mutation,
            variables: ["verificationId": verificationId, "jwt": jwt],
            jwt: jwt
        )
        guard let payload = data["retryCashKycEvaluation"] as? [String: Any] else {
            throw graphQLError("No se recibió respuesta de reintento KYC")
        }
        return parseCashKycDecision(payload)
    }

    // MARK: - Cash KYC (account-level by merchant)

    func cashKycPolicyByMerchant(
        merchantId: String,
        branchId: String?,
        jwt: String
    ) async throws -> CashKycDecisionSnapshot {
        let query = """
            query CashKycPolicyByMerchant($merchantId: String!, $branchId: String, $jwt: String!) {
              cashKycPolicyByMerchant(merchantId: $merchantId, branchId: $branchId, jwt: $jwt) {
                kycRequired
                policyVersion
                minConfidence
                ttlDays
                allowCash: allowCashNow
                appCoversCash: appCoversCashNow
              }
            }
            """
        var variables: [String: Any] = ["merchantId": merchantId, "jwt": jwt]
        if let branchId, !branchId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            variables["branchId"] = branchId
        }
        let data = try await performRawGraphQL(query: query, variables: variables, jwt: jwt)
        guard let node = data["cashKycPolicyByMerchant"] as? [String: Any] else {
            throw graphQLError("No se recibió política KYC del comercio")
        }
        return parseCashKycDecision(node)
    }

    func cashKycStatusByAccount(
        merchantId: String,
        branchId: String?,
        jwt: String
    ) async throws -> CashKycDecisionSnapshot {
        let query = """
            query CashKycStatusByAccount($merchantId: String!, $branchId: String, $jwt: String!) {
              cashKycStatusByAccount(merchantId: $merchantId, branchId: $branchId, jwt: $jwt) {
                allowCash
                appCoversCash
                kycEvalStatus
                cashCoverageStatus
                reasonCodes
                expiresAt
                nextAction
                verificationId
                providerErrorCode
                providerError
              }
            }
            """
        var variables: [String: Any] = ["merchantId": merchantId, "jwt": jwt]
        if let branchId, !branchId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            variables["branchId"] = branchId
        }
        let data = try await performRawGraphQL(query: query, variables: variables, jwt: jwt)
        guard let node = data["cashKycStatusByAccount"] as? [String: Any] else {
            throw graphQLError("No se recibió estado KYC de la cuenta")
        }
        return parseCashKycDecision(node)
    }

    func startCashKycEvaluationByAccount(
        merchantId: String,
        branchId: String?,
        identityDocumentFrontBase64: String,
        selfieLiveBase64: String,
        deviceContext: [String: Any],
        transactionContext: [String: Any]?,
        jwt: String
    ) async throws -> CashKycDecisionSnapshot {
        let mutation = """
            mutation StartCashKycEvaluationByAccount($input: StartCashKycByAccountInput!, $jwt: String!) {
              startCashKycEvaluationByAccount(input: $input, jwt: $jwt) {
                verificationId
                allowCash
                appCoversCash
                kycEvalStatus
                cashCoverageStatus
                reasonCodes
                nextAction
                correlationId
                providerErrorCode
                providerError
              }
            }
            """

        let identityDocumentFrontRef = try await uploadKycEvidenceRef(
            jpegBase64: identityDocumentFrontBase64,
            jwt: jwt,
            label: "identity_document_front"
        )
        let selfieLiveRef = try await uploadKycEvidenceRef(
            jpegBase64: selfieLiveBase64,
            jwt: jwt,
            label: "selfie_live"
        )

        var input: [String: Any] = [
            "merchantId": merchantId,
            "identityDocumentFrontRef": identityDocumentFrontRef,
            "selfieLiveRef": selfieLiveRef,
            "deviceContext": deviceContext,
        ]
        if let branchId, !branchId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            input["branchId"] = branchId
        }
        _ = transactionContext

        let data = try await performRawGraphQL(
            query: mutation,
            variables: ["input": input, "jwt": jwt],
            jwt: jwt
        )
        guard let payload = data["startCashKycEvaluationByAccount"] as? [String: Any] else {
            throw graphQLError("No se recibió respuesta al iniciar KYC por cuenta")
        }

        let startDecision = parseCashKycDecision(payload)

        // El payload de inicio puede ser mínimo; consultar estado account-level para datos completos.
        do {
            return try await cashKycStatusByAccount(
                merchantId: merchantId,
                branchId: branchId,
                jwt: jwt
            )
        } catch {
            // Fallback seguro al payload recibido al iniciar, para no perder progreso de UX.
            return startDecision
        }
    }

    // MARK: - Cash KYC (global account-level)

    func globalCashKycStatus(jwt: String) async throws -> CashKycDecisionSnapshot {
        let query = """
            query GlobalCashKycStatus($jwt: String!) {
              globalCashKycStatus(jwt: $jwt) {
                verificationId
                kycEvalStatus
                cashCoverageStatus
                allowCash
                appCoversCash
                reasonCodes
                nextAction
                expiresAt
                providerErrorCode
                providerError
              }
            }
            """
        let data = try await performRawGraphQL(
            query: query,
            variables: ["jwt": jwt],
            jwt: jwt
        )
        guard let node = data["globalCashKycStatus"] as? [String: Any] else {
            throw graphQLError("No se recibió estado global KYC")
        }
        return parseCashKycDecision(node)
    }

    func startGlobalCashKycEvaluation(
        identityDocumentFrontBase64: String,
        selfieWithIdBase64: String,
        deviceContext: [String: Any],
        jwt: String
    ) async throws -> CashKycDecisionSnapshot {
        do {
            return try await startGlobalCashKycEvaluationREST(
                identityDocumentFrontBase64: identityDocumentFrontBase64,
                selfieWithIdBase64: selfieWithIdBase64,
                deviceContext: deviceContext,
                jwt: jwt
            )
        } catch let error as NSError
            where error.domain == "GlobalCashKycREST"
            && (error.code == 404 || error.code == 405)
        {
            // Compatibilidad: si el endpoint REST global no existe en el backend activo, usar GraphQL.
            return try await startGlobalCashKycEvaluationGraphQL(
                identityDocumentFrontBase64: identityDocumentFrontBase64,
                selfieWithIdBase64: selfieWithIdBase64,
                deviceContext: deviceContext,
                jwt: jwt
            )
        }
    }

    private func startGlobalCashKycEvaluationREST(
        identityDocumentFrontBase64: String,
        selfieWithIdBase64: String,
        deviceContext: [String: Any],
        jwt: String
    ) async throws -> CashKycDecisionSnapshot {
        guard let identityDocumentData = Data(base64Encoded: identityDocumentFrontBase64),
            let selfieWithIdData = Data(base64Encoded: selfieWithIdBase64)
        else {
            throw graphQLError("No se pudo procesar la evidencia para KYC global")
        }

        guard let url = URL(string: "\(ApolloClientManager.baseURL)/kyc/global/evaluate") else {
            throw graphQLError("Endpoint global KYC inválido")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()
        appendMultipartImage(
            to: &body,
            boundary: boundary,
            fieldName: "identity_document_front",
            filename: "identity_document_front.jpg",
            imageData: identityDocumentData
        )
        appendMultipartImage(
            to: &body,
            boundary: boundary,
            fieldName: "selfie_with_id",
            filename: "selfie_with_id.jpg",
            imageData: selfieWithIdData
        )

        appendMultipartField(
            to: &body, boundary: boundary, name: "device_id_hash",
            value: string(from: deviceContext, keys: ["deviceIdHash", "device_id_hash"]) ?? "")
        appendMultipartField(
            to: &body, boundary: boundary, name: "ip_hash",
            value: string(from: deviceContext, keys: ["ipHash", "ip_hash"]) ?? "")
        appendMultipartField(
            to: &body, boundary: boundary, name: "app_version",
            value: string(from: deviceContext, keys: ["appVersion", "app_version"]) ?? "")
        appendMultipartField(
            to: &body, boundary: boundary, name: "os",
            value: string(from: deviceContext, keys: ["os"]) ?? "")

        if let latitude = number(from: deviceContext, keys: ["latitude"]) {
            appendMultipartField(
                to: &body, boundary: boundary, name: "latitude", value: String(latitude))
        }
        if let longitude = number(from: deviceContext, keys: ["longitude"]) {
            appendMultipartField(
                to: &body, boundary: boundary, name: "longitude", value: String(longitude))
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "GlobalCashKycREST",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Respuesta inválida del servidor"]
            )
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = extractErrorMessage(from: data)
            throw NSError(
                domain: "GlobalCashKycREST",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(
                domain: "GlobalCashKycREST",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Respuesta inválida del endpoint KYC global"]
            )
        }

        return parseCashKycDecision(json)
    }

    private func startGlobalCashKycEvaluationGraphQL(
        identityDocumentFrontBase64: String,
        selfieWithIdBase64: String,
        deviceContext: [String: Any],
        jwt: String
    ) async throws -> CashKycDecisionSnapshot {
        let mutation = """
            mutation StartGlobalCashKycEvaluation($input: StartGlobalCashKycInput!, $jwt: String!) {
              startGlobalCashKycEvaluation(input: $input, jwt: $jwt) {
                verificationId
                allowCash
                appCoversCash
                kycEvalStatus
                cashCoverageStatus
                reasonCodes
                nextAction
                correlationId
                providerErrorCode
                providerError
              }
            }
            """

        let identityDocumentFrontRef = try await uploadKycEvidenceRef(
            jpegBase64: identityDocumentFrontBase64,
            jwt: jwt,
            label: "global_identity_document_front"
        )
        let selfieWithIdRef = try await uploadKycEvidenceRef(
            jpegBase64: selfieWithIdBase64,
            jwt: jwt,
            label: "global_selfie_with_id"
        )

        let input: [String: Any] = [
            "identityDocumentFrontRef": identityDocumentFrontRef,
            "selfieWithIdRef": selfieWithIdRef,
            "deviceContext": deviceContext,
        ]

        let data = try await performRawGraphQL(
            query: mutation,
            variables: ["input": input, "jwt": jwt],
            jwt: jwt
        )
        guard let payload = data["startGlobalCashKycEvaluation"] as? [String: Any] else {
            throw graphQLError("No se recibió respuesta al iniciar KYC global")
        }

        let startDecision = parseCashKycDecision(payload)
        do {
            return try await globalCashKycStatus(jwt: jwt)
        } catch {
            return startDecision
        }
    }

    private func performRawGraphQL(
        query: String,
        variables: [String: Any],
        jwt: String
    ) async throws -> [String: Any] {
        guard let url = URL(string: "\(ApolloClientManager.baseURL)/graphql") else {
            throw graphQLError("Endpoint GraphQL inválido")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "query": query,
            "variables": variables,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw graphQLError("Respuesta inválida del servidor")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw graphQLError("Error HTTP \(httpResponse.statusCode)")
        }

        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw graphQLError("No se pudo decodificar respuesta GraphQL")
        }

        if let errors = root["errors"] as? [[String: Any]],
            let firstMessage = errors.first?["message"] as? String
        {
            throw graphQLError(firstMessage)
        }

        guard let payloadData = root["data"] as? [String: Any] else {
            throw graphQLError("Respuesta GraphQL sin campo data")
        }

        return payloadData
    }

    private func uploadKycEvidenceRef(jpegBase64: String, jwt: String, label: String) async throws
        -> String
    {
        guard let imageData = Data(base64Encoded: jpegBase64) else {
            throw graphQLError("No se pudo procesar la evidencia de \(label)")
        }
        return try await uploadKycEvidenceRef(imageData: imageData, jwt: jwt, label: label)
    }

    private func uploadKycEvidenceRef(imageData: Data, jwt: String, label: String) async throws
        -> String
    {
        guard let url = URL(string: "\(ApolloClientManager.baseURL)/upload/user/avatar") else {
            throw graphQLError("Endpoint de upload inválido")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"image\"; filename=\"\(label).jpg\"\r\n".data(
                using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw graphQLError("Respuesta inválida al subir evidencia")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Error de upload"
            throw graphQLError("No se pudo subir evidencia: \(message)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw graphQLError("Respuesta inválida del upload de evidencia")
        }

        if let imagePath = json["image_path"] as? String, !imagePath.isEmpty {
            return imagePath
        }
        if let imagePath = json["imagePath"] as? String, !imagePath.isEmpty {
            return imagePath
        }

        throw graphQLError("El upload de evidencia no devolvió referencia válida")
    }

    private func appendMultipartField(
        to data: inout Data,
        boundary: String,
        name: String,
        value: String
    ) {
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(value)\r\n".data(using: .utf8)!)
    }

    private func appendMultipartImage(
        to data: inout Data,
        boundary: String,
        fieldName: String,
        filename: String,
        imageData: Data
    ) {
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append(
            "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n"
                .data(using: .utf8)!)
        data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        data.append(imageData)
        data.append("\r\n".data(using: .utf8)!)
    }

    private func parseCashKycDecision(_ node: [String: Any]) -> CashKycDecisionSnapshot {
        let allowCash = bool(from: node, keys: ["allowCash", "allow_cash", "allowCashNow"])
        let appCoversCash = bool(
            from: node,
            keys: ["appCoversCash", "app_covers_cash", "appCoversCashNow"])

        let evalStatusRaw = string(from: node, keys: ["kycEvalStatus", "kyc_eval_status"])
        let coverageRaw = string(from: node, keys: ["cashCoverageStatus", "cash_coverage_status"])
        let kycRequired = bool(from: node, keys: ["kycRequired", "kyc_required"])

        let evalStatus = CashKycEvalStatus(rawValue: evalStatusRaw)
        let coverageStatus = CashCoverageStatus(rawValue: coverageRaw)

        let resolvedAllowCash: Bool
        if let allowCash {
            resolvedAllowCash = allowCash
        } else if coverageRaw != nil {
            resolvedAllowCash = coverageStatus != .blocked
        } else if let kycRequired {
            resolvedAllowCash = !kycRequired
        } else {
            resolvedAllowCash = false
        }

        let resolvedAppCoversCash: Bool
        if let appCoversCash {
            resolvedAppCoversCash = appCoversCash
        } else if coverageRaw != nil {
            resolvedAppCoversCash = coverageStatus == .eligibleCovered
        } else {
            resolvedAppCoversCash = false
        }

        let reasonCodes =
            (node["reasonCodes"] as? [String])
            ?? (node["reason_codes"] as? [String])
            ?? []

        return CashKycDecisionSnapshot(
            allowCash: resolvedAllowCash,
            appCoversCash: resolvedAppCoversCash,
            kycEvalStatus: evalStatus,
            cashCoverageStatus: coverageStatus,
            reasonCodes: reasonCodes,
            expiresAt: parseDate(from: node, keys: ["expiresAt", "expires_at"]),
            nextAction: string(from: node, keys: ["nextAction", "next_action"]),
            correlationId: string(from: node, keys: ["correlationId", "correlation_id"]),
            verificationId: string(from: node, keys: ["verificationId", "verification_id", "id"]),
            backendMessage: string(from: node, keys: ["message"]),
            providerErrorCode: string(from: node, keys: ["providerErrorCode", "provider_error_code"]),
            providerError: string(from: node, keys: ["providerError", "provider_error"]),
            evidenceRefs: parseEvidenceRefs(from: node)
        )
    }

    private func parseEvidenceRefs(from node: [String: Any]) -> CashKycEvidenceRefs? {
        guard let refs = node["evidenceRefs"] as? [String: Any] ?? node["evidence_refs"] as? [String: Any]
        else {
            return nil
        }

        return CashKycEvidenceRefs(
            selfieWithId: string(from: refs, keys: ["selfie_with_id", "selfieWithId"]),
            identityDocumentFront: string(
                from: refs,
                keys: ["identity_document_front", "identityDocumentFront"]
            )
        )
    }

    private func parseDate(from node: [String: Any], keys: [String]) -> Date? {
        guard let value = string(from: node, keys: keys) else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    private func string(from node: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = node[key] as? String {
                return value
            }
        }
        return nil
    }

    private func bool(from node: [String: Any], keys: [String]) -> Bool? {
        for key in keys {
            if let value = node[key] as? Bool {
                return value
            }
        }
        return nil
    }

    private func number(from node: [String: Any], keys: [String]) -> Double? {
        for key in keys {
            if let value = node[key] as? Double { return value }
            if let value = node[key] as? Int { return Double(value) }
            if let value = node[key] as? NSNumber { return value.doubleValue }
            if let value = node[key] as? String, let parsed = Double(value) { return parsed }
        }
        return nil
    }

    private func extractErrorMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let providerError = json["providerError"] as? String, !providerError.isEmpty {
                return providerError
            }
            if let providerError = json["provider_error"] as? String, !providerError.isEmpty {
                return providerError
            }
            if let detail = json["detail"] as? String, !detail.isEmpty { return detail }
            if let message = json["message"] as? String, !message.isEmpty { return message }
            if let errors = json["errors"] as? [[String: Any]],
                let first = errors.first?["message"] as? String, !first.isEmpty
            {
                return first
            }
        }
        return String(data: data, encoding: .utf8) ?? "Error de verificación"
    }

    private func graphQLError(_ message: String) -> NSError {
        NSError(
            domain: "GraphQL",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
