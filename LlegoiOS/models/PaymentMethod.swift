import SwiftUI

// MARK: - Payment Method Model (Legacy - for UI compatibility)
struct PaymentMethod: Identifiable, Equatable {
    enum ImageType: Equatable {
        case systemIcon(String)
        case assetImage(String)
        case url(String)
    }

    let id: String
    let name: String
    let description: String
    let imageType: ImageType
    let color: Color
    let currency: String

    // Computed property para compatibilidad con código existente
    var icon: String {
        switch imageType {
        case .systemIcon(let name):
            return name
        case .assetImage(let name):
            return name
        case .url(let urlString):
            return urlString
        }
    }

    static func == (lhs: PaymentMethod, rhs: PaymentMethod) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Convert from Backend Model
    static func from(_ model: PaymentMethodModel) -> PaymentMethod {
        // Map method type to icon and color
        let (imageType, color) = iconAndColor(for: model.method, code: model.code, iconUrl: model.iconUrl)
        
        // Use instructions as description if available
        let description = model.instructions ?? defaultDescription(for: model.method)
        
        return PaymentMethod(
            id: model.id,
            name: model.name,
            description: description,
            imageType: imageType,
            color: color,
            currency: model.currency
        )
    }
    
    private static func iconAndColor(for method: String, code: String, iconUrl: String?) -> (ImageType, Color) {
        // If iconUrl is provided, use it
        if let iconUrl = iconUrl, !iconUrl.isEmpty {
            return (.url(iconUrl), Color.llegoPrimary)
        }
        
        // Otherwise, map based on method and code
        switch method.lowercased() {
        case "wallet":
            return (.systemIcon("wallet.pass"), Color.llegoAccent)
        case "transfer", "transfermovil":
            return (.systemIcon("building.columns"), Color.llegoSecondary)
        case "stripe", "card":
            return (.systemIcon("creditcard"), Color.llegoTertiary)
        case "cash":
            if code.contains("usd") {
                return (.systemIcon("dollarsign.circle"), Color.llegoAccent)
            } else {
                return (.systemIcon("banknote"), Color.llegoPrimary)
            }
        default:
            // Check for specific payment providers
            if code.contains("qvapay") {
                return (.assetImage("qvapay"), Color(red: 0.2, green: 0.6, blue: 0.9))
            } else if code.contains("tropipay") {
                return (.assetImage("tropipay"), Color(red: 0.9, green: 0.4, blue: 0.1))
            } else {
                return (.systemIcon("creditcard"), Color.llegoPrimary)
            }
        }
    }
    
    private static func defaultDescription(for method: String) -> String {
        switch method.lowercased() {
        case "wallet":
            return "Pagar con saldo"
        case "transfer", "transfermovil":
            return "Transferencia bancaria"
        case "stripe", "card":
            return "Visa/Mastercard"
        case "cash":
            return "Pago al recibir"
        default:
            return "Pago digital"
        }
    }
}

