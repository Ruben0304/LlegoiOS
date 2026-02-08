//
//  ConversationalSearchRepository.swift
//  LlegoiOS
//
//  Repository para manejar las queries de AI Chat
//

import Apollo
import Foundation

@MainActor
final class ConversationalSearchRepository {
    private let apolloClient = ApolloClientManager.shared.apollo
    private let localAIAssistantService = LocalAIAssistantService.shared

    func sendMessage(
        message: String,
        provider: ConversationalAIProvider,
        completion: @escaping @Sendable (Result<AIChatData, Error>) -> Void
    ) {
        switch provider {
        case .appleIntelligence:
            sendMessageWithAppleIntelligence(message: message, completion: completion)
        case .llegoAI:
            sendMessageWithBackend(message: message, completion: completion)
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
        completion: @escaping @Sendable (Result<AIChatData, Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🚀 [REPOSITORY] Iniciando query AIChatQuery")
            print("📝 [REPOSITORY] Message: \"\(message)\"")

            // Verificar autenticación
            let jwt = AuthManager.shared.getAccessToken()
            let isAuthenticated = AuthManager.shared.isAuthenticated
            let deviceId = DeviceIDManager.shared.getDeviceId()
            let jwtInput: GraphQLNullable<String> = jwt.map { .some($0) } ?? .none
            let deviceIdInput: GraphQLNullable<String> = deviceId.map { .some($0) } ?? .none
            #if DEBUG
                print("🔐 [REPOSITORY] isAuthenticated: \(isAuthenticated)")
                print("🎫 [REPOSITORY] JWT presente: \(jwt != nil)")
                print("📱 [REPOSITORY] deviceId presente: \(deviceId != nil)")
                if jwt == nil {
                    print(
                        "⚠️ [REPOSITORY] JWT NO DISPONIBLE - La query puede fallar si requiere autenticación"
                    )
                }
            #endif

            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            client.fetch(
                query: LlegoAPI.AIChatQuery(
                    message: message,
                    deviceId: deviceIdInput,
                    jwt: jwtInput
                ),
                cachePolicy: .fetchIgnoringCacheData  // No cachear para obtener respuestas frescas del AI
            ) { result in
                Task { @MainActor in
                    print("\n📡 [REPOSITORY] Respuesta recibida del servidor")

                    switch result {
                    case .success(let graphQLResult):
                        print("✅ [REPOSITORY] GraphQL Result OK")

                        // Log de errores GraphQL si existen
                        if let errors = graphQLResult.errors {
                            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            print("❌ [REPOSITORY] GraphQL Errors detectados:")
                            errors.forEach { error in
                                print("  ├─ Error: \(error.localizedDescription)")
                                print("  ├─ Message: \(error.message ?? "N/A")")
                                if let extensions = error.extensions {
                                    print("  ├─ Extensions: \(extensions)")
                                }
                                if let path = error.path {
                                    print("  └─ Path: \(path)")
                                }
                            }
                            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            if let backendError = self.parseBackendError(from: errors) {
                                completion(.failure(backendError))
                            } else {
                                let firstMessage =
                                    errors.first?.message ?? "Error en la consulta de AI"
                                completion(
                                    .failure(
                                        NSError(
                                            domain: "GraphQL",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: firstMessage]
                                        )))
                            }
                            return
                        }

                        // Verificar si data existe
                        guard let data = graphQLResult.data else {
                            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            print("❌ [REPOSITORY] graphQLResult.data es NIL")
                            print("⚠️ [REPOSITORY] Esto significa que el servidor no devolvió datos")
                            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            completion(
                                .failure(
                                    NSError(
                                        domain: "GraphQL", code: -2,
                                        userInfo: [
                                            NSLocalizedDescriptionKey:
                                                "No se recibió respuesta del AI"
                                        ])))
                            return
                        }

                        print("✅ [REPOSITORY] graphQLResult.data existe")

                        // Verificar si aiChat existe
                        guard let aiChat = data.aiChat else {
                            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            print("❌ [REPOSITORY] data.aiChat es NIL")
                            print("⚠️ [REPOSITORY] La query aiChat no devolvió resultados")
                            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            print("📋 [REPOSITORY] Datos disponibles en data:")
                            print("   └─ data object: \(data)")
                            print("")
                            print("💡 [REPOSITORY] Posibles causas:")
                            print("   1. El backend requiere autenticación (JWT)")
                            print("   2. Error interno en el backend (sin error GraphQL)")
                            print("   3. La query requiere parámetros adicionales")
                            print("")
                            print("🔍 [REPOSITORY] Recomendación:")
                            print("   - Verificar logs del backend")
                            print("   - Probar con un usuario autenticado")
                            print("   - Verificar que el resolver de aiChat esté funcionando")
                            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            completion(
                                .failure(
                                    NSError(
                                        domain: "GraphQL",
                                        code: -3,
                                        userInfo: [
                                            NSLocalizedDescriptionKey:
                                                "Respuesta vacía de AI - El backend devolvió aiChat: null"
                                        ]
                                    )))
                            return
                        }

                        print("✅ [REPOSITORY] data.aiChat existe")

                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        print("📥 [REPOSITORY] Procesando respuesta aiChat")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        print("📋 Response Type: \"\(aiChat.responseType)\"")
                        print("💬 AI Text: \"\(aiChat.aiText)\"")
                        print("🧠 Confidence: \(aiChat.confidence)")
                        print("📦 Suggested Products: \(aiChat.suggestedProducts.count)")
                        if !aiChat.suggestedProducts.isEmpty {
                            print("\n📦 DETALLE DE PRODUCTOS SUGERIDOS:")
                            aiChat.suggestedProducts.enumerated().forEach { index, suggestion in
                                let product = suggestion.product
                                print("  \(index + 1). \(product.name)")
                                print("     ├─ ID: \(product.id)")
                                print("     ├─ Precio: \(product.currency) $\(product.price)")
                                print("     ├─ Descripción: \(product.description)")
                                print("     ├─ Imagen URL: \(product.imageUrl)")
                                print("     ├─ Disponible: \(product.availability ? "Sí" : "No")")
                                print("     ├─ Branch Name: \(suggestion.branchName ?? "N/A")")
                                print(
                                    "     ├─ Branch Avatar: \(suggestion.branchAvatarUrl ?? "N/A")")
                                print(
                                    "     ├─ Branch Address: \(suggestion.branchAddress ?? "N/A")")
                                print("     ├─ Branch Phone: \(suggestion.branchPhone ?? "N/A")")
                                print("     └─ Razón: \(suggestion.reason ?? "N/A")")
                            }
                        }
                        print("\n🏪 Suggested Branches: \(aiChat.suggestedBranches.count)")
                        if !aiChat.suggestedBranches.isEmpty {
                            print("\n🏪 DETALLE DE TIENDAS SUGERIDAS:")
                            aiChat.suggestedBranches.enumerated().forEach { index, suggestion in
                                let branch = suggestion.branch
                                print("  \(index + 1). \(branch.name)")
                                print("     ├─ ID: \(branch.id)")
                                print("     ├─ Dirección: \(branch.address ?? "N/A")")
                                print("     ├─ Teléfono: \(branch.phone)")
                                print("     ├─ Estado: \(branch.status)")
                                print("     ├─ Avatar URL: \(branch.avatarUrl ?? "N/A")")
                                print(
                                    "     ├─ Coordenadas: [\(branch.coordinates.coordinates.map { String($0) }.joined(separator: ", "))]"
                                )
                                print("     └─ Razón: \(suggestion.reason ?? "N/A")")
                            }
                        }
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

                        let productEntities = aiChat.suggestedProducts.map { suggestion in
                            let product = suggestion.product
                            return AIChatProductEntity(
                                id: product.id,
                                name: product.name,
                                description: product.description,
                                price: product.price,
                                currency: product.currency,
                                imageUrl: product.imageUrl,
                                availability: product.availability,
                                branchName: suggestion.branchName,
                                branchAvatarUrl: suggestion.branchAvatarUrl,
                                branchAddress: suggestion.branchAddress,
                                branchPhone: suggestion.branchPhone,
                                reason: suggestion.reason
                            )
                        }

                        let branchEntities = aiChat.suggestedBranches.map { suggestion in
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

                        let chatData = AIChatData(
                            responseType: aiChat.responseType,
                            aiText: aiChat.aiText,
                            productEntities: productEntities,
                            branchEntities: branchEntities,
                            confidence: aiChat.confidence
                        )

                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        print("✅ [REPOSITORY] AIChatData creado exitosamente")
                        print(
                            "📦 [REPOSITORY] Productos en AIChatData: \(chatData.productEntities.count)"
                        )
                        print(
                            "🏪 [REPOSITORY] Branches en AIChatData: \(chatData.branchEntities.count)"
                        )
                        print("🎉 [REPOSITORY] Completando con SUCCESS")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

                        completion(.success(chatData))

                    case .failure(let error):
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        print("❌ [REPOSITORY] Network Error")
                        print("📛 Error: \(error.localizedDescription)")
                        if let apolloError = error as? any Error {
                            print("🔍 Error completo: \(apolloError)")
                        }
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
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

    private func parseBackendError(from errors: [GraphQLError]) -> AIChatBackendError? {
        for error in errors {
            guard
                let extensions = error.extensions,
                let codeRaw = stringValue(from: extensions["code"]),
                let code = AIChatBackendErrorCode(rawValue: codeRaw)
            else {
                continue
            }

            let quota: AIChatQuotaInfo?
            if let quotaRaw = extensions["quota"], let quotaDict = dictionaryValue(from: quotaRaw) {
                quota = AIChatQuotaInfo(
                    source: stringValue(from: quotaDict["source"]),
                    limit: intValue(from: quotaDict["limit"]),
                    used: intValue(from: quotaDict["used"]),
                    remaining: intValue(from: quotaDict["remaining"])
                )
            } else {
                quota = nil
            }

            return AIChatBackendError(
                code: code,
                quota: quota,
                fallbackMessage: error.message ?? "Ocurrió un error en AI Chat."
            )
        }
        return nil
    }

    private func stringValue(from raw: Any?) -> String? {
        if let value = raw as? String {
            return value
        }
        if let value = raw as? AnyHashable {
            if let string = value.base as? String {
                return string
            }
            return String(describing: value.base)
        }
        return nil
    }

    private func intValue(from raw: Any?) -> Int? {
        if let value = raw as? Int {
            return value
        }
        if let value = raw as? Int32 {
            return Int(value)
        }
        if let value = raw as? Int64 {
            return Int(value)
        }
        if let value = raw as? Double {
            return Int(value)
        }
        if let value = raw as? Float {
            return Int(value)
        }
        if let value = raw as? NSNumber {
            return value.intValue
        }
        if let value = raw as? String {
            return Int(value)
        }
        if let value = raw as? AnyHashable {
            return intValue(from: value.base)
        }
        return nil
    }

    private func dictionaryValue(from raw: Any?) -> [String: Any]? {
        if let dict = raw as? [String: Any] {
            return dict
        }
        if let dict = raw as? [String: AnyHashable] {
            return dict.mapValues { $0.base }
        }
        if let value = raw as? AnyHashable {
            if let dict = value.base as? [String: Any] {
                return dict
            }
            if let dict = value.base as? [String: AnyHashable] {
                return dict.mapValues { $0.base }
            }
        }
        return nil
    }

}

// MARK: - Models específicos de ConversationalSearchRepository

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
            rating: nil  // Por ahora sin rating
        )
    }
}
