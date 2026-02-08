//
//  LocalAIAssistantService.swift
//  LlegoiOS
//

import Foundation
import SwiftData

#if canImport(FoundationModels)
    import FoundationModels
#endif

enum AppleIntelligenceSupportStatus: Equatable {
    case available
    case unsupportedDevice
    case notEnabled
    case unavailable(String)

    var isAvailable: Bool {
        if case .available = self {
            return true
        }
        return false
    }

    var userErrorMessage: String {
        switch self {
        case .available:
            return ""
        case .unsupportedDevice:
            return "Tu dispositivo no es compatible. Debe ser iPhone 15 Pro o superior."
        case .notEnabled:
            return "Apple Intelligence está desactivado. Debes activarlo en Configuración."
        case .unavailable(let reason):
            return "Apple Intelligence no está disponible en este momento: \(reason)"
        }
    }
}

enum LocalAIAssistantError: LocalizedError {
    case appleIntelligenceUnsupported
    case appleIntelligenceDisabled
    case appleIntelligenceUnavailable(String)
    case unauthenticated
    case invalidModelResponse
    case semanticSearchFailed(String)
    case contextWindowExceeded

    var errorDescription: String? {
        switch self {
        case .appleIntelligenceUnsupported:
            return
                "Este dispositivo debe ser iPhone 15 Pro o superior para usar Apple Intelligence local."
        case .appleIntelligenceDisabled:
            return "Debes activar Apple Intelligence para usar el modo local."
        case .appleIntelligenceUnavailable(let reason):
            return "Apple Intelligence no está disponible: \(reason)"
        case .unauthenticated:
            return "Necesitas iniciar sesión para usar la búsqueda semántica."
        case .invalidModelResponse:
            return "No se pudo interpretar la respuesta del modelo local."
        case .semanticSearchFailed(let message):
            return "Falló la búsqueda semántica: \(message)"
        case .contextWindowExceeded:
            return "El mensaje y el contexto eran demasiado largos para Apple Intelligence local."
        }
    }
}

struct LocalAIIntentAnalysis: Codable {
    let responseType: String
    let reasoning: String
    let searchQueries: [LocalAISearchQuery]
    let missingInfo: [String]
    let confidence: Double

    init(
        responseType: String = "general_response",
        reasoning: String = "",
        searchQueries: [LocalAISearchQuery] = [],
        missingInfo: [String] = [],
        confidence: Double = 0.0
    ) {
        self.responseType = responseType
        self.reasoning = reasoning
        self.searchQueries = searchQueries
        self.missingInfo = missingInfo
        self.confidence = confidence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        responseType =
            try container.decodeIfPresent(String.self, forKey: .responseType) ?? "general_response"
        reasoning = try container.decodeIfPresent(String.self, forKey: .reasoning) ?? ""
        searchQueries =
            try container.decodeIfPresent([LocalAISearchQuery].self, forKey: .searchQueries) ?? []
        missingInfo = try container.decodeIfPresent([String].self, forKey: .missingInfo) ?? []
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0.0
    }
}

struct LocalAISearchQuery: Codable {
    let collection: String
    let query: String
    let limit: Int
}

struct LocalAIFinalResponse: Codable {
    let responseType: String
    let aiText: String
    let suggestedProductIds: [LocalAIProductSuggestion]
    let suggestedBranchIds: [LocalAIBranchSuggestion]
    let missingFields: [String]
    let confidence: Double

    init(
        responseType: String = "general_response",
        aiText: String = "",
        suggestedProductIds: [LocalAIProductSuggestion] = [],
        suggestedBranchIds: [LocalAIBranchSuggestion] = [],
        missingFields: [String] = [],
        confidence: Double = 0.0
    ) {
        self.responseType = responseType
        self.aiText = aiText
        self.suggestedProductIds = suggestedProductIds
        self.suggestedBranchIds = suggestedBranchIds
        self.missingFields = missingFields
        self.confidence = confidence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        responseType =
            try container.decodeIfPresent(String.self, forKey: .responseType) ?? "general_response"
        aiText = try container.decodeIfPresent(String.self, forKey: .aiText) ?? ""
        suggestedProductIds =
            try container.decodeIfPresent(
                [LocalAIProductSuggestion].self, forKey: .suggestedProductIds) ?? []
        suggestedBranchIds =
            try container.decodeIfPresent(
                [LocalAIBranchSuggestion].self, forKey: .suggestedBranchIds) ?? []
        missingFields = try container.decodeIfPresent([String].self, forKey: .missingFields) ?? []
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0.0
    }
}

