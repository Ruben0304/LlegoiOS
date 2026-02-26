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
                graphQLStatus = .some(.case(mapStatusToGraphQL(status)))
            } else {
                graphQLStatus = .none
            }

            let query = LlegoAPI.GetMyOrdersQuery(
                status: graphQLStatus,
                limit: .some(Int32(limit)),
                offset: .some(Int32(offset)),
                jwt: jwt
            )

            client.fetchCompat(query: query, cachePolicy: .fetchIgnoringCacheData) { [weak self] result in
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
                            let items = order.items.map { item in
                                OrderListItem(
                                    id: item.productId,
                                    name: item.name,
                                    quantity: item.quantity,
                                    imageUrl: item.imageUrl
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
                                status: self.mapGraphQLToStatus(order.status),
                                paymentStatus: self.mapGraphQLToPaymentStatus(order.paymentStatus),
                                itemCount: order.items.count,
                                items: items
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

    // MARK: - Helpers

    private func mapStatusToGraphQL(_ status: OrderStatusEnum) -> LlegoAPI.OrderStatusEnum {
        switch status {
        case .pendingAcceptance: return .pendingAcceptance
        case .modifiedByStore: return .modifiedByStore
        case .accepted: return .accepted
        case .preparing: return .preparing
        case .readyForPickup: return .readyForPickup
        case .onTheWay: return .onTheWay
        case .delivered: return .delivered
        case .cancelled: return .cancelled
        }
    }

    private func mapGraphQLToStatus(_ status: GraphQLEnum<LlegoAPI.OrderStatusEnum>)
        -> OrderStatusEnum
    {
        switch status {
        case .case(let value):
            switch value {
            case .pendingAcceptance: return .pendingAcceptance
            case .modifiedByStore: return .modifiedByStore
            case .accepted: return .accepted
            case .preparing: return .preparing
            case .readyForPickup: return .readyForPickup
            case .onTheWay: return .onTheWay
            case .delivered: return .delivered
            case .cancelled: return .cancelled
            }
        case .unknown:
            return .pendingAcceptance
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
}

// MARK: - Result Model

struct OrderListResult {
    let orders: [RecentOrder]
    let totalCount: Int
    let hasMore: Bool
}
