import ActivityKit
import Foundation

struct DeliveryActivityAttributes: ActivityAttributes {
    // Datos estáticos que no cambian durante la actividad
    let orderID: String
    let storeName: String
    let storeIcon: String  // SF Symbol name
    let totalAmount: String
    let deliveryAddress: String

    // Estado dinámico que se actualiza en tiempo real
    struct ContentState: Codable, Hashable {
        let status: String  // DeliveryStatus rawValue
        let statusDisplayText: String
        let statusIcon: String  // SF Symbol
        let progressValue: Double  // 0.0 - 1.0
        let remainingDistance: String  // e.g. "342 m", "1.2 km"
        let estimatedMinutes: Int
    }
}
