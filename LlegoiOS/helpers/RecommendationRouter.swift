//
//  RecommendationRouter.swift
//  LlegoiOS
//

import Foundation

enum RecommendationContext {
    case cart(productIds: [String])
    case pdp(productId: String, productName: String)
}

struct RecommendationResult {
    let products: [Product]
    let source: RecommendationSource
    let usedFallback: Bool
    
    enum RecommendationSource {
        case appleIntelligence
        case llegoCloud
    }
}

@MainActor
final class RecommendationRouter {
    static let shared = RecommendationRouter()
    
    private let localEngine = RecommendationEngine.shared
    private let cloudRepository = CartRepository()
    private let preferenceManager = AIPreferenceManager.shared
    private let cartManager = CartManager.shared
    
    private init() {}
    
    func getRecommendations(
        context: RecommendationContext,
        limit: Int = 6
    ) async throws -> RecommendationResult {
        
        print("🔀 [RecommendationRouter] Iniciando recomendaciones")
        print("🔀 [RecommendationRouter] Preferencia: \(preferenceManager.selectedEngine.displayName)")
        
        do {
            let cloudCandidates = try await fetchCloudCandidates(context: context)
            
            guard !cloudCandidates.isEmpty else {
                print("⚠️ [RecommendationRouter] Cloud retornó 0 candidatos")
                return RecommendationResult(products: [], source: .llegoCloud, usedFallback: false)
            }
            
            print("🌐 [RecommendationRouter] Cloud retornó \(cloudCandidates.count) candidatos")
            
            let shouldTryLocal = preferenceManager.selectedEngine == .appleIntelligence
            
            var finalProducts = cloudCandidates
            var usedFallback = false
            var source: RecommendationResult.RecommendationSource = .llegoCloud
            
            if shouldTryLocal {
                print("🔀 [RecommendationRouter] Intentando re-ranking local...")
                
                do {
                    let rerankedProducts = try await applyLocalReRanking(
                        context: context,
                        candidates: cloudCandidates
                    )
                    
                    if !rerankedProducts.isEmpty {
                        print("✅ [RecommendationRouter] Re-ranking local exitoso: \(rerankedProducts.count) productos")
                        finalProducts = rerankedProducts
                        source = .appleIntelligence
                    } else {
                        print("⚠️ [RecommendationRouter] Re-ranking retornó 0, usando cloud")
                        usedFallback = true
                    }
                } catch {
                    print("❌ [RecommendationRouter] Error en re-ranking: \(error.localizedDescription)")
                    print("🔄 [RecommendationRouter] Fallback a cloud")
                    usedFallback = true
                }
            }
            
            let filtered = applyFinalFilters(products: finalProducts, context: context)
            let limited = Array(filtered.prefix(limit))
            
            print("✅ [RecommendationRouter] Retornando \(limited.count) productos")
            print("   Fuente: \(source)")
            print("   Usó fallback: \(usedFallback)")
            
            return RecommendationResult(
                products: limited,
                source: source,
                usedFallback: usedFallback
            )
            
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == -1001 {
                print("🔄 [RecommendationRouter] Cloud timeout, trying Apple fallback")
                return await getRecommendationsFromAppleFallback(context: context, limit: limit)
            } else if nsError.domain == NSURLErrorDomain {
                print("🔄 [RecommendationRouter] Cloud network error, trying Apple fallback")
                return await getRecommendationsFromAppleFallback(context: context, limit: limit)
            }
            throw error
        }
    }
    
