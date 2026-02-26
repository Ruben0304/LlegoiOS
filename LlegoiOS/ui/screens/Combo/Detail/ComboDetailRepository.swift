import Foundation
import Apollo

class ComboDetailRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    func fetchComboDetail(id: String, completion: @escaping @Sendable (Result<ComboDetailGraphQL, Error>) -> Void) {
        apolloClient.fetch(
            query: LlegoAPI.GetComboDetailQuery(comboId: id),
            cachePolicy: .returnCacheDataAndFetch
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors (Combo Detail):")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }
                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"])))
                    return
                }

                guard let combo = graphQLResult.data?.combo else {
                    print("⚠️ No combo data received for ID: \(id)")
                    completion(.failure(NSError(domain: "ComboDetail", code: -1, userInfo: [NSLocalizedDescriptionKey: "Combo no encontrado"])))
                    return
                }

                let detail = ComboDetailGraphQL(
                    id: combo.id,
                    branchId: combo.branchId,
                    name: combo.name,
                    description: combo.description,
                    imageUrl: combo.imageUrl,
                    currency: combo.currency,
                    availability: combo.availability,
                    discountType: combo.discountType.rawValue,
                    discountValue: combo.discountValue,
                    basePrice: combo.basePrice,
                    finalPrice: combo.finalPrice,
                    savings: combo.savings,
                    branchName: combo.branch?.name ?? "Tienda",
                    branchLogoUrl: combo.branch?.avatarUrl,
                    representativeProducts: combo.representativeProducts.map {
                        ComboRepresentativeProductGraphQL(id: $0.id, name: $0.name, imageUrl: $0.imageUrl ?? "")
                    },
                    slots: combo.slots.map { slot in
                        ComboSlotGraphQL(
                            id: slot.id,
                            name: slot.name,
                            description: slot.description,
                            minSelections: slot.minSelections,
                            maxSelections: slot.maxSelections,
                            isRequired: slot.isRequired,
                            displayOrder: slot.displayOrder,
                            options: slot.options.map { option in
                                ComboOptionGraphQL(
                                    productId: option.productId,
                                    isDefault: option.isDefault,
                                    priceAdjustment: option.priceAdjustment,
                                    productName: option.product?.name ?? "",
                                    productImageUrl: option.product?.imageUrl ?? "",
                                    productBasePrice: option.product?.price ?? 0,
                                    productCurrency: option.product?.currency ?? "USD",
                                    availableModifiers: option.availableModifiers.map {
                                        ComboModifierGraphQL(name: $0.name, priceAdjustment: $0.priceAdjustment)
                                    }
                                )
                            }
                        )
                    },
                    createdAt: combo.createdAt
                )

                print("✅ Fetched combo detail for ID: \(id)")
                completion(.success(detail))

            case .failure(let error):
                print("❌ Network Error (Combo Detail): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    func fetchCombosByBranch(branchId: String, completion: @escaping @Sendable (Result<[ComboDetailGraphQL], Error>) -> Void) {
        apolloClient.fetch(
            query: LlegoAPI.GetCombosByBranchQuery(branchId: branchId),
            cachePolicy: .returnCacheDataAndFetch
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors (Combos By Branch):")
                    errors.forEach { error in print("  - \(error.localizedDescription)") }
                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"])))
                    return
                }

                guard let combos = graphQLResult.data?.combosByBranch else {
                    completion(.success([]))
                    return
                }

                let details = combos.map { combo in
                    ComboDetailGraphQL(
                        id: combo.id,
                        branchId: combo.branchId,
                        name: combo.name,
                        description: combo.description,
                        imageUrl: combo.imageUrl,
                        currency: combo.currency,
                        availability: combo.availability,
                        discountType: combo.discountType.rawValue,
                        discountValue: combo.discountValue,
                        basePrice: combo.basePrice,
                        finalPrice: combo.finalPrice,
                        savings: combo.savings,
                        branchName: combo.branch?.name ?? "Tienda",
                        branchLogoUrl: combo.branch?.avatarUrl,
                        representativeProducts: combo.representativeProducts.map {
                            ComboRepresentativeProductGraphQL(id: $0.id, name: $0.name, imageUrl: $0.imageUrl ?? "")
                        },
                        slots: combo.slots.map { slot in
                            ComboSlotGraphQL(
                                id: slot.id,
                                name: slot.name,
                                description: slot.description,
                                minSelections: slot.minSelections,
                                maxSelections: slot.maxSelections,
                                isRequired: slot.isRequired,
                                displayOrder: slot.displayOrder,
                                options: slot.options.map { option in
                                    ComboOptionGraphQL(
                                        productId: option.productId,
                                        isDefault: option.isDefault,
                                        priceAdjustment: option.priceAdjustment,
                                        productName: option.product?.name ?? "",
                                        productImageUrl: option.product?.imageUrl ?? "",
                                        productBasePrice: option.product?.price ?? 0,
                                        productCurrency: option.product?.currency ?? "USD",
                                        availableModifiers: option.availableModifiers.map {
                                            ComboModifierGraphQL(name: $0.name, priceAdjustment: $0.priceAdjustment)
                                        }
                                    )
                                }
                            )
                        },
                        createdAt: combo.createdAt
                    )
                }

                print("✅ Fetched \(details.count) combos for branch \(branchId)")
                completion(.success(details))

            case .failure(let error):
                print("❌ Network Error (Combos By Branch): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

// MARK: - GraphQL Models

struct ComboDetailGraphQL: Identifiable, Sendable, Equatable {
    let id: String
    let branchId: String
    let name: String
    let description: String
    let imageUrl: String?
    let currency: String
    let availability: Bool
    let discountType: String
    let discountValue: Double
    let basePrice: Double
    let finalPrice: Double
    let savings: Double
    let branchName: String
    let branchLogoUrl: String?
    let representativeProducts: [ComboRepresentativeProductGraphQL]
    let slots: [ComboSlotGraphQL]
    let createdAt: String
}

struct ComboRepresentativeProductGraphQL: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let imageUrl: String
}

struct ComboSlotGraphQL: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let description: String?
    let minSelections: Int
    let maxSelections: Int
    let isRequired: Bool
    let displayOrder: Int
    let options: [ComboOptionGraphQL]
}

struct ComboOptionGraphQL: Sendable, Equatable {
    let productId: String
    let isDefault: Bool
    let priceAdjustment: Double
    let productName: String
    let productImageUrl: String
    let productBasePrice: Double
    let productCurrency: String
    let availableModifiers: [ComboModifierGraphQL]

    var effectivePrice: Double {
        productBasePrice + priceAdjustment
    }
}

struct ComboModifierGraphQL: Sendable, Equatable {
    let name: String
    let priceAdjustment: Double
}
