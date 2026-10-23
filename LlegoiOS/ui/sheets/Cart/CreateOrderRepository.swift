import Apollo
import Foundation

@MainActor
final class CreateOrderRepository {
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
        idempotencyKey: String? = nil,
        completion: @escaping @Sendable (Result<CreatedOrder, Error>) -> Void
    ) {
        Task { @MainActor in
            // Un token vacío también es no autenticado: antes caía en una ruta de Apollo sin
            // clave de idempotencia (un doble toque podía crear dos pedidos).
            guard let jwt = AuthManager.shared.getAccessToken(), !jwt.isEmpty else {
                completion(
                    .failure(
                        NSError(
                            domain: "CreateOrderRepository", code: 401,
                            userInfo: [NSLocalizedDescriptionKey: "No autenticado"])))
                return
            }

            // JSON para enviar fulfillment (DELIVERY o PICKUP) y la clave de idempotencia
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
                idempotencyKey: idempotencyKey,
                jwt: jwt,
                completion: completion
            )
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
        idempotencyKey: String?,
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
                    scheduledFor: scheduledFor.map { iso8601String(from: $0) },
                    idempotencyKey: idempotencyKey
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
                        throw CreateOrderError(
                            code: firstError.extensions?.code,
                            message: firstError.message
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
        // Con la misma clave, el backend devuelve el pedido ya creado en vez de duplicarlo.
        let idempotencyKey: String?
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
        let extensions: Extensions?

        struct Extensions: Decodable {
            let code: String?
        }
    }
}
