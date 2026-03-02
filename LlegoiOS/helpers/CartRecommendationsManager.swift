import Foundation
import Combine

@MainActor
final class CartRecommendationsManager: ObservableObject {
    static let shared = CartRecommendationsManager()

    @Published private(set) var suggestedProducts: [Product] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let repository = CartRepository()
    private let cartManager = CartManager.shared
    private let userDefaults = UserDefaults.standard
    private let cachedProductsKey = "llego_cached_ai_recommendations"
    private let cachedSignatureKey = "llego_cached_ai_recommendations_cart_signature"

    private var cartObserver: AnyCancellable?
    private var loadingTask: Task<Void, Never>?
    private var currentCartSignature: String = ""

    private init() {
        loadPersistedState()
        observeCartChanges()
        bootstrapIfNeeded()
    }

    func refreshNow() {
        let signature = Self.signature(for: cartManager.localItems)
        refreshIfNeeded(for: signature)
    }

    private func observeCartChanges() {
        cartObserver = cartManager.$localItems
            .map(Self.signature(for:))
            .removeDuplicates()
            .sink { [weak self] signature in
                self?.handleCartSignatureChange(signature)
            }
    }

    private func bootstrapIfNeeded() {
        let signature = Self.signature(for: cartManager.localItems)
        currentCartSignature = signature
        refreshIfNeeded(for: signature)
    }

    private func handleCartSignatureChange(_ signature: String) {
        // Solo limpiar/recargar si realmente cambió el contenido del carrito.
        guard signature != currentCartSignature else { return }
        currentCartSignature = signature

        // Al cambiar el carrito, se limpia el caché y luego se recarga en background.
        clearPersistedRecommendations(signature: signature)

        guard !signature.isEmpty else {
            return
        }

        startBackgroundLoad(for: signature)
    }

    private func refreshIfNeeded(for signature: String) {
        if signature.isEmpty {
            clearPersistedRecommendations(signature: signature)
            return
        }

        let persistedSignature = userDefaults.string(forKey: cachedSignatureKey) ?? ""
        if persistedSignature == signature, !suggestedProducts.isEmpty {
            return
        }

        if isLoading, currentCartSignature == signature {
            return
        }

        currentCartSignature = signature
        startBackgroundLoad(for: signature)
    }

    private func startBackgroundLoad(for signature: String) {
        loadingTask?.cancel()
        isLoading = true
        errorMessage = nil
        
        let productIds = cartManager.localItems.map(\.productId)
        
        loadingTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                print("🛒 [CartRecommendationsManager] Iniciando carga...")
                
                let result = try await RecommendationRouter.shared.getRecommendations(
                    context: .cart(productIds: productIds),
                    limit: 6
                )
                
                guard !Task.isCancelled else { return }
                
                print("✅ [CartRecommendationsManager] Recibidas \(result.products.count) recomendaciones")
                print("   Fuente: \(result.source)")
                print("   Usó fallback: \(result.usedFallback)")
                
                self.suggestedProducts = result.products
                self.isLoading = false
                self.errorMessage = nil
                self.persist(products: result.products, signature: signature)
                
            } catch {
                guard !Task.isCancelled else { return }
                
                print("❌ [CartRecommendationsManager] Error: \(error.localizedDescription)")
                self.suggestedProducts = []
                self.isLoading = false
                self.errorMessage = "No se pudieron cargar recomendaciones"
                self.persist(products: [], signature: signature)
            }
        }
    }

    private func fetchCloudRecommendations(productIds: [String]) async throws -> [Product] {
        try await withCheckedThrowingContinuation { continuation in
            repository.fetchCloudRecommendations(productIds: productIds, limit: 6) { result in
                continuation.resume(with: result)
            }
        }
    }

    private func loadPersistedState() {
        guard let data = userDefaults.data(forKey: cachedProductsKey) else {
            suggestedProducts = []
            return
        }

        do {
            suggestedProducts = try JSONDecoder().decode([Product].self, from: data)
        } catch {
            suggestedProducts = []
        }
    }

    private func persist(products: [Product], signature: String) {
        if let encoded = try? JSONEncoder().encode(products) {
            userDefaults.set(encoded, forKey: cachedProductsKey)
        }
        userDefaults.set(signature, forKey: cachedSignatureKey)
    }

    private func clearPersistedRecommendations(signature: String) {
        loadingTask?.cancel()
        suggestedProducts = []
        errorMessage = nil
        isLoading = false
        persist(products: [], signature: signature)
    }

    private static func signature(for items: [CartItemLocal]) -> String {
        // Solo los IDs ordenados — cambios de cantidad no disparan nuevas recomendaciones
        items
            .map(\.productId)
            .sorted()
            .joined(separator: "|")
    }
}
