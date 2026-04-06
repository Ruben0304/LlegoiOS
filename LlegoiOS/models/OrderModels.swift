import SwiftUI

// MARK: - Order Status Enum (matches GraphQL OrderStatusEnum)
enum OrderStatusEnum: String, CaseIterable, Codable {
    case awaitingDeliveryAcceptance = "AWAITING_DELIVERY_ACCEPTANCE"
    case pendingPayment = "PENDING_PAYMENT"
    case paymentInProgress = "PAYMENT_IN_PROGRESS"
    case pendingAcceptance = "PENDING_ACCEPTANCE"
    case modifiedByStore = "MODIFIED_BY_STORE"
    case rejectedByStore = "REJECTED_BY_STORE"
    case accepted = "ACCEPTED"
    case preparing = "PREPARING"
    case readyForPickup = "READY_FOR_PICKUP"
    case onTheWay = "ON_THE_WAY"
    case delivered = "DELIVERED"
    case cancelled = "CANCELLED"
    case unknown = "UNKNOWN"

    var displayName: String {
        switch self {
        case .awaitingDeliveryAcceptance: return "Tienda confirmó. Esperando mensajero"
        case .pendingPayment: return "Listo para pagar"
        case .paymentInProgress: return "Procesando pago"
        case .pendingAcceptance: return "Esperando confirmación de la tienda"
        case .modifiedByStore: return "Modificado"
        case .rejectedByStore: return "Rechazado por la tienda"
        case .accepted: return "Aceptado"
        case .preparing: return "Preparando"
        case .readyForPickup: return "Listo para recoger"
        case .onTheWay: return "En camino"
        case .delivered: return "Entregado"
        case .cancelled: return "Cancelado"
        case .unknown: return "Estado actualizado"
        }
    }

    var color: Color {
        switch self {
        case .awaitingDeliveryAcceptance: return .blue
        case .pendingPayment: return .orange
        case .paymentInProgress: return .orange
        case .pendingAcceptance: return .orange
        case .modifiedByStore: return .blue
        case .rejectedByStore: return .red
        case .accepted: return .green
        case .preparing: return .orange
        case .readyForPickup: return .yellow
        case .onTheWay: return .llegoPrimary
        case .delivered: return .green
        case .cancelled: return .red
        case .unknown: return .gray
        }
    }

    var icon: String {
        switch self {
        case .awaitingDeliveryAcceptance: return "storefront.circle.fill"
        case .pendingPayment: return "creditcard.circle.fill"
        case .paymentInProgress: return "clock.fill"
        case .pendingAcceptance: return "clock.fill"
        case .modifiedByStore: return "square.and.pencil"
        case .rejectedByStore: return "xmark.shield.fill"
        case .accepted: return "checkmark.circle.fill"
        case .preparing: return "timer.circle.fill"
        case .readyForPickup: return "bag.circle.fill"
        case .onTheWay: return "car.circle.fill"
        case .delivered: return "house.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    // Normaliza estados legacy/no canónicos para lógica de contrato.
    var normalizedForContract: OrderStatusEnum {
        switch self {
        case .paymentInProgress:
            return .pendingPayment
        default:
            return self
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
    let customerVisibleStatus: OrderStatusEnum
    let status: OrderStatusEnum
    let deadlineAt: Date?
    let paymentStatus: PaymentStatusEnum
    let itemCount: Int
    let items: [OrderListItem]
    let fulfillmentMode: FulfillmentMode?

    var formattedTotal: String {
        String(format: "$%.2f", total)
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "es")
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var displayStatus: OrderStatusEnum {
        customerVisibleStatus == .unknown ? status : customerVisibleStatus
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
        customerVisibleStatus: .pendingAcceptance,
        status: .pendingAcceptance,
        deadlineAt: nil,
        paymentStatus: .pending,
        itemCount: 3,
        items: [],
        fulfillmentMode: nil
    ),
    RecentOrder(
        id: "2",
        orderNumber: "ORD-2026-001233",
        storeName: "Pizzeria Roma",
        storeImageUrl: nil,
        date: Date().addingTimeInterval(-86400),
        total: 22.80,
        currency: "USD",
        customerVisibleStatus: .onTheWay,
        status: .onTheWay,
        deadlineAt: nil,
        paymentStatus: .completed,
        itemCount: 2,
        items: [],
        fulfillmentMode: nil
    ),
    RecentOrder(
        id: "3",
        orderNumber: "ORD-2026-001232",
        storeName: "Sushi House",
        storeImageUrl: nil,
        date: Date().addingTimeInterval(-172800),
        total: 18.20,
        currency: "USD",
        customerVisibleStatus: .cancelled,
        status: .cancelled,
        deadlineAt: nil,
        paymentStatus: .failed,
        itemCount: 4,
        items: [],
        fulfillmentMode: nil
    ),
]
