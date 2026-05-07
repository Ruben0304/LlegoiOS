import SwiftUI
import Combine

/// Enum que representa los tipos de sucursales disponibles
/// Fuente de verdad para branchTipo en minúsculas (como lo espera el backend para campos String)
enum BranchType: String {
    case restaurante = "restaurante"
    case tienda = "tienda"
    case dulceria = "dulceria"
    case perfumeria = "perfumeria"
    case ropa = "ropa"
}

/// Manages the global branch type filter across the application
/// When the user selects a category in HomeView, this type will be used
/// to filter products and branches in ShopView and ShopTabLandingView
@MainActor
class BranchTypeManager: ObservableObject {
    /// Shared singleton instance
    static let shared = BranchTypeManager()

    /// Current selected branch type that determines the filter for queries
    /// Default is restaurante (index 0 in HomeView)
    @Published var selectedType: BranchType = .restaurante

    private init() {}

    /// Update the selected branch type
    func setType(_ type: BranchType) {
        selectedType = type
    }

    /// Set type based on HomeView category index
    /// - 0: Restaurantes -> restaurante
    /// - 1: Tiendas -> tienda
    /// - 2: Dulcería -> dulceria
    /// - 3: Perfumería -> perfumeria
    /// - 4: Ropa -> ropa
    func setTypeFromCategoryIndex(_ index: Int) {
        switch index {
        case 0:
            selectedType = .restaurante
        case 1:
            selectedType = .tienda
        case 2:
            selectedType = .dulceria
        case 3:
            selectedType = .perfumeria
        case 4:
            selectedType = .ropa
        default:
            selectedType = .restaurante
        }
    }

    /// Valor branchTipo en minúsculas para argumentos GraphQL de tipo String
    var graphQLValue: String {
        selectedType.rawValue
    }
}
