//
//  ConversationalSearchRepository.swift
//  LlegoiOS
//
//  Repository para manejar las queries de AI Chat
//

import Foundation
import Apollo

@MainActor
final class ConversationalSearchRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    func sendMessage(
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
            print("🔐 [REPOSITORY] isAuthenticated: \(isAuthenticated)")
            print("🎫 [REPOSITORY] JWT presente: \(jwt != nil)")
            if let jwt = jwt {
                let tokenPreview = String(jwt.prefix(20)) + "..."
                print("🎫 [REPOSITORY] JWT preview: \(tokenPreview)")
            } else {
                print("⚠️ [REPOSITORY] JWT NO DISPONIBLE - La query puede fallar si requiere autenticación")
            }

            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            client.fetch(
                query: LlegoAPI.AIChatQuery(
                    message: message,
                    jwt: jwt != nil ? .some(jwt!) : .none
                ),
                cachePolicy: .fetchIgnoringCacheData // No cachear para obtener respuestas frescas del AI
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
                            completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error en la consulta de AI"])))
                            return
                        }

                        // Verificar si data existe
                        guard let data = graphQLResult.data else {
                            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            print("❌ [REPOSITORY] graphQLResult.data es NIL")
                            print("⚠️ [REPOSITORY] Esto significa que el servidor no devolvió datos")
                            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            completion(.failure(NSError(domain: "GraphQL", code: -2, userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del AI"])))
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
                            completion(.failure(NSError(
                                domain: "GraphQL",
                                code: -3,
                                userInfo: [NSLocalizedDescriptionKey: "Respuesta vacía de AI - El backend devolvió aiChat: null"]
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
                                print("     ├─ Branch Avatar: \(suggestion.branchAvatarUrl ?? "N/A")")
                                print("     ├─ Branch Address: \(suggestion.branchAddress ?? "N/A")")
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
                                print("     ├─ Coordenadas: [\(branch.coordinates.coordinates.map { String($0) }.joined(separator: ", "))]")
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
                        print("📦 [REPOSITORY] Productos en AIChatData: \(chatData.productEntities.count)")
                        print("🏪 [REPOSITORY] Branches en AIChatData: \(chatData.branchEntities.count)")
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

}

// MARK: - Models específicos de ConversationalSearchRepository

struct AIChatData: Sendable {
    let responseType: String
    let aiText: String
    let productEntities: [AIChatProductEntity]
    let branchEntities: [AIChatBranchEntity]
    let confidence: Double
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
        let logoUrl = "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center"
        let bannerUrl = "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"

        return Store(
            id: id,
            name: name,
            etaMinutes: etaMinutes,
            logoUrl: logoUrl,
            bannerUrl: bannerUrl,
            address: address,
            rating: nil // Por ahora sin rating
        )
    }
}