    private func fetchCloudCandidates(context: RecommendationContext) async throws -> [Product] {
        let productIds: [String]
        
        switch context {
        case .cart(let ids):
            productIds = ids
        case .pdp(let productId, _):
            productIds = [productId]
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            cloudRepository.fetchCloudCandidates(productIds: productIds, limit: 20) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func applyLocalReRanking(
        context: RecommendationContext,
        candidates: [Product]
    ) async throws -> [Product] {
        
        guard localEngine.isAvailable() else {
            throw RecommendationError.appleIntelligenceNotAvailable
        }
        
        let candidateTuples = candidates.map { (id: $0.id, name: $0.name) }
        let rerankedIds: [String]
        
        switch context {
        case .cart:
            let cartNames = cartManager.localItems.compactMap { localItem -> String? in
                return candidates.first(where: { $0.id == localItem.productId })?.name
            }
            
            guard !cartNames.isEmpty else {
                throw RecommendationError.cartEmpty
            }
            
            rerankedIds = try await localEngine.reRankComplementary(
                cartNames: cartNames,
                candidates: candidateTuples
            )
            
        case .pdp(_, let productName):
            rerankedIds = try await localEngine.reRankSimilar(
                productName: productName,
                candidates: candidateTuples
            )
        }
        
        guard !rerankedIds.isEmpty else {
            throw RecommendationError.invalidResponse
        }
        
        let productsDict = Dictionary(uniqueKeysWithValues: candidates.map { ($0.id, $0) })
        return rerankedIds.compactMap { productsDict[$0] }
    }
    
    private func applyFinalFilters(products: [Product], context: RecommendationContext) -> [Product] {
        var filtered = products
        
        switch context {
        case .cart:
            let cartIds = Set(cartManager.localItems.map(\.productId))
            filtered = filtered.filter { !cartIds.contains($0.id) }
            print("🔍 [RecommendationRouter] Excluidos del carrito: \(products.count - filtered.count)")
            
        case .pdp(let productId, _):
            filtered = filtered.filter { $0.id != productId }
            print("🔍 [RecommendationRouter] Excluido producto actual: \(products.count - filtered.count)")
        }
        
        return filtered
    }
    
    private func getRecommendationsFromAppleFallback(
        context: RecommendationContext,
        limit: Int
    ) async -> RecommendationResult {
        
        let cachedProducts = ProductCacheManager.shared.getProducts(limit: 200)
        
        guard !cachedProducts.isEmpty else {
            print("⚠️ [Fallback] Cache empty")
            return RecommendationResult(products: [], source: .llegoCloud, usedFallback: true)
        }
        
        print("📦 [Fallback] Cache size: \(cachedProducts.count)")
        
        guard localEngine.isAvailable() else {
            print("❌ [Fallback] Apple Intelligence unavailable")
            return RecommendationResult(products: [], source: .llegoCloud, usedFallback: true)
        }
        
        let candidateTuples = cachedProducts.map { (id: $0.id, name: $0.name) }
        
        do {
            let rerankedIds: [String]
            
            switch context {
            case .cart:
                let cartNames = cartManager.localItems.compactMap { localItem -> String? in
                    return cachedProducts.first(where: { $0.id == localItem.productId })?.name
                }
                
                guard !cartNames.isEmpty else {
                    print("⚠️ [Fallback] No cart names available")
                    return RecommendationResult(products: [], source: .appleIntelligence, usedFallback: true)
                }
                
                rerankedIds = try await localEngine.reRankComplementary(
                    cartNames: cartNames,
                    candidates: candidateTuples
                )
                
            case .pdp(_, let productName):
                rerankedIds = try await localEngine.reRankSimilar(
                    productName: productName,
                    candidates: candidateTuples
                )
            }
            
            guard !rerankedIds.isEmpty else {
                print("⚠️ [Fallback] Apple returned empty IDs")
                return RecommendationResult(products: [], source: .appleIntelligence, usedFallback: true)
            }
            
            let productsDict = Dictionary(uniqueKeysWithValues: cachedProducts.map { ($0.id, $0) })
            let mappedProducts = rerankedIds.compactMap { id -> Product? in
                guard let cached = productsDict[id] else { return nil }
                return Product(
                    id: cached.id,
                    name: cached.name,
                    shop: "Tienda",
                    shopLogoUrl: "",
                    weight: cached.currency,
                    price: "\(cached.currency) \(cached.price)",
                    imageUrl: cached.imageUrl
                )
            }
            
            let filtered = applyFinalFilters(products: mappedProducts, context: context)
            let limited = Array(filtered.prefix(limit))
            
            print("✅ [Fallback] Returning \(limited.count) products")
            
            return RecommendationResult(
                products: limited,
                source: .appleIntelligence,
                usedFallback: true
            )
            
        } catch {
            print("❌ [Fallback] Error: \(error.localizedDescription)")
            return RecommendationResult(products: [], source: .appleIntelligence, usedFallback: true)
        }
    }
}