struct LocalAIProductSuggestion: Codable {
    let id: String
    let reason: String?
}

struct LocalAIBranchSuggestion: Codable {
    let id: String
    let reason: String?
}

struct LocalAIAssistantOutput {
    let responseType: String
    let aiText: String
    let products: [LocalAIProductEntity]
    let branches: [LocalAIBranchEntity]
    let confidence: Double
}

struct LocalAIProductEntity {
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

struct LocalAIBranchEntity {
    let id: String
    let name: String
    let address: String
    let phone: String
    let status: String
    let avatarUrl: String?
    let coordinatesType: String
    let coordinates: [Double]
    let reason: String?
}

@Model
final class LocalAIChatMessageEntity {
    var id: UUID
    var sessionId: String
    var role: String
    var content: String
    var createdAt: Date

    init(sessionId: String, role: String, content: String, createdAt: Date = .now) {
        self.id = UUID()
        self.sessionId = sessionId
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

struct LocalAIHistoryItem {
    let role: String
    let content: String
}

actor LocalAIConversationStore {
    private let container: ModelContainer

    init() {
        do {
            self.container = try ModelContainer(for: LocalAIChatMessageEntity.self)
        } catch {
            fatalError("No se pudo inicializar SwiftData para chat local: \(error)")
        }
    }

    func addMessage(sessionId: String, role: String, content: String) throws {
        let context = ModelContext(container)
        let message = LocalAIChatMessageEntity(sessionId: sessionId, role: role, content: content)
        context.insert(message)
        try context.save()
    }

    func getConversationHistory(sessionId: String, limit: Int) throws -> [LocalAIHistoryItem] {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<LocalAIChatMessageEntity>(
            predicate: #Predicate { $0.sessionId == sessionId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        let newestFirst = try context.fetch(descriptor)
        return newestFirst.reversed().map { LocalAIHistoryItem(role: $0.role, content: $0.content) }
    }
}

enum SemanticSearchCollection: String, Codable {
    case products = "PRODUCTS"
    case branches = "BRANCHES"
    case businesses = "BUSINESSES"

    init?(localValue: String) {
        switch localValue.lowercased() {
        case "products":
            self = .products
        case "branches":
            self = .branches
        case "businesses":
            self = .businesses
        default:
            return nil
        }
    }
}

struct SemanticSearchResponsePayload: Decodable {
    let collection: String
    let totalResults: Int
    let products: [SemanticSearchProductResult]
    let branches: [SemanticSearchBranchResult]
    let businesses: [SemanticSearchBusinessResult]
}

struct SemanticSearchProductResult: Decodable {
    let score: Double
    let product: SemanticSearchProduct
    let branchName: String?
    let branchAvatarUrl: String?
    let branchAddress: String?
    let branchPhone: String?
}

struct SemanticSearchProduct: Decodable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let currency: String
    let imageUrl: String
    let availability: Bool
}

struct SemanticSearchBranchResult: Decodable {
    let score: Double
    let branch: SemanticSearchBranch
}

struct SemanticSearchBranch: Decodable {
    let id: String
    let name: String
    let address: String?
    let phone: String
    let status: String
    let avatarUrl: String?
    let coordinates: SemanticSearchCoordinates?
}

struct SemanticSearchCoordinates: Decodable {
    let type: String
    let coordinates: [Double]
}

struct SemanticSearchBusinessResult: Decodable {
    let score: Double
    let business: SemanticSearchBusiness
}

struct SemanticSearchBusiness: Decodable {
    let id: String
    let name: String
    let description: String?
    let avatarUrl: String?
}

private struct SemanticSearchGraphQLRequest: Encodable {
    let query: String
    let variables: Variables

    struct Variables: Encodable {
        let query: String
        let collection: String
        let limit: Int
        let jwt: String
    }
}

private struct SemanticSearchGraphQLResponse: Decodable {
    let data: DataContainer?
    let errors: [GraphQLErrorPayload]?

    struct DataContainer: Decodable {
        let semanticSearch: SemanticSearchResponsePayload?
    }
}

private struct GraphQLErrorPayload: Decodable {
    let message: String
}

final class SemanticSearchClient: @unchecked Sendable {
    private let endpointURL: URL
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()

    init(baseURL: String) {
        guard let url = URL(string: "\(baseURL)/graphql") else {
            fatalError("Base URL inválida para semantic search")
        }
        self.endpointURL = url
    }

    func search(
        query: String,
        collection: SemanticSearchCollection,
        limit: Int,
        jwt: String
    ) async throws -> SemanticSearchResponsePayload {
        let queryText = """
            query SemanticSearch($query: String!, $collection: SemanticSearchCollection!, $limit: Int!, $jwt: String!) {
              semanticSearch(query: $query, collection: $collection, limit: $limit, jwt: $jwt) {
                collection
                totalResults
                products {
                  score
                  product {
                    id
                    name
                    description
                    price
                    currency
                    imageUrl
                    availability
                  }
                  branchName
                  branchAvatarUrl
                  branchAddress
                  branchPhone
                }
                branches {
                  score
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
                }
                businesses {
                  score
                  business {
                    id
                    name
                    description
                    avatarUrl
                  }
                }
              }
            }
            """

        let payload = SemanticSearchGraphQLRequest(
            query: queryText,
            variables: .init(
                query: query,
                collection: collection.rawValue,
                limit: max(1, limit),
                jwt: jwt
            )
        )

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try jsonEncoder.encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LocalAIAssistantError.semanticSearchFailed("Respuesta HTTP inválida")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw LocalAIAssistantError.semanticSearchFailed("HTTP \(httpResponse.statusCode)")
        }

        let decoded = try jsonDecoder.decode(SemanticSearchGraphQLResponse.self, from: data)
        if let firstError = decoded.errors?.first {
            throw LocalAIAssistantError.semanticSearchFailed(firstError.message)
        }

        guard let semanticSearch = decoded.data?.semanticSearch else {
            throw LocalAIAssistantError.semanticSearchFailed("No hubo datos en semanticSearch")
        }

        return semanticSearch
    }
}

final class LocalAIAssistantService: @unchecked Sendable {
    static let shared = LocalAIAssistantService()

