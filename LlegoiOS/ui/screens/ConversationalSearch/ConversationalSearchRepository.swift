//
//  ConversationalSearchRepository.swift
//  LlegoiOS
//
//  Repository para manejar las queries/subscriptions de AI Chat
//

import Foundation

@MainActor
final class ConversationalSearchRepository {
    private let localAIAssistantService = LocalAIAssistantService.shared
    private let backendClient = AIChatBackendClient(baseURL: ApolloClientManager.baseURL)

    func sendMessage(
        message: String,
        provider: ConversationalAIProvider,
        onStreamEvent: (@Sendable (AIChatStreamEvent) -> Void)? = nil,
        completion: @escaping @Sendable (Result<AIChatData, Error>) -> Void
    ) {
        switch provider {
        case .appleIntelligence:
            sendMessageWithAppleIntelligence(message: message, completion: completion)
        case .llegoAI:
            sendMessageWithBackend(
                message: message,
                onStreamEvent: onStreamEvent,
                completion: completion
            )
        }
    }

    private func sendMessageWithAppleIntelligence(
        message: String,
        completion: @escaping @Sendable (Result<AIChatData, Error>) -> Void
    ) {
        Task { @MainActor in
            guard let jwt = AuthManager.shared.getAccessToken() else {
                completion(.failure(LocalAIAssistantError.unauthenticated))
                return
            }

            let sessionId =
                AuthManager.shared.userId ?? DeviceIDManager.shared.getDeviceId()
                ?? UUID().uuidString

            do {
                let output = try await localAIAssistantService.sendMessage(
                    message: message,
                    sessionId: sessionId,
                    jwt: jwt
                )
                completion(.success(mapLocalOutputToChatData(output)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func sendMessageWithBackend(
        message: String,
        onStreamEvent: (@Sendable (AIChatStreamEvent) -> Void)?,
        completion: @escaping @Sendable (Result<AIChatData, Error>) -> Void
    ) {
        let jwt = AuthManager.shared.getAccessToken()
        let deviceId = DeviceIDManager.shared.getDeviceId()

        Task {
            if onStreamEvent != nil {
                await MainActor.run {
                    onStreamEvent?(.started)
                }
            }

            do {
                let result = try await backendClient.streamMessage(
                    message: message,
                    deviceId: deviceId,
                    jwt: jwt,
                    onChunk: { text in
                        await MainActor.run {
                            onStreamEvent?(.partialText(text))
                        }
                    }
                )

                await MainActor.run {
                    completion(.success(result))
                }
            } catch {
                do {
                    // Fallback a query HTTP para mantener compatibilidad si WS no está disponible.
                    let fallback = try await backendClient.queryMessage(
                        message: message,
                        deviceId: deviceId,
                        jwt: jwt
                    )
                    await MainActor.run {
                        completion(.success(fallback))
                    }
                } catch {
                    await MainActor.run {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    private func mapLocalOutputToChatData(_ output: LocalAIAssistantOutput) -> AIChatData {
        let products = output.products.map {
            AIChatProductEntity(
                id: $0.id,
                name: $0.name,
                description: $0.description,
                price: $0.price,
                currency: $0.currency,
                imageUrl: $0.imageUrl,
                availability: $0.availability,
                branchName: $0.branchName,
                branchAvatarUrl: $0.branchAvatarUrl,
                branchAddress: $0.branchAddress,
                branchPhone: $0.branchPhone,
                reason: $0.reason
            )
        }

        let branches = output.branches.map {
            AIChatBranchEntity(
                id: $0.id,
                name: $0.name,
                address: $0.address,
                phone: $0.phone,
                status: $0.status,
                avatarUrl: $0.avatarUrl,
                coordinates: AIChatCoordinates(
                    type: $0.coordinatesType, coordinates: $0.coordinates),
                reason: $0.reason
            )
        }

        return AIChatData(
            responseType: output.responseType,
            aiText: output.aiText,
            productEntities: products,
            branchEntities: branches,
            confidence: output.confidence
        )
    }
}

private actor AIChatBackendClient {
    private let endpointURL: URL
    private let webSocketURL: URL
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    init(baseURL: String) {
        let httpURL = URL(string: "\(baseURL)/graphql") ?? URL(string: "https://llegobackend-production.up.railway.app/graphql")!
        endpointURL = httpURL

        if var components = URLComponents(url: httpURL, resolvingAgainstBaseURL: false) {
            components.scheme = components.scheme == "https" ? "wss" : "ws"
            webSocketURL = components.url ?? httpURL
        } else {
            webSocketURL = httpURL
        }
    }

    func queryMessage(
        message: String,
        deviceId: String?,
        jwt: String?
    ) async throws -> AIChatData {
        let requestPayload = GraphQLHTTPRequest(
            query: Self.aiChatQuery,
            variables: .init(message: message, deviceId: deviceId, jwt: jwt)
        )

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try jsonEncoder.encode(requestPayload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "AIChat",
                code: -10,
                userInfo: [NSLocalizedDescriptionKey: "No fue posible conectar con AI Chat."]
            )
        }

        let decoded = try jsonDecoder.decode(AIChatQueryHTTPResponse.self, from: data)

        if let graphqlError = decoded.errors?.first {
            throw backendError(from: graphqlError)
        }

        guard let result = decoded.data?.aiChat else {
            throw NSError(
                domain: "AIChat",
                code: -11,
                userInfo: [NSLocalizedDescriptionKey: "Respuesta vacía del servicio de AI Chat."]
            )
        }

        if let serviceError = result.error {
            throw backendError(from: serviceError)
        }

        guard let success = result.success else {
            throw NSError(
                domain: "AIChat",
                code: -12,
                userInfo: [NSLocalizedDescriptionKey: "No se pudo procesar la respuesta del asistente."]
            )
        }

        return mapSuccessPayloadToChatData(success)
    }

    func streamMessage(
        message: String,
        deviceId: String?,
        jwt: String?,
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws -> AIChatData {
        let request = URLRequest(url: webSocketURL)
        let webSocket = URLSession.shared.webSocketTask(with: request, protocols: ["graphql-transport-ws"])
        webSocket.resume()

        defer {
            webSocket.cancel(with: .normalClosure, reason: nil)
        }

        try await sendWebSocket(
            webSocket,
            payload: GraphQLWSMessage(
                type: "connection_init",
                payload: [:]
            )
        )

        var gotAck = false
        var latestText = ""
        var finalChunk: AIChatStreamChunkPayload?
        let operationId = UUID().uuidString

        while !gotAck {
            let message = try await webSocket.receive()
            if case .string(let text) = message,
               let wsMessage = decodeWebSocketMessage(text: text),
               wsMessage.type == "connection_ack"
            {
                gotAck = true
            }
        }

        try await sendWebSocket(
            webSocket,
            payload: GraphQLWSMessage(
                id: operationId,
                type: "subscribe",
                payload: [
                    "query": Self.aiChatStreamSubscription,
                    "variables": GraphQLWSVariables(
                        message: message,
                        deviceId: deviceId,
                        jwt: jwt
                    ).dictionary
                ]
            )
        )

        var shouldContinue = true
        while shouldContinue {
            let message = try await webSocket.receive()

            guard case .string(let text) = message,
                  let wsMessage = decodeWebSocketMessage(text: text)
            else {
                continue
            }

            switch wsMessage.type {
            case "next":
                guard wsMessage.id == operationId,
                      let payload = wsMessage.payload,
                      let payloadData = payload["data"] as? [String: Any]
                else {
                    continue
                }

                let data = try JSONSerialization.data(withJSONObject: payloadData)
                let decoded = try jsonDecoder.decode(AIChatStreamDataContainer.self, from: data)

                if let streamError = decoded.aiChatStream?.error {
                    throw backendError(from: streamError)
                }

                guard let chunk = decoded.aiChatStream else {
                    continue
                }

                if let accumulated = chunk.accumulatedText, !accumulated.isEmpty {
                    latestText = accumulated
                } else if let delta = chunk.delta {
                    latestText += delta
                }

                await onChunk(latestText)

                if chunk.isFinal == true {
                    finalChunk = chunk
                    shouldContinue = false
                }

            case "error":
                if let payload = wsMessage.payload,
                   let firstError = payload["message"] as? String
                {
                    throw NSError(
                        domain: "AIChat",
                        code: -13,
                        userInfo: [NSLocalizedDescriptionKey: firstError]
                    )
                }
                throw NSError(
                    domain: "AIChat",
                    code: -14,
                    userInfo: [NSLocalizedDescriptionKey: "Error en streaming de AI Chat."]
                )

            case "complete":
                if wsMessage.id == operationId {
                    shouldContinue = false
                }

            default:
                continue
            }
        }

        try? await sendWebSocket(
            webSocket,
            payload: GraphQLWSMessage(id: operationId, type: "complete")
        )

        let products = mapProductEntities(finalChunk?.suggestedProducts ?? [])
        let aiText = finalChunk?.accumulatedText?.isEmpty == false
            ? finalChunk?.accumulatedText ?? latestText
            : latestText

        return AIChatData(
            responseType: products.isEmpty ? "general_response" : "search_products",
            aiText: aiText,
            productEntities: products,
            branchEntities: [],
            confidence: finalChunk?.confidence ?? 0
        )
    }

    private func sendWebSocket(_ socket: URLSessionWebSocketTask, payload: GraphQLWSMessage) async throws {
        let data = try jsonEncoder.encode(payload)
        let text = String(data: data, encoding: .utf8) ?? "{}"
        try await socket.send(.string(text))
    }

    private func decodeWebSocketMessage(text: String) -> GraphQLWSIncomingMessage? {
        guard let data = text.data(using: .utf8) else {
            return nil
        }
        return try? jsonDecoder.decode(GraphQLWSIncomingMessage.self, from: data)
    }

    private func mapSuccessPayloadToChatData(_ payload: AIChatSuccessPayload) -> AIChatData {
        AIChatData(
            responseType: payload.responseType,
            aiText: payload.aiText,
            productEntities: mapProductEntities(payload.suggestedProducts),
            branchEntities: mapBranchEntities(payload.suggestedBranches),
            confidence: payload.confidence
        )
    }

    private func mapProductEntities(_ products: [AIChatSuggestedProductPayload]) -> [AIChatProductEntity] {
        products.map { suggestion in
            let product = suggestion.product
            return AIChatProductEntity(
                id: product.id,
                name: product.name,
                description: product.description,
                price: product.price,
                currency: product.currency,
                imageUrl: product.imageUrl ?? product.image ?? "",
                availability: product.availability,
                branchName: suggestion.branchName,
                branchAvatarUrl: suggestion.branchAvatarUrl,
                branchAddress: suggestion.branchAddress,
                branchPhone: suggestion.branchPhone,
                reason: suggestion.reason
            )
        }
    }

    private func mapBranchEntities(_ branches: [AIChatSuggestedBranchPayload]) -> [AIChatBranchEntity] {
        branches.map { suggestion in
            let branch = suggestion.branch
            return AIChatBranchEntity(
                id: branch.id,
                name: branch.name,
                address: branch.address ?? "",
                phone: branch.phone,
                status: branch.status ?? "",
                avatarUrl: branch.avatarUrl,
                coordinates: AIChatCoordinates(
                    type: branch.coordinates.type,
                    coordinates: branch.coordinates.coordinates
                ),
                reason: suggestion.reason
            )
        }
    }

    private func backendError(from payload: AIChatErrorPayload) -> AIChatBackendError {
        AIChatBackendError(
            code: AIChatBackendErrorCode(rawValue: payload.code) ?? .unknown,
            quota: payload.quota.map {
                AIChatQuotaInfo(
                    source: $0.source,
                    limit: $0.limit,
                    used: $0.used,
                    remaining: $0.remaining
                )
            },
            retryAfter: payload.retryAfter,
            fallbackMessage: payload.message
        )
    }

    private func backendError(from payload: GraphQLErrorPayload) -> AIChatBackendError {
        AIChatBackendError(
            code: AIChatBackendErrorCode(rawValue: payload.extensions?.code ?? "") ?? .unknown,
            quota: payload.extensions?.quota.map {
                AIChatQuotaInfo(
                    source: $0.source,
                    limit: $0.limit,
                    used: $0.used,
                    remaining: $0.remaining
                )
            },
            retryAfter: payload.extensions?.retryAfter,
            fallbackMessage: payload.message
        )
    }

    private static let aiChatQuery = """
    query AIChat($message: String!, $deviceId: String, $jwt: String) {
      aiChat(input: { message: $message, deviceId: $deviceId }, jwt: $jwt) {
        success {
          responseType
          aiText
          suggestedProducts {
            product {
              id
              name
              description
              price
              currency
              imageUrl
              image
              availability
            }
            reason
            branchName
            branchAvatarUrl
            branchAddress
            branchPhone
          }
          suggestedBranches {
            branch {
              id
              name
              address
              phone
              status
              avatarUrl
              coordinates {
                type
                coordinates
              }
            }
            reason
          }
          confidence
        }
        error {
          code
          message
          quota {
            source
            limit
            used
            remaining
          }
          retryAfter
        }
      }
    }
    """

    private static let aiChatStreamSubscription = """
    subscription AIChatStream($message: String!, $deviceId: String, $jwt: String) {
      aiChatStream(input: { message: $message, deviceId: $deviceId }, jwt: $jwt) {
        delta
        accumulatedText
        isFinal
        suggestedProducts {
          product {
            id
            name
            description
            price
            currency
            imageUrl
            image
            availability
          }
          reason
          branchName
          branchAvatarUrl
          branchAddress
          branchPhone
        }
        confidence
        error {
          code
          message
        }
      }
    }
    """
}

private struct GraphQLHTTPRequest: Encodable {
    let query: String
    let variables: GraphQLHTTPVariables
}

private struct GraphQLHTTPVariables: Encodable {
    let message: String
    let deviceId: String?
    let jwt: String?
}

private struct AIChatQueryHTTPResponse: Decodable {
    let data: AIChatQueryResponseData?
    let errors: [GraphQLErrorPayload]?
}

private struct AIChatQueryResponseData: Decodable {
    let aiChat: AIChatQueryResultPayload?
}

private struct AIChatQueryResultPayload: Decodable {
    let success: AIChatSuccessPayload?
    let error: AIChatErrorPayload?
}

private struct AIChatSuccessPayload: Decodable {
    let responseType: String
    let aiText: String
    let suggestedProducts: [AIChatSuggestedProductPayload]
    let suggestedBranches: [AIChatSuggestedBranchPayload]
    let confidence: Double
}

private struct AIChatSuggestedProductPayload: Decodable {
    let product: AIChatProductPayload
    let reason: String?
    let branchName: String?
    let branchAvatarUrl: String?
    let branchAddress: String?
    let branchPhone: String?
}

private struct AIChatProductPayload: Decodable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let currency: String
    let imageUrl: String?
    let image: String?
    let availability: Bool
}

private struct AIChatSuggestedBranchPayload: Decodable {
    let branch: AIChatBranchPayload
    let reason: String?
}

private struct AIChatBranchPayload: Decodable {
    let id: String
    let name: String
    let address: String?
    let phone: String
    let status: String?
    let avatarUrl: String?
    let coordinates: AIChatCoordinatesPayload
}

private struct AIChatCoordinatesPayload: Decodable {
    let type: String
    let coordinates: [Double]
}

private struct AIChatErrorPayload: Decodable {
    let code: String
    let message: String
    let quota: AIChatQuotaPayload?
    let retryAfter: Int?
}

private struct AIChatQuotaPayload: Decodable {
    let source: String?
    let limit: Int?
    let used: Int?
    let remaining: Int?
}

private struct GraphQLErrorPayload: Decodable {
    let message: String
    let extensions: GraphQLErrorExtensions?
}

private struct GraphQLErrorExtensions: Decodable {
    let code: String?
    let quota: AIChatQuotaPayload?
    let retryAfter: Int?
}

private struct GraphQLWSMessage: Encodable {
    let id: String?
    let type: String
    let payload: [String: AnyEncodable]?

    init(id: String? = nil, type: String, payload: [String: Any] = [:]) {
        self.id = id
        self.type = type
        self.payload = payload.mapValues { AnyEncodable($0) }
    }
}

private struct GraphQLWSVariables {
    let message: String
    let deviceId: String?
    let jwt: String?

    var dictionary: [String: Any] {
        [
            "message": message,
            "deviceId": deviceId as Any,
            "jwt": jwt as Any,
        ]
    }
}

private struct GraphQLWSIncomingMessage: Decodable {
    let id: String?
    let type: String
    let payload: [String: Any]?

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)

        if let payloadObject = try container.decodeIfPresent(JSONValue.self, forKey: .payload) {
            payload = payloadObject.objectValue
        } else {
            payload = nil
        }
    }
}

private struct AIChatStreamDataContainer: Decodable {
    let aiChatStream: AIChatStreamChunkPayload?
}

private struct AIChatStreamChunkPayload: Decodable {
    let delta: String?
    let accumulatedText: String?
    let isFinal: Bool?
    let suggestedProducts: [AIChatSuggestedProductPayload]?
    let confidence: Double?
    let error: AIChatErrorPayload?
}

private struct AnyEncodable: Encodable {
    private let encodeFunction: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        encodeFunction = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunction(encoder)
    }
}

private enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.typeMismatch(
                JSONValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported JSON value"
                )
            )
        }
    }

    var objectValue: [String: Any]? {
        guard case .object(let value) = self else {
            return nil
        }
        return value.mapValues { $0.anyValue }
    }

    var anyValue: Any {
        switch self {
        case .string(let value): return value
        case .number(let value): return value
        case .bool(let value): return value
        case .object(let value): return value.mapValues { $0.anyValue }
        case .array(let value): return value.map { $0.anyValue }
        case .null: return NSNull()
        }
    }
}

// MARK: - Models específicos de ConversationalSearchRepository

enum AIChatStreamEvent: Sendable {
    case started
    case partialText(String)
}

struct AIChatData: Sendable {
    let responseType: String
    let aiText: String
    let productEntities: [AIChatProductEntity]
    let branchEntities: [AIChatBranchEntity]
    let confidence: Double
}

enum AIChatBackendErrorCode: String, Sendable {
    case freeQuotaExceeded = "AI_FREE_QUOTA_EXCEEDED"
    case quotaExceeded = "AI_QUOTA_EXCEEDED"
    case deviceIdRequired = "AI_DEVICE_ID_REQUIRED"
    case messageTooLong = "AI_MESSAGE_TOO_LONG"
    case dailyDeviceQuotaExceeded = "AI_DAILY_DEVICE_QUOTA_EXCEEDED"
    case rateLimitExceeded = "AI_RATE_LIMIT_EXCEEDED"
    case serviceError = "AI_SERVICE_ERROR"
    case invalidRequest = "AI_INVALID_REQUEST"
    case unknown = "UNKNOWN"
}

struct AIChatQuotaInfo: Sendable {
    let source: String?
    let limit: Int?
    let used: Int?
    let remaining: Int?
}

struct AIChatBackendError: LocalizedError, Sendable {
    let code: AIChatBackendErrorCode
    let quota: AIChatQuotaInfo?
    let retryAfter: Int?
    let fallbackMessage: String

    var errorDescription: String? {
        fallbackMessage
    }
}

struct AIChatProductEntity: Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let currency: String
    let imageUrl: String
    let availability: Bool
    let branchName: String?
    let branchAvatarUrl: String?
    let branchAddress: String?
    let branchPhone: String?
    let reason: String?
}

struct AIChatBranchEntity: Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let address: String
    let phone: String
    let status: String
    let avatarUrl: String?
    let coordinates: AIChatCoordinates
    let reason: String?
}

struct AIChatCoordinates: Sendable, Hashable {
    let type: String
    let coordinates: [Double]
}

struct AIChatPaymentEntity: Identifiable, Sendable, Hashable {
    let id: String
    let currency: String
    let method: String
}

// MARK: - Extensions

extension AIChatBranchEntity {
    // Convertir AIChatBranchEntity a Store para navegación
    func toStore() -> Store {
        // Calcular ETA basado en coordenadas (placeholder)
        let etaMinutes = Int.random(in: 15...45)

        // URLs de placeholder para logo y banner
        let logoUrl =
            "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center"
        let bannerUrl =
            "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"

        return Store(
            id: id,
            name: name,
            etaMinutes: etaMinutes,
            logoUrl: logoUrl,
            bannerUrl: bannerUrl,
            address: address,
            rating: nil
        )
    }
}
