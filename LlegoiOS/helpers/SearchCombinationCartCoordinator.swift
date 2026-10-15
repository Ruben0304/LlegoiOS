import Foundation

enum SearchCombinationCartPreparation {
    case added
    case requiresConfiguration(productIds: [String])
}

struct SearchCombinationCartLine {
    let productId: String
    let quantity: Int
    let selectedVariants: [SelectedVariantOption]
    let basePrice: Double
    let unitPrice: Double
}

enum SearchCombinationCartError: LocalizedError {
    case invalidCombination
    case unavailable(String)
    case changedPrice
    case differentBranch
    case missingVariants(String)
    case invalidSelection(String)
    case catalogOnly
    case ordersPaused

    var errorDescription: String? {
        switch self {
        case .invalidCombination: return "No se pudo preparar la combinación. Vuelve a buscar."
        case .unavailable(let name): return "\(name) ya no está disponible en esta sucursal. Vuelve a buscar."
        case .changedPrice: return "El precio de un producto cambió. Vuelve a buscar para ver el total actualizado."
        case .differentBranch: return "Tu carrito contiene productos de otra sucursal. Completa ese pedido o vacía el carrito antes de añadir esta combinación."
        case .missingVariants(let name): return "No se pudieron cargar las opciones de \(name). Inténtalo de nuevo."
        case .invalidSelection(let name): return "Elige las opciones de \(name) antes de añadir la combinación."
        case .catalogOnly: return "Esta sucursal solo muestra su catálogo y no permite añadir productos al carrito."
        case .ordersPaused: return BranchOrderingMessages.notAcceptingOrdersDetail
        }
    }
}

/// Revalidates the entire selection before committing any product. These are
/// ordinary order lines, independent of the merchant's registered combo system.
@MainActor
final class SearchCombinationCartCoordinator {
    static let shared = SearchCombinationCartCoordinator()
    typealias DetailLoader = @MainActor (String) async throws -> ProductDetailGraphQL
    typealias BranchEligibilityLoader = @MainActor (String) async throws -> Bool

    private let cart: CartManager
    private let loadDetail: DetailLoader
    private let canOrderFromBranch: BranchEligibilityLoader
    private var isAdding = false

