import Apollo
import Combine
import Foundation

/// Singleton para gestionar el carrito globalmente desde cualquier parte de la app
@MainActor
class CartManager: ObservableObject {
    static let shared = CartManager()

    @Published private(set) var cartItemCount: Int = 0
    @Published private(set) var localItems: [CartItemLocal] = []
    @Published private(set) var localShowcaseItems: [ShowcaseCartItemLocal] = []

    private let userDefaults = UserDefaults.standard
    private let cartKey = "llego_cart_items"
    private let showcaseCartKey = "llego_showcase_cart_items"
    private let apolloClient = ApolloClientManager.shared.apollo

    private init() {
        loadCartItems()
        loadShowcaseCartItems()
        updateItemCount()
    }

    // MARK: - Public Methods

    /// Añadir producto al carrito (llamar desde cualquier parte de la app)
    func addToCart(
        productId: String,
        quantity: Int = 1,
        selectedVariants: [SelectedVariantOption] = [],
        cartItemId: String? = nil,
        comboGroupId: String? = nil,
        comboId: String? = nil,
        comboName: String? = nil,
        comboComponentSlotId: String? = nil,
        comboComponentSlotName: String? = nil,
        comboComponentOrder: Int? = nil,
        basePrice: Double? = nil,
        finalUnitPrice: Double? = nil
    ) {
        var items = localItems
        let resolvedCartItemId =
            cartItemId
            ?? CartItemLocal.buildCartItemId(
                productId: productId, selectedVariants: selectedVariants)

        if let index = items.firstIndex(where: { $0.cartItemId == resolvedCartItemId }) {
            // Si ya existe, incrementar cantidad
            items[index].quantity += quantity
            items[index].comboGroupId = comboGroupId ?? items[index].comboGroupId
            items[index].comboId = comboId ?? items[index].comboId
            items[index].comboName = comboName ?? items[index].comboName
            items[index].comboComponentSlotId =
                comboComponentSlotId ?? items[index].comboComponentSlotId
            items[index].comboComponentSlotName =
                comboComponentSlotName ?? items[index].comboComponentSlotName
            items[index].comboComponentOrder =
                comboComponentOrder ?? items[index].comboComponentOrder
            if let basePrice {
                items[index].basePrice = basePrice
            }
            if let finalUnitPrice {
                items[index].finalUnitPrice = finalUnitPrice
            }
            let unit = items[index].finalUnitPrice ?? items[index].basePrice ?? 0
            items[index].finalTotalPrice = unit * Double(items[index].quantity)
            print(
                "✅ Updated cart line '\(resolvedCartItemId)' to quantity \(items[index].quantity)")
        } else {
            // Si no existe, añadir nuevo item
            let item = CartItemLocal(
                productId: productId,
                quantity: quantity,
                selectedVariants: selectedVariants,
                comboGroupId: comboGroupId,
                comboId: comboId,
                comboName: comboName,
                comboComponentSlotId: comboComponentSlotId,
                comboComponentSlotName: comboComponentSlotName,
                comboComponentOrder: comboComponentOrder,
                basePrice: basePrice,
                finalUnitPrice: finalUnitPrice,
                finalTotalPrice: nil,
                cartItemId: resolvedCartItemId
            )
            items.append(item)
            print("✅ Added NEW cart line with ID: '\(resolvedCartItemId)' quantity: \(quantity)")
        }

        saveCartItems(items)
        print("📦 Cart now has \(items.count) unique products, total items: \(cartItemCount)")

        // Llamar a la mutation en segundo plano para estadísticas
        sendAddToCartMutation(productId: productId)
    }

    /// Añadir un combo al carrito como múltiples líneas de producto agrupadas.
    func addComboToCart(
        comboId: String,
        comboName: String,
        components: [(
            productId: String,
            slotId: String,
            slotName: String,
            unitBasePrice: Double,
            unitFinalPrice: Double,
            componentOrder: Int
        )],
        quantity: Int = 1
    ) {
        guard quantity > 0 else { return }
        guard !components.isEmpty else { return }

        let comboGroupId = "combo::\(comboId)::\(UUID().uuidString)"
        for component in components {
            let lineCartItemId =
                "combo-item::\(comboGroupId)::\(component.componentOrder)::\(component.productId)"
            addToCart(
                productId: component.productId,
                quantity: quantity,
                selectedVariants: [],
                cartItemId: lineCartItemId,
                comboGroupId: comboGroupId,
                comboId: comboId,
                comboName: comboName,
                comboComponentSlotId: component.slotId,
                comboComponentSlotName: component.slotName,
                comboComponentOrder: component.componentOrder,
                basePrice: component.unitBasePrice,
                finalUnitPrice: component.unitFinalPrice
            )
        }
    }

