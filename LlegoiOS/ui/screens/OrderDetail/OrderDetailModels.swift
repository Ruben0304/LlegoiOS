import SwiftUI

struct OrderDetail: Identifiable {
    let id: String
    let businessName: String
    let businessImageName: String
    var items: [OrderDetailItem]
    var deliveryFee: Double
    var discounts: [OrderDetailDiscount]
    var status: OrderDetailStatus
    let estimatedTime: String?
    let placedAt: Date
    var lastStatusAt: Date
    var comments: [OrderDetailComment]

    var isEditable: Bool {
        status == .modifiedByStore
    }

    var subtotal: Double {
        items.reduce(0) { $0 + $1.lineTotal }
    }

    var total: Double {
        let discountTotal = discounts.reduce(0) { $0 + $1.amount }
        return subtotal + deliveryFee - discountTotal
    }
}

struct OrderDetailItem: Identifiable {
    let id: String
    let name: String
    let imageName: String
    var quantity: Int
    let price: Double
    let wasModifiedByStore: Bool

    var lineTotal: Double {
        Double(quantity) * price
    }
}

struct OrderDetailDiscount: Identifiable {
    let id: String
    let title: String
    let amount: Double
    let type: OrderDetailDiscountType
}

enum OrderDetailDiscountType {
    case premium
    case level
}

enum OrderDetailStatus: String {
    case pendingAcceptance
    case modifiedByStore
    case inProgress
    case cancelled
    case accepted

    var displayName: String {
        switch self {
        case .pendingAcceptance:
            return "Pendiente de aceptacion"
        case .modifiedByStore:
            return "Modificado por la tienda"
        case .inProgress:
            return "En progreso"
        case .cancelled:
            return "Cancelado"
        case .accepted:
            return "Aceptado"
        }
    }

    var accentColor: Color {
        switch self {
        case .pendingAcceptance:
            return Color.orange
        case .modifiedByStore:
            return Color.blue
        case .inProgress:
            return Color.llegoPrimary
        case .cancelled:
            return Color.red
        case .accepted:
            return Color.green
        }
    }
}

struct OrderDetailComment: Identifiable {
    let id: String
    let author: OrderDetailActor
    let message: String
    let timestamp: Date
}

enum OrderDetailActor {
    case customer
    case business
}