    private let conversationStore = LocalAIConversationStore()
    private let semanticSearchClient = SemanticSearchClient(baseURL: ApolloClientManager.baseURL)

    private init() {}

    func currentAvailability() -> AppleIntelligenceSupportStatus {
        #if canImport(FoundationModels)
            if #available(iOS 26.0, *) {
                switch SystemLanguageModel.default.availability {
                case .available:
                    return .available
                case .unavailable(let reason):
                    let reasonText = String(describing: reason)
                    if reasonText.localizedCaseInsensitiveContains("deviceNotEligible") {
                        return .unsupportedDevice
                    }
                    if reasonText.localizedCaseInsensitiveContains("appleIntelligenceNotEnabled") {
                        return .notEnabled
                    }
                    return .unavailable(reasonText)
                @unknown default:
                    return .unavailable("Estado desconocido")
                }
            }
            return .unsupportedDevice
        #else
            return .unsupportedDevice
        #endif
    }

    func sendMessage(message: String, sessionId: String, jwt: String) async throws
        -> LocalAIAssistantOutput
    {
        let availability = currentAvailability()
        switch availability {
        case .available:
            break
        case .unsupportedDevice:
            throw LocalAIAssistantError.appleIntelligenceUnsupported
        case .notEnabled:
            throw LocalAIAssistantError.appleIntelligenceDisabled
        case .unavailable(let reason):
            throw LocalAIAssistantError.appleIntelligenceUnavailable(reason)
        }

        try await conversationStore.addMessage(sessionId: sessionId, role: "user", content: message)
        let history = try await conversationStore.getConversationHistory(
            sessionId: sessionId, limit: 8)
        let historyText = buildHistoryText(history, maxMessages: 6, maxCharsPerMessage: 220)

        let intent = try await analyzeIntent(message: message, historyText: historyText)
        let context = try await executeSearches(intent: intent, originalMessage: message, jwt: jwt)
        let response = try await generateFinalResponse(
            message: message,
            historyText: historyText,
            intent: intent,
            context: context
        )

        try await conversationStore.addMessage(
            sessionId: sessionId, role: "assistant", content: response.aiText)

        return response
    }