    init(
        cart: CartManager = .shared,
        canOrderFromBranch: BranchEligibilityLoader? = nil,
        loadDetail: DetailLoader? = nil
    ) {
        self.cart = cart
        self.loadDetail = loadDetail ?? { id in
            try await withCheckedThrowingContinuation { continuation in
                ProductDetailRepository().fetchProductDetail(id: id) { result in
                    continuation.resume(with: result)
                }
            }
        }
        self.canOrderFromBranch = canOrderFromBranch ?? { id in
            try await withCheckedThrowingContinuation { continuation in
                StoreDetailRepository().fetchBranchDetail(id: id) { result in
                    do {
                        let branch = try result.get()
                        guard branch.acceptingOrders else {
                            continuation.resume(throwing: SearchCombinationCartError.ordersPaused)
                            return
                        }
                        continuation.resume(returning: !branch.catalogOnly)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    func prepare(_ combination: SearchCombination) async throws -> SearchCombinationCartPreparation {
        try await add(combination, selections: nil)
    }

    func add(
        _ combination: SearchCombination,
        selections: [String: [SelectedVariantOption]]?
    ) async throws -> SearchCombinationCartPreparation {
        guard !isAdding else { throw SearchCombinationCartError.invalidCombination }
        isAdding = true
        defer { isAdding = false }
        let details = try await configurationDetails(for: combination)
        let needsOptions = details.filter { !($0.variantLists ?? []).isEmpty }
        if selections == nil, !needsOptions.isEmpty {
            return .requiresConfiguration(productIds: needsOptions.map(\.id))
        }

        let lines = try zip(combination.products, details).map { product, detail in
            let selected = selections?[product.id] ?? []
            let validated = try validatedSelections(selected, detail: detail)
            let price = NSDecimalNumber(decimal: computeFinalUnitPrice(
                base: Decimal(detail.price), selected: validated)).doubleValue
            guard price.isFinite, price >= 0 else { throw SearchCombinationCartError.invalidCombination }
            return SearchCombinationCartLine(
                productId: product.id, quantity: product.quantity, selectedVariants: validated,
                basePrice: detail.price, unitPrice: price)
        }

        // The cart may change while requests are in flight. Check its exact
        // contents again immediately before the single synchronous commit.
        for _ in 0..<3 {
            try Task.checkCancellation()
            let snapshot = Set(cart.localItems.map(\.productId))
            if cart.localShowcaseItems.contains(where: { $0.branchId != combination.branchId }) {
                throw SearchCombinationCartError.differentBranch
            }
            for id in snapshot.sorted() {
                let detail = try await loadDetail(id)
                guard detail.branchId == combination.branchId else {
                    throw SearchCombinationCartError.differentBranch
                }
            }
            if snapshot == Set(cart.localItems.map(\.productId)) {
                guard cart.localShowcaseItems.allSatisfy({ $0.branchId == combination.branchId }) else {
                    throw SearchCombinationCartError.differentBranch
                }
                try Task.checkCancellation()
                try cart.addSearchCombinationProducts(lines)
                return .added
            }
        }
        throw SearchCombinationCartError.invalidCombination
    }

    func configurationDetails(for combination: SearchCombination) async throws -> [ProductDetailGraphQL] {
        guard combination.products.count >= 2, !combination.branchId.isEmpty,
              Set(combination.products.map(\.id)).count == combination.products.count,
              combination.products.allSatisfy({
                  !$0.id.isEmpty && $0.branchId == combination.branchId && $0.quantity > 0
                  && $0.price.isFinite && $0.price >= 0 && $0.currency == combination.currency
              }) else { throw SearchCombinationCartError.invalidCombination }
        guard try await canOrderFromBranch(combination.branchId) else {
            throw SearchCombinationCartError.catalogOnly
        }
        var details: [ProductDetailGraphQL] = []
        for product in combination.products {
            try Task.checkCancellation()
            let detail = try await loadDetail(product.id)
            try Task.checkCancellation()
            guard detail.id == product.id, detail.branchId == combination.branchId, detail.availability else {
                throw SearchCombinationCartError.unavailable(product.name)
            }
            guard detail.price.isFinite, detail.price >= 0,
                  detail.currency == product.currency, abs(detail.price - product.price) < 0.005 else {
                throw SearchCombinationCartError.changedPrice
            }
            let lists = detail.variantLists ?? []
            let loadedIDs = Set(lists.map(\.id))
            guard Set(detail.variantListIds ?? []).isSubset(of: loadedIDs),
                  lists.allSatisfy({ !$0.options.isEmpty }) else {
                throw SearchCombinationCartError.missingVariants(product.name)
            }
            details.append(detail)
        }
        return details
    }

    private func validatedSelections(
        _ selections: [SelectedVariantOption], detail: ProductDetailGraphQL
    ) throws -> [SelectedVariantOption] {
        let lists = detail.variantLists ?? []
        guard selections.count == lists.count else {
            throw SearchCombinationCartError.invalidSelection(detail.name)
        }
        return try lists.map { list in
            let matches = selections.filter { $0.listId == list.id }
            guard matches.count == 1, let selection = matches.first,
                  let option = list.options.first(where: {
                      $0.id == selection.optionId && $0.name == selection.optionName
                  }) else { throw SearchCombinationCartError.invalidSelection(detail.name) }
            // Use the current catalog adjustment rather than a stale client value.
            guard option.priceAdjustment == selection.priceAdjustment else {
                throw SearchCombinationCartError.changedPrice
            }
            return SelectedVariantOption(
                listId: list.id, listName: list.name, optionId: option.id,
                optionName: option.name, priceAdjustment: option.priceAdjustment)
        }
    }
}