    func updateComboQuantity(comboGroupId: String, quantity: Int) {
        var items = localItems
        let indexes = items.indices.filter { items[$0].comboGroupId == comboGroupId }
        guard !indexes.isEmpty else { return }

        if quantity <= 0 {
            items.removeAll { $0.comboGroupId == comboGroupId }
            saveCartItems(items)
            return
        }

        for index in indexes {
            items[index].quantity = quantity
            let unit = items[index].finalUnitPrice ?? items[index].basePrice ?? 0
            items[index].finalTotalPrice = unit * Double(quantity)
        }
        saveCartItems(items)
    }

    func removeComboFromCart(comboGroupId: String) {
        var items = localItems
        items.removeAll { $0.comboGroupId == comboGroupId }
        saveCartItems(items)
        print("🗑️ Removed combo group \(comboGroupId) from cart")
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
        var showcaseItems = localShowcaseItems

        if let index = items.firstIndex(where: { $0.cartItemId == cartItemId }) {
            if quantity <= 0 {
                items.remove(at: index)
            } else {
                items[index].quantity = quantity
                let unit = items[index].finalUnitPrice ?? items[index].basePrice ?? 0
                items[index].finalTotalPrice = unit * Double(quantity)
            }
            saveCartItems(items)
            return
        }

        if let index = showcaseItems.firstIndex(where: { $0.cartItemId == cartItemId }) {
            if quantity <= 0 {
                showcaseItems.remove(at: index)
            } else {
                showcaseItems[index].quantity = quantity
            }
            saveShowcaseCartItems(showcaseItems)
        }
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
        var showcaseItems = localShowcaseItems
        items.removeAll { $0.cartItemId == cartItemId }
        showcaseItems.removeAll { $0.cartItemId == cartItemId }
        saveCartItems(items)
        saveShowcaseCartItems(showcaseItems)
        print("🗑️ Removed cart line \(cartItemId) from cart")
    }

    func addShowcaseToCart(
        showcaseId: String,
        branchId: String,
        branchName: String,
        title: String,
        imageUrl: String,
        requestDescription: String,
        quantity: Int = 1
    ) {
        let normalizedDescription = requestDescription.trimmingCharacters(
            in: .whitespacesAndNewlines)
        guard !normalizedDescription.isEmpty else { return }

        var items = localShowcaseItems
        let cartItemId = ShowcaseCartItemLocal.buildCartItemId(
            showcaseId: showcaseId,
            requestDescription: normalizedDescription
        )

        if let index = items.firstIndex(where: { $0.cartItemId == cartItemId }) {
            items[index].quantity += quantity
        } else {
            let item = ShowcaseCartItemLocal(
                cartItemId: cartItemId,
                showcaseId: showcaseId,
                branchId: branchId,
                branchName: branchName,
                title: title,
                imageUrl: imageUrl,
                requestDescription: normalizedDescription,
                quantity: quantity
            )
            items.append(item)
        }

        saveShowcaseCartItems(items)
        print("✅ Added showcase item '\(showcaseId)' to cart")
    }

    /// Limpiar todo el carrito
    func clearCart() {
        userDefaults.removeObject(forKey: cartKey)
        userDefaults.removeObject(forKey: showcaseCartKey)
        localItems = []
        localShowcaseItems = []
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

    private func saveShowcaseCartItems(_ items: [ShowcaseCartItemLocal]) {
        do {
            let encoded = try JSONEncoder().encode(items)
            userDefaults.set(encoded, forKey: showcaseCartKey)
        } catch {
            print(
                "⚠️ CartManager: Failed to encode showcase cart items - \(error.localizedDescription)"
            )
        }
        localShowcaseItems = items
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

    private func loadShowcaseCartItems() {
        if let encodedData = userDefaults.data(forKey: showcaseCartKey) {
            do {
                localShowcaseItems = try JSONDecoder().decode(
                    [ShowcaseCartItemLocal].self, from: encodedData)
                return
            } catch {
                print(
                    "⚠️ CartManager: Failed to decode showcase cart items - \(error.localizedDescription)"
                )
            }
        }

        localShowcaseItems = []
    }

    private func updateItemCount() {
        let productCount = localItems.reduce(0) { $0 + $1.quantity }
        let showcaseCount = localShowcaseItems.reduce(0) { $0 + $1.quantity }
        cartItemCount = productCount + showcaseCount
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

struct ShowcaseCartItemLocal: Codable, Sendable {
    let cartItemId: String
    let showcaseId: String
    let branchId: String
    let branchName: String
    let title: String
    let imageUrl: String
    let requestDescription: String
    var quantity: Int

    static func buildCartItemId(showcaseId: String, requestDescription: String) -> String {
        let normalizedDescription =
            requestDescription
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
        return "showcase::\(showcaseId)::\(normalizedDescription)"
    }
}