    private func executeSearches(
        intent: LocalAIIntentAnalysis,
        originalMessage: String,
        jwt: String
    ) async throws -> [SemanticSearchCollection: SemanticSearchResponsePayload] {
        var output: [SemanticSearchCollection: SemanticSearchResponsePayload] = [:]
        let queries: [LocalAISearchQuery]

        if intent.searchQueries.isEmpty {
            // Fallback defensivo: si el modelo no pidió búsquedas, ejecutamos las 2 colecciones principales.
            queries = [
                LocalAISearchQuery(collection: "products", query: originalMessage, limit: 10),
                LocalAISearchQuery(collection: "branches", query: originalMessage, limit: 6),
            ]
        } else {
            queries = intent.searchQueries
        }

        for query in queries {
            guard let collection = SemanticSearchCollection(localValue: query.collection) else {
                continue
            }
            let payload = try await semanticSearchClient.search(
                query: query.query,
                collection: collection,
                limit: query.limit,
                jwt: jwt
            )
            if let existing = output[collection] {
                output[collection] = mergeSemanticPayload(
                    existing: existing, incoming: payload, collection: collection)
            } else {
                output[collection] = payload
            }
        }

        // Fallback adicional para consultas compuestas ("batido y pizza"): reintenta por término
        // solo si productos quedó vacío.
        if output[.products]?.products.isEmpty ?? true {
            let fallbackTerms = extractFallbackSearchTerms(from: originalMessage)
            for term in fallbackTerms {
                let payload = try await semanticSearchClient.search(
                    query: term,
                    collection: .products,
                    limit: 8,
                    jwt: jwt
                )
                if let existing = output[.products] {
                    output[.products] = mergeSemanticPayload(
                        existing: existing, incoming: payload, collection: .products)
                } else {
                    output[.products] = payload
                }
            }
        }

        return output
    }

    private func buildContextText(
        _ context: [SemanticSearchCollection: SemanticSearchResponsePayload]
    ) -> String {
        var lines: [String] = []

        if let products = context[.products] {
            lines.append("Available Products:")
            for item in products.products.prefix(8) {
                lines.append(
                    "- ID: \(item.product.id), Name: \(trimmed(item.product.name, max: 48)), Price: \(item.product.currency) \(item.product.price), Branch: \(trimmed(item.branchName ?? "N/A", max: 40)), Available: \(item.product.availability)"
                )
            }
        }

        if let branches = context[.branches] {
            lines.append("Available Branches:")
            for item in branches.branches.prefix(6) {
                lines.append(
                    "- ID: \(item.branch.id), Name: \(trimmed(item.branch.name, max: 48)), Address: \(trimmed(item.branch.address ?? "N/A", max: 72)), Status: \(item.branch.status)"
                )
            }
        }

        if let businesses = context[.businesses] {
            lines.append("Available Businesses:")
            for item in businesses.businesses {
                lines.append(
                    "- ID: \(item.business.id), Name: \(item.business.name), Description: \(item.business.description ?? "N/A")"
                )
            }
        }

        if lines.isEmpty {
            return "No search results were found."
        }
        // Límite defensivo para evitar exceder ventana del modelo.
        let compact = lines.joined(separator: "\n")
        return trimmed(compact, max: 2400)
    }

