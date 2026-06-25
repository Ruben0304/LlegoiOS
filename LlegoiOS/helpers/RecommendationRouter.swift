//
//  RecommendationRouter.swift
//  LlegoiOS
//

import Foundation

enum RecommendationContext {
    case cart(productIds: [String], firstProductId: String?)
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
    private var cachedBranchFirstProductId: String?
    private var cachedBranchProductsForAI: [CartRepository.BranchProductForAI] = []
    
    private init() {}
    
    func getRecommendations(
        context: RecommendationContext,
        limit: Int = 6
    ) async throws -> RecommendationResult {
        
        print("🔀 [RecommendationRouter] Iniciando recomendaciones")
        print("🔀 [RecommendationRouter] Preferencia: \(preferenceManager.selectedEngine.displayName) (\(preferenceManager.selectedEngine.rawValue))")

        // Log context details
        switch context {
        case .cart(let ids, let firstProductId):
            print("🔀 [RecommendationRouter] Contexto: cart | productIds=\(ids) | firstProductId=\(firstProductId ?? "nil")")
        case .pdp(let productId, let name):
            print("🔀 [RecommendationRouter] Contexto: pdp | productId=\(productId) | name=\(name)")
        }

        // Apple Intelligence flow: usa productsFromSameBranch con el primer productId del carrito
        if preferenceManager.selectedEngine == .appleIntelligence,
           case .cart(let productIds, let firstProductId) = context,
           let firstProductId = firstProductId {
            print("🍎 [RecommendationRouter] → Flujo Apple Intelligence con productId: \(firstProductId)")
            return await getRecommendationsFromBranchWithAppleIntelligence(
                cartProductIds: productIds,
                firstProductId: firstProductId,
                limit: limit
            )
        }

        // Si Apple Intelligence está seleccionado pero no tenemos el productId aún,
        // retornar vacío y esperar a que llegue (updateFirstProductId lo relanza).
        if preferenceManager.selectedEngine == .appleIntelligence,
           case .cart(_, let firstProductId) = context,
           firstProductId == nil {
            print("⏳ [RecommendationRouter] Apple Intelligence seleccionado pero firstProductId aún no disponible — esperando")
            return RecommendationResult(products: [], source: .appleIntelligence, usedFallback: false)
        }

        // Cloud flow (default)
        print("🌐 [RecommendationRouter] → Flujo Cloud")
        do {
            let cloudCandidates = try await fetchCloudCandidates(context: context)

            guard !cloudCandidates.isEmpty else {
                print("⚠️ [RecommendationRouter] Cloud retornó 0 candidatos")
                return RecommendationResult(products: [], source: .llegoCloud, usedFallback: false)
            }
            
            print("🌐 [RecommendationRouter] Cloud retornó \(cloudCandidates.count) candidatos")
            
            let filtered = applyFinalFilters(products: cloudCandidates, context: context)
            let limited = Array(filtered.prefix(limit))
            
            print("✅ [RecommendationRouter] Retornando \(limited.count) productos")
            
            return RecommendationResult(
                products: limited,
                source: .llegoCloud,
                usedFallback: false
            )
            
        } catch {
            // Forzado a nube: sin fallback a Apple Intelligence. Si la nube falla,
            // devolvemos vacío para no romper la UI del carrito.
            print("⚠️ [RecommendationRouter] Cloud falló: \(error.localizedDescription) — sin recomendaciones")
            return RecommendationResult(products: [], source: .llegoCloud, usedFallback: false)
        }
    }

