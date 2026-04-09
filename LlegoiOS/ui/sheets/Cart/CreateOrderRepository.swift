import Apollo
import Foundation

@MainActor
final class CreateOrderRepository {
    private let apolloClient = ApolloClientManager.shared.apollo
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    // MARK: - Create Order

    func createOrder(
        branchId: String,
        items: [OrderRequestItem],
        fulfillment: FulfillmentPayloadInput = .delivery,
        deliveryAddress: DeliveryAddressInput?,
        paymentMethod: String,
        paymentIntentId: String? = nil,
        comments: String? = nil,
        promoCode: String? = nil,
        scheduledFor: Date? = nil,
        completion: @escaping @Sendable (Result<CreatedOrder, Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            guard let jwt = AuthManager.shared.getAccessToken() else {
                completion(
                    .failure(
                        NSError(
                            domain: "CreateOrderRepository", code: 401,
                            userInfo: [NSLocalizedDescriptionKey: "No autenticado"])))
                return
            }

            // Prefer JSON payload so fulfillment is sent explicitly for DELIVERY and PICKUP.
            let shouldUseMixedPayload = !jwt.isEmpty
            if shouldUseMixedPayload {
                createMixedOrder(
                    branchId: branchId,
                    items: items,
                    fulfillment: fulfillment,
                    deliveryAddress: deliveryAddress,
                    paymentMethod: paymentMethod,
                    paymentIntentId: paymentIntentId,
                    comments: comments,
                    promoCode: promoCode,
                    scheduledFor: scheduledFor,
                    jwt: jwt,
                    completion: completion
                )
                return
            }

            guard let deliveryAddress else {
                completion(
                    .failure(
                        NSError(
                            domain: "CreateOrderRepository",
                            code: -11,
                            userInfo: [NSLocalizedDescriptionKey: "Falta dirección de entrega"]
                        )
                    )
                )
                return
            }

            // Build items input
            let itemsInput = items.compactMap { item -> LlegoAPI.OrderItemInput? in
                switch item.itemType {
                case .product:
                    guard let productId = item.productId else { return nil }
                    return LlegoAPI.OrderItemInput(
                        quantity: Int32(item.quantity),
                        itemType: GraphQLEnum(.product),
                        productId: .some(productId)
                    )
                case .combo:
                    guard let comboId = item.comboId else { return nil }
                    let comboSelections = item.comboSelections?.map { selection in
                        LlegoAPI.OrderComboSlotSelectionInput(
                            slotId: selection.slotId,
                            selectedOptions: selection.selectedOptions.map { option in
                                LlegoAPI.OrderComboSelectedOptionInput(
                                    productId: option.productId,
                                    quantity: Int32(option.quantity),
                                    modifiers: option.modifiers.map {
                                        LlegoAPI.OrderComboModifierInput(name: $0.name)
                                    }
                                )
                            }
                        )
                    }
                    return LlegoAPI.OrderItemInput(
                        quantity: Int32(item.quantity),
                        itemType: GraphQLEnum(.combo),
                        comboId: .some(comboId),
                        comboSelections: comboSelections
                    )
                case .showcase:
                    return nil
                }
            }

            // Build delivery address input
            let addressInput = LlegoAPI.DeliveryAddressInput(
                street: deliveryAddress.street,
                latitude: deliveryAddress.latitude,
                longitude: deliveryAddress.longitude,
                city: deliveryAddress.city.map { .some($0) } ?? .none,
                reference: deliveryAddress.reference.map { .some($0) } ?? .none,
                addressType: deliveryAddress.addressType.flatMap {
                    LlegoAPI.AddressTypeInput(rawValue: $0)
                }.map { .some(GraphQLEnum($0)) } ?? .none,
                buildingName: deliveryAddress.buildingName.map { .some($0) } ?? .none,
                floor: deliveryAddress.floor.map { .some($0) } ?? .none,
                apartment: deliveryAddress.apartment.map { .some($0) } ?? .none,
                deliveryInstructions: deliveryAddress.deliveryInstructions.map { .some($0) }
                    ?? .none
            )

            // Build create order input
            let input = LlegoAPI.CreateOrderInput(
                branchId: branchId,
                items: itemsInput,
                deliveryAddress: .some(addressInput),
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
                            let errorMessage =
                                errors.first?.localizedDescription ?? "Error al crear el pedido"
                            completion(
                                .failure(
                                    NSError(
                                        domain: "GraphQL", code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                            return
                        }

                        guard let order = graphQLResult.data?.createOrder else {
                            completion(
                                .failure(
                                    NSError(
                                        domain: "CreateOrderRepository", code: -1,
                                        userInfo: [
                                            NSLocalizedDescriptionKey: "No se pudo crear el pedido"
                                        ])))
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
        fulfillment: FulfillmentPayloadInput,
        deliveryAddress: DeliveryAddressInput?,
        paymentMethod: String,
        paymentIntentId: String?,
        comments: String?,
        promoCode: String?,
        scheduledFor: Date?,
        jwt: String,
        completion: @escaping @Sendable (Result<CreatedOrder, Error>) -> Void
    ) {
        guard let endpointURL = URL(string: "\(ApolloClientManager.baseURL)/graphql") else {
            completion(
                .failure(
                    NSError(
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
                deliveryMode
                scheduledFor
                items {
                  itemType
                  itemId
                  productId
                  name
                  price
                  quantity
                  basePrice
                  finalPrice
                  discountType
                  discountValue
                  imageUrl
                  lineTotal
                  comboSelections {
                    slotId
                    slotName
                    selectedOptions {
                      productId
                      name
                      price
                      quantity
                      priceAdjustment
                      modifiers {
                        name
                        priceAdjustment
                      }
                    }
                  }
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
                pickupAddress {
                  street
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
                            comboId: item.comboId,
                            comboSelections: item.comboSelections?.map { selection in
                                .init(
                                    slotId: selection.slotId,
                                    selectedOptions: selection.selectedOptions.map { option in
                                        .init(
                                            productId: option.productId,
                                            quantity: option.quantity,
                                            modifiers: option.modifiers.map { .init(name: $0.name) }
                                        )
                                    }
                                )
                            },
                            showcaseId: item.showcaseId,
                            requestDescription: item.description
                        )
                    },
                    fulfillment: .init(
                        type: fulfillment.type.rawValue,
                        pickupBranchId: fulfillment.pickupBranchId,
                        pickupWindowId: fulfillment.pickupWindowId
                    ),
                    deliveryAddress: deliveryAddress.map {
                        .init(
                            street: $0.street,
                            latitude: $0.latitude,
                            longitude: $0.longitude,
                            city: $0.city,
                            reference: $0.reference,
                            addressType: $0.addressType,
                            buildingName: $0.buildingName,
                            floor: $0.floor,
                            apartment: $0.apartment,
                            deliveryInstructions: $0.deliveryInstructions
                        )
                    },
                    paymentMethod: paymentMethod,
                    paymentIntentId: paymentIntentId,
                    comments: comments,
                    promoCode: promoCode,
                    scheduledFor: scheduledFor.map { iso8601String(from: $0) }
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
                        let rawMessage =
                            String(data: data, encoding: .utf8) ?? "Respuesta desconocida"
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

    private func mapToCreatedOrder(_ order: LlegoAPI.CreateOrderMutation.Data.CreateOrder)
        -> CreatedOrder
    {
        let items = order.items.map { item in
            CreatedOrderItem(
                productId: item.productId,
                name: item.name,
                price: item.finalPrice,
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
            deliveryReference: order.deliveryAddress.reference,
            deliveryMode: nil,
            pickupAddress: nil
        )
    }

    private func mapToCreatedOrder(_ order: MixedCreateOrderResponse.DataContainer.CreateOrder)
        -> CreatedOrder
    {
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
            deliveryStreet: order.deliveryAddress?.street ?? order.pickupAddress?.street ?? "",
            deliveryCity: order.deliveryAddress?.city,
            deliveryReference: order.deliveryAddress?.reference,
            deliveryMode: order.deliveryMode,
            pickupAddress: order.pickupAddress?.street
        )
    }

    private func mapStatus(_ status: GraphQLEnum<LlegoAPI.OrderStatusEnum>) -> String {
        switch status {
        case .case(let value): return value.rawValue
        case .unknown:
            print("⚠️ Unknown order status enum received from GraphQL in CreateOrderRepository")
            return "UNKNOWN"
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

    /// Converts a Date to ISO 8601 UTC string for the backend (e.g. "2026-04-10T00:00:00.000Z")
    private func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}

// MARK: - Input Models

struct OrderRequestItem {
    let itemType: CartOrderItemType
    let quantity: Int
    let productId: String?
    let comboId: String?
    let comboSelections: [OrderRequestComboSlotSelection]?
    let showcaseId: String?
    let description: String?
}

struct OrderRequestComboSlotSelection {
    let slotId: String
    let slotName: String
    let selectedOptions: [OrderRequestComboSelectedOption]
}

struct OrderRequestComboSelectedOption {
    let productId: String
    let quantity: Int
    let modifiers: [OrderRequestComboModifier]
}

struct OrderRequestComboModifier {
    let name: String
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
    let deliveryMode: String?
    let pickupAddress: String?

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
        let fulfillment: Fulfillment
        let deliveryAddress: DeliveryAddress?
        let paymentMethod: String
        let paymentIntentId: String?
        let comments: String?
        let promoCode: String?
        let scheduledFor: String?
    }

    struct Item: Encodable {
        let quantity: Int
        let itemType: String
        let productId: String?
        let comboId: String?
        let comboSelections: [ComboSelection]?
        let showcaseId: String?
        let requestDescription: String?

        enum CodingKeys: String, CodingKey {
            case quantity
            case itemType
            case productId
            case comboId
            case comboSelections
            case showcaseId
            case requestDescription = "description"
        }
    }

    struct ComboSelection: Encodable {
        let slotId: String
        let selectedOptions: [SelectedOption]
    }

    struct SelectedOption: Encodable {
        let productId: String
        let quantity: Int
        let modifiers: [Modifier]
    }

    struct Modifier: Encodable {
        let name: String
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

    struct Fulfillment: Encodable {
        let type: String
        let pickupBranchId: String?
        let pickupWindowId: String?
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
            let deliveryMode: String?
            let scheduledFor: String?
            let items: [Item]
            let discounts: [Discount]
            let deliveryAddress: DeliveryAddress?
            let pickupAddress: PickupAddress?
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

            struct PickupAddress: Decodable {
                let street: String?
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