    private func mapFinalResponse(
        _ final: LocalAIFinalResponse,
        context: [SemanticSearchCollection: SemanticSearchResponsePayload]
    ) -> LocalAIAssistantOutput {
        let productResults = context[.products]?.products ?? []
        let branchResults = context[.branches]?.branches ?? []
        let productsById = Dictionary(
            uniqueKeysWithValues: productResults.map { ($0.product.id, $0) })
        let branchesById = Dictionary(
            uniqueKeysWithValues: branchResults.map { ($0.branch.id, $0) })

        var products: [LocalAIProductEntity] = final.suggestedProductIds.compactMap { suggestion in
            guard let item = productsById[suggestion.id] else { return nil }
            return LocalAIProductEntity(
                id: item.product.id,
                name: item.product.name,
                description: item.product.description,
                price: item.product.price,
                currency: item.product.currency,
                imageUrl: item.product.imageUrl,
                availability: item.product.availability,
                branchName: item.branchName,
                branchAvatarUrl: item.branchAvatarUrl,
                branchAddress: item.branchAddress,
                branchPhone: item.branchPhone,
                reason: suggestion.reason
            )
        }

        var branches: [LocalAIBranchEntity] = final.suggestedBranchIds.compactMap { suggestion in
            guard let item = branchesById[suggestion.id] else { return nil }
            return LocalAIBranchEntity(
                id: item.branch.id,
                name: item.branch.name,
                address: item.branch.address ?? "",
                phone: item.branch.phone,
                status: item.branch.status,
                avatarUrl: item.branch.avatarUrl,
                coordinatesType: item.branch.coordinates?.type ?? "Point",
                coordinates: item.branch.coordinates?.coordinates ?? [],
                reason: suggestion.reason
            )
        }

        // Fallback defensivo: si el modelo no devolvió IDs sugeridos, usar top resultados de semanticSearch.
        if products.isEmpty, final.responseType.lowercased() == "search_products" {
            products = productResults.prefix(6).map { item in
                LocalAIProductEntity(
                    id: item.product.id,
                    name: item.product.name,
                    description: item.product.description,
                    price: item.product.price,
                    currency: item.product.currency,
                    imageUrl: item.product.imageUrl,
                    availability: item.product.availability,
                    branchName: item.branchName,
                    branchAvatarUrl: item.branchAvatarUrl,
                    branchAddress: item.branchAddress,
                    branchPhone: item.branchPhone,
                    reason: "Coincidencia semántica"
                )
            }
        }

        if branches.isEmpty, final.responseType.lowercased() == "search_branches" {
            branches = branchResults.prefix(6).map { item in
                LocalAIBranchEntity(
                    id: item.branch.id,
                    name: item.branch.name,
                    address: item.branch.address ?? "",
                    phone: item.branch.phone,
                    status: item.branch.status,
                    avatarUrl: item.branch.avatarUrl,
                    coordinatesType: item.branch.coordinates?.type ?? "Point",
                    coordinates: item.branch.coordinates?.coordinates ?? [],
                    reason: "Coincidencia semántica"
                )
            }
        }

        let responseText = normalizedResponseText(
            original: final.aiText,
            responseType: final.responseType,
            products: products,
            branches: branches
        )

        return LocalAIAssistantOutput(
            responseType: final.responseType,
            aiText: responseText,
            products: products,
            branches: branches,
            confidence: final.confidence
        )
    }

    private func mergeSemanticPayload(
        existing: SemanticSearchResponsePayload,
        incoming: SemanticSearchResponsePayload,
        collection: SemanticSearchCollection
    ) -> SemanticSearchResponsePayload {
        switch collection {
        case .products:
            var seen = Set<String>()
            let merged = (existing.products + incoming.products).filter {
                seen.insert($0.product.id).inserted
            }
            return SemanticSearchResponsePayload(
                collection: incoming.collection,
                totalResults: merged.count,
                products: merged,
                branches: existing.branches,
                businesses: existing.businesses
            )
        case .branches:
            var seen = Set<String>()
            let merged = (existing.branches + incoming.branches).filter {
                seen.insert($0.branch.id).inserted
            }
            return SemanticSearchResponsePayload(
                collection: incoming.collection,
                totalResults: merged.count,
                products: existing.products,
                branches: merged,
                businesses: existing.businesses
            )
        case .businesses:
            var seen = Set<String>()
            let merged = (existing.businesses + incoming.businesses).filter {
                seen.insert($0.business.id).inserted
            }
            return SemanticSearchResponsePayload(
                collection: incoming.collection,
                totalResults: merged.count,
                products: existing.products,
                branches: existing.branches,
                businesses: merged
            )
        }
    }

    private func extractFallbackSearchTerms(from text: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",;|/")
        let normalized =
            text
            .replacingOccurrences(of: " y ", with: ",", options: .caseInsensitive)
            .replacingOccurrences(of: " and ", with: ",", options: .caseInsensitive)
        let rawTerms =
            normalized
            .components(separatedBy: separators)
            .flatMap { $0.components(separatedBy: " ") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let stopWords = Set([
            "quiero", "dame", "busca", "buscar", "necesito", "por", "favor", "un", "una", "de",
            "la", "el", "los", "las",
        ])
        var seen = Set<String>()
        return
            rawTerms
            .map { $0.lowercased() }
            .filter { $0.count > 2 && !stopWords.contains($0) }
            .filter { seen.insert($0).inserted }
    }

