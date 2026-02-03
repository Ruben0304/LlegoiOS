import Foundation
import Combine
import Apollo

@MainActor
class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()

    @Published private(set) var localItems: [FavoriteItemLocal] = []
    @Published private(set) var favoriteItemCount: Int = 0

    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "llego_favorite_items"
    private let apolloClient = ApolloClientManager.shared.apollo

    private init() {
        loadFavorites()
        updateItemCount()
    }

    // MARK: - Public Methods

    func addFavorite(productId: String) {
        var items = localItems

        guard !items.contains(where: { $0.productId == productId }) else {
            return
        }

        items.append(FavoriteItemLocal(productId: productId))
        saveFavorites(items)
        print("❤️ Added favorite with ID: '\(productId)'")

        // Llamar a la mutation en segundo plano para estadísticas
        sendAddFavoriteMutation(productId: productId)
    }

    func removeFavorite(productId: String) {
        var items = localItems
        items.removeAll { $0.productId == productId }
        saveFavorites(items)
        print("🗑️ Removed favorite with ID: '\(productId)'")
    }

    func toggleFavorite(productId: String) {
        if isFavorite(productId: productId) {
            removeFavorite(productId: productId)
        } else {
            addFavorite(productId: productId)
        }
    }

    func isFavorite(productId: String) -> Bool {
        localItems.contains(where: { $0.productId == productId })
    }

    func clearFavorites() {
        userDefaults.removeObject(forKey: favoritesKey)
        localItems = []
        updateItemCount()
        print("🧹 Favorites cleared")
    }

    // MARK: - Private Methods

    private func saveFavorites(_ items: [FavoriteItemLocal]) {
        let encoded = items.map { $0.productId }
        userDefaults.set(encoded, forKey: favoritesKey)
        localItems = items
        updateItemCount()
    }

    private func loadFavorites() {
        let ids = userDefaults.stringArray(forKey: favoritesKey) ?? []
        localItems = ids.map { FavoriteItemLocal(productId: $0) }
    }

    private func updateItemCount() {
        favoriteItemCount = localItems.count
    }

    /// Enviar mutation al backend para estadísticas (sin bloquear la UI)
    private func sendAddFavoriteMutation(productId: String) {
        Task {
            do {
                // Obtener JWT si está disponible
                let jwt = await AuthManager.shared.getAccessToken()

                // Llamar a la mutation de manera asíncrona
                _ = try await apolloClient.perform(mutation: LlegoAPI.AddFavoriteMutation(
                    productId: productId,
                    jwt: jwt.map { .some($0) } ?? .none
                ))

                print("📊 Favorite analytics sent for product: \(productId)")
            } catch {
                // Silenciosamente fallar - esto es solo para estadísticas
                print("⚠️ Failed to send favorite analytics: \(error.localizedDescription)")
            }
        }
    }
}
