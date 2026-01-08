import Foundation
import Apollo

@MainActor
final class CreateOrderRepository {
    private let apolloClient = ApolloClientManager.shared.apollo
    
    // MARK: - Create Order
    
    func createOrder(
        branchId: String,
        items: [(productId: String, quantity: Int)],
        deliveryAddress: DeliveryAddressInput,
        paymentMethod: String,
        paymentIntentId: String? = nil,
        comments: String? = nil,
        promoCode: String? = nil,
        completion: @escaping @Sendable (Result<CreatedOrder, Error>) -> Void
    ) {
        let client = apolloClient
        
        Task { @MainActor in
            guard let jwt = AuthManager.shared.getAccessToken() else {
                completion(.failure(NSError(domain: "CreateOrderRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "No autenticado"])))
                return
            }
            
            // Build items input
            let itemsInput = items.map { item in
                LlegoAPI.OrderItemInput(productId: item.productId, quantity: Int32(item.quantity))
            }
            
            // Build delivery address input
            let addressInput = LlegoAPI.DeliveryAddressInput(
                street: deliveryAddress.street,
                city: deliveryAddress.city.map { .some($0) } ?? .none,
                reference: deliveryAddress.reference.map { .some($0) } ?? .none,
                latitude: deliveryAddress.latitude,
                longitude: deliveryAddress.longitude
            )
            
            // Build create order input
            let input = LlegoAPI.CreateOrderInput(
                branchId: branchId,
                items: itemsInput,
                deliveryAddress: addressInput,
                paymentMethod: paymentMethod,
                paymentIntentId: paymentIntentId.map { .some($0) } ?? .none,
                comments: comments.map { .some($0) } ?? .none,
                promoCode: promoCode.map { .some($0) } ?? .none
            )
            
            let mutation = LlegoAPI.CreateOrderMutation(input: input, jwt: jwt)
            
            client.perform(mutation: mutation) { [weak self] result in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let graphQLResult):
                        if let errors = graphQLResult.errors {
                            print("❌ GraphQL Errors creating order: \(errors)")
                            let errorMessage = errors.first?.localizedDescription ?? "Error al crear el pedido"
                            completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                            return
                        }
                        
                        guard let order = graphQLResult.data?.createOrder else {
                            completion(.failure(NSError(domain: "CreateOrderRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el pedido"])))
                            return
                        }
                        
                        let createdOrder = self.mapToCreatedOrder(order)
                        completion(.success(createdOrder))
                        
                    case .failure(let error):
                        print("❌ Network error creating order: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    // MARK: - Mapping
    
    private func mapToCreatedOrder(_ order: LlegoAPI.CreateOrderMutation.Data.CreateOrder) -> CreatedOrder {
        let items = order.items.map { item in
            CreatedOrderItem(
                productId: item.productId,
                name: item.name,
                price: item.price,
                quantity: item.quantity,
                imageUrl: item.imageUrl,
                lineTotal: item.lineTotal
            )
        }
        
        let discounts = order.discounts.map { discount in
            CreatedOrderDiscount(
                id: discount.id,
                title: discount.title,
                amount: discount.amount,
                type: mapDiscountType(discount.type)
            )
        }
        
        return CreatedOrder(
            id: order.id,
            orderNumber: order.orderNumber,
            status: mapStatus(order.status),
            subtotal: order.subtotal,
            deliveryFee: order.deliveryFee,
            total: order.total,
            currency: order.currency,
            paymentMethod: order.paymentMethod,
            paymentStatus: mapPaymentStatus(order.paymentStatus),
            createdAt: order.createdAt,
            items: items,
            discounts: discounts,
            branchName: order.branch.name,
            branchImageUrl: order.branch.avatarUrl,
            businessName: order.business.name,
            deliveryStreet: order.deliveryAddress.street,
            deliveryCity: order.deliveryAddress.city,
            deliveryReference: order.deliveryAddress.reference
        )
    }
    
    private func mapStatus(_ status: GraphQLEnum<LlegoAPI.OrderStatusEnum>) -> String {
        switch status {
        case .case(let value): return value.rawValue
        case .unknown: return "PENDING_ACCEPTANCE"
        }
    }
    
    private func mapPaymentStatus(_ status: GraphQLEnum<LlegoAPI.PaymentStatusEnum>) -> String {
        switch status {
        case .case(let value): return value.rawValue
        case .unknown: return "PENDING"
        }
    }
    
    private func mapDiscountType(_ type: GraphQLEnum<LlegoAPI.DiscountTypeEnum>) -> String {
        switch type {
        case .case(let value): return value.rawValue
        case .unknown: return "PROMO"
        }
    }
}

// MARK: - Input Models

struct DeliveryAddressInput {
    let street: String
    let city: String?
    let reference: String?
    let latitude: Double
    let longitude: Double
}

// MARK: - Result Models

struct CreatedOrder {
    let id: String
    let orderNumber: String
    let status: String
    let subtotal: Double
    let deliveryFee: Double
    let total: Double
    let currency: String
    let paymentMethod: String
    let paymentStatus: String
    let createdAt: String
    let items: [CreatedOrderItem]
    let discounts: [CreatedOrderDiscount]
    let branchName: String
    let branchImageUrl: String?
    let businessName: String
    let deliveryStreet: String
    let deliveryCity: String?
    let deliveryReference: String?
    
    var formattedTotal: String {
        String(format: "$%.2f", total)
    }
}

struct CreatedOrderItem {
    let productId: String
    let name: String
    let price: Double
    let quantity: Int
    let imageUrl: String
    let lineTotal: Double
}

struct CreatedOrderDiscount {
    let id: String
    let title: String
    let amount: Double
    let type: String
}
