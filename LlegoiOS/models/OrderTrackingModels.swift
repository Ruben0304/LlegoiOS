import SwiftUI
import CoreLocation

// MARK: - Order Tracking Model
struct OrderTracking {
    let order: OrderTrackingOrder
    var deliveryPersonLocation: CLLocationCoordinate2D?
    let storeLocation: CLLocationCoordinate2D
    let deliveryLocation: CLLocationCoordinate2D
    var estimatedMinutes: Int?
    var distanceKm: Double?
    let routePolyline: String?
}

// MARK: - Order Tracking Order (simplified order for tracking view)
struct OrderTrackingOrder: Identifiable {
    let id: String
    let orderNumber: String
    let status: OrderStatusEnum
    let total: Double
    let currency: String
    let estimatedDeliveryTime: Date?
    let estimatedMinutesRemaining: Int?
    let items: [OrderTrackingItem]
    let deliveryPerson: OrderDeliveryPerson?
    let timeline: [OrderTimelineEvent]
    let branchId: String
    let branchName: String
    let branchImageUrl: String?
    
    var formattedTotal: String { String(format: "$%.2f", total) }
    
    var formattedETA: String? {
        guard let minutes = estimatedMinutesRemaining else { return nil }
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
}

// MARK: - Order Tracking Item
struct OrderTrackingItem: Identifiable {
    let id: String
    let productId: String
    let name: String
    let quantity: Int
    let price: Double
    let imageUrl: String?
    
    var formattedPrice: String { String(format: "$%.2f", price) }
}

// MARK: - Delivery Location Update (for real-time tracking)
struct DeliveryLocationUpdate {
    let orderId: String
    let location: CLLocationCoordinate2D
    let timestamp: Date
    let estimatedMinutesRemaining: Int?
    let distanceRemainingKm: Double?
}

// MARK: - Legacy compatibility (keeping old types for existing views)
typealias Order = OrderTrackingOrder
typealias OrderItem = OrderTrackingItem
typealias DeliveryPerson = OrderDeliveryPerson
typealias OrderStatus = OrderStatusEnum
