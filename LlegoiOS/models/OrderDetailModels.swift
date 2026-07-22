import CoreLocation
import SwiftUI

// MARK: - Order Detail Model
struct OrderDetail: Identifiable {
    let id: String
    let orderNumber: String
    let status: OrderStatusEnum
    let customerVisibleStatus: OrderStatusEnum
    let subtotal: Double
    let deliveryFee: Double
    let serviceCharge: Double
    let total: Double
    let currency: String
    let paymentMethod: String
    let paymentStatus: PaymentStatusEnum
    let createdAt: Date
    let updatedAt: Date
    let lastStatusAt: Date
    let deadlineAt: Date?
    let scheduledFor: Date?
    let deliveryVerificationCode: String?
    let isEditable: Bool
    let canCancel: Bool
    let rating: Int?
    let ratingComment: String?
    let estimatedDeliveryTime: Date?
    let estimatedMinutesRemaining: Int?
    let estimatedMinutes: Int?
    let deliveryMode: FulfillmentMode?
    let pickupAddress: OrderPickupAddress?
    let estimatedReadyAt: Date?

    var items: [OrderDetailItem]
    var discounts: [OrderDetailDiscount]
    let deliveryAddress: OrderDeliveryAddress?
    let deliveryPerson: OrderDeliveryPerson?
    var timeline: [OrderTimelineEvent]
    var comments: [OrderDetailComment]

    // Branch info
    let branchId: String
    let branchName: String
    let branchAddress: String?
    let branchPhone: String?
    let branchImageUrl: String?
    let branchCoordinates: CLLocationCoordinate2D?
    let transferAccounts: [OrderTransferAccount]
    let transferPhones: [OrderTransferPhone]

    // Business info
    let businessId: String
    let businessName: String
    let businessImageUrl: String?

    var formattedSubtotal: String { formatOrderAmount(subtotal, currency: currency) }
    var formattedDeliveryFee: String { formatOrderAmount(deliveryFee, currency: currency) }
    var formattedServiceCharge: String { formatOrderAmount(serviceCharge, currency: currency) }
    var formattedTotal: String { formatOrderAmount(total, currency: currency) }
    var formattedZeroAmount: String { formatOrderAmount(0, currency: currency) }
    var isPickup: Bool { deliveryMode == .pickup }
    var displayStatus: OrderStatusEnum {
        customerVisibleStatus == .unknown ? status : customerVisibleStatus
    }
}

// MARK: - Order Detail Item
struct OrderDetailItem: Identifiable {
    let id: String
    let productId: String
    let name: String
    let price: Double
    var quantity: Int
    let imageUrl: String?
    let wasModifiedByStore: Bool
    let currency: String

    var lineTotal: Double {
        Double(quantity) * price
    }

    var formattedPrice: String { formatOrderAmount(price, currency: currency) }
    var formattedLineTotal: String { formatOrderAmount(lineTotal, currency: currency) }
}

// MARK: - Order Discount
struct OrderDetailDiscount: Identifiable {
    let id: String
    let title: String
    let amount: Double
    let type: DiscountTypeEnum
    let currency: String

    var formattedAmount: String { "-" + formatOrderAmount(amount, currency: currency) }
}

// MARK: - Delivery Address
struct OrderDeliveryAddress {
    let street: String
    let city: String?
    let reference: String?
    let coordinates: CLLocationCoordinate2D?
    let addressType: String?
    let buildingName: String?
    let floor: String?
    let apartment: String?
    let deliveryInstructions: String?

    var fullAddress: String {
        var parts = [street]
        if let city = city { parts.append(city) }
        return parts.joined(separator: ", ")
    }
}

struct OrderPickupAddress {
    let street: String?
    let city: String?
    let reference: String?

    var displayText: String {
        if let street, !street.isEmpty { return street }
        if let city, !city.isEmpty { return city }
        return "Recogida en tienda"
    }
}

// MARK: - Delivery Person
struct OrderDeliveryPerson: Identifiable {
    let id: String
    let name: String
    let phone: String
    let rating: Double
    let vehicleType: String?
    let vehiclePlate: String?
    let profileImageUrl: String?
    let isOnline: Bool
    var currentLocation: CLLocationCoordinate2D?

    var formattedRating: String { String(format: "%.1f", rating) }
}

// MARK: - Timeline Event
struct OrderTimelineEvent: Identifiable {
    let id = UUID()
    let status: OrderStatusEnum
    let timestamp: Date
    let message: String
    let actor: OrderActorEnum

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, HH:mm"
        formatter.locale = Locale(identifier: "es")
        return formatter.string(from: timestamp)
    }
}

// MARK: - Order Comment
struct OrderDetailComment: Identifiable {
    let id: String
    let author: OrderActorEnum
    let message: String
    let timestamp: Date

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Transfer Account
struct OrderTransferAccount: Identifiable {
    let id = UUID()
    let cardNumber: String
    let confirmPhone: String
    let cardHolderName: String
    let pagoQr: String?
}

// MARK: - Transfer Phone
struct OrderTransferPhone: Identifiable {
    let id = UUID()
    let phone: String
}

// MARK: - Refund

/// Estado de reembolso derivado del intento de pago de la orden.
enum OrderRefundState {
    case eligible    // pago completado: se puede solicitar reembolso
    case requested   // reembolso solicitado, en revisión
    case processing  // reembolso en proceso
    case refunded    // reembolso completado
}

/// Información de reembolso asociada a un intento de pago de la orden.
struct OrderRefundInfo {
    let paymentAttemptId: String
    var state: OrderRefundState
    var refundAmount: Double?
    let currency: String

    var formattedRefundAmount: String? {
        guard let refundAmount else { return nil }
        return formatOrderAmount(refundAmount, currency: currency)
    }
}

// MARK: - Legacy compatibility aliases
typealias OrderDetailStatus = OrderStatusEnum
typealias OrderDetailDiscountType = DiscountTypeEnum
typealias OrderDetailActor = OrderActorEnum
