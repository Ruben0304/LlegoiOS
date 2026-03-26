import Foundation
import Apollo

class ComboDetailRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    func fetchComboDetail(id: String, completion: @escaping @Sendable (Result<ComboDetailGraphQL, Error>) -> Void) {
        apolloClient.fetchCompat(
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

                let detail = Self.mapCombo(combo)
                print("✅ Fetched combo detail for ID: \(id)")
                completion(.success(detail))

            case .failure(let error):
                print("❌ Network Error (Combo Detail): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    func fetchCombosByBranch(branchId: String, completion: @escaping @Sendable (Result<[ComboDetailGraphQL], Error>) -> Void) {
        apolloClient.fetchCompat(
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

                let details = combos.map { Self.mapCombosByBranch($0) }
                print("✅ Fetched \(details.count) combos for branch \(branchId)")
                completion(.success(details))

            case .failure(let error):
                print("❌ Network Error (Combos By Branch): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - Private mapping

    private static func mapSlot(_ slot: LlegoAPI.GetComboDetailQuery.Data.Combo.Slot) -> ComboSlotGraphQL {
        ComboSlotGraphQL(
            id: slot.id,
            name: slot.name,
            description: slot.description,
            minSelections: slot.minSelections,
            maxSelections: slot.maxSelections,
            isFree: slot.isFree,
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
    }

    private static func mapSlotByBranch(_ slot: LlegoAPI.GetCombosByBranchQuery.Data.CombosByBranch.Slot) -> ComboSlotGraphQL {
        ComboSlotGraphQL(
            id: slot.id,
            name: slot.name,
            description: slot.description,
            minSelections: slot.minSelections,
            maxSelections: slot.maxSelections,
            isFree: slot.isFree,
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
    }

    private static func mapCombo(_ combo: LlegoAPI.GetComboDetailQuery.Data.Combo) -> ComboDetailGraphQL {
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
            finalPrice: combo.finalPrice,
            savings: combo.savings,
            startingFinalPrice: combo.startingFinalPrice,
            startingSavings: combo.startingSavings,
            branchName: combo.branch?.name ?? "Tienda",
            branchLogoUrl: combo.branch?.avatarUrl,
            representativeProducts: combo.representativeProducts.map {
                ComboRepresentativeProductGraphQL(id: $0.id, name: $0.name, imageUrl: $0.imageUrl)
            },
            slots: combo.slots.map { mapSlot($0) },
            giftOptions: combo.giftOptions.map {
                ComboGiftOptionGraphQL(
                    productId: $0.productId,
                    productName: $0.product?.name ?? "",
                    productImageUrl: $0.product?.imageUrl ?? ""
                )
            },
            createdAt: combo.createdAt
        )
    }

    private static func mapCombosByBranch(_ combo: LlegoAPI.GetCombosByBranchQuery.Data.CombosByBranch) -> ComboDetailGraphQL {
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
            finalPrice: combo.finalPrice,
            savings: combo.savings,
            startingFinalPrice: combo.startingFinalPrice,
            startingSavings: combo.startingSavings,
            branchName: combo.branch?.name ?? "Tienda",
            branchLogoUrl: combo.branch?.avatarUrl,
            representativeProducts: combo.representativeProducts.map {
                ComboRepresentativeProductGraphQL(id: $0.id, name: $0.name, imageUrl: $0.imageUrl)
            },
            slots: combo.slots.map { mapSlotByBranch($0) },
            giftOptions: combo.giftOptions.map {
                ComboGiftOptionGraphQL(
                    productId: $0.productId,
                    productName: $0.product?.name ?? "",
                    productImageUrl: $0.product?.imageUrl ?? ""
                )
            },
            createdAt: combo.createdAt
        )
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
    /// Price after discount applied
    let finalPrice: Double
    /// Amount saved by this combo
    let savings: Double
    /// Minimum possible final price across all slot option combinations
    let startingFinalPrice: Double?
    /// Minimum savings across all combinations
    let startingSavings: Double?
    let branchName: String
    let branchLogoUrl: String?
    let representativeProducts: [ComboRepresentativeProductGraphQL]
    let slots: [ComboSlotGraphQL]
    let giftOptions: [ComboGiftOptionGraphQL]
    let createdAt: String

    /// Base price (before discount) = finalPrice + savings
    var basePrice: Double { finalPrice + savings }

    /// Starting base price across all option combinations
    var startingBasePrice: Double? {
        guard let startingFinalPrice, let startingSavings else { return nil }
        return startingFinalPrice + startingSavings
    }

    var hasDiscount: Bool { savings > 0.009 }
    var hasFreeSlots: Bool { slots.contains { $0.isFree } }
    var hasGifts: Bool { !giftOptions.isEmpty }

    var comboKind: ComboKind {
        if hasGifts { return .withGifts }
        if hasFreeSlots { return .withFreeSlots }
        switch discountType.uppercased() {
        case "PERCENTAGE", "FIXED": return .discounted
        default: return .bundle
        }
    }
}

enum ComboKind: Sendable, Equatable {
    case discounted    // PERCENTAGE or FIXED discount on paid slots
    case withGifts     // store-selected gift products (free, not selectable)
    case withFreeSlots // user-selected slots that are free/included
    case bundle        // plain bundle, no discount, no gifts, all paid
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
    let isFree: Bool
    let displayOrder: Int
    let options: [ComboOptionGraphQL]

    var isRequired: Bool { minSelections > 0 }
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

struct ComboGiftOptionGraphQL: Identifiable, Sendable, Equatable {
    let productId: String
    let productName: String
    let productImageUrl: String
    var id: String { productId }
}
