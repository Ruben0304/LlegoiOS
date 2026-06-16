import Apollo
import Foundation

class StoreDetailRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch complete branch/store details by ID
    func fetchBranchDetail(
        id: String, completion: @escaping @Sendable (Result<BranchDetailGraphQL, Error>) -> Void
    ) {
        apolloClient.fetchCompat(
            query: LlegoAPI.GetBranchDetailQuery(id: id),
            cachePolicy: .fetchIgnoringCacheData
        ) { result in
            switch result {
            case .success(let graphQLResult):
                print("🔎 [StoreDetail] GetBranchDetail id=\(id) baseURL=\(ApolloClientManager.baseURL)")

                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors (Branch Detail):")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }
                }

                guard let branch = graphQLResult.data?.branch else {
                    print("⚠️ No branch detail data received for ID: \(id)")
                    completion(
                        .failure(
                            NSError(
                                domain: "BranchDetail",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Branch not found"]
                            )
                        )
                    )
                    return
                }

                let schedule = BranchSchedule(
                    days: branch.schedule.days.map { d in
                        DaySchedule(
                            day: d.day,
                            isOpen: d.isOpen,
                            hours: d.hours.map { h in TimeRange(open: h.open, close: h.close) }
                        )
                    },
                    temporaryStatus: branch.schedule.temporaryStatus.map { ts in
                        BranchTemporaryStatus(
                            temporallyClosed: ts.temporallyClosed,
                            temporallyOpen: ts.temporallyOpen,
                            reason: ts.reason
                        )
                    }
                )

                let branchDetail = BranchDetailGraphQL(
                    id: branch.id,
                    businessId: branch.businessId,
                    name: branch.name,
                    address: branch.address,
                    coordinates: CoordinatesGraphQL(
                        type: branch.coordinates.type,
                        coordinates: branch.coordinates.coordinates
                    ),
                    phone: branch.phone,
                    status: branch.status ?? "",
                    avatarUrl: branch.avatarUrl,
                    avatarUrlBaja: branch.avatarUrlBaja,
                    avatarUrlAlta: branch.avatarUrlAlta,
                    coverUrl: branch.coverUrl,
                    coverUrlBaja: branch.coverUrlBaja,
                    coverUrlAlta: branch.coverUrlAlta,
                    deliveryRadius: branch.deliveryRadius,
                    facilities: nil,
                    createdAt: branch.createdAt,
                    socialMedia: nil,
                    acceptedCurrency: branch.acceptedCurrency?.value?.rawValue,
                    exchangeRate: branch.exchangeRate,
                    schedule: schedule,
                    showcases: branch.showcases.map { showcase in
                        ShowcaseGraphQL(
                            id: showcase.id,
                            title: showcase.title,
                            description: showcase.description,
                            imageUrl: showcase.imageUrl,
                            isActive: showcase.isActive,
                            items: showcase.items?.map { item in
                                ShowcaseItemGraphQL(
                                    id: item.id,
                                    name: item.name,
                                    description: item.description,
                                    price: item.price,
                                    availability: item.availability
                                )
                            }
                        )
                    },
                    catalogOnly: branch.catalogOnly
                )

                print(
                    "🔎 [StoreDetail] branchId=\(branch.id) name=\(branch.name) acceptedCurrency=\(branchDetail.acceptedCurrency ?? "nil") exchangeRate=\(branchDetail.exchangeRate.map(String.init) ?? "nil")"
                )
                print("✅ Fetched branch detail for ID: \(id)")
                completion(.success(branchDetail))

            case .failure(let error):
                print("❌ Network Error (Branch Detail): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // Fetch business details including social media
    func fetchBusinessDetail(
        id: String, completion: @escaping @Sendable (Result<BusinessDetailGraphQL, Error>) -> Void
    ) {
        apolloClient.fetchCompat(
            query: LlegoAPI.GetBusinessDetailQuery(id: id),
            cachePolicy: .returnCacheDataAndFetch
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors (Business Detail):")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }
                    completion(
                        .failure(
                            NSError(
                                domain: "GraphQL", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"])))
                    return
                }

                guard let business = graphQLResult.data?.business else {
                    print("⚠️ No business detail data received for ID: \(id)")
                    completion(
                        .failure(
                            NSError(
                                domain: "BusinessDetail", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Business not found"])))
                    return
                }

                let businessDetail = BusinessDetailGraphQL(
                    id: business.id,
                    name: business.name,
                    socialMedia: nil,  // Not available in query
                    avatarUrl: business.avatarUrl,
                    avatarUrlBaja: business.avatarUrlBaja,
                    avatarUrlAlta: business.avatarUrlAlta,
                    coverUrl: business.avatarUrl
                )

                print("✅ Fetched business detail for ID: \(id)")
                completion(.success(businessDetail))

            case .failure(let error):
                print("❌ Network Error (Business Detail): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // Fetch sibling branches (branches of the same business)
    func fetchSiblingBranches(
        businessId: String, completion: @escaping @Sendable (Result<[BranchGraphQL], Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()
            let branchType = BranchTypeManager.shared.selectedType.rawValue

            client.fetchCompat(
                query: LlegoAPI.GetBranchesQuery(
                    first: 100,
                    after: .none,
                    businessId: .some(businessId),
                    tipo: .none,  // Fetch all branches for this business, ignoring user's current category filter
                    radiusKm: .none,
                    productCategoryId: .none,
                    jwt: jwt.map { .some($0) } ?? .none
                ),
                cachePolicy: .returnCacheDataAndFetch
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (Sibling Branches):")
                        errors.forEach { error in
                            print("  - \(error.localizedDescription)")
                        }
                        completion(
                            .failure(
                                NSError(
                                    domain: "GraphQL", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"]
                                )))
                        return
                    }

                    guard let data = graphQLResult.data else {
                        print("⚠️ No sibling branches data received")
                        completion(.success([]))
                        return
                    }

                    let mappedBranches = data.branches.edges.map { edge in
                        BranchGraphQL(
                            id: edge.node.id,
                            businessId: edge.node.businessId,
                            name: edge.node.name,
                            address: edge.node.address ?? "",
                            coordinates: CoordinatesGraphQL(
                                type: edge.node.coordinates.type,
                                coordinates: edge.node.coordinates.coordinates
                            ),
                            phone: edge.node.phone,
                            status: edge.node.status ?? "",
                            avatarUrl: edge.node.avatarUrl,
                            avatarUrlBaja: edge.node.avatarUrlBaja,
                            avatarUrlAlta: edge.node.avatarUrlAlta,
                            coverUrl: edge.node.coverUrl,
                            coverUrlBaja: edge.node.coverUrlBaja,
                            coverUrlAlta: edge.node.coverUrlAlta,
                            deliveryRadius: edge.node.deliveryRadius,
                            facilities: nil,
                            createdAt: edge.node.createdAt
                        )
                    }

                    print(
                        "✅ Fetched \(mappedBranches.count) sibling branches for business \(businessId)"
                    )
                    completion(.success(mappedBranches))

                case .failure(let error):
                    print("❌ Network Error (Sibling Branches): \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    // Fetch products for a specific branch
    func fetchBranchProducts(
        branchId: String, limit: Int = 10,
        completion: @escaping @Sendable (Result<[StoreProductGraphQL], Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()
            let branchType = BranchTypeManager.shared.selectedType.rawValue

            client.fetchCompat(
                query: LlegoAPI.GetProductsQuery(
                    first: Int32(limit),
                    after: .none,
                    branchId: .some(branchId),
                    categoryId: .none,
                    availableOnly: .some(true),
                    branchTipo: LlegoAPI.BranchTipo(rawValue: branchType.uppercased()).map {
                        .some(GraphQLEnum($0))
                    } ?? .none,
                    radiusKm: .none,
                    jwt: jwt.map { .some($0) } ?? .none
                ),
                cachePolicy: .returnCacheDataAndFetch
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (Branch Products):")
                        errors.forEach { error in
                            print("  - \(error.localizedDescription)")
                        }
                        completion(
                            .failure(
                                NSError(
                                    domain: "GraphQL", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"]
                                )))
                        return
                    }

                    guard let products = graphQLResult.data?.products else {
                        print("⚠️ No products data received for branch \(branchId)")
                        completion(.success([]))
                        return
                    }

                    // Limit to first 'limit' products
                    let limitedProducts = Array(products.edges.prefix(limit))

                    let mappedProducts = limitedProducts.map { edge in
                        StoreProductGraphQL(
                            id: edge.node.id,
                            branchId: edge.node.branchId,
                            name: edge.node.name,
                            price: edge.node.price,
                            currency: edge.node.currency,
                            imageUrl: edge.node.imageUrlBaja,
                            availability: edge.node.availability,
                            createdAt: edge.node.createdAt
                        )
                    }

                    print("✅ Fetched \(mappedProducts.count) products for branch \(branchId)")
                    completion(.success(mappedProducts))

                case .failure(let error):
                    print("❌ Network Error (Branch Products): \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Similar Branches via Qdrant recommend

    func fetchSimilarBranches(
        branchId: String,
        completion: @escaping @Sendable (Result<[BranchGraphQL], Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()

            client.fetchCompat(
                query: LlegoAPI.GetSimilarBranchesQuery(
                    branchId: branchId,
                    limit: .some(6),
                    jwt: jwt.map { .some($0) } ?? .none
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    let nodes = graphQLResult.data?.getSimilarBranches ?? []
                    let mapped = nodes.map { node in
                        BranchGraphQL(
                            id: node.id,
                            businessId: node.businessId,
                            name: node.name,
                            address: node.address ?? "",
                            coordinates: CoordinatesGraphQL(type: "Point", coordinates: []),
                            phone: "",
                            status: "",
                            avatarUrl: node.avatarUrl,
                            avatarUrlBaja: node.avatarUrlBaja,
                            avatarUrlAlta: node.avatarUrlAlta,
                            coverUrl: node.coverUrl,
                            coverUrlBaja: node.coverUrlBaja,
                            coverUrlAlta: node.coverUrlAlta,
                            deliveryRadius: node.deliveryRadius,
                            facilities: nil,
                            createdAt: node.createdAt
                        )
                    }
                    completion(.success(mapped))
                case .failure(let error):
                    print("⚠️ [StoreDetail] fetchSimilarBranches failed: \(error.localizedDescription)")
                    completion(.success([]))
                }
            }
        }
    }

    // MARK: - Branch Likes

    /// Like a branch (add to user's liked branches)
    func likeBranch(branchId: String, completion: @escaping @Sendable (Result<Bool, Error>) -> Void)
    {
        let client = apolloClient

        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()

            client.perform(
                mutation: LlegoAPI.LikeBranchMutation(
                    branchId: branchId,
                    jwt: jwt.map { .some($0) } ?? .none
                )
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (Like Branch):")
                        errors.forEach { error in
                            print("  - \(error.localizedDescription)")
                        }
                        completion(
                            .failure(
                                NSError(
                                    domain: "GraphQL", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"]
                                )))
                        return
                    }

                    if graphQLResult.data?.likeBranch != nil {
                        print("✅ Successfully liked branch: \(branchId)")
                        completion(.success(true))
                    } else {
                        completion(
                            .failure(
                                NSError(
                                    domain: "LikeBranch", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Failed to like branch"]))
                        )
                    }

                case .failure(let error):
                    print("❌ Network Error (Like Branch): \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    /// Unlike a branch (remove from user's liked branches)
    func unlikeBranch(
        branchId: String, completion: @escaping @Sendable (Result<Bool, Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()

            client.perform(
                mutation: LlegoAPI.UnlikeBranchMutation(
                    branchId: branchId,
                    jwt: jwt.map { .some($0) } ?? .none
                )
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (Unlike Branch):")
                        errors.forEach { error in
                            print("  - \(error.localizedDescription)")
                        }
                        completion(
                            .failure(
                                NSError(
                                    domain: "GraphQL", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"]
                                )))
                        return
                    }

                    if let success = graphQLResult.data?.unlikeBranch, success {
                        print("✅ Successfully unliked branch: \(branchId)")
                        completion(.success(true))
                    } else {
                        completion(
                            .failure(
                                NSError(
                                    domain: "UnlikeBranch", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Failed to unlike branch"]
                                )))
                    }

                case .failure(let error):
                    print("❌ Network Error (Unlike Branch): \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

}

// MARK: - Models
// BranchGraphQL and CoordinatesGraphQL are defined in Store/StoreModels.swift

// Model to represent complete GraphQL Branch details
struct BranchDetailGraphQL: Identifiable, Sendable {
    let id: String
    let businessId: String
    let name: String
    let address: String?
    let coordinates: CoordinatesGraphQL
    let phone: String
    let status: String
    let avatarUrl: String?
    let avatarUrlBaja: String?
    let avatarUrlAlta: String?
    let coverUrl: String?
    let coverUrlBaja: String?
    let coverUrlAlta: String?
    let deliveryRadius: Double?
    let facilities: [String]?
    let createdAt: String
    let socialMedia: [String: String]?
    let acceptedCurrency: String?
    let exchangeRate: Int?
    let schedule: BranchSchedule?
    let showcases: [ShowcaseGraphQL]
    let catalogOnly: Bool

    var preferredAvatarLargeUrl: String? {
        avatarLargeURL(low: avatarUrlBaja, original: avatarUrl, high: avatarUrlAlta)
    }

    var preferredCoverBestUrl: String? {
        coverBestURL(low: coverUrlBaja, original: coverUrl, high: coverUrlAlta)
    }
}

// Model to represent GraphQL Business details
struct BusinessDetailGraphQL: Identifiable, Sendable {
    let id: String
    let name: String
    let socialMedia: [String: String]?
    let avatarUrl: String?
    let avatarUrlBaja: String?
    let avatarUrlAlta: String?
    let coverUrl: String?

    var preferredAvatarLargeUrl: String? {
        avatarLargeURL(low: avatarUrlBaja, original: avatarUrl, high: avatarUrlAlta)
    }
}

// Model to represent GraphQL Product for store detail (to avoid conflict with ProductRepository)
struct StoreProductGraphQL: Identifiable, Sendable {
    let id: String
    let branchId: String
    let name: String
    let price: Double
    let currency: String
    let imageUrl: String
    let availability: Bool
    let createdAt: String
}

struct ShowcaseGraphQL: Identifiable, Sendable {
    let id: String
    let title: String
    let description: String?
    let imageUrl: String
    let isActive: Bool
    let items: [ShowcaseItemGraphQL]?
}

struct ShowcaseItemGraphQL: Identifiable, Sendable {
    let id: String
    let name: String
    let description: String?
    let price: Double?
    let availability: Bool
}
