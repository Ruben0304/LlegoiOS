import Foundation
import SwiftUI
import Combine

enum CartViewState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class CartViewModel: ObservableObject {
    @Published var state: CartViewState = .idle
    @Published var cartItems: [CartItem] = []
    @Published var errorMessage: String?
    @Published var hasWatchedAds: Bool = false // Descuento por ver anuncios

    private let repository = CartRepository()
    private let cartManager = CartManager.shared

    // MARK: - Service Fee Constants
    private let standardServiceFeeRate: Double = 0.15 // 15%
    private let discountedServiceFeeRate: Double = 0.10 // 10% con descuento

    // MARK: - Computed Properties

    var totalItems: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Double {
        cartItems.reduce(0.0) { $0 + ($1.price * Double($1.quantity)) }
    }

    var deliveryFee: Double {
        cartItems.isEmpty ? 0.0 : 2.50
    }

    /// Tasa de servicio actual (15% normal, 10% con descuento)
    var currentServiceFeeRate: Double {
        hasWatchedAds ? discountedServiceFeeRate : standardServiceFeeRate
    }

    /// Porcentaje de servicio formateado
    var serviceFeePercentage: Int {
        Int(currentServiceFeeRate * 100)
    }

    /// Cargo de servicio calculado sobre el subtotal
    var serviceFee: Double {
        subtotal * currentServiceFeeRate
    }

    /// Ahorro por ver anuncios
    var adSavings: Double {
        hasWatchedAds ? subtotal * (standardServiceFeeRate - discountedServiceFeeRate) : 0
    }

    var total: Double {
        subtotal + deliveryFee + serviceFee
    }

    var formattedSubtotal: String {
        formatPrice(subtotal)
    }

    var formattedDeliveryFee: String {
        formatPrice(deliveryFee)
    }

    var formattedServiceFee: String {
        formatPrice(serviceFee)
    }

    var formattedAdSavings: String {
        formatPrice(adSavings)
    }

    var formattedTotal: String {
        formatPrice(total)
    }

    /// Total si viera los anuncios (para mostrar incentivo)
    var totalWithDiscount: Double {
        subtotal + deliveryFee + (subtotal * discountedServiceFeeRate)
    }

    var formattedTotalWithDiscount: String {
        formatPrice(totalWithDiscount)
    }

    /// Ahorro potencial si ve los anuncios
    var potentialSavings: Double {
        subtotal * (standardServiceFeeRate - discountedServiceFeeRate)
    }

    var formattedPotentialSavings: String {
        formatPrice(potentialSavings)
    }

    /// Activar descuento por ver anuncios
    func activateAdDiscount() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            hasWatchedAds = true
        }
    }

    // MARK: - Actions

    /// Cargar productos del carrito (desde local + GraphQL)
    func loadCart() {
        state = .loading
        errorMessage = nil

        repository.fetchCartProducts { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let cartProducts):
                    // Mapear a UI models
                    self.cartItems = cartProducts.map { product in
                        CartItem(
                            id: product.id,
                            name: product.name,
                            shop: "Store", // TODO: Obtener nombre de la tienda desde branch
                            weight: product.weight,
                            price: product.price,
                            imageUrl: product.image,
                            quantity: product.quantity,
                            availability: product.availability
                        )
                    }

                    print("✅ Loaded \(self.cartItems.count) items in cart")
                    self.state = .success

                case .failure(let error):
                    self.errorMessage = "Error al cargar el carrito: \(error.localizedDescription)"
                    self.state = .error(self.errorMessage!)
                    print("❌ Error loading cart: \(error)")
                }
            }
        }
    }

    /// Incrementar cantidad de un producto
    func incrementQuantity(productId: String) {
        if let item = cartItems.first(where: { $0.id == productId }) {
            cartManager.updateQuantity(productId: productId, quantity: item.quantity + 1)
            loadCart()
        }
    }

    /// Decrementar cantidad de un producto
    func decrementQuantity(productId: String) {
        if let item = cartItems.first(where: { $0.id == productId }) {
            let newQuantity = item.quantity - 1
            if newQuantity <= 0 {
                removeFromCart(productId: productId)
            } else {
                cartManager.updateQuantity(productId: productId, quantity: newQuantity)
                loadCart()
            }
        }
    }

    /// Remover producto del carrito
    func removeFromCart(productId: String) {
        cartManager.removeFromCart(productId: productId)
        loadCart()
    }

    /// Limpiar todo el carrito
    func clearCart() {
        cartManager.clearCart()
        cartItems = []
        state = .success
    }

    // MARK: - Helpers

    private func formatPrice(_ price: Double) -> String {
        return String(format: "$%.2f", price)
    }
}

// MARK: - UI Model

struct CartItem: Identifiable, Hashable {
    let id: String
    let name: String
    let shop: String
    let weight: String
    let price: Double
    let imageUrl: String
    var quantity: Int
    let availability: Bool

    var formattedPrice: String {
        String(format: "$%.2f", price)
    }

    var itemTotal: Double {
        price * Double(quantity)
    }

    var formattedItemTotal: String {
        String(format: "$%.2f", itemTotal)
    }
}
