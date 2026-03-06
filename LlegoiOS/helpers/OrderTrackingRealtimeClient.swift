import Foundation

struct OrderTrackingRealtimeEvent {
    let orderId: String
    let statusRaw: String?
    let estimatedMinutes: Int?
    let distanceKm: Double?
    let deliveryPersonCoordinates: [Double]?
}

actor OrderTrackingRealtimeClient {
    private let webSocketURL: URL
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()

    init(baseURL: String) {
        let httpURL = URL(string: "\(baseURL)/graphql")
            ?? URL(string: "https://llegobackend-production.up.railway.app/graphql")!

        if var components = URLComponents(url: httpURL, resolvingAgainstBaseURL: false) {
            components.scheme = components.scheme == "https" ? "wss" : "ws"
            webSocketURL = components.url ?? httpURL
        } else {
            webSocketURL = httpURL
        }
    }

    func streamOrderUpdates(
        orderId: String,
        jwt: String,
        onEvent: @escaping @Sendable (OrderTrackingRealtimeEvent) async -> Void
    ) async throws {
        let webSocket = URLSession.shared.webSocketTask(
            with: webSocketURL,
            protocols: ["graphql-transport-ws"]
        )
        webSocket.resume()

        defer {
            webSocket.cancel(with: .goingAway, reason: nil)
        }

        let initMessage = GraphQLWSMessage(
            id: nil,
            type: "connection_init",
            payload: .object(
                [
                    "Authorization": .string("Bearer \(jwt)"),
                    "authorization": .string("Bearer \(jwt)"),
                    "jwt": .string(jwt),
                ]
            )
        )
        try await send(initMessage, over: webSocket)
        _ = try await receiveGraphQLWSMessage(over: webSocket)

        let operation = GraphQLWSSubscribeOperation(
            query: Self.orderTrackingSubscription,
            variables: ["orderId": .string(orderId), "jwt": .string(jwt)],
            operationName: "OrderTrackingStream"
        )
        let subscribeMessage = GraphQLWSMessage(
            id: "order-tracking-\(orderId)",
            type: "subscribe",
            payload: .subscribe(operation)
        )
        try await send(subscribeMessage, over: webSocket)

        while !Task.isCancelled {
            let incoming = try await receiveGraphQLWSMessage(over: webSocket)

            if incoming.type == "complete" {
                break
            }
            guard incoming.type == "next", let payload = incoming.payload else { continue }

            guard let decoded = payload.decoded(OrderTrackingPayload.self, using: jsonDecoder),
                let stream = decoded.data?.orderTrackingStream
            else {
                continue
            }

            let event = OrderTrackingRealtimeEvent(
                orderId: stream.order.id,
                statusRaw: stream.order.status,
                estimatedMinutes: stream.estimatedMinutes ?? stream.order.estimatedMinutesRemaining,
                distanceKm: stream.distanceKm,
                deliveryPersonCoordinates: stream.deliveryPersonLocation?.coordinates
            )
            await onEvent(event)
        }
    }

    private func send(_ message: GraphQLWSMessage, over socket: URLSessionWebSocketTask) async throws {
        let data = try jsonEncoder.encode(message)
        guard let text = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "OrderTrackingRealtimeClient", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No se pudo serializar mensaje WS."
            ])
        }
        try await socket.send(.string(text))
    }

    private func receiveGraphQLWSMessage(over socket: URLSessionWebSocketTask) async throws
        -> GraphQLWSMessage
    {
        let incoming = try await socket.receive()
        let text: String
        switch incoming {
        case .string(let value):
            text = value
        case .data(let data):
            text = String(data: data, encoding: .utf8) ?? ""
        @unknown default:
            text = ""
        }

        guard let data = text.data(using: .utf8) else {
            throw NSError(domain: "OrderTrackingRealtimeClient", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Mensaje WS inválido."
            ])
        }
        return try jsonDecoder.decode(GraphQLWSMessage.self, from: data)
    }
}

private extension OrderTrackingRealtimeClient {
    static let orderTrackingSubscription = """
    subscription OrderTrackingStream($orderId: String!, $jwt: String) {
      orderTrackingStream(orderId: $orderId, jwt: $jwt) {
        estimatedMinutes
        distanceKm
        deliveryPersonLocation {
          type
          coordinates
        }
        order {
          id
          status
          estimatedMinutesRemaining
        }
      }
    }
    """
}

// MARK: - WS Protocol Models

private struct GraphQLWSMessage: Codable {
    let id: String?
    let type: String
    let payload: GraphQLWSPayload?
}

private enum GraphQLWSPayload: Codable {
    case object([String: GraphQLWSValue])
    case subscribe(GraphQLWSSubscribeOperation)
    case raw(Data)

    init(from decoder: Decoder) throws {
        if let op = try? GraphQLWSSubscribeOperation(from: decoder) {
            self = .subscribe(op)
            return
        }
        if let object = try? [String: GraphQLWSValue](from: decoder) {
            self = .object(object)
            return
        }
        let single = try decoder.singleValueContainer()
        self = .raw((try? single.decode(Data.self)) ?? Data())
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .object(let object):
            try object.encode(to: encoder)
        case .subscribe(let subscribe):
            try subscribe.encode(to: encoder)
        case .raw:
            var container = encoder.singleValueContainer()
            try container.encode([String: String]())
        }
    }

    func decoded<T: Decodable>(_ type: T.Type, using decoder: JSONDecoder) -> T? {
        switch self {
        case .object(let object):
            guard let data = try? JSONEncoder().encode(object) else { return nil }
            return try? decoder.decode(type, from: data)
        case .subscribe:
            return nil
        case .raw(let data):
            return try? decoder.decode(type, from: data)
        }
    }
}

private struct GraphQLWSSubscribeOperation: Codable {
    let query: String
    let variables: [String: GraphQLWSValue]
    let operationName: String
}

private enum GraphQLWSValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: GraphQLWSValue])
    case array([GraphQLWSValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: GraphQLWSValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([GraphQLWSValue].self) {
            self = .array(value)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

// MARK: - Subscription Payload

private struct OrderTrackingPayload: Decodable {
    let data: DataContainer?

    struct DataContainer: Decodable {
        let orderTrackingStream: StreamData?
    }

    struct StreamData: Decodable {
        let estimatedMinutes: Int?
        let distanceKm: Double?
        let deliveryPersonLocation: LocationNode?
        let order: OrderNode
    }

    struct LocationNode: Decodable {
        let type: String?
        let coordinates: [Double]?
    }

    struct OrderNode: Decodable {
        let id: String
        let status: String?
        let estimatedMinutesRemaining: Int?
    }
}
