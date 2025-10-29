import Foundation
import Combine

/// Singleton para gestionar el carrito globalmente desde cualquier parte de la app
@MainActor
class CartManager: ObservableObject {
    static let shared = CartManager()

    @Published private(set) var cartItemCount: Int = 0
    @Published private(set) var localItems: [CartItemLocal] = []

    private let userDefaults = UserDefaults.standard
    private let cartKey = "llego_cart_items"

    private init() {
        loadCartItems()
        updateItemCount()
    }

    // MARK: - Public Methods

    /// Añadir producto al carrito (llamar desde cualquier parte de la app)
    func addToCart(productId: String, quantity: Int = 1) {
        var items = localItems

        if let index = items.firstIndex(where: { $0.productId == productId }) {
            // Si ya existe, incrementar cantidad
            items[index].quantity += quantity
            print("✅ Updated product '\(productId)' to quantity \(items[index].quantity)")
        } else {
            // Si no existe, añadir nuevo item
            items.append(CartItemLocal(productId: productId, quantity: quantity))
            print("✅ Added NEW product with ID: '\(productId)' quantity: \(quantity)")
        }

        saveCartItems(items)
        print("📦 Cart now has \(items.count) unique products, total items: \(cartItemCount)")
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

    /// Limpiar todo el carrito
    func clearCart() {
        userDefaults.removeObject(forKey: cartKey)
        localItems = []
        updateItemCount()
        print("🧹 Cart cleared")
    }

    /// Obtener cantidad de un producto específico en el carrito
    func getQuantity(for productId: String) -> Int {
        localItems.first(where: { $0.productId == productId })?.quantity ?? 0
    }

    /// Verificar si un producto está en el carrito
    func isInCart(productId: String) -> Bool {
        localItems.contains(where: { $0.productId == productId })
    }

    // MARK: - Private Methods

    private func saveCartItems(_ items: [CartItemLocal]) {
        let encoded = items.map { ["id": $0.productId, "quantity": $0.quantity] }
        userDefaults.set(encoded, forKey: cartKey)
        localItems = items
        updateItemCount()
    }

    private func loadCartItems() {
        guard let data = userDefaults.array(forKey: cartKey) as? [[String: Any]] else {
            localItems = []
            return
        }

        localItems = data.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let quantity = dict["quantity"] as? Int else {
                return nil
            }
            return CartItemLocal(productId: id, quantity: quantity)
        }
    }

    private func updateItemCount() {
        cartItemCount = localItems.reduce(0) { $0 + $1.quantity }
    }
}
