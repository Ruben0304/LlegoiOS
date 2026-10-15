//
//  SearchRepository.swift
//  LlegoiOS
//
//  Repositorio para búsqueda de productos y tiendas
//

import Apollo
import Foundation
import MapKit

@MainActor
final class SearchRepository {
    private let apolloClient: ApolloClient

    init(apolloClient: ApolloClient = ApolloClientManager.shared.apollo) {
        self.apolloClient = apolloClient
    }

    struct CombinationPage: Sendable {
        let candidates: [SearchCombinationCandidate]
        let didReachPageLimit: Bool
    }

    struct CartSuggestions: Sendable {
        let context: SearchCartContext
        let products: [SearchCombinationCandidate]
    }

    /// Resolve the cart's actual branch, then search its own inventory. This is
    /// independent of global ranking, which may omit a matching local product.
    func searchCartSuggestions(
        query: String, cartProductIds: Set<String>, showcaseBranchIds: Set<String> = []
    ) async throws -> CartSuggestions? {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !cartProductIds.isEmpty else { return nil }
        switch SearchCombinationParser.parse(query) {
        case .quantityNeedsConfiguration, .tooManyIntents: return nil
        case .single, .combination: break
        }
        let cartResponse = try await apolloClient.fetch(
            query: LlegoAPI.GetProductsByIdsQuery(ids: cartProductIds.sorted(), jwt: .none),
            cachePolicy: .networkOnly)
        try Task.checkCancellation()
        guard cartResponse.errors?.isEmpty != false, let cartProducts = cartResponse.data?.productsByIds,
              Set(cartProducts.map(\.id)) == cartProductIds else { return nil }
        let branchIds = Set(cartProducts.map(\.branchId)).union(showcaseBranchIds)
        guard branchIds.count == 1, let branchId = branchIds.first, !branchId.isEmpty,
              let sourceId = cartProductIds.sorted().first else { return nil }
        guard let branch = try await fetchCombinationBranch(branchId: branchId), !branch.catalogOnly else { return nil }
        let context = SearchCartContext(
            branchId: branchId, branchName: branch.name,
            cartProductNames: cartProducts.map(\.name), productIds: cartProductIds)

        let inventoryResponse = try await apolloClient.fetch(
            query: LlegoAPI.GetBranchProductsForAIQuery(productId: sourceId, limit: 100, jwt: .none),
            cachePolicy: .networkOnly)
        try Task.checkCancellation()
        guard inventoryResponse.errors?.isEmpty != false,
              let inventory = inventoryResponse.data?.productsFromSameBranch else { return nil }
        let candidates = inventory.filter {
            $0.branchId == branchId && $0.availability && !cartProductIds.contains($0.id)
        }.map { product in
            SearchCombinationCandidate(
                id: product.id, branchId: product.branchId, branchName: branch.name,
                businessName: branch.name, name: product.name, description: product.description,
                price: product.price, currency: product.currency, imageUrl: product.imageUrlBaja,
                availability: product.availability)
        }
        let segments = SearchCombinationParser.segments(query)
        let intents = SearchCombinationIntentResolver.resolve(
            segments: segments,
            candidatesBySegment: Array(repeating: candidates, count: segments.count),
            catalogCandidates: candidates)
        var seen: Set<String> = []
        let products = intents.flatMap {
            SearchCombinationMatcher.matchingCandidates(intent: $0.intent, candidates: candidates, limit: 4)
        }.filter { seen.insert($0.id).inserted }
        return CartSuggestions(context: context, products: branch.acceptingOrders ? Array(products.prefix(4)) : [])
    }

