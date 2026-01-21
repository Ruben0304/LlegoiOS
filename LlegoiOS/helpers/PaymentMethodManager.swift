import Foundation
import Apollo
import Combine

// MARK: - Payment Method Model
struct PaymentMethodModel: Identifiable, Sendable {
    let id: String
    let name: String
    let code: String
    let currency: String
    let method: String
    let commissionPercent: Double
    let deliveryFeePercent: Double
    let isRefundable: Bool
    let requiresProof: Bool
    let requiresBusinessConfirmation: Bool
    let expirationMinutes: Int?
    let isActive: Bool
    let displayOrder: Int
    let iconUrl: String?
    let instructions: String?
}

// MARK: - Payment Attempt Model
struct PaymentAttemptModel: Identifiable, Sendable {
    let id: String
    let orderId: String
    let paymentMethodId: String
    let subtotal: Double
    let deliveryFee: Double
    let includesDeliveryFee: Bool
    let taxAmount: Double
    let discountAmount: Double
    let commissionAmount: Double
    let totalAmount: Double
    let currency: String
    let status: String
    let stripePaymentIntentId: String?
    let stripeClientSecret: String?
    let proofUrl: String?
    let customerConfirmedAt: String?
    let businessConfirmedAt: String?
}

// MARK: - Initiate Payment Result
struct InitiatePaymentResultModel: Sendable {
    let paymentAttempt: PaymentAttemptModel
    let instructions: String?
}

@MainActor
class PaymentMethodManager: ObservableObject {
    static let shared = PaymentMethodManager()
    
    @Published var paymentMethods: [PaymentMethodModel] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let apolloClient = ApolloClientManager.shared.apollo
    private let authManager = AuthManager.shared
    
    private init() {}
    
    // MARK: - Fetch Payment Methods
    func fetchPaymentMethods() async throws -> [PaymentMethodModel] {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let jwt = authManager.getAccessToken()
                
                let query = LlegoAPI.GetPaymentMethodsQuery(jwt: jwt.map { .some($0) } ?? .none)
                
                apolloClient.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                    switch result {
                    case .success(let graphQLResult):
                        if let errors = graphQLResult.errors {
                            print("❌ GraphQL Errors (payment methods):")
                            errors.forEach { print("  - \($0.localizedDescription)") }
                            continuation.resume(throwing: NSError(
                                domain: "GraphQL",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error desconocido"]
                            ))
                            return
                        }
                        
                        guard let data = graphQLResult.data?.paymentMethods else {
                            print("⚠️ Payment methods devolvió nil")
                            continuation.resume(throwing: NSError(
                                domain: "GraphQL",
                                code: -2,
                                userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                            ))
                            return
                        }
                        
                        let methods = data.map { pm in
                            PaymentMethodModel(
                                id: pm.id,
                                name: pm.name,
                                code: pm.code,
                                currency: pm.currency,
                                method: pm.method,
                                commissionPercent: pm.commissionPercent,
                                deliveryFeePercent: pm.deliveryFeePercent,
                                isRefundable: pm.isRefundable,
                                requiresProof: pm.requiresProof,
                                requiresBusinessConfirmation: pm.requiresBusinessConfirmation,
                                expirationMinutes: pm.expirationMinutes,
                                isActive: pm.isActive,
                                displayOrder: pm.displayOrder,
                                iconUrl: pm.iconUrl,
                                instructions: pm.instructions
                            )
                        }
                        
                        print("✅ Fetched \(methods.count) payment methods")
                        continuation.resume(returning: methods)
                        
                    case .failure(let error):
                        print("❌ Error fetching payment methods: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    // MARK: - Load Payment Methods (with state management)
    func loadPaymentMethods() {
        Task {
            isLoading = true
            error = nil
            
            do {
                let methods = try await fetchPaymentMethods()
                await MainActor.run {
                    self.paymentMethods = methods.filter { $0.isActive }.sorted { $0.displayOrder < $1.displayOrder }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Filter Methods
    func methodsByCurrency(_ currency: String) -> [PaymentMethodModel] {
        paymentMethods.filter { $0.currency.uppercased() == currency.uppercased() }
    }
    
    func methodsByType(_ method: String) -> [PaymentMethodModel] {
        paymentMethods.filter { $0.method == method }
    }
}
