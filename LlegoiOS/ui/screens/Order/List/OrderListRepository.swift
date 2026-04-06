import Apollo
import CoreLocation
import Foundation

@MainActor
final class OrderListRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // MARK: - Fetch Orders

    func fetchOrders(
        status: OrderStatusEnum? = nil,
        limit: Int = 20,
        offset: Int = 0,
        completion: @escaping @Sendable (Result<OrderListResult, Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            guard let jwt = AuthManager.shared.getAccessToken() else {
                completion(
                    .failure(
                        NSError(
                            domain: "OrderListRepository", code: 401,
                            userInfo: [NSLocalizedDescriptionKey: "No autenticado"])))
                return
            }

            let graphQLStatus: GraphQLNullable<GraphQLEnum<LlegoAPI.OrderStatusEnum>>
            if let status = status {
                if let mapped = mapStatusToGraphQL(status) {
                    graphQLStatus = .some(.case(mapped))
                } else {
                    print("⚠️ Ignoring unmappable order status filter '\(status.rawValue)'")
                    graphQLStatus = .none
                }
            } else {
                graphQLStatus = .none
            }

            let query = LlegoAPI.GetMyOrdersQuery(
                status: graphQLStatus,
                limit: .some(Int32(limit)),
                offset: .some(Int32(offset)),
                jwt: jwt
            )

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

                        guard let data = graphQLResult.data?.myOrders else {
                            completion(
                                .success(OrderListResult(orders: [], totalCount: 0, hasMore: false))
                            )
                            return
                        }

                        let orders = data.orders.map { order -> RecentOrder in
                            let technicalStatus = self.mapGraphQLToStatus(order.status)
                            let visibleStatus = self.mapGraphQLToStatus(order.customerVisibleStatus)
                            let deliveryMode = self.mapFulfillmentMode(order.deliveryMode)

                            let items = order.items.map { item in
                                OrderListItem(
                                    id: item.productId,
                                    name: item.name,
                                    quantity: item.quantity,
                                    imageUrl: item.imageUrlMuyBaja ?? item.imageUrl
                                )
                            }

                            return RecentOrder(
                                id: order.id,
                                orderNumber: order.orderNumber,
                                storeName: order.branch.name,
                                storeImageUrl: order.branch.avatarUrl,
                                date: self.parseDate(order.createdAt) ?? Date(),
                                total: order.total,
                                currency: order.currency,
                                customerVisibleStatus: visibleStatus,
                                status: technicalStatus,
                                deadlineAt: order.deadlineAt.flatMap { self.parseDate($0) },
                                paymentStatus: self.mapGraphQLToPaymentStatus(order.paymentStatus),
                                itemCount: order.items.count,
                                items: items,
                                fulfillmentMode: deliveryMode
                            )
                        }

                        let result = OrderListResult(
                            orders: orders,
                            totalCount: data.totalCount,
                            hasMore: data.hasMore
                        )

                        completion(.success(result))

                    case .failure(let error):
                        print("❌ Network error: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    /// Returns exact count of delivered orders using backend filtering + totalCount.
    /// This avoids relying on locally paginated history.
    func fetchDeliveredOrdersCount(
        completion: @escaping @Sendable (Result<Int, Error>) -> Void
    ) {
        fetchOrders(status: .delivered, limit: 1, offset: 0) { result in
            switch result {
            case .success(let data):
                completion(.success(data.totalCount))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Helpers

    private func mapStatusToGraphQL(_ status: OrderStatusEnum) -> LlegoAPI.OrderStatusEnum? {
        switch status {
        case .awaitingDeliveryAcceptance: return .awaitingDeliveryAcceptance
        case .pendingPayment: return .pendingPayment
        case .paymentInProgress: return .pendingPayment
        case .pendingAcceptance: return .pendingAcceptance
        case .modifiedByStore: return .modifiedByStore
        case .rejectedByStore: return .rejectedByStore
        case .accepted: return .accepted
        case .preparing: return .preparing
        case .readyForPickup: return .readyForPickup
        case .onTheWay: return .onTheWay
        case .delivered: return .delivered
        case .cancelled: return .cancelled
        case .unknown:
            assertionFailure("Attempted to map unknown local order status to GraphQL enum")
            return nil
        }
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

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    private func mapGraphQLToPaymentStatus(
        _ status: GraphQLEnum<LlegoAPI.PaymentStatusEnum>
    ) -> PaymentStatusEnum {
        switch status {
        case .case(let value):
            switch value {
            case .pending: return .pending
            case .validated: return .validated
            case .completed: return .completed
            case .failed: return .failed
            }
        case .unknown:
            return .pending
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
}

// MARK: - Result Model

struct OrderListResult {
    let orders: [RecentOrder]
    let totalCount: Int
    let hasMore: Bool
}
