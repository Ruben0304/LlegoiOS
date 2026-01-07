import SwiftUI
import Combine

/// Enum que representa los tipos de sucursales disponibles
/// Coincide con el enum BranchTipo del schema GraphQL
enum BranchType: String {
    case restaurante = "RESTAURANTE"
    case tienda = "TIENDA"
    case dulceria = "DULCERIA"
}

/// Manages the global branch type filter across the application
/// When the user selects a category in HomeView, this type will be used
/// to filter products and branches in ShopView and ShopTabLandingView
@MainActor
class BranchTypeManager: ObservableObject {
    /// Shared singleton instance
    static let shared = BranchTypeManager()

    /// Current selected branch type that determines the filter for queries
    /// Default is RESTAURANTE (index 0 in HomeView)
    @Published var selectedType: BranchType = .restaurante

    private init() {}

    /// Update the selected branch type
    func setType(_ type: BranchType) {
        selectedType = type
    }

    /// Set type based on HomeView category index
    /// - 0: Restaurantes -> RESTAURANTE
    /// - 1: Tiendas -> TIENDA
    /// - 2: Dulcería -> DULCERIA
    func setTypeFromCategoryIndex(_ index: Int) {
        switch index {
        case 0:
            selectedType = .restaurante
        case 1:
            selectedType = .tienda
        case 2:
            selectedType = .dulceria
        default:
            selectedType = .restaurante
        }
    }

    /// Get the GraphQL enum string value for the current type
    var graphQLValue: String {
        selectedType.rawValue
    }
}
