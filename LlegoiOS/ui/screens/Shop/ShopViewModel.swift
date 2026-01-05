import Foundation
import SwiftUI
import Combine

enum SortOption: String, CaseIterable {
    case proximity = "Cercanía"
    case priceLowToHigh = "Precio: Menor a Mayor"
    case priceHighToLow = "Precio: Mayor a Menor"

    var displayName: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .proximity:
            return "location.circle.fill"
        case .priceLowToHigh:
            return "arrow.up.circle.fill"
        case .priceHighToLow:
            return "arrow.down.circle.fill"
        }
    }
}

enum ShopViewState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class ShopViewModel: ObservableObject {
    @Published var state: ShopViewState = .idle
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var isLoading: Bool = false

    // Filtros
    @Published var maxDistance: Double = 50.0 // 50 = sin límite
    @Published var selectedCategory: String? = nil
    @Published var searchQuery: String = "" {
        didSet {
            applyFiltersAndSort()
        }
    }

    // Ordenación
    @Published var sortOption: SortOption = .proximity

    // Branch filter
    var branchId: String? = nil

    private let repository = ShopRepository()

    // Categorías rápidas para chips horizontales
    let quickCategories = [
        "Italiana",
        "Platos Fuertes",
        "Vegetariana",
        "Batidos",
        "Bebidas",
        "Botellas"
    ]

    var hasActiveFilters: Bool {
        maxDistance < 50 || selectedCategory != nil || !searchQuery.isEmpty
    }

    func loadProducts(isRefreshing: Bool = false) {
        // Solo mostrar loading si NO es un refresh
        if !isRefreshing {
            isLoading = true
            state = .loading
        }

        repository.fetchProducts(branchId: branchId) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let productsGraphQL):
                    // Mapear productos GraphQL a modelos UI
                    self.products = productsGraphQL.map { productGraphQL in
                        Product(
                            id: productGraphQL.id,
                            name: productGraphQL.name,
                            shop: productGraphQL.businessName,
                            weight: "0",
                            price: self.formatPrice(
                                price: productGraphQL.price,
                                currency: productGraphQL.currency
                            ),
                            imageUrl: productGraphQL.imageUrl
                        )
                    }

                    self.applyFiltersAndSort()

                    // Marcar como completado
                    self.isLoading = false
                    if !isRefreshing {
                        self.state = .success
                    }

                    print("✅ Loaded \(self.products.count) products" + (self.branchId != nil ? " for branch \(self.branchId!)" : ""))

                case .failure(let error):
                    self.isLoading = false

                    // Mejorar mensaje de error para offline
                    let nsError = error as NSError
                    let isNetworkError = nsError.domain == NSURLErrorDomain &&
                        (nsError.code == NSURLErrorNotConnectedToInternet ||
                         nsError.code == NSURLErrorTimedOut ||
                         nsError.code == NSURLErrorCannotConnectToHost ||
                         nsError.code == NSURLErrorNetworkConnectionLost)

                    let errorMessage = isNetworkError
                        ? "No hay conexión a internet y no hay productos guardados en caché"
                        : "Error al cargar productos: \(error.localizedDescription)"

                    print("❌ ShopViewModel error: \(errorMessage)")
                    self.state = .error(errorMessage)
                }
            }
        }
    }

    func applyFilters() {
        applyFiltersAndSort()
    }

    func applySort() {
        applyFiltersAndSort()
    }

    func clearFilters() {
        maxDistance = 50.0
        selectedCategory = nil
        searchQuery = ""
        applyFiltersAndSort()
    }

    private func applyFiltersAndSort() {
        var result = products

        // Aplicar búsqueda por texto
        if !searchQuery.isEmpty {
            result = result.filter { product in
                product.name.localizedCaseInsensitiveContains(searchQuery) ||
                product.shop.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        // Aplicar filtro de categoría
        if let category = selectedCategory {
            result = result.filter { product in
                // Filtrar por nombre del producto que contenga la categoría
                product.name.localizedCaseInsensitiveContains(category) ||
                category.localizedCaseInsensitiveContains(product.name)
            }
        }

        // Aplicar filtro de distancia
        // TODO: Implementar cuando tengamos coordenadas de las tiendas
        // Por ahora, si maxDistance < 50, simplemente limitamos el número de productos
        if maxDistance < 50 {
            let limit = Int(maxDistance * 2) // Aproximación: 2 productos por km
            result = Array(result.prefix(limit))
        }

        // Aplicar ordenación
        switch sortOption {
        case .proximity:
            // TODO: Ordenar por distancia real cuando tengamos coordenadas
            // Por ahora, dejar el orden original
            break

        case .priceLowToHigh:
            result = result.sorted { product1, product2 in
                extractPrice(from: product1.price) < extractPrice(from: product2.price)
            }

        case .priceHighToLow:
            result = result.sorted { product1, product2 in
                extractPrice(from: product1.price) > extractPrice(from: product2.price)
            }
        }

        filteredProducts = result
    }

    // MARK: - Helper Methods

    private func formatPrice(price: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = getCurrencySymbol(for: currency)
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "\(getCurrencySymbol(for: currency))\(price)"
    }

    private func getCurrencySymbol(for currency: String) -> String {
        switch currency.uppercased() {
        case "USD": return "$"
        case "EUR": return "€"
        case "CUP": return "$"
        default: return "$"
        }
    }

    private func extractPrice(from priceString: String) -> Double {
        // Extraer el precio numérico de un string como "$12.50"
        let cleanedString = priceString
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        return Double(cleanedString) ?? 0.0
    }
}
