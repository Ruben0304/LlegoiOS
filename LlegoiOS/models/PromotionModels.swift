import Foundation

// MARK: - Promotion Type
enum PromotionType: String, CaseIterable {
    case raffle = "raffle"
    case discount = "discount"
    case specialOffer = "special_offer"
    case flash = "flash"
    
    var icon: String {
        switch self {
        case .raffle: return "gift.fill"
        case .discount: return "percent"
        case .specialOffer: return "star.fill"
        case .flash: return "bolt.fill"
        }
    }
    
    var label: String {
        switch self {
        case .raffle: return "Rifa"
        case .discount: return "Descuento"
        case .specialOffer: return "Oferta"
        case .flash: return "Flash"
        }
    }
    
    var color: String {
        switch self {
        case .raffle: return "#9C27B0"
        case .discount: return "#FF5722"
        case .specialOffer: return "#FFC107"
        case .flash: return "#E91E63"
        }
    }
}

// MARK: - Promotion Model
struct Promotion: Identifiable {
    let id: String
    let title: String
    let description: String
    let type: PromotionType
    let imageUrl: String
    let discount: Int?
    let originalPrice: Double?
    let discountedPrice: Double?
    let expiresAt: Date?
    let storeName: String?
    let storeId: String?
    let productId: String?
    let isActive: Bool
    
    var formattedDiscount: String? {
        guard let discount = discount else { return nil }
        return "-\(discount)%"
    }
    
    var formattedOriginalPrice: String? {
        guard let price = originalPrice else { return nil }
        return String(format: "$%.2f", price)
    }
    
    var formattedDiscountedPrice: String? {
        guard let price = discountedPrice else { return nil }
        return String(format: "$%.2f", price)
    }
    
    var timeRemaining: String? {
        guard let expiresAt = expiresAt else { return nil }
        let now = Date()
        let diff = expiresAt.timeIntervalSince(now)
        
        if diff <= 0 { return "Expirado" }
        
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        
        if hours > 24 {
            let days = hours / 24
            return "\(days)d restantes"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Sample Promotions
extension Promotion {
    static let samples: [Promotion] = [
        Promotion(
            id: "promo1",
            title: "Gran Rifa de Navidad",
            description: "Participa y gana increíbles premios",
            type: .raffle,
            imageUrl: "https://images.unsplash.com/photo-1513885535751-8b9238bd345a?w=400&h=300&fit=crop",
            discount: nil,
            originalPrice: nil,
            discountedPrice: nil,
            expiresAt: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            storeName: "Llego",
            storeId: nil,
            productId: nil,
            isActive: true
        ),
        Promotion(
            id: "promo2",
            title: "50% en Pizzas",
            description: "Solo por hoy en pizzas medianas",
            type: .flash,
            imageUrl: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&h=300&fit=crop",
            discount: 50,
            originalPrice: 15.99,
            discountedPrice: 7.99,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 3, to: Date()),
            storeName: "Pizza Express",
            storeId: "store1",
            productId: "prod1",
            isActive: true
        ),
        Promotion(
            id: "promo3",
            title: "Envío Gratis",
            description: "En pedidos mayores a $20",
            type: .specialOffer,
            imageUrl: "https://images.unsplash.com/photo-1526367790999-0150786686a2?w=400&h=300&fit=crop",
            discount: nil,
            originalPrice: nil,
            discountedPrice: nil,
            expiresAt: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
            storeName: nil,
            storeId: nil,
            productId: nil,
            isActive: true
        ),
        Promotion(
            id: "promo4",
            title: "30% en Bebidas",
            description: "Descuento en todas las bebidas",
            type: .discount,
            imageUrl: "https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400&h=300&fit=crop",
            discount: 30,
            originalPrice: 5.99,
            discountedPrice: 4.19,
            expiresAt: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            storeName: "Drinks & More",
            storeId: "store2",
            productId: "prod2",
            isActive: true
        )
    ]
}