    /// Keep the cart's product names (including qualifiers) as intents. A shop
    /// qualifies only when it can satisfy the entire selection in one branch.
    func searchCartAlternatives(query: String, context: SearchCartContext) async throws -> [SearchCombination] {
        var intents = context.cartProductNames
        guard !intents.isEmpty else { return [] }
        let segments = SearchCombinationParser.segments(query)
        var catalog: [SearchCombinationCandidate] = []
        var segmentCandidates: [[SearchCombinationCandidate]] = []
        for segment in segments {
            let page = try await searchCombinationCandidates(query: segment.text)
            segmentCandidates.append(page.candidates)
            catalog += page.candidates
        }
        if segments.contains(where: \.canMergeWithPrevious) {
            catalog += try await searchCombinationCandidates(query: query).candidates
        }
        intents += SearchCombinationIntentResolver.resolve(
            segments: segments, candidatesBySegment: segmentCandidates,
            catalogCandidates: catalog).map(\.intent)
        var seen: Set<String> = []
        intents = intents.filter { seen.insert($0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)).inserted }
        guard (2...4).contains(intents.count) else { return [] }
        var candidates: [[SearchCombinationCandidate]] = []
        for intent in intents {
            candidates.append(try await searchCombinationCandidates(query: intent).candidates)
        }
        let combinations = SearchCombinationMatcher.build(intents: intents, candidatesByIntent: candidates)
            .filter { $0.branchId != context.branchId }
        let branches = await fetchCombinationBranches(branchIDs: Set(combinations.map(\.branchId)))
        try Task.checkCancellation()
        return combinations.compactMap { combination in
            guard let branch = branches[combination.branchId], !branch.catalogOnly, branch.acceptingOrders else { return nil }
            return SearchCombination(
                id: combination.id, branchId: combination.branchId, branchName: branch.name,
                products: combination.products, totalPrice: combination.totalPrice, currency: combination.currency)
        }
    }

    /// Each intent has an independent, cancellable and bounded paginated query.
    @MainActor
    func searchCombinationCandidates(
        query: String, pageSize: Int32 = 20, maxPages: Int = 3
    ) async throws -> CombinationPage {
        var accumulated: [SearchCombinationCandidate] = []
        var cursor: String?
        var hasNextPage = false
        for _ in 0..<max(1, maxPages) {
            try Task.checkCancellation()
            let searchQuery = LlegoAPI.SearchProductsQuery(
                query: query, first: pageSize,
                after: cursor.map { .some($0) } ?? .none,
                useVectorSearch: .some(true),
                // This is the global search tab, like SearchBothQuery. The
                // category selected on Home must not hide combination products.
                branchTipo: .none,
                categoryId: .none, radiusKm: .none,
                jwt: .none
            )
            let response = try await apolloClient.fetch(query: searchQuery, cachePolicy: .networkOnly)
            try Task.checkCancellation()
            if let error = response.errors?.first {
                throw NSError(domain: "GraphQL", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: error.message ?? "No se pudo completar la búsqueda."
                ])
            }
            guard let data = response.data else {
                throw NSError(domain: "GraphQL", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "No se pudo completar la búsqueda."
                ])
            }
            accumulated += data.searchProducts.edges.map { edge in
                let node = edge.node
                return SearchCombinationCandidate(
                    id: node.id, branchId: node.branchId,
                    branchName: node.business?.name ?? "Negocio",
                    businessName: node.business?.name ?? "Negocio",
                    name: node.name, description: node.description,
                    price: node.price, currency: node.currency,
                    imageUrl: node.imageUrlBaja, availability: node.availability)
            }
            hasNextPage = data.searchProducts.pageInfo.hasNextPage
            guard hasNextPage else { break }
            guard let next = data.searchProducts.pageInfo.endCursor, next != cursor else { break }
            cursor = next
        }
        return CombinationPage(candidates: accumulated, didReachPageLimit: hasNextPage)
    }

    struct CombinationBranch: Sendable {
        let name: String
        let catalogOnly: Bool
        let acceptingOrders: Bool
    }

    @MainActor
    private func fetchCombinationBranch(branchId: String) async throws -> CombinationBranch? {
        let response = try await apolloClient.fetch(
            query: LlegoAPI.GetBranchDetailQuery(id: branchId), cachePolicy: .networkOnly)
        try Task.checkCancellation()
        guard response.errors?.isEmpty != false,
              let branch = response.data?.branch, branch.id == branchId else { return nil }
        let name = [branch.name, branch.address].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
        return CombinationBranch(name: name, catalogOnly: branch.catalogOnly, acceptingOrders: branch.acceptingOrders)
    }

    @MainActor
    func fetchCombinationBranches(branchIDs: Set<String>) async -> [String: CombinationBranch] {
        await withTaskGroup(of: (String, CombinationBranch?).self) { group in
            for branchID in branchIDs {
                group.addTask { [self] in
                    let branch = try? await self.fetchCombinationBranch(branchId: branchID)
                    return (branchID, branch)
                }
            }
            var branches: [String: CombinationBranch] = [:]
            for await (branchID, branch) in group {
                if let branch { branches[branchID] = branch }
            }
            return branches
        }
    }

    // MARK: - Search Products
    @MainActor
    func searchProducts(
        query: String,
        first: Int32 = 20,
        categoryId: String? = nil,
        completion: @escaping @Sendable (Result<[Product], Error>) -> Void
    ) {
        print("🌐 SearchRepository - searchProducts() called with query: '\(query)'")

        // Obtener JWT si está disponible
        let jwt = AuthManager.shared.getAccessToken()
        #if DEBUG
            print("🔑 SearchRepository - JWT: \(jwt != nil ? "presente" : "NO presente")")
        #endif

        // Obtener tipo de branch global
        let branchType = BranchTypeManager.shared.selectedType.rawValue
        print("🏪 SearchRepository - branchType: \(branchType)")

        let searchQuery = LlegoAPI.SearchProductsQuery(
            query: query,
            first: first,
            after: .none,
            useVectorSearch: .some(true),
            branchTipo: LlegoAPI.BranchTipo(rawValue: branchType.uppercased()).map { .some(GraphQLEnum($0)) }
                ?? .none,
            categoryId: categoryId.map { .some($0) } ?? .none,
            radiusKm: .none,
            jwt: jwt.map { .some($0) } ?? .none
        )

        print("🚀 SearchRepository - Calling apolloClient.fetchCompat() for products...")
        apolloClient.fetchCompat(query: searchQuery, cachePolicy: .fetchIgnoringCacheData) { result in
            print("📡 SearchRepository - Apollo fetch callback received for products")

            switch result {
            case .success(let graphQLResult):
                print("✅ SearchRepository - GraphQL query SUCCESS")

                if let errors = graphQLResult.errors, !errors.isEmpty {
                    print(
                        "❌ SearchRepository - GraphQL errors: \(errors.compactMap { $0.message }.joined(separator: ", "))"
                    )
                    completion(
                        .failure(
                            NSError(
                                domain: "GraphQL",
                                code: -1,
                                userInfo: [
                                    NSLocalizedDescriptionKey: errors.first?.message
                                        ?? "Error desconocido"
                                ]
                            )))
                    return
                }

                guard let data = graphQLResult.data else {
                    print("⚠️ SearchRepository - No data in GraphQL result, returning empty array")
                    completion(.success([]))
                    return
                }

                print(
                    "📦 SearchRepository - Received \(data.searchProducts.edges.count) product edges"
                )

                let products = data.searchProducts.edges.map { edge -> Product in
                    let node = edge.node
                    let priceFormatted = String(format: "%.2f %@", node.price, node.currency)

                    return Product(
                        id: node.id,
                        name: node.name,
                        shop: node.business?.name ?? "",
                        weight: node.weight,
                        price: priceFormatted,
                        imageUrl: node.imageUrlBaja
                    )
                }

                print("✅ SearchRepository - Mapped to \(products.count) Product objects")
                completion(.success(products))

            case .failure(let error):
                print("❌ SearchRepository - Apollo fetch FAILED: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - Search Both (productos + negocios en una sola llamada)
    @MainActor
    func searchBoth(
        query: String,
        completion: @escaping @Sendable (Result<([Product], [StoreWithCoordinates], [String: [ProductGraphQL]]), Error>) -> Void
    ) {
        let jwt = AuthManager.shared.getAccessToken()

        let searchQuery = LlegoAPI.SearchBothQuery(
            query: query,
            firstProducts: 10,
            firstBranches: 8,
            useVectorSearch: .some(true),
            jwt: .none  // No JWT: prevents backend from filtering branch products by user delivery radius
        )

        apolloClient.fetchCompat(query: searchQuery, cachePolicy: .fetchIgnoringCacheData) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    completion(.failure(NSError(
                        domain: "GraphQL", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: errors.first?.message ?? "Error desconocido"]
                    )))
                    return
                }

                guard let data = graphQLResult.data else {
                    completion(.success(([], [], [:])))
                    return
                }

                let products = data.searchProducts.edges.map { edge -> Product in
                    let node = edge.node
                    let priceFormatted = String(format: "%.2f %@", node.price, node.currency)
                    return Product(
                        id: node.id,
                        name: node.name,
                        shop: node.business?.name ?? "",
                        shopLogoUrl: avatarSmallURL(
                            low: node.business?.avatarUrlBaja,
                            original: node.business?.avatarUrl,
                            high: node.business?.avatarUrlAlta
                        ) ?? "",
                        weight: "",
                        price: priceFormatted,
                        imageUrl: node.imageUrlBaja
                    )
                }

                var storeProducts: [String: [ProductGraphQL]] = [:]

                let stores = data.searchBranches.edges.map { edge -> StoreWithCoordinates in
                    let node = edge.node
                    let etaMinutes = node.deliveryRadius.map { Int($0 * 5 + 10) } ?? 30

                    // Collect nested products for each branch
                    let branchProducts = node.products.map { product in
                        ProductGraphQL(
                            id: product.id,
                            branchId: node.id,
                            name: product.name,
                            price: product.price,
                            currency: product.currency,
                            imageUrl: product.imageUrlBaja,
                            availability: product.availability,
                            createdAt: "",
                            businessName: node.name,
                            distanceKm: nil,
                            categoryId: nil,
                            categoryName: nil
                        )
                    }
                    storeProducts[node.id] = branchProducts

                    return StoreWithCoordinates(
                        id: node.id,
                        name: node.name,
                        etaMinutes: etaMinutes,
                        logoUrl: avatarSmallURL(
                            low: node.avatarUrlBaja,
                            original: node.avatarUrl,
                            high: node.avatarUrlAlta
                        ) ?? "",
                        bannerUrl: coverFastURL(
                            low: node.coverUrlBaja,
                            original: node.coverUrl,
                            high: node.coverUrlAlta
                        ) ?? "",
                        address: node.address,
                        rating: nil,
                        description: nil,
                        coordinate: CLLocationCoordinate2D(
                            latitude: node.coordinates.coordinates.count > 1 ? node.coordinates.coordinates[1] : 0,
                            longitude: node.coordinates.coordinates.count > 0 ? node.coordinates.coordinates[0] : 0
                        ),
                        acceptingOrders: node.acceptingOrders
                    )
                }

                completion(.success((products, stores, storeProducts)))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Search Branches/Stores (con productos anidados)
    @MainActor
    func searchBranches(
        query: String,
        first: Int32 = 20,
        productCategoryId: String? = nil,
        completion:
            @escaping @Sendable (
                Result<([StoreWithCoordinates], [String: [ProductGraphQL]]), Error>
            ) -> Void
    ) {
        print("🌐 SearchRepository - searchBranches() called with query: '\(query)'")

        // Obtener JWT si está disponible
        let jwt = AuthManager.shared.getAccessToken()
        #if DEBUG
            print("🔑 SearchRepository - JWT: \(jwt != nil ? "presente" : "NO presente")")
        #endif

        let searchQuery = LlegoAPI.SearchBranchesQuery(
            query: query,
            first: first,
            after: .none,
            useVectorSearch: .some(true),
            productCategoryId: productCategoryId.map { .some($0) } ?? .none,
            radiusKm: .none,
            jwt: .none  // No JWT: prevents backend from filtering products by user delivery radius
        )

        print("🚀 SearchRepository - Calling apolloClient.fetchCompat() for branches...")
        apolloClient.fetchCompat(query: searchQuery, cachePolicy: .fetchIgnoringCacheData) { result in
            print("📡 SearchRepository - Apollo fetch callback received for branches")

            switch result {
            case .success(let graphQLResult):
                print("✅ SearchRepository - GraphQL query SUCCESS")

                if let errors = graphQLResult.errors, !errors.isEmpty {
                    print(
                        "❌ SearchRepository - GraphQL errors: \(errors.compactMap { $0.message }.joined(separator: ", "))"
                    )
                    completion(
                        .failure(
                            NSError(
                                domain: "GraphQL",
                                code: -1,
                                userInfo: [
                                    NSLocalizedDescriptionKey: errors.first?.message
                                        ?? "Error desconocido"
                                ]
                            )))
                    return
                }

                guard let data = graphQLResult.data else {
                    print("⚠️ SearchRepository - No data in GraphQL result, returning empty array")
                    completion(.success(([], [:])))
                    return
                }

                print(
                    "🏪 SearchRepository - Received \(data.searchBranches.edges.count) branch edges")

                var storeProducts: [String: [ProductGraphQL]] = [:]

                let stores = data.searchBranches.edges.map { edge -> StoreWithCoordinates in
                    let node = edge.node

                    // Mapear productos anidados
                    let products = node.products.map { product in
                        ProductGraphQL(
                            id: product.id,
                            branchId: node.id,
                            name: product.name,
                            price: product.price,
                            currency: product.currency,
                            imageUrl: product.imageUrlBaja,
                            availability: product.availability,
                            createdAt: "",
                            businessName: node.name,
                            distanceKm: nil,
                            categoryId: nil,
                            categoryName: nil
                        )
                    }
                    storeProducts[node.id] = products
                    print("  ├─ Branch '\(node.name)' con \(products.count) productos anidados")

                    // Calcular ETA basado en deliveryRadius
                    let etaMinutes = node.deliveryRadius.map { Int($0 * 5 + 10) } ?? 30

                    return StoreWithCoordinates(
                        id: node.id,
                        name: node.name,
                        etaMinutes: etaMinutes,
                        logoUrl: avatarSmallURL(
                            low: node.avatarUrlBaja,
                            original: node.avatarUrl,
                            high: node.avatarUrlAlta
                        ) ?? "",
                        bannerUrl: coverFastURL(
                            low: node.coverUrlBaja,
                            original: node.coverUrl,
                            high: node.coverUrlAlta
                        ) ?? "",
                        address: node.address ?? "",
                        rating: nil,
                        description: nil,
                        coordinate: CLLocationCoordinate2D(
                            latitude: node.coordinates.coordinates.count > 1 ? node.coordinates.coordinates[1] : 0,
                            longitude: node.coordinates.coordinates.count > 0 ? node.coordinates.coordinates[0] : 0
                        ),
                        acceptingOrders: node.acceptingOrders
                    )
                }

                print(
                    "✅ SearchRepository - Mapped to \(stores.count) Store objects con productos anidados"
                )
                completion(.success((stores, storeProducts)))

            case .failure(let error):
                print("❌ SearchRepository - Apollo fetch FAILED: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}
