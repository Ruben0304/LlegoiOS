import Foundation
import Apollo

struct QvaPayPaymentResult {
    let paymentUrl: String
    let transactionUuid: String
    let amount: Double
    let orderId: String
}

@MainActor
class QvaPayRepository {
    private let apolloClient = ApolloClientManager.shared.apollo
    private let authManager = AuthManager.shared
    
    func initiateQvapayPayment(orderId: String) async throws -> QvaPayPaymentResult {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                guard let jwt = authManager.getAccessToken() else {
                    continuation.resume(throwing: NSError(
                        domain: "QvaPayRepository",
                        code: 401,
                        userInfo: [NSLocalizedDescriptionKey: "No autenticado"]
                    ))
                    return
                }
                
                let mutation = LlegoAPI.InitiateQvapayPaymentMutation(
                    orderId: orderId,
                    jwt: jwt
                )
                
                apolloClient.performCompat(mutation: mutation) { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let graphQLResult):
                            if let errors = graphQLResult.errors {
                                print("❌ GraphQL Errors (initiate QvaPay):")
                                errors.forEach { print("  - \($0.localizedDescription)") }
                                continuation.resume(throwing: NSError(
                                    domain: "GraphQL",
                                    code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error desconocido"]
                                ))
                                return
                            }
                            
                            guard let data = graphQLResult.data?.initiateQvapayPayment else {
                                print("⚠️ initiateQvapayPayment devolvió nil")
                                continuation.resume(throwing: NSError(
                                    domain: "GraphQL",
                                    code: -2,
                                    userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                                ))
                                return
                            }
                            
                            let result = QvaPayPaymentResult(
                                paymentUrl: data.paymentUrl,
                                transactionUuid: data.transactionUuid,
                                amount: data.amount,
                                orderId: data.orderId
                            )
                            
                            print("✅ QvaPay payment initiated: \(result.paymentUrl)")
                            continuation.resume(returning: result)
                            
                        case .failure(let error):
                            print("❌ Error initiating QvaPay payment: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
}
