import Apollo
import Combine
import Foundation

/// Singleton para gestionar el carrito globalmente desde cualquier parte de la app
@MainActor
class CartManager: ObservableObject {
    static let shared = CartManager()

    @Published private(set) var cartItemCount: Int = 0
    @Published private(set) var localItems: [CartItemLocal] = []

    private let userDefaults = UserDefaults.standard
    private let cartKey = "llego_cart_items"
    private let apolloClient = ApolloClientManager.shared.apollo

    private init() {
        loadCartItems()
        updateItemCount()
    }

    // MARK: - Public Methods

    /// Añadir producto al carrito (llamar desde cualquier parte de la app)
    func addToCart(
        productId: String,
        quantity: Int = 1,
        selectedVariants: [SelectedVariantOption] = [],
        basePrice: Double? = nil,
        finalUnitPrice: Double? = nil
    ) {
        var items = localItems
        let cartItemId = CartItemLocal.buildCartItemId(
            productId: productId, selectedVariants: selectedVariants)

        if let index = items.firstIndex(where: { $0.cartItemId == cartItemId }) {
            // Si ya existe, incrementar cantidad
            items[index].quantity += quantity
            if let basePrice {
                items[index].basePrice = basePrice
            }
            if let finalUnitPrice {
                items[index].finalUnitPrice = finalUnitPrice
            }
            let unit = items[index].finalUnitPrice ?? items[index].basePrice ?? 0
            items[index].finalTotalPrice = unit * Double(items[index].quantity)
            print("✅ Updated cart line '\(cartItemId)' to quantity \(items[index].quantity)")
        } else {
            // Si no existe, añadir nuevo item
            let item = CartItemLocal(
                productId: productId,
                quantity: quantity,
                selectedVariants: selectedVariants,
                basePrice: basePrice,
                finalUnitPrice: finalUnitPrice,
                finalTotalPrice: nil,
                cartItemId: cartItemId
            )
            items.append(item)
            print("✅ Added NEW cart line with ID: '\(cartItemId)' quantity: \(quantity)")
        }

        saveCartItems(items)
        print("📦 Cart now has \(items.count) unique products, total items: \(cartItemCount)")

        // Llamar a la mutation en segundo plano para estadísticas
        sendAddToCartMutation(productId: productId)
    }

    /// Actualizar cantidad de un producto
    func updateQuantity(productId: String, quantity: Int) {
        var items = localItems

        if let index = items.firstIndex(where: { $0.productId == productId }) {
            if quantity <= 0 {
                // Si cantidad es 0 o menor, remover item
                items.remove(at: index)
            } else {
                items[index].quantity = quantity
                let unit = items[index].finalUnitPrice ?? items[index].basePrice ?? 0
                items[index].finalTotalPrice = unit * Double(quantity)
            }
        }

        saveCartItems(items)
    }

    /// Actualizar cantidad por ID de línea del carrito (soporta variantes)
    func updateQuantity(cartItemId: String, quantity: Int) {
        var items = localItems

        if let index = items.firstIndex(where: { $0.cartItemId == cartItemId }) {
            if quantity <= 0 {
                items.remove(at: index)
            } else {
                items[index].quantity = quantity
                let unit = items[index].finalUnitPrice ?? items[index].basePrice ?? 0
                items[index].finalTotalPrice = unit * Double(quantity)
            }
        }

        saveCartItems(items)
    }

    /// Remover producto del carrito
    func removeFromCart(productId: String) {
        var items = localItems
        items.removeAll { $0.productId == productId }
        saveCartItems(items)
        print("🗑️ Removed product \(productId) from cart")
    }

    func removeFromCart(cartItemId: String) {
        var items = localItems
        items.removeAll { $0.cartItemId == cartItemId }
        saveCartItems(items)
        print("🗑️ Removed cart line \(cartItemId) from cart")
    }

    /// Limpiar todo el carrito
    func clearCart() {
        userDefaults.removeObject(forKey: cartKey)
        localItems = []
        updateItemCount()
        print("🧹 Cart cleared")
    }

    /// Obtener cantidad de un producto específico en el carrito
    func getQuantity(for productId: String) -> Int {
        localItems
            .filter { $0.productId == productId }
            .reduce(0) { partial, item in
                partial + item.quantity
            }
    }

    /// Verificar si un producto está en el carrito
    func isInCart(productId: String) -> Bool {
        localItems.contains(where: { $0.productId == productId })
    }

    // MARK: - Private Methods

    private func saveCartItems(_ items: [CartItemLocal]) {
        do {
            let encoded = try JSONEncoder().encode(items)
            userDefaults.set(encoded, forKey: cartKey)
        } catch {
            print("⚠️ CartManager: Failed to encode cart items - \(error.localizedDescription)")
        }
        localItems = items
        updateItemCount()
    }

    private func loadCartItems() {
        if let encodedData = userDefaults.data(forKey: cartKey) {
            do {
                localItems = try JSONDecoder().decode([CartItemLocal].self, from: encodedData)
                return
            } catch {
                print(
                    "⚠️ CartManager: Failed to decode new cart format - \(error.localizedDescription)"
                )
            }
        }

        // Backward compatibility with old cart format: [[id, quantity]]
        if let legacyData = userDefaults.array(forKey: cartKey) as? [[String: Any]] {
            localItems = legacyData.compactMap { dict in
                guard let id = dict["id"] as? String,
                    let quantity = dict["quantity"] as? Int
                else {
                    return nil
                }
                return CartItemLocal(productId: id, quantity: quantity)
            }
            return
        }

        localItems = []
    }

    private func updateItemCount() {
        cartItemCount = localItems.reduce(0) { $0 + $1.quantity }
    }

    /// Enviar mutation al backend para estadísticas (sin bloquear la UI)
    private func sendAddToCartMutation(productId: String) {
        Task {
            do {
                // Obtener JWT si está disponible
                let jwt = await AuthManager.shared.getAccessToken()

                // Llamar a la mutation de manera asíncrona
                _ = try await apolloClient.perform(
                    mutation: LlegoAPI.AddToCartMutation(
                        productId: productId,
                        jwt: jwt.map { .some($0) } ?? .none
                    ))

                print("📊 Cart analytics sent for product: \(productId)")
            } catch {
                // Silenciosamente fallar - esto es solo para estadísticas
                print("⚠️ Failed to send cart analytics: \(error.localizedDescription)")
            }
        }
    }
}
