import Foundation
import Apollo

@MainActor
final class CreateOrderRepository {
    private let apolloClient = ApolloClientManager.shared.apollo
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    
    // MARK: - Create Order
    
    func createOrder(
        branchId: String,
        items: [OrderRequestItem],
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

            let hasShowcaseItems = items.contains { $0.itemType == .showcase }
            if hasShowcaseItems {
                createMixedOrder(
                    branchId: branchId,
                    items: items,
                    deliveryAddress: deliveryAddress,
                    paymentMethod: paymentMethod,
                    paymentIntentId: paymentIntentId,
                    comments: comments,
                    promoCode: promoCode,
                    jwt: jwt,
                    completion: completion
                )
                return
            }
            
            // Build items input
            let itemsInput = items.compactMap { item -> LlegoAPI.OrderItemInput? in
                guard let productId = item.productId else { return nil }
                return LlegoAPI.OrderItemInput(quantity: Int32(item.quantity), productId: .some(productId))
            }
            
            // Build delivery address input
            let addressInput = LlegoAPI.DeliveryAddressInput(
                street: deliveryAddress.street,
                latitude: deliveryAddress.latitude,
                longitude: deliveryAddress.longitude,
                city: deliveryAddress.city.map { .some($0) } ?? .none,
                reference: deliveryAddress.reference.map { .some($0) } ?? .none,
                addressType: deliveryAddress.addressType.flatMap { LlegoAPI.AddressTypeInput(rawValue: $0) }.map { .some(GraphQLEnum($0)) } ?? .none,
                buildingName: deliveryAddress.buildingName.map { .some($0) } ?? .none,
                floor: deliveryAddress.floor.map { .some($0) } ?? .none,
                apartment: deliveryAddress.apartment.map { .some($0) } ?? .none,
                deliveryInstructions: deliveryAddress.deliveryInstructions.map { .some($0) } ?? .none
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
            
            client.performCompat(mutation: mutation) { [weak self] result in
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
    
    private func createMixedOrder(
        branchId: String,
        items: [OrderRequestItem],
        deliveryAddress: DeliveryAddressInput,
        paymentMethod: String,
        paymentIntentId: String?,
        comments: String?,
        promoCode: String?,
        jwt: String,
        completion: @escaping @Sendable (Result<CreatedOrder, Error>) -> Void
    ) {
        guard let endpointURL = URL(string: "\(ApolloClientManager.baseURL)/graphql") else {
            completion(.failure(NSError(
                domain: "CreateOrderRepository",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Endpoint GraphQL inválido"]
            )))
            return
        }

        let mutation = """
            mutation CreateOrder($input: CreateOrderInput!, $jwt: String!) {
              createOrder(input: $input, jwt: $jwt) {
                id
                orderNumber
                status
                subtotal
                deliveryFee
                total
                currency
                paymentMethod
                paymentStatus
                createdAt
                items {
                  productId
                  name
                  quantity
                  basePrice
                  finalPrice
                  imageUrl
                  lineTotal
                }
                discounts {
                  id
                  title
                  amount
                  type
                }
                deliveryAddress {
                  street
                  city
                  reference
                }
                branch {
                  id
                  name
                  avatarUrl
                }
                business {
                  id
                  name
                }
              }
            }
            """

        let payload = MixedCreateOrderRequestPayload(
            query: mutation,
            variables: .init(
                jwt: jwt,
                input: .init(
                    branchId: branchId,
                    items: items.map { item in
                        .init(
                            quantity: item.quantity,
                            itemType: item.itemType.rawValue,
                            productId: item.productId,
                            showcaseId: item.showcaseId,
                            requestDescription: item.description
                        )
                    },
                    deliveryAddress: .init(
                        street: deliveryAddress.street,
                        latitude: deliveryAddress.latitude,
                        longitude: deliveryAddress.longitude,
                        city: deliveryAddress.city,
                        reference: deliveryAddress.reference,
                        addressType: deliveryAddress.addressType,
                        buildingName: deliveryAddress.buildingName,
                        floor: deliveryAddress.floor,
                        apartment: deliveryAddress.apartment,
                        deliveryInstructions: deliveryAddress.deliveryInstructions
                    ),
                    paymentMethod: paymentMethod,
                    paymentIntentId: paymentIntentId,
                    comments: comments,
                    promoCode: promoCode
                )
            )
        )

        do {
            var request = URLRequest(url: endpointURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try jsonEncoder.encode(payload)

            Task {
                do {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NSError(
                            domain: "CreateOrderRepository",
                            code: -3,
                            userInfo: [NSLocalizedDescriptionKey: "Respuesta HTTP inválida"]
                        )
                    }
                    guard (200..<300).contains(httpResponse.statusCode) else {
                        let rawMessage = String(data: data, encoding: .utf8) ?? "Respuesta desconocida"
                        throw NSError(
                            domain: "CreateOrderRepository",
                            code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: rawMessage]
                        )
                    }

                    let decoded = try jsonDecoder.decode(MixedCreateOrderResponse.self, from: data)
                    if let firstError = decoded.errors?.first {
                        throw NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: firstError.message]
                        )
                    }

                    guard let order = decoded.data?.createOrder else {
                        throw NSError(
                            domain: "CreateOrderRepository",
                            code: -4,
                            userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el pedido"]
                        )
                    }

                    let createdOrder = mapToCreatedOrder(order)
                    completion(.success(createdOrder))
                } catch {
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
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
                imageUrl: item.imageUrl ?? "",
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

    private func mapToCreatedOrder(_ order: MixedCreateOrderResponse.DataContainer.CreateOrder) -> CreatedOrder {
        let items = order.items.map { item in
            CreatedOrderItem(
                productId: item.productId ?? "",
                name: item.name,
                price: item.finalPrice ?? item.basePrice ?? 0,
                quantity: item.quantity,
                imageUrl: item.imageUrl ?? "",
                lineTotal: item.lineTotal
            )
        }

        let discounts = order.discounts.map { discount in
            CreatedOrderDiscount(
                id: discount.id,
                title: discount.title,
                amount: discount.amount,
                type: discount.type
            )
        }

        return CreatedOrder(
            id: order.id,
            orderNumber: order.orderNumber,
            status: order.status,
            subtotal: order.subtotal,
            deliveryFee: order.deliveryFee,
            total: order.total,
            currency: order.currency,
            paymentMethod: order.paymentMethod,
            paymentStatus: order.paymentStatus,
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

struct OrderRequestItem {
    let itemType: CartOrderItemType
    let quantity: Int
    let productId: String?
    let showcaseId: String?
    let description: String?
}

struct DeliveryAddressInput {
    let street: String
    let city: String?
    let reference: String?
    let latitude: Double
    let longitude: Double
    var addressType: String? = nil
    var buildingName: String? = nil
    var floor: String? = nil
    var apartment: String? = nil
    var deliveryInstructions: String? = nil
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

private struct MixedCreateOrderRequestPayload: Encodable {
    let query: String
    let variables: Variables

    struct Variables: Encodable {
        let jwt: String
        let input: Input
    }

    struct Input: Encodable {
        let branchId: String
        let items: [Item]
        let deliveryAddress: DeliveryAddress
        let paymentMethod: String
        let paymentIntentId: String?
        let comments: String?
        let promoCode: String?
    }

    struct Item: Encodable {
        let quantity: Int
        let itemType: String
        let productId: String?
        let showcaseId: String?
        let requestDescription: String?

        enum CodingKeys: String, CodingKey {
            case quantity
            case itemType
            case productId
            case showcaseId
            case requestDescription = "description"
        }
    }

    struct DeliveryAddress: Encodable {
        let street: String
        let latitude: Double
        let longitude: Double
        let city: String?
        let reference: String?
        let addressType: String?
        let buildingName: String?
        let floor: String?
        let apartment: String?
        let deliveryInstructions: String?
    }
}

private struct MixedCreateOrderResponse: Decodable {
    let data: DataContainer?
    let errors: [GraphQLErrorPayload]?

    struct DataContainer: Decodable {
        let createOrder: CreateOrder

        struct CreateOrder: Decodable {
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
            let items: [Item]
            let discounts: [Discount]
            let deliveryAddress: DeliveryAddress
            let branch: Branch
            let business: Business

            struct Item: Decodable {
                let productId: String?
                let name: String
                let quantity: Int
                let basePrice: Double?
                let finalPrice: Double?
                let imageUrl: String?
                let lineTotal: Double
            }

            struct Discount: Decodable {
                let id: String
                let title: String
                let amount: Double
                let type: String
            }

            struct DeliveryAddress: Decodable {
                let street: String
                let city: String?
                let reference: String?
            }

            struct Branch: Decodable {
                let id: String
                let name: String
                let avatarUrl: String?
            }

            struct Business: Decodable {
                let id: String
                let name: String
            }
        }
    }

    struct GraphQLErrorPayload: Decodable {
        let message: String
    }
}
