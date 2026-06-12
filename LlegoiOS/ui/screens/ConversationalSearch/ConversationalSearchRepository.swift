//
//  ConversationalSearchRepository.swift
//  LlegoiOS
//
//  Repository para manejar las queries/subscriptions de AI Chat
//

import Foundation

@MainActor
final class ConversationalSearchRepository {
    private let backendClient = AIChatBackendClient(baseURL: ApolloClientManager.baseURL)
    private var activeBackendTask: Task<Void, Never>?
    private var activeBackendRequestId: UUID?

    func sendMessage(
        message: String,
        provider: ConversationalAIProvider,
        onStreamEvent: (@Sendable (AIChatStreamEvent) -> Void)? = nil,
        completion: @escaping @Sendable (Result<AIChatData, Error>) -> Void
    ) {
        sendMessageWithBackend(
            message: message,
            onStreamEvent: onStreamEvent,
            completion: completion
        )
    }

    private func sendMessageWithBackend(
        message: String,
        onStreamEvent: (@Sendable (AIChatStreamEvent) -> Void)?,
        completion: @escaping @Sendable (Result<AIChatData, Error>) -> Void
    ) {
        let jwt = AuthManager.shared.getAccessToken()
        let deviceId = DeviceIDManager.shared.getDeviceId()
        let requestId = UUID()

        activeBackendTask?.cancel()
        activeBackendRequestId = requestId

        activeBackendTask = Task {
            if onStreamEvent != nil {
                await MainActor.run {
                    guard self.activeBackendRequestId == requestId else { return }
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
                            guard self.activeBackendRequestId == requestId else { return }
                            onStreamEvent?(.partialText(text))
                        }
                    }
                )

                await MainActor.run {
                    guard self.activeBackendRequestId == requestId else { return }
                    completion(.success(result))
                    self.activeBackendTask = nil
                    self.activeBackendRequestId = nil
                }
            } catch {
                if Task.isCancelled || error is CancellationError {
                    return
                }

                do {
                    // Fallback a query HTTP para mantener compatibilidad si WS no está disponible.
                    let fallback = try await backendClient.queryMessage(
                        message: message,
                        deviceId: deviceId,
                        jwt: jwt
                    )
                    await MainActor.run {
                        guard self.activeBackendRequestId == requestId else { return }
                        completion(.success(fallback))
                        self.activeBackendTask = nil
                        self.activeBackendRequestId = nil
                    }
                } catch {
                    if Task.isCancelled || error is CancellationError {
                        return
                    }
                    await MainActor.run {
                        guard self.activeBackendRequestId == requestId else { return }
                        completion(.failure(error))
                        self.activeBackendTask = nil
                        self.activeBackendRequestId = nil
                    }
                }
            }
        }
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
        let webSocket = URLSession.shared.webSocketTask(
            with: webSocketURL,
            protocols: ["graphql-transport-ws"]
        )
        webSocket.resume()

        defer {
            webSocket.cancel(with: URLSessionWebSocketTask.CloseCode.normalClosure, reason: nil)
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
                        input: GraphQLWSInput(
                            message: message,
                            deviceId: deviceId,
                            stream: true
                        ),
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

        let suggestedProductIds = finalChunk?.suggestedProductIds ?? []
        let suggestedBranchIds = finalChunk?.suggestedBranchIds ?? []
        let products = try await hydrateProductsByIds(
            ids: suggestedProductIds,
            jwt: jwt
        )
        var branches = uniqueBranchesFromProducts(products)
        if !suggestedBranchIds.isEmpty {
            let existingIds = Set(branches.map(\.id))
            let missingBranchIds = suggestedBranchIds.filter { !existingIds.contains($0) }
            if !missingBranchIds.isEmpty {
                let extraBranches = try await hydrateBranchesByIdsAlias(ids: missingBranchIds, jwt: jwt)
                branches.append(contentsOf: extraBranches)
            }
        }
        let aiText = finalChunk?.accumulatedText?.isEmpty == false
            ? finalChunk?.accumulatedText ?? latestText
            : latestText

        let responseType: String
        if !products.isEmpty {
            responseType = "search_products"
        } else if !branches.isEmpty {
            responseType = "search_branches"
        } else {
            responseType = "general_response"
        }

        return AIChatData(
            responseType: responseType,
            aiText: aiText,
            productEntities: products,
            branchEntities: branches,
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
                branchId: nil,
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
                status: branch.status,
                avatarUrl: branch.avatarUrl,
                coordinates: AIChatCoordinates(
                    type: branch.coordinates.type,
                    coordinates: branch.coordinates.coordinates
                ),
                reason: suggestion.reason
            )
        }
    }

    private func uniqueBranchesFromProducts(_ products: [AIChatProductEntity]) -> [AIChatBranchEntity] {
        var seen: Set<String> = []
        var result: [AIChatBranchEntity] = []

        for product in products {
            guard let branchId = product.branchId else { continue }
            guard !seen.contains(branchId) else { continue }
            seen.insert(branchId)
            result.append(
                AIChatBranchEntity(
                    id: branchId,
                    name: product.branchName ?? "Sucursal",
                    address: product.branchAddress ?? "",
                    phone: product.branchPhone ?? "",
                    status: nil,
                    avatarUrl: product.branchAvatarUrl,
                    coordinates: AIChatCoordinates(type: "Point", coordinates: []),
                    reason: nil
                )
            )
        }

        return result
    }

    private func hydrateProductsByIds(ids: [String], jwt: String?) async throws -> [AIChatProductEntity] {
        guard !ids.isEmpty else { return [] }

        let payload = GenericGraphQLRequest(
            query: Self.productsByIdsQuery,
            variables: [
                "ids": AnyEncodable(ids),
                "jwt": AnyEncodable(jwt as Any),
            ]
        )

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try jsonEncoder.encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "AIChat",
                code: -20,
                userInfo: [NSLocalizedDescriptionKey: "No fue posible hidratar productos por IDs."]
            )
        }

        let decoded = try jsonDecoder.decode(ProductsByIdsHTTPResponse.self, from: data)
        if let error = decoded.errors?.first {
            throw backendError(from: error)
        }

        let edges = decoded.data?.products.edges ?? []
        var byId: [String: AIChatProductEntity] = [:]
        for edge in edges {
            let node = edge.node
            let product = AIChatProductEntity(
                id: node.id,
                branchId: node.branchId,
                name: node.name,
                description: "",
                price: node.price,
                currency: node.currency,
                imageUrl: node.imageUrl,
                availability: node.availability,
                branchName: node.branch?.name,
                branchAvatarUrl: node.branch?.avatarUrl,
                branchAddress: node.branch?.address,
                branchPhone: node.branch?.phone,
                reason: nil
            )
            byId[product.id] = product
        }

        return ids.compactMap { byId[$0] }
    }

    private func hydrateBranchesByIdsAlias(ids: [String], jwt: String?) async throws -> [AIChatBranchEntity] {
        guard !ids.isEmpty else { return [] }

        var variableDefs: [String] = ["$jwt: String"]
        var fields: [String] = []
        var variables: [String: AnyEncodable] = ["jwt": AnyEncodable(jwt as Any)]

        for (index, id) in ids.enumerated() {
            let variableName = "id\(index)"
            variableDefs.append("$\(variableName): String!")
            fields.append(
                """
                b\(index): branch(id: $\(variableName), jwt: $jwt) {
                  id
                  name
                  avatarUrl
                  address
                  phone
                  status
                  coordinates { type coordinates }
                }
                """
            )
            variables[variableName] = AnyEncodable(id)
        }

        let query = """
        query BranchesByIdsAlias(\(variableDefs.joined(separator: ", "))) {
          \(fields.joined(separator: "\n"))
        }
        """

        let payload = GenericGraphQLRequest(query: query, variables: variables)
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try jsonEncoder.encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "AIChat",
                code: -21,
                userInfo: [NSLocalizedDescriptionKey: "No fue posible hidratar sucursales por IDs."]
            )
        }

        let decoded = try jsonDecoder.decode(BranchesByAliasHTTPResponse.self, from: data)
        if let error = decoded.errors?.first {
            throw backendError(from: error)
        }

        var result: [AIChatBranchEntity] = []
        for id in ids {
            guard let rawBranch = decoded.data?.first(where: { $0.value.id == id })?.value else {
                continue
            }
            result.append(
                AIChatBranchEntity(
                    id: rawBranch.id,
                    name: rawBranch.name,
                    address: rawBranch.address ?? "",
                    phone: rawBranch.phone ?? "",
                    status: rawBranch.status ?? "",
                    avatarUrl: rawBranch.avatarUrl,
                    coordinates: AIChatCoordinates(
                        type: rawBranch.coordinates?.type ?? "Point",
                        coordinates: rawBranch.coordinates?.coordinates ?? []
                    ),
                    reason: nil
                )
            )
        }
        return result
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
          maxWords
          wordsCount
        }
      }
    }
    """

    private static let aiChatStreamSubscription = """
    subscription AIChatStream($input: AiAssistantChatInput!, $jwt: String) {
      aiChatStream(input: $input, jwt: $jwt) {
        delta
        accumulatedText
        isFinal
        confidence
        missingFields
        suggestedProductIds
        suggestedBranchIds
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

    private static let productsByIdsQuery = """
    query ProductsByIds($ids: [String!], $jwt: String) {
      products(ids: $ids, first: 50, jwt: $jwt) {
        edges {
          node {
            id
            name
            price
            currency
            availability
            imageUrl
            branchId
            branch {
              id
              name
              avatarUrl
              address
              phone
            }
          }
        }
        pageInfo {
          totalCount
          hasNextPage
        }
      }
    }
    """
}

private struct GraphQLHTTPRequest: Encodable {
    let query: String
    let variables: GraphQLHTTPVariables
}

private struct GenericGraphQLRequest: Encodable {
    let query: String
    let variables: [String: AnyEncodable]
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
    let maxWords: Int?
    let wordsCount: Int?
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
    let input: GraphQLWSInput
    let jwt: String?

    var dictionary: [String: Any] {
        [
            "input": input.dictionary,
            "jwt": jwt as Any,
        ]
    }
}

private struct GraphQLWSInput {
    let message: String
    let deviceId: String?
    let stream: Bool

    var dictionary: [String: Any] {
        [
            "message": message,
            "deviceId": deviceId as Any,
            "stream": stream,
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
    let missingFields: [String]?
    let suggestedProductIds: [String]?
    let suggestedBranchIds: [String]?
    let confidence: Double?
    let error: AIChatErrorPayload?
}

private struct ProductsByIdsHTTPResponse: Decodable {
    let data: ProductsByIdsDataContainer?
    let errors: [GraphQLErrorPayload]?
}

private struct ProductsByIdsDataContainer: Decodable {
    let products: ProductsByIdsConnection
}

private struct ProductsByIdsConnection: Decodable {
    let edges: [ProductsByIdsEdge]
}

private struct ProductsByIdsEdge: Decodable {
    let node: ProductsByIdsNode
}

private struct ProductsByIdsNode: Decodable {
    let id: String
    let branchId: String?
    let name: String
    let price: Double
    let currency: String
    let availability: Bool
    let imageUrl: String
    let branch: ProductsByIdsBranch?
}

private struct ProductsByIdsBranch: Decodable {
    let id: String
    let name: String
    let avatarUrl: String?
    let address: String?
    let phone: String?
}

private struct BranchesByAliasHTTPResponse: Decodable {
    let data: [String: BranchByAliasPayload]?
    let errors: [GraphQLErrorPayload]?
}

private struct BranchByAliasPayload: Decodable {
    let id: String
    let name: String
    let avatarUrl: String?
    let address: String?
    let phone: String?
    let status: String?
    let coordinates: AIChatCoordinatesPayload?
}

private struct AnyEncodable: Encodable {
    private let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let value as String:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case let value as Float:
            try container.encode(value)
        case let value as Bool:
            try container.encode(value)
        case let value as [String: Any]:
            try container.encode(value.mapValues { AnyEncodable($0) })
        case let value as [Any]:
            try container.encode(value.map { AnyEncodable($0) })
        case let value as String?:
            if let value {
                try container.encode(value)
            } else {
                try container.encodeNil()
            }
        default:
            let context = EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Unsupported type for AnyEncodable: \(type(of: value))"
            )
            throw EncodingError.invalidValue(value, context)
        }
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
    let branchId: String?
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
    let status: String?
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
