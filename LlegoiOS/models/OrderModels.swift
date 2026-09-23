import SwiftUI

// MARK: - Order Currency Formatting

func orderCurrencySymbol(for currency: String) -> String {
    switch currency.uppercased() {
    case "USD":
        return "$"
    case "CUP":
        return "CUP"
    default:
        return currency
    }
}

func formatOrderAmount(_ amount: Double, currency: String) -> String {
    String(format: "\(orderCurrencySymbol(for: currency)) %.2f", amount)
}

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

    /// Texto corto para badges. La explicación larga va en `headline`/`nextStep`.
    var displayName: String {
        switch self {
        case .awaitingDeliveryAcceptance: return "Buscando mensajero"
        case .pendingPayment: return "Pendiente de pago"
        case .paymentInProgress: return "Verificando pago"
        case .pendingAcceptance: return "Por confirmar"
        case .modifiedByStore: return "Revisa los cambios"
        case .rejectedByStore: return "Rechazado"
        case .accepted: return "Confirmado"
        case .preparing: return "Preparando"
        case .readyForPickup: return "Listo para recoger"
        case .onTheWay: return "En camino"
        case .delivered: return "Entregado"
        case .cancelled: return "Cancelado"
        case .unknown: return "Actualizado"
        }
    }

    /// Naranja = le toca al cliente, azul = esperando a otro, rojo = malas noticias.
    var color: Color {
        switch self {
        case .pendingPayment, .modifiedByStore: return .orange
        case .pendingAcceptance, .awaitingDeliveryAcceptance, .paymentInProgress: return .blue
        case .rejectedByStore, .cancelled: return .red
        case .accepted: return .indigo
        case .preparing: return .purple
        case .readyForPickup, .onTheWay: return .teal
        case .delivered: return .green
        case .unknown: return .gray
        }
    }

    var icon: String {
        switch self {
        case .awaitingDeliveryAcceptance: return "person.crop.circle.badge.clock"
        case .pendingPayment: return "creditcard.circle.fill"
        case .paymentInProgress: return "clock.badge.checkmark"
        case .pendingAcceptance: return "hourglass"
        case .modifiedByStore: return "square.and.pencil"
        case .rejectedByStore: return "xmark.shield.fill"
        case .accepted: return "checkmark.circle.fill"
        case .preparing: return "timer.circle.fill"
        case .readyForPickup: return "bag.circle.fill"
        case .onTheWay: return "bicycle.circle.fill"
        case .delivered: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    /// Estados en los que el pedido no avanza hasta que el cliente haga algo.
    var requiresCustomerAction: Bool {
        switch self {
        case .pendingPayment, .modifiedByStore, .rejectedByStore: return true
        default: return false
        }
    }

    var isFinal: Bool { self == .delivered || self == .cancelled }

    var isActive: Bool { !isFinal && self != .unknown }

    func headline(isPickup: Bool) -> String {
        switch self {
        case .pendingAcceptance: return "Esperando a la tienda"
        case .awaitingDeliveryAcceptance: return "Buscando mensajero"
        case .pendingPayment: return "Completa el pago"
        case .paymentInProgress: return "Verificando tu pago"
        case .modifiedByStore: return "La tienda cambió tu pedido"
        case .rejectedByStore: return "La tienda no pudo aceptar tu pedido"
        case .accepted: return "Pedido confirmado"
        case .preparing: return "Preparando tu pedido"
        case .readyForPickup: return isPickup ? "¡Listo para recoger!" : "Listo, esperando al mensajero"
        case .onTheWay: return "Tu pedido va en camino"
        case .delivered: return isPickup ? "Pedido recogido" : "Pedido entregado"
        case .cancelled: return "Pedido cancelado"
        case .unknown: return "Estado actualizado"
        }
    }

    /// Qué está pasando y qué viene después, en una frase.
    func nextStep(isPickup: Bool) -> String {
        switch self {
        case .pendingAcceptance:
            return "La tienda está revisando tu pedido. Te avisaremos en cuanto lo confirme."
        case .awaitingDeliveryAcceptance:
            return "La tienda confirmó tu pedido. Estamos asignando un mensajero."
        case .pendingPayment:
            return "La tienda confirmó tu pedido. Paga para que empiecen a prepararlo."
        case .paymentInProgress:
            return "Recibimos tu aviso de pago. La tienda lo está confirmando; no tienes que pagar de nuevo."
        case .modifiedByStore:
            return "Revisa los productos marcados como modificados y acepta los cambios para continuar."
        case .rejectedByStore:
            return "Puedes modificar los productos y reenviar el pedido, o cancelarlo."
        case .accepted:
            return "La tienda empezará a prepararlo en breve."
        case .preparing:
            return isPickup
                ? "Te avisaremos cuando esté listo para recoger."
                : "Cuando esté listo, un mensajero lo llevará a tu dirección."
        case .readyForPickup:
            return isPickup
                ? "Pasa por la tienda y muestra tu código de verificación."
                : "El mensajero lo recogerá en breve."
        case .onTheWay:
            return "Ten a mano tu código de verificación para cuando llegue."
        case .delivered:
            return "¡Que lo disfrutes!"
        case .cancelled:
            return "Este pedido fue cancelado."
        case .unknown:
            return "Desliza hacia abajo para actualizar."
        }
    }

    /// Mensaje del plazo según quién tiene que actuar. `remaining` ya viene formateado.
    func deadlineMessage(remaining: String) -> String {
        switch self {
        case .pendingPayment:
            return "Tienes \(remaining) para pagar o el pedido se cancelará."
        case .modifiedByStore, .rejectedByStore:
            return "Tienes \(remaining) para responder o el pedido se cancelará."
        case .awaitingDeliveryAcceptance:
            return "Si ningún mensajero acepta en \(remaining), el pedido se cancelará sin coste."
        default:
            return "Si la tienda no confirma en \(remaining), el pedido se cancelará sin coste."
        }
    }

    // MARK: Stepper

    static func steps(isPickup: Bool) -> [String] {
        isPickup
            ? ["Enviado", "Confirmado", "Preparando", "Listo", "Recogido"]
            : ["Enviado", "Confirmado", "Preparando", "En camino", "Entregado"]
    }

    /// Paso actual del stepper (0...4). Nil para pedidos cancelados.
    func stepIndex(isPickup: Bool) -> Int? {
        switch self {
        case .cancelled: return nil
        case .accepted: return 1
        case .preparing: return 2
        case .readyForPickup: return isPickup ? 3 : 2
        case .onTheWay: return 3
        case .delivered: return 4
        default: return 0
        }
    }

    /// Progreso 0...1 derivado del stepper: una sola escala para detalle, tracking y Live Activity.
    func progress(isPickup: Bool) -> Double {
        guard let step = stepIndex(isPickup: isPickup) else { return 0 }
        let lastStep = Double(Self.steps(isPickup: isPickup).count - 1)
        // Un poco de avance dentro del paso para que la barra no parezca congelada.
        return min(1, (Double(step) + (step == 0 ? 0.1 : 0)) / lastStep)
    }

    /// El backend muestra READY_FOR_PICKUP como ON_THE_WAY (pensado para envíos).
    /// En recogida en tienda eso es falso: el cliente es quien va a buscarlo.
    static func customerFacing(
        status: OrderStatusEnum, visible: OrderStatusEnum, isPickup: Bool
    ) -> OrderStatusEnum {
        if isPickup && status == .readyForPickup { return .readyForPickup }
        return visible == .unknown ? status : visible
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

// MARK: - Order Time Formatting

enum OrderTimeFormatting {
    static let havana = TimeZone(identifier: "America/Havana") ?? .current

    /// "4:32 min" o "1 h 05 min". Nil si el plazo ya venció.
    static func remaining(until deadline: Date, now: Date) -> String? {
        let seconds = Int(deadline.timeIntervalSince(now))
        guard seconds > 0 else { return nil }
        if seconds >= 3600 {
            return String(format: "%d h %02d min", seconds / 3600, (seconds % 3600) / 60)
        }
        return String(format: "%d:%02d min", seconds / 60, seconds % 60)
    }

    /// Hora local de Cuba, p. ej. "14:30".
    static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = havana
        formatter.locale = Locale(identifier: "es")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    /// "hoy a las 14:30", "mañana a las 9:00" o "vie 26 sep a las 9:00".
    static func scheduled(_ date: Date, now: Date = Date()) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = havana
        let day: String
        if calendar.isDate(date, inSameDayAs: now) {
            day = "hoy"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
            calendar.isDate(date, inSameDayAs: tomorrow)
        {
            day = "mañana"
        } else {
            let formatter = DateFormatter()
            formatter.timeZone = havana
            formatter.locale = Locale(identifier: "es")
            formatter.dateFormat = "EEE d MMM"
            day = formatter.string(from: date)
        }
        return "\(day) a las \(time(date))"
    }
}

// MARK: - Payment Status Enum
enum PaymentStatusEnum: String, Codable {
    case pending = "PENDING"
    case validated = "VALIDATED"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
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
        formatOrderAmount(total, currency: currency)
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "es")
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var isPickup: Bool { fulfillmentMode == .pickup }

    var displayStatus: OrderStatusEnum {
        .customerFacing(status: status, visible: customerVisibleStatus, isPickup: isPickup)
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
