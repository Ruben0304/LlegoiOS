import SwiftUI
import UIKit

// MARK: - Garment Type

enum GarmentType: String, CaseIterable, Identifiable {
    case tshirt = "Camiseta"
    case pullover = "Pullover"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tshirt:   return "tshirt.fill"
        case .pullover: return "figure.arms.open"
        }
    }

    var subtitle: String {
        switch self {
        case .tshirt:   return "Manga corta"
        case .pullover: return "Manga larga"
        }
    }
}

// MARK: - Gender

enum GarmentGender: String, CaseIterable, Identifiable {
    case men   = "Hombre"
    case women = "Mujer"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .men:   return "figure.stand"
        case .women: return "figure.dress.line.vertical.figure"
        }
    }
}

// MARK: - Color Presets

struct ShirtColorOption: Identifiable, Equatable {
    let id: String
    let name: String
    let uiColor: UIColor

    var color: Color { Color(uiColor: uiColor) }

    static func == (lhs: ShirtColorOption, rhs: ShirtColorOption) -> Bool {
        lhs.id == rhs.id
    }

    static let presets: [ShirtColorOption] = [
        .init(id: "white",     name: "Blanco",   uiColor: UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)),
        .init(id: "stone",     name: "Piedra",   uiColor: UIColor(red: 0.82, green: 0.78, blue: 0.72, alpha: 1)),
        .init(id: "sand",      name: "Arena",    uiColor: UIColor(red: 0.86, green: 0.78, blue: 0.62, alpha: 1)),
        .init(id: "rose",      name: "Rosa",     uiColor: UIColor(red: 0.92, green: 0.55, blue: 0.72, alpha: 1)),
        .init(id: "burgundy",  name: "Burdeos",  uiColor: UIColor(red: 0.40, green: 0.10, blue: 0.18, alpha: 1)),
        .init(id: "olive",     name: "Oliva",    uiColor: UIColor(red: 0.45, green: 0.50, blue: 0.30, alpha: 1)),
        .init(id: "forest",    name: "Bosque",   uiColor: UIColor(red: 0.10, green: 0.30, blue: 0.22, alpha: 1)),
        .init(id: "navy",      name: "Marino",   uiColor: UIColor(red: 0.10, green: 0.18, blue: 0.36, alpha: 1)),
        .init(id: "lavender",  name: "Lavanda",  uiColor: UIColor(red: 0.65, green: 0.62, blue: 0.78, alpha: 1)),
        .init(id: "graphite",  name: "Grafito",  uiColor: UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1)),
        .init(id: "black",     name: "Negro",    uiColor: UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1))
    ]
}

// MARK: - Decal

struct Decal: Identifiable, Equatable {
    let id: UUID
    var image: UIImage
    /// Posición normalizada (0..1) dentro del área de diseño (centro del decal).
    var position: CGPoint
    /// Escala relativa al ancho del área de diseño (0..1).
    var scale: CGFloat
    /// Rotación.
    var rotation: Angle
    /// Opacidad.
    var opacity: Double

    init(image: UIImage,
         position: CGPoint = CGPoint(x: 0.5, y: 0.5),
         scale: CGFloat = 0.42,
         rotation: Angle = .zero,
         opacity: Double = 1.0) {
        self.id = UUID()
        self.image = image
        self.position = position
        self.scale = scale
        self.rotation = rotation
        self.opacity = opacity
    }

    static func == (lhs: Decal, rhs: Decal) -> Bool { lhs.id == rhs.id }
}
