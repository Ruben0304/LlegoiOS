import SwiftUI

// MARK: - Payment Method Model
struct PaymentMethod: Equatable {
    enum ImageType: Equatable {
        case systemIcon(String)
        case assetImage(String)
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
        }
    }

    static func == (lhs: PaymentMethod, rhs: PaymentMethod) -> Bool {
        return lhs.id == rhs.id
    }
}
