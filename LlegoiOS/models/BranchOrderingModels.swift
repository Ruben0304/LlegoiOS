import Foundation

// MARK: - Pedidos pausados por la tienda

/// Datos de la sucursal que el checkout necesita: su horario y si acepta pedidos.
struct BranchOrderingInfo: Sendable {
    let schedule: BranchSchedule?
    /// false cuando la sucursal pausó la recepción de pedidos desde la app de negocios.
    let acceptingOrders: Bool
}

/// Textos para cuando la sucursal pausó los pedidos (`acceptingOrders = false`).
enum BranchOrderingMessages {
    /// Etiqueta corta para chips y avisos.
    static let notAcceptingOrdersShort = "No acepta pedidos ahora"
    /// Explicación para la ficha de la tienda y el carrito.
    static let notAcceptingOrdersDetail =
        "La tienda pausó temporalmente los pedidos. Puedes ver su catálogo e intentarlo más tarde."
    /// Mensaje cuando el backend rechaza el pedido con BRANCH_NOT_ACCEPTING_ORDERS.
    static let notAcceptingOrdersAlert =
        "Esta tienda no acepta pedidos en este momento. Inténtalo de nuevo más tarde."
}

/// Error de `createOrder` con el código estable que manda el backend en
/// `extensions.code` (por ejemplo BRANCH_NOT_ACCEPTING_ORDERS).
struct CreateOrderError: LocalizedError {
    static let branchNotAcceptingOrdersCode = "BRANCH_NOT_ACCEPTING_ORDERS"

    let code: String?
    let message: String

    var isBranchNotAcceptingOrders: Bool {
        code == Self.branchNotAcceptingOrdersCode
    }

    var errorDescription: String? {
        // El backend ya manda un mensaje en español, pero para este caso se usa el
        // texto propio de la app para que coincida con el aviso del carrito.
        isBranchNotAcceptingOrders ? BranchOrderingMessages.notAcceptingOrdersAlert : message
    }
}
