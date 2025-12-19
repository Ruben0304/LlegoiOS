//
//  ConversationalSearchRepository.swift
//  LlegoiOS
//
//  Repository para manejar las queries de AI Chat
//

import Foundation
import Apollo

class ConversationalSearchRepository {
    private let apolloClient = ApolloClientManager.shared.apollo
    
    func sendMessage(
        message: String,
        sessionId: String,
        completion: @escaping @Sendable (Result<AIChatData, Error>) -> Void
    ) {
        apolloClient.fetch(
            query: LlegoAPI.AIChatQuery(message: message, sessionId: sessionId),
            cachePolicy: .fetchIgnoringCacheData // No cachear para obtener respuestas frescas del AI
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors:")
                    errors.forEach { print("  - \($0.localizedDescription)") }
                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error en la consulta de AI"])))
                    return
                }
                
                guard let data = graphQLResult.data else {
                    completion(.failure(NSError(domain: "GraphQL", code: -2, userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del AI"])))
                    return
                }
                
                guard let aiChat = data.aiChat else {
                    print("⚠️ [REPOSITORY] aiChat es nil en la respuesta")
                    completion(.failure(NSError(
                        domain: "GraphQL",
                        code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "Respuesta vacía de AI"]
                    )))
                    return
                }

                let output = aiChat.output

                // LOGS DE DEBUG
                print("📥 [REPOSITORY] Response Type: \(output.type)")
                print("📥 [REPOSITORY] AI Text: \(output.aItext)")
                print("📥 [REPOSITORY] IDs: \(output.ids)")

                // Map entities según su tipo
                var productEntities: [AIChatProductEntity] = []
                var branchEntities: [AIChatBranchEntity] = []
                var paymentEntities: [AIChatPaymentEntity] = []

                // Verificar si entities no es nulo antes de iterar
                if let entities = output.entities {
                    print("📥 [REPOSITORY] Total entities: \(entities.count)")

                    for entity in entities {
                        if let product = entity.asProductType {
                            print("📦 [REPOSITORY] Mapeando producto: \(product.id) - \(product.name)")
                            productEntities.append(AIChatProductEntity(
                                id: product.id,
                                name: product.name,
                                description: product.description,
                                price: product.price,
                                currency: product.currency,
                                image: product.image,
                                availability: product.availability
                            ))
                        } else if let branch = entity.asBranchType {
                            print("🏪 [REPOSITORY] Mapeando branch: \(branch.id) - \(branch.name)")
                            branchEntities.append(AIChatBranchEntity(
                                id: branch.id,
                                name: branch.name,
                                address: branch.address,
                                phone: branch.phone,
                                status: branch.status,
                                coordinates: AIChatCoordinates(
                                    type: branch.coordinates.type,
                                    coordinates: branch.coordinates.coordinates
                                )
                            ))
                        } else if let payment = entity.asPaymentMethodType {
                            print("💳 [REPOSITORY] Mapeando payment: \(payment.id) - \(payment.method) - \(payment.currency)")
                            paymentEntities.append(AIChatPaymentEntity(
                                id: payment.id,
                                currency: payment.currency,
                                method: payment.method
                            ))
                        } else {
                            print("❓ [REPOSITORY] Entidad desconocida, no se pudo mapear")
                        }
                    }
                } else {
                    print("⚠️ [REPOSITORY] entities es NULL - Tipo de respuesta: \(output.type)")
                }

                print("📊 [REPOSITORY] Resultado - Products: \(productEntities.count), Branches: \(branchEntities.count), Payments: \(paymentEntities.count)")

                let chatData = AIChatData(
                    type: output.type,
                    aiText: output.aItext,
                    ids: output.ids,
                    productEntities: productEntities,
                    branchEntities: branchEntities,
                    paymentEntities: paymentEntities
                )
                
                completion(.success(chatData))
                
            case .failure(let error):
                print("❌ Network Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Models específicos de ConversationalSearchRepository

struct AIChatData: Sendable {
    let type: String
    let aiText: String
    let ids: [String]
    let productEntities: [AIChatProductEntity]
    let branchEntities: [AIChatBranchEntity]
    let paymentEntities: [AIChatPaymentEntity]
}

struct AIChatProductEntity: Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let currency: String
    let image: String
    let availability: Bool
}

struct AIChatBranchEntity: Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let address: String
    let phone: String
    let status: String
    let coordinates: AIChatCoordinates
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
