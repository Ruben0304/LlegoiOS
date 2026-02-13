import SwiftUI

// MARK: - Order Status Enum (matches GraphQL OrderStatusEnum)
enum OrderStatusEnum: String, CaseIterable, Codable {
    case pendingAcceptance = "PENDING_ACCEPTANCE"
    case modifiedByStore = "MODIFIED_BY_STORE"
    case accepted = "ACCEPTED"
    case preparing = "PREPARING"
    case readyForPickup = "READY_FOR_PICKUP"
    case onTheWay = "ON_THE_WAY"
    case delivered = "DELIVERED"
    case cancelled = "CANCELLED"

    var displayName: String {
        switch self {
        case .pendingAcceptance: return "Pendiente"
        case .modifiedByStore: return "Modificado"
        case .accepted: return "Aceptado"
        case .preparing: return "Preparando"
        case .readyForPickup: return "Listo para recoger"
        case .onTheWay: return "En camino"
        case .delivered: return "Entregado"
        case .cancelled: return "Cancelado"
        }
    }

    var color: Color {
        switch self {
        case .pendingAcceptance: return .orange
        case .modifiedByStore: return .blue
        case .accepted: return .green
        case .preparing: return .orange
        case .readyForPickup: return .yellow
        case .onTheWay: return .llegoPrimary
        case .delivered: return .green
        case .cancelled: return .red
        }
    }

    var icon: String {
        switch self {
        case .pendingAcceptance: return "clock.fill"
        case .modifiedByStore: return "square.and.pencil"
        case .accepted: return "checkmark.circle.fill"
        case .preparing: return "timer.circle.fill"
        case .readyForPickup: return "bag.circle.fill"
        case .onTheWay: return "car.circle.fill"
        case .delivered: return "house.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

// MARK: - Payment Status Enum
enum PaymentStatusEnum: String, Codable {
    case pending = "PENDING"
    case validated = "VALIDATED"
    case completed = "COMPLETED"
    case failed = "FAILED"
}

// MARK: - Discount Type Enum
enum DiscountTypeEnum: String, Codable {
    case premium = "PREMIUM"
    case level = "LEVEL"
    case promo = "PROMO"
}

// MARK: - Order Actor Enum
enum OrderActorEnum: String, Codable {
    case customer = "CUSTOMER"
    case business = "BUSINESS"
    case system = "SYSTEM"
    case delivery = "DELIVERY"
}

// MARK: - Recent Order Model (for list view)
struct RecentOrder: Identifiable {
    let id: String
    let orderNumber: String
    let storeName: String
    let storeImageUrl: String?
    let date: Date
    let total: Double
    let currency: String
    let status: OrderStatusEnum
    let paymentStatus: PaymentStatusEnum
    let itemCount: Int
    let items: [OrderListItem]

    var formattedTotal: String {
        String(format: "$%.2f", total)
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "es")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct OrderListItem: Identifiable {
    let id: String
    let name: String
    let quantity: Int
    let imageUrl: String?
}

// MARK: - Sample Data (for previews)
let sampleRecentOrders: [RecentOrder] = [
    RecentOrder(
        id: "1",
        orderNumber: "ORD-2026-001234",
        storeName: "Cafe Habana",
        storeImageUrl: nil,
        date: Date().addingTimeInterval(-720),
        total: 12.50,
        currency: "USD",
        status: .pendingAcceptance,
        paymentStatus: .pending,
        itemCount: 3,
        items: []
    ),
    RecentOrder(
        id: "2",
        orderNumber: "ORD-2026-001233",
        storeName: "Pizzeria Roma",
        storeImageUrl: nil,
        date: Date().addingTimeInterval(-86400),
        total: 22.80,
        currency: "USD",
        status: .onTheWay,
        paymentStatus: .completed,
        itemCount: 2,
        items: []
    ),
    RecentOrder(
        id: "3",
        orderNumber: "ORD-2026-001232",
        storeName: "Sushi House",
        storeImageUrl: nil,
        date: Date().addingTimeInterval(-172800),
        total: 18.20,
        currency: "USD",
        status: .cancelled,
        paymentStatus: .failed,
        itemCount: 4,
        items: []
    ),
]
