import Apollo
import CoreLocation
import Foundation

@MainActor
final class OrderDetailRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // MARK: - Fetch Order Detail

    func fetchOrder(
        id: String,
        completion: @escaping @Sendable (Result<OrderDetail, Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            guard let jwt = AuthManager.shared.getAccessToken() else {
                completion(
                    .failure(
                        NSError(
                            domain: "OrderDetailRepository", code: 401,
                            userInfo: [NSLocalizedDescriptionKey: "No autenticado"])))
                return
            }

            let query = LlegoAPI.GetOrderDetailQuery(id: id, jwt: jwt)

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

                        guard let order = graphQLResult.data?.order else {
                            completion(
                                .failure(
                                    NSError(
                                        domain: "OrderDetailRepository", code: 404,
                                        userInfo: [
                                            NSLocalizedDescriptionKey: "Pedido no encontrado"
                                        ])))
                            return
                        }

                        let detail = self.mapToOrderDetail(order)
                        completion(.success(detail))

                    case .failure(let error):
                        print("❌ Network error: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // MARK: - Accept Modifications

    func acceptModifications(
        orderId: String,
        completion: @escaping @Sendable (Result<OrderDetail, Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            guard let jwt = AuthManager.shared.getAccessToken() else {
                completion(
                    .failure(
                        NSError(
                            domain: "OrderDetailRepository", code: 401,
                            userInfo: [NSLocalizedDescriptionKey: "No autenticado"])))
                return
            }

            let mutation = LlegoAPI.AcceptOrderModificationsMutation(orderId: orderId, jwt: jwt)

            client.performCompat(mutation: mutation) { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .success(let graphQLResult):
                        if let errors = graphQLResult.errors {
                            completion(
                                .failure(
                                    NSError(
                                        domain: "GraphQL", code: -1,
                                        userInfo: [
                                            NSLocalizedDescriptionKey: errors.first?
                                                .localizedDescription ?? "Error"
                                        ])))
                            return
                        }
                        self?.fetchOrder(id: orderId, completion: completion)

                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // MARK: - Cancel Order

    func cancelOrder(
        orderId: String,
        reason: String?,
        completion: @escaping @Sendable (Result<OrderDetail, Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            guard let jwt = AuthManager.shared.getAccessToken() else {
                completion(
                    .failure(
                        NSError(
                            domain: "OrderDetailRepository", code: 401,
                            userInfo: [NSLocalizedDescriptionKey: "No autenticado"])))
                return
            }

            let mutation = LlegoAPI.CancelOrderMutation(
                orderId: orderId,
                reason: reason.map { .some($0) } ?? .none,
                jwt: jwt
            )

            client.performCompat(mutation: mutation) { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .success(let graphQLResult):
                        if let errors = graphQLResult.errors {
                            completion(
                                .failure(
                                    NSError(
                                        domain: "GraphQL", code: -1,
                                        userInfo: [
                                            NSLocalizedDescriptionKey: errors.first?
                                                .localizedDescription ?? "Error"
                                        ])))
                            return
                        }
                        self?.fetchOrder(id: orderId, completion: completion)

                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // MARK: - Resubmit Order

    func resubmitOrder(
        orderId: String,
        completion: @escaping @Sendable (Result<OrderDetail, Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            guard let jwt = AuthManager.shared.getAccessToken() else {
                completion(
                    .failure(
                        NSError(
                            domain: "OrderDetailRepository", code: 401,
                            userInfo: [NSLocalizedDescriptionKey: "No autenticado"])))
                return
            }

            let input = LlegoAPI.ResubmitOrderInput(orderId: orderId)
            let mutation = LlegoAPI.ResubmitOrderMutation(input: input, jwt: jwt)

            client.performCompat(mutation: mutation) { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .success(let graphQLResult):
                        if let errors = graphQLResult.errors {
                            completion(
                                .failure(
                                    NSError(
                                        domain: "GraphQL", code: -1,
                                        userInfo: [
                                            NSLocalizedDescriptionKey: errors.first?
                                                .localizedDescription ?? "Error"
                                        ])))
                            return
                        }

                        self?.fetchOrder(id: orderId, completion: completion)

                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // MARK: - Add Comment

    func addComment(
        orderId: String,
        message: String,
        completion: @escaping @Sendable (Result<Void, Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            guard let jwt = AuthManager.shared.getAccessToken() else {
                completion(
                    .failure(
                        NSError(
                            domain: "OrderDetailRepository", code: 401,
                            userInfo: [NSLocalizedDescriptionKey: "No autenticado"])))
                return
            }

            let input = LlegoAPI.AddOrderCommentInput(orderId: orderId, message: message)
            let mutation = LlegoAPI.AddOrderCommentMutation(input: input, jwt: jwt)

            client.performCompat(mutation: mutation) { result in
                Task { @MainActor in
                    switch result {
                    case .success(let graphQLResult):
                        if let errors = graphQLResult.errors {
                            completion(
                                .failure(
                                    NSError(
                                        domain: "GraphQL", code: -1,
                                        userInfo: [
                                            NSLocalizedDescriptionKey: errors.first?
                                                .localizedDescription ?? "Error"
                                        ])))
                            return
                        }
                        completion(.success(()))

                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // MARK: - Fetch Order Async (for polling)

    func fetchOrderAsync(id: String) async throws -> OrderDetail {
        return try await withCheckedThrowingContinuation { continuation in
            fetchOrder(id: id) { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: - Confirm Transfer By Shortcut (sin comprobante)

    func confirmTransferByShortcut(paymentAttemptId: String) async throws {
        let client = apolloClient

        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                guard let jwt = AuthManager.shared.getAccessToken() else {
                    continuation.resume(throwing: NSError(
                        domain: "OrderDetailRepository", code: 401,
                        userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa."]))
                    return
                }

                let mutation = LlegoAPI.ConfirmTransferByShortcutMutation(
                    paymentAttemptId: paymentAttemptId,
                    jwt: jwt,
                    transferId: .none
                )

                client.performCompat(mutation: mutation) { result in
                    switch result {
                    case .success(let graphQLResult):
                        if let errors = graphQLResult.errors {
                            continuation.resume(throwing: NSError(
                                domain: "GraphQL", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error"]))
                        } else {
                            continuation.resume(returning: ())
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    // MARK: - Confirm Payment Sent (con comprobante)

    func confirmPaymentSent(paymentAttemptId: String, proofUrl: String) async throws {
        let client = apolloClient

        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                guard let jwt = AuthManager.shared.getAccessToken() else {
                    continuation.resume(throwing: NSError(
                        domain: "OrderDetailRepository", code: 401,
                        userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa."]))
                    return
                }

                let mutation = LlegoAPI.ConfirmPaymentSentMutation(
                    paymentAttemptId: paymentAttemptId,
                    proofUrl: proofUrl,
                    jwt: jwt
                )

                client.performCompat(mutation: mutation) { result in
                    switch result {
                    case .success(let graphQLResult):
                        if let errors = graphQLResult.errors {
                            continuation.resume(throwing: NSError(
                                domain: "GraphQL", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error"]))
                        } else {
                            continuation.resume(returning: ())
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    // MARK: - Mapping Helpers

    private func mapToOrderDetail(_ order: LlegoAPI.GetOrderDetailQuery.Data.Order) -> OrderDetail {
        let technicalStatus = mapGraphQLToStatus(order.status)
        let visibleStatus = mapGraphQLToStatus(order.customerVisibleStatus)
        let fulfillmentMode = mapFulfillmentMode(order.deliveryMode)

        let items = order.items.map { item in
            OrderDetailItem(
                id: item.productId,
                productId: item.productId,
                name: item.name,
                price: item.price,
                quantity: item.quantity,
                imageUrl: item.imageUrlMuyBaja ?? item.imageUrl,
                wasModifiedByStore: item.wasModifiedByStore
            )
        }

        let discounts = order.discounts.map { discount in
            OrderDetailDiscount(
                id: discount.id,
                title: discount.title,
                amount: discount.amount,
                type: mapDiscountType(discount.type)
            )
        }

        let deliveryCoords = order.deliveryAddress.coordinates.coordinates
        let deliveryCoordinate: CLLocationCoordinate2D? =
            deliveryCoords.count >= 2
            ? CLLocationCoordinate2D(latitude: deliveryCoords[1], longitude: deliveryCoords[0])
            : nil

        let deliveryAddress = OrderDeliveryAddress(
            street: order.deliveryAddress.street,
            city: order.deliveryAddress.city,
            reference: order.deliveryAddress.reference,
            coordinates: deliveryCoordinate,
            addressType: {
                if case .case(let value) = order.deliveryAddress.addressType {
                    return value.rawValue
                }
                return nil
            }(),
            buildingName: order.deliveryAddress.buildingName,
            floor: order.deliveryAddress.floor,
            apartment: order.deliveryAddress.apartment,
            deliveryInstructions: order.deliveryAddress.deliveryInstructions
        )

        let deliveryPerson: OrderDeliveryPerson? = order.deliveryPerson.map { dp in
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
                currentLocation: nil
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

        let comments = order.comments.map { comment in
            OrderDetailComment(
                id: comment.id,
                author: mapActor(comment.author),
                message: comment.message,
                timestamp: parseDate(comment.timestamp) ?? Date()
            )
        }

        let branchCoords = order.branch.coordinates.coordinates
        let branchCoordinate: CLLocationCoordinate2D? =
            branchCoords.count >= 2
            ? CLLocationCoordinate2D(latitude: branchCoords[1], longitude: branchCoords[0])
            : nil

        let transferAccounts = order.branch.accounts
            .filter { $0.isActive }
            .map { account in
                OrderTransferAccount(
                    cardNumber: account.cardNumber,
                    cardHolderName: account.cardHolderName,
                    bankName: account.bankName
                )
            }

        let transferPhones = order.branch.phones
            .filter { $0.isActive }
            .map { OrderTransferPhone(phone: $0.phone) }

        return OrderDetail(
            id: order.id,
            orderNumber: order.orderNumber,
            status: technicalStatus,
            customerVisibleStatus: visibleStatus,
            subtotal: order.subtotal,
            deliveryFee: order.deliveryFee,
            total: order.total,
            currency: order.currency,
            paymentMethod: order.paymentMethod,
            paymentStatus: mapPaymentStatus(order.paymentStatus),
            createdAt: parseDate(order.createdAt) ?? Date(),
            updatedAt: parseDate(order.updatedAt) ?? Date(),
            lastStatusAt: parseDate(order.lastStatusAt) ?? Date(),
            deadlineAt: order.deadlineAt.flatMap { parseDate($0) },
            deliveryVerificationCode: technicalStatus == .onTheWay
                ? order.deliveryVerificationCode
                : nil,
            isEditable: order.isEditable,
            canCancel: order.canCancel,
            estimatedDeliveryTime: order.estimatedDeliveryTime.flatMap { parseDate($0) },
            estimatedMinutesRemaining: order.estimatedMinutesRemaining,
            deliveryMode: fulfillmentMode,
            pickupAddress: fulfillmentMode == .pickup
                ? OrderPickupAddress(
                    street: order.branch.address,
                    city: nil,
                    reference: nil
                ) : nil,
            estimatedReadyAt: nil,
            items: items,
            discounts: discounts,
            deliveryAddress: fulfillmentMode == .pickup ? nil : deliveryAddress,
            deliveryPerson: deliveryPerson,
            timeline: timeline,
            comments: comments,
            branchId: order.branch.id,
            branchName: order.branch.name,
            branchAddress: order.branch.address,
            branchPhone: order.branch.phone,
            branchImageUrl: order.branch.avatarUrl,
            branchCoordinates: branchCoordinate,
            transferAccounts: transferAccounts,
            transferPhones: transferPhones,
            businessId: order.business.id,
            businessName: order.business.name,
            businessImageUrl: order.business.avatarUrl
        )
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

    private func mapPaymentStatus(_ status: GraphQLEnum<LlegoAPI.PaymentStatusEnum>)
        -> PaymentStatusEnum
    {
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

    private func mapDiscountType(_ type: GraphQLEnum<LlegoAPI.DiscountTypeEnum>) -> DiscountTypeEnum
    {
        switch type {
        case .case(let value):
            switch value {
            case .premium: return .premium
            case .level: return .level
            case .promo: return .promo
            }
        case .unknown:
            return .promo
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
