import Foundation
import Apollo

struct TronDealerPaymentResult {
    let address: String
    let expectedAmount: Double
    let network: String
    let token: String
    let orderId: String
}

@MainActor
class TronDealerRepository {
    private let apolloClient = ApolloClientManager.shared.apollo
    private let authManager = AuthManager.shared
    
    func initiateTrondealerPayment(orderId: String) async throws -> TronDealerPaymentResult {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                guard let jwt = authManager.getAccessToken() else {
                    continuation.resume(throwing: NSError(
                        domain: "TronDealerRepository",
                        code: 401,
                        userInfo: [NSLocalizedDescriptionKey: "No autenticado"]
                    ))
                    return
                }
                
                let mutation = LlegoAPI.InitiateTrondealerPaymentMutation(
                    orderId: orderId,
                    jwt: jwt
                )
                
                apolloClient.performCompat(mutation: mutation) { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let graphQLResult):
                            if let errors = graphQLResult.errors {
                                print("❌ GraphQL Errors (initiate TronDealer):")
                                errors.forEach { print("  - \($0.localizedDescription)") }
                                continuation.resume(throwing: NSError(
                                    domain: "GraphQL",
                                    code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error desconocido"]
                                ))
                                return
                            }
                            
                            guard let data = graphQLResult.data?.initiateTrondealerPayment else {
                                print("⚠️ initiateTrondealerPayment devolvió nil")
                                continuation.resume(throwing: NSError(
                                    domain: "GraphQL",
                                    code: -2,
                                    userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                                ))
                                return
                            }
                            
                            let result = TronDealerPaymentResult(
                                address: data.address,
                                expectedAmount: data.expectedAmount,
                                network: data.network ?? "TRON",
                                token: data.token,
                                orderId: data.orderId
                            )
                            
                            print("✅ TronDealer payment initiated: \(result.address)")
                            continuation.resume(returning: result)
                            
                        case .failure(let error):
                            print("❌ Error initiating TronDealer payment: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
}