    private func normalizedResponseText(
        original: String,
        responseType: String,
        products: [LocalAIProductEntity],
        branches: [LocalAIBranchEntity]
    ) -> String {
        let trimmed = original.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        let looksGeneric = trimmed.isEmpty || lower.contains("searching for")

        if looksGeneric && responseType.lowercased() == "search_products" && !products.isEmpty {
            let names = products.prefix(3).map { $0.name }.joined(separator: ", ")
            return "Encontré opciones que coinciden: \(names)."
        }
        if looksGeneric && responseType.lowercased() == "search_branches" && !branches.isEmpty {
            let names = branches.prefix(3).map { $0.name }.joined(separator: ", ")
            return "Encontré sucursales que pueden servirte: \(names)."
        }

        return trimmed
    }

    #if canImport(FoundationModels)
        @available(iOS 26.0, *)
        private func analyzeIntentWithFoundationModel(message: String, historyText: String)
            async throws
            -> LocalAIIntentAnalysis
        {
            let session = LanguageModelSession()
            let prompt = """
                \(intentSystemPrompt)

                Conversation:
                \(historyText)

                User: \(message)

                Respond ONLY with JSON that matches:
                {
                  "responseType": "search_products | search_branches | request_details | general_response",
                  "reasoning": "string",
                  "searchQueries": [{"collection": "products|branches|businesses", "query": "string", "limit": 10}],
                  "missingInfo": ["string"],
                  "confidence": 0.0
                }
                """

            let result: LanguageModelSession.Response<String>
            do {
                result = try await session.respond(to: prompt)
            } catch {
                throw mapFoundationModelError(error)
            }
            let jsonText = extractJSON(from: result.content)
            guard let data = jsonText.data(using: .utf8) else {
                throw LocalAIAssistantError.invalidModelResponse
            }
            do {
                return try decodeIntent(from: data)
            } catch {
                print("❌ [LOCAL AI] Intent JSON inválido: \(jsonText)")
                throw LocalAIAssistantError.invalidModelResponse
            }
        }

        @available(iOS 26.0, *)
        private func generateFinalResponseWithFoundationModel(
            message: String,
            historyText: String,
            intent: LocalAIIntentAnalysis,
            context: [SemanticSearchCollection: SemanticSearchResponsePayload]
        ) async throws -> LocalAIAssistantOutput {
            let session = LanguageModelSession()
            let contextText = buildContextText(context)

            let prompt = """
                \(finalResponseSystemPrompt)

                Conversation:
                \(historyText)
                User: \(message)

                Intent:
                responseType: \(intent.responseType)
                reasoning: \(intent.reasoning)

                Search context:
                \(contextText)

                Respond ONLY with JSON that matches:
                {
                  "responseType": "search_products | search_branches | request_details | general_response",
                  "aiText": "string",
                  "suggestedProductIds": [{"id": "productId", "reason": "string"}],
                  "suggestedBranchIds": [{"id": "branchId", "reason": "string"}],
                  "missingFields": ["string"],
                  "confidence": 0.0
                }
                """

            let result: LanguageModelSession.Response<String>
            do {
                result = try await session.respond(to: prompt)
            } catch {
                throw mapFoundationModelError(error)
            }
            let jsonText = extractJSON(from: result.content)
            guard let data = jsonText.data(using: .utf8) else {
                throw LocalAIAssistantError.invalidModelResponse
            }
            do {
                let decoded = try decodeFinalResponse(from: data)
                return mapFinalResponse(decoded, context: context)
            } catch {
                print("❌ [LOCAL AI] Final JSON inválido: \(jsonText)")
                throw LocalAIAssistantError.invalidModelResponse
            }
        }
    #endif

    private func analyzeIntent(message: String, historyText: String) async throws
        -> LocalAIIntentAnalysis
    {
        #if canImport(FoundationModels)
            if #available(iOS 26.0, *) {
                return try await analyzeIntentWithFoundationModel(
                    message: message,
                    historyText: historyText
                )
            }
        #endif
        throw LocalAIAssistantError.appleIntelligenceUnsupported
    }