    /// Flujo Apple Intelligence: llama productsFromSameBranch con el primer productId del carrito
    /// y re-rankea con el modelo local.
    private func getRecommendationsFromBranchWithAppleIntelligence(
        cartProductIds: [String],
        firstProductId: String,
        limit: Int
    ) async -> RecommendationResult {
        guard localEngine.isAvailable() else {
            print("⚠️ [RecommendationRouter] Apple Intelligence no disponible")
            return RecommendationResult(products: [], source: .appleIntelligence, usedFallback: false)
        }

        do {
            // 1. Obtener candidatos del branch. Si firstProductId no cambió,
            // reutilizar candidatos cacheados y solo rerankear con IA.
            let branchProducts: [CartRepository.BranchProductForAI]
            if cachedBranchFirstProductId == firstProductId, !cachedBranchProductsForAI.isEmpty {
                branchProducts = cachedBranchProductsForAI
                print("♻️ [RecommendationRouter] Reutilizando \(branchProducts.count) candidatos cacheados para firstProductId=\(firstProductId)")
            } else {
                let fetchedProducts: [CartRepository.BranchProductForAI] = try await withCheckedThrowingContinuation { continuation in
                    cloudRepository.fetchBranchProductsForAI(productId: firstProductId, limit: 50) { result in
                        continuation.resume(with: result)
                    }
                }
                branchProducts = fetchedProducts
                cachedBranchFirstProductId = firstProductId
                cachedBranchProductsForAI = fetchedProducts
                print("🌐 [RecommendationRouter] Candidatos recargados desde backend: \(branchProducts.count) para firstProductId=\(firstProductId)")
            }

            guard !branchProducts.isEmpty else {
                print("⚠️ [RecommendationRouter] Branch retornó 0 productos para AI")
                return RecommendationResult(products: [], source: .appleIntelligence, usedFallback: false)
            }

            print("🍎 [RecommendationRouter] Branch retornó \(branchProducts.count) productos")

            // 2. Build candidate tuples including description for better AI context
            let candidateTuples = branchProducts.map { product in
                let nameWithDesc = product.description.isEmpty
                    ? product.name
                    : "\(product.name) - \(product.description)"
                return (id: product.id, name: nameWithDesc)
            }

            // 3. Get cart item names from cart local items (use productId to match)
            let cartItemProductIds = Set(cartManager.localItems.map(\.productId))
            let cartNames = branchProducts
                .filter { cartItemProductIds.contains($0.id) }
                .map(\.name)

            guard !cartNames.isEmpty else {
                print("⚠️ [RecommendationRouter] No se encontraron nombres de productos del carrito en el branch")
                let fallbackCartNames = cartManager.localItems.map { "Producto \($0.productId)" }
                let rerankedIds = try await localEngine.reRankComplementary(
                    cartNames: fallbackCartNames,
                    candidates: candidateTuples
                )
                return buildResult(from: rerankedIds, branchProducts: branchProducts, cartProductIds: cartProductIds, limit: limit)
            }

            // 4. Re-rank with Apple Intelligence
            let rerankedIds = try await localEngine.reRankComplementary(
                cartNames: cartNames,
                candidates: candidateTuples
            )

            print("🍎 [RecommendationRouter] Apple Intelligence re-rankeó \(rerankedIds.count) productos")

            // 5. Map back to Product objects and apply filters
            return buildResult(from: rerankedIds, branchProducts: branchProducts, cartProductIds: cartProductIds, limit: limit)

        } catch {
            print("❌ [RecommendationRouter] Error en flujo Apple Intelligence: \(error.localizedDescription)")
            return RecommendationResult(products: [], source: .appleIntelligence, usedFallback: false)
        }
    }

    private func buildResult(
        from rerankedIds: [String],
        branchProducts: [CartRepository.BranchProductForAI],
        cartProductIds: [String],
        limit _: Int
    ) -> RecommendationResult {
        let productsDict = Dictionary(uniqueKeysWithValues: branchProducts.map { ($0.id, $0) })
        let cartIds = Set(cartProductIds)

        let products = rerankedIds.compactMap { id -> Product? in
            guard let p = productsDict[id], !cartIds.contains(id) else { return nil }
            return Product(
                id: p.id,
                name: p.name,
                shop: "Tienda",
                shopLogoUrl: "",
                weight: p.currency,
                price: "\(p.currency) \(p.price)",
                imageUrl: p.imageUrl
            )
        }

        print("✅ [RecommendationRouter] Apple Intelligence retornando \(products.count) productos")
        return RecommendationResult(products: products, source: .appleIntelligence, usedFallback: false)
    }
    
    private func fetchCloudCandidates(context: RecommendationContext) async throws -> [Product] {
        let productIds: [String]
        
        switch context {
        case .cart(let ids, _):
            productIds = ids
        case .pdp(let id, _):
            productIds = [id]
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
        case .cart(_, _):
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
