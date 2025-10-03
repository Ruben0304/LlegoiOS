import SwiftUI
import CoreLocation
import MapKit

// MARK: - Store Model (UI compatibility layer)
struct Store: Identifiable {
    let id: String
    let name: String
    let etaMinutes: Int
    let logoUrl: String
    let bannerUrl: String
    let address: String?
    let rating: Double?

    init(id: String, name: String, etaMinutes: Int, logoUrl: String, bannerUrl: String, address: String? = nil, rating: Double? = nil) {
        self.id = id
        self.name = name
        self.etaMinutes = etaMinutes
        self.logoUrl = logoUrl
        self.bannerUrl = bannerUrl
        self.address = address
        self.rating = rating
    }

    // Convenience initializer for backward compatibility with default values
    init(id: String, name: String, address: String, etaMinutes: Int = 30, logoUrl: String = "", bannerUrl: String = "", rating: Double? = nil) {
        self.id = id
        self.name = name
        self.etaMinutes = etaMinutes
        self.logoUrl = logoUrl
        self.bannerUrl = bannerUrl
        self.address = address
        self.rating = rating
    }
}

// MARK: - Store Card Size
enum StoreCardSize {
    case medium
    case expanded
}

// MARK: - Search Category
enum SearchCategory: String, CaseIterable {
    case products = "Productos"
    case stores = "Negocios"
}

// MARK: - Order Tracking Models
struct Order: Identifiable {
    let id: String
    let orderNumber: String
    let storeName: String
    let storeLogoUrl: String
    let deliveryAddress: String
    let estimatedDeliveryTime: Date
    let items: [OrderItem]
    let total: String
    let status: OrderStatus
    let deliveryPerson: DeliveryPerson?
    let timeline: [OrderTimelineEvent]
    let storeLocation: CLLocationCoordinate2D
    let deliveryLocation: CLLocationCoordinate2D
    let currentDeliveryLocation: CLLocationCoordinate2D?
}

struct OrderItem: Identifiable {
    let id: String
    let name: String
    let quantity: Int
    let price: String
    let imageUrl: String
}

struct DeliveryPerson: Identifiable {
    let id: String
    let name: String
    let rating: Double
    let phoneNumber: String
    let vehicleType: String
    let vehiclePlate: String
    let profileImageUrl: String
}

enum OrderStatus: String, CaseIterable {
    case confirmed = "Confirmado"
    case preparing = "Preparando"
    case readyForPickup = "Listo para recoger"
    case onTheWay = "En camino"
    case delivered = "Entregado"
    case cancelled = "Cancelado"
    
    var icon: String {
        switch self {
        case .confirmed: return "checkmark.circle.fill"
        case .preparing: return "timer.circle.fill"
        case .readyForPickup: return "bag.circle.fill"
        case .onTheWay: return "car.circle.fill"
        case .delivered: return "house.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .confirmed: return .llegoAccent
        case .preparing: return .orange
        case .readyForPickup: return .yellow
        case .onTheWay: return .llegoPrimary
        case .delivered: return .green
        case .cancelled: return .red
        }
    }
}

struct OrderTimelineEvent: Identifiable {
    let id = UUID()
    let status: OrderStatus
    let timestamp: Date
    let message: String
    let isCompleted: Bool
}
