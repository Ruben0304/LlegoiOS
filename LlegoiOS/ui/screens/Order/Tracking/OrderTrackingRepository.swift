import Apollo
import CoreLocation
import Foundation

@MainActor
final class OrderTrackingRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // MARK: - Fetch Order Tracking

    func fetchTracking(
        orderId: String,
        completion: @escaping @Sendable (Result<OrderTracking, Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            guard let jwt = AuthManager.shared.getAccessToken() else {
                completion(
                    .failure(
                        NSError(
                            domain: "OrderTrackingRepository", code: 401,
                            userInfo: [NSLocalizedDescriptionKey: "No autenticado"])))
                return
            }

            let query = LlegoAPI.GetOrderTrackingQuery(orderId: orderId, jwt: jwt)

            client.fetchCompat(query: query, cachePolicy: .fetchIgnoringCacheData) {
                [weak self] result in
                Task { @MainActor in
                    guard let self = self else { return }

                    switch result {
                    case .success(let graphQLResult):
                        if let errors = graphQLResult.errors {
                            print("❌ GraphQL Errors: \(errors)")
                            completion(
                                .failure(
                                    NSError(
                                        domain: "GraphQL", code: -1,
                                        userInfo: [
                                            NSLocalizedDescriptionKey: errors.first?
                                                .localizedDescription ?? "Error desconocido"
                                        ])))
                            return
                        }

                        guard let data = graphQLResult.data?.orderTracking else {
                            completion(
                                .failure(
                                    NSError(
                                        domain: "OrderTrackingRepository", code: 404,
                                        userInfo: [
                                            NSLocalizedDescriptionKey: "Tracking no encontrado"
                                        ])))
                            return
                        }

                        let tracking = self.mapToOrderTracking(data)
                        completion(.success(tracking))

                    case .failure(let error):
                        print("❌ Network error: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // MARK: - Mapping

    private func mapToOrderTracking(_ data: LlegoAPI.GetOrderTrackingQuery.Data.OrderTracking)
        -> OrderTracking
    {
        let order = data.order
        let technicalStatus = mapGraphQLToStatus(order.status)
        let visibleStatus = mapGraphQLToStatus(order.customerVisibleStatus)
        let deliveryMode = mapFulfillmentMode(order.deliveryMode)
        let isPickup = deliveryMode == .pickup

        let items = order.items.map { item in
            OrderTrackingItem(
                id: item.productId,
                productId: item.productId,
                name: item.name,
                quantity: item.quantity,
                price: item.price,
                imageUrl: item.imageUrlMuyBaja ?? item.imageUrl
            )
        }

        let deliveryPerson: OrderDeliveryPerson? =
            isPickup
            ? nil
            : order.deliveryPerson.map { dp in
                var currentLocation: CLLocationCoordinate2D? = nil
                if let coords = dp.currentLocation?.coordinates, coords.count >= 2 {
                    currentLocation = CLLocationCoordinate2D(
                        latitude: coords[1], longitude: coords[0])
                }

                let vehicleTypeValue: String?
                if case .case(let value) = dp.vehicleType {
                    vehicleTypeValue = value.rawValue
                } else {
                    vehicleTypeValue = nil
                }

                return OrderDeliveryPerson(
                    id: dp.id,
                    name: dp.name,
                    phone: dp.phone,
                    rating: dp.rating,
                    vehicleType: vehicleTypeValue,
                    vehiclePlate: dp.vehiclePlate,
                    profileImageUrl: dp.profileImageUrl,
                    isOnline: dp.isOnline,
                    currentLocation: currentLocation
                )
            }

        let timeline = order.timeline.map { event in
            OrderTimelineEvent(
                status: mapGraphQLToStatus(event.status),
                timestamp: parseDate(event.timestamp) ?? Date(),
                message: event.message,
                actor: mapActor(event.actor)
            )
        }

        let trackingOrder = OrderTrackingOrder(
            id: order.id,
            orderNumber: order.orderNumber,
            status: technicalStatus,
            customerVisibleStatus: visibleStatus,
            deadlineAt: order.deadlineAt.flatMap { parseDate($0) },
            deliveryVerificationCode: technicalStatus == .onTheWay
                ? order.deliveryVerificationCode
                : nil,
            total: order.total,
            currency: order.currency,
            estimatedDeliveryTime: order.estimatedDeliveryTime.flatMap { parseDate($0) },
            estimatedMinutesRemaining: order.estimatedMinutesRemaining,
            items: items,
            deliveryPerson: deliveryPerson,
            timeline: timeline,
            branchId: order.branch.id,
            branchName: order.branch.name,
            branchImageUrl: order.branch.avatarUrl,
            deliveryMode: deliveryMode,
            pickupAddress: isPickup ? order.branch.name : nil,
            estimatedReadyAt: nil
        )

        let storeLocation = parseCoordinates(data.storeLocation.coordinates)
        let deliveryLocation = isPickup ? nil : parseCoordinates(data.deliveryLocation.coordinates)
        let deliveryPersonLocation =
            isPickup
            ? nil : data.deliveryPersonLocation.flatMap { parseCoordinates($0.coordinates) }

        return OrderTracking(
            order: trackingOrder,
            deliveryPersonLocation: deliveryPersonLocation,
            storeLocation: storeLocation,
            deliveryLocation: deliveryLocation,
            estimatedMinutes: data.estimatedMinutes,
            distanceKm: data.distanceKm,
            routePolyline: data.routePolyline
        )
    }

    private func parseCoordinates(_ coords: [Double]) -> CLLocationCoordinate2D? {
        guard coords.count >= 2 else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0])
    }

    private func mapGraphQLToStatus(_ status: GraphQLEnum<LlegoAPI.OrderStatusEnum>)
        -> OrderStatusEnum
    {
        switch status {
        case .case(let value):
            switch value {
            case .awaitingDeliveryAcceptance: return .awaitingDeliveryAcceptance
            case .pendingPayment: return .pendingPayment
            case .paymentInProgress:
                print("ℹ️ Legacy order status PAYMENT_IN_PROGRESS received from GraphQL")
                return .paymentInProgress
            case .pendingAcceptance: return .pendingAcceptance
            case .modifiedByStore: return .modifiedByStore
            case .rejectedByStore: return .rejectedByStore
            case .accepted: return .accepted
            case .preparing: return .preparing
            case .readyForPickup: return .readyForPickup
            case .onTheWay: return .onTheWay
            case .delivered: return .delivered
            case .cancelled: return .cancelled
            }
        case .unknown:
            print("⚠️ Unknown order status enum received from GraphQL")
            return .unknown
        }
    }

    private func mapActor(_ actor: GraphQLEnum<LlegoAPI.OrderActorEnum>) -> OrderActorEnum {
        switch actor {
        case .case(let value):
            switch value {
            case .customer: return .customer
            case .business: return .business
            case .system: return .system
            case .delivery: return .delivery
            }
        case .unknown:
            return .system
        }
    }

    private func mapFulfillmentMode(_ rawValue: String) -> FulfillmentMode {
        switch rawValue.uppercased() {
        case FulfillmentMode.pickup.rawValue:
            return .pickup
        case FulfillmentMode.delivery.rawValue:
            return .delivery
        default:
            print("⚠️ Unknown fulfillment mode '\(rawValue)' - defaulting to delivery")
            return .delivery
        }
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
}