    private func generateFinalResponse(
        message: String,
        historyText: String,
        intent: LocalAIIntentAnalysis,
        context: [SemanticSearchCollection: SemanticSearchResponsePayload]
    ) async throws -> LocalAIAssistantOutput {
        #if canImport(FoundationModels)
            if #available(iOS 26.0, *) {
                return try await generateFinalResponseWithFoundationModel(
                    message: message,
                    historyText: historyText,
                    intent: intent,
                    context: context
                )
            }
        #endif
        throw LocalAIAssistantError.appleIntelligenceUnsupported
    }

    private func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{"), trimmed.hasSuffix("}") {
            return trimmed
        }

        if let fenceStart = trimmed.range(of: "```"),
            let fenceEnd = trimmed.range(of: "```", options: .backwards),
            fenceStart.lowerBound != fenceEnd.lowerBound
        {
            let fenced = String(trimmed[fenceStart.upperBound..<fenceEnd.lowerBound])
            let cleaned =
                fenced
                .replacingOccurrences(of: "json", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.hasPrefix("{"), cleaned.hasSuffix("}") {
                return cleaned
            }
        }

        if let firstBrace = trimmed.firstIndex(of: "{"),
            let lastBrace = trimmed.lastIndex(of: "}")
        {
            return String(trimmed[firstBrace...lastBrace])
        }

        return trimmed
    }

    private func buildHistoryText(
        _ history: [LocalAIHistoryItem],
        maxMessages: Int,
        maxCharsPerMessage: Int
    ) -> String {
        let sliced = history.suffix(maxMessages)
        return sliced.map {
            let role = ($0.role == "user") ? "User" : "Assistant"
            return "\(role): \(trimmed($0.content, max: maxCharsPerMessage))"
        }.joined(separator: "\n")
    }

    private func trimmed(_ text: String, max: Int) -> String {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count > max else { return clean }
        let index = clean.index(clean.startIndex, offsetBy: max)
        return String(clean[..<index]) + "..."
    }

    private func mapFoundationModelError(_ error: Error) -> Error {
        let text = String(describing: error).lowercased()
        if text.contains("exceeds the maximum allowed context size")
            || text.contains("exceeded model context window size")
        {
            return LocalAIAssistantError.contextWindowExceeded
        }
        return error
    }

    private func decodeIntent(from data: Data) throws -> LocalAIIntentAnalysis {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(LocalAIIntentAnalysis.self, from: data)
    }

    private func decodeFinalResponse(from data: Data) throws -> LocalAIFinalResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(LocalAIFinalResponse.self, from: data)
    }

    private let intentSystemPrompt = """
        You are an intelligent shopping assistant for Llego, a local business discovery and ordering platform.

        Your role is to help users:
        1. Find products and stores (PRIMARY FUNCTION)
        2. Answer questions about products, stores, and ordering

        CURRENT LIMITATION: Order creation is temporarily disabled. Focus on helping users discover products and branches.

        When analyzing user intent, determine:
        - What type of response is needed (search products, search branches, request for details, or general conversation)
        - What vector searches should be executed (if any)
        - What information might be missing for a complete search

        Be conversational and helpful. If the user is vague, ask clarifying questions.
        If user wants to create an order, politely explain that order creation is temporarily unavailable but you can help them find products and stores.
        """

    private let finalResponseSystemPrompt = """
        You are an intelligent shopping assistant for Llego.

        You have access to search results from our database. Your job is to:
        1. Analyze the search results and their metadata
        2. Use the product NAMES from the search results to determine if they match what the user requested
        3. Suggest ALL products that semantically match the user's request based on their names
        4. Provide a natural, conversational response

        CRITICAL - PRODUCT IDs: You MUST use the EXACT product IDs from the search results provided in the context.
        - The products in "Available Products" section have real IDs from our database
        - NEVER invent or hallucinate product IDs - only use IDs that appear in the context

        CRITICAL - PRODUCT NAMES:
        - Suggest ALL items that could match what the user wants, not just exact name matches
        - Use semantic understanding

        CRITICAL - BRANCH INFO: When suggesting products, ALWAYS include the branch name and branch avatar information from the context.

        Be helpful and accurate. If you're unsure if a product matches, include it and explain what it is.
        When suggesting products or stores, explain WHY they match the user's request.

        IMPORTANT: Order creation is temporarily disabled. DO NOT suggest creating draft orders. Focus on search and discovery only.
        """
}
