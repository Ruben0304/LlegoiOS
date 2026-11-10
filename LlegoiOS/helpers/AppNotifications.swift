import Foundation

extension Notification.Name {
    static let openOrdersFromCheckout = Notification.Name("openOrdersFromCheckout")
    /// Se publica al cerrar o invalidar la sesión: los flujos en curso deben cancelarse.
    static let authSessionInvalidated = Notification.Name("authSessionInvalidated")
    static let prepareOpenOrdersFromCart = Notification.Name("prepareOpenOrdersFromCart")
}
