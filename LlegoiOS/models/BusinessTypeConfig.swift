import Foundation
import SwiftUI
import SceneKit

// MARK: - Business Type Configuration Model
/// Configuración dinámica de tipos de negocio
/// Soporta tipos locales (bundle) y remotos (descargados)
struct BusinessTypeConfig: Codable, Identifiable, Equatable {
    let id: String
    let key: String                    // "RESTAURANTE", "DULCERIA", "TIENDA"
    let name: String
    let description: String
    let icon: String                   // SF Symbol name
    let model3dFileName: String        // Nombre del archivo .usdz
    let model3dUrl: String?            // URL para descargar (nil = local en bundle)
    let model3dVersion: Int            // Para invalidar cache
    let gradient: GradientConfig
    let camera: CameraConfig
    let glowColor: String              // Hex color para el glow del modelo
    let features: [FeatureConfig]      // Subcategorías del panel derecho
    let sortOrder: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // MARK: - Computed Properties
    
    /// true si el modelo viene en el bundle de la app
    var isLocalBundle: Bool {
        model3dUrl == nil
    }
    
    /// Retorna el path del modelo 3D (local o descargado)
    var model3DPath: URL? {
        if isLocalBundle {
            return Bundle.main.url(
                forResource: model3dFileName.replacingOccurrences(of: ".usdz", with: ""),
                withExtension: "usdz"
            )
        } else {
            return BusinessTypeConfig.downloadedModelsDirectory
                .appendingPathComponent(model3dFileName)
        }
    }
    
    /// Verifica si el modelo 3D está disponible para usar
    var isModel3DAvailable: Bool {
        guard let path = model3DPath else { return false }
        return FileManager.default.fileExists(atPath: path.path)
    }
    
    /// Color de glow como SwiftUI Color
    var glowSwiftUIColor: Color {
        Color(hex: glowColor)
    }
    
    /// Directorio donde se guardan los modelos descargados
    static var downloadedModelsDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let modelsDir = documentsPath.appendingPathComponent("BusinessTypeModels")
        if !FileManager.default.fileExists(atPath: modelsDir.path) {
            try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        }
        return modelsDir
    }
    
    /// Convierte a CategoryModel3D para compatibilidad con el carrusel existente
    func toCategoryModel3D() -> CategoryModel3D {
        CategoryModel3D(
            name: name,
            fileName: model3dFileName,
            description: description,
            icon: icon,
            cameraPosition: camera.position,
            cameraEulerAngles: camera.eulerAngles,
            customScale: nil
        )
    }
}

// MARK: - Feature Configuration (Subcategorías)
struct FeatureConfig: Codable, Identifiable, Equatable {
    var id: String { "\(icon)-\(title)" }
    let icon: String
    let title: String
    let subtitle: String
    let sortOrder: Int
    
    func toFeature() -> Feature {
        Feature(icon: icon, title: title, subtitle: subtitle)
    }
}

// MARK: - Gradient Configuration
struct GradientConfig: Codable, Equatable {
    let darkColor: String
    let mediumColor: String
    let lightColor: String
    let veryLightColor: String
    let overlayColor: String
    
    var dark: Color { Color(hex: darkColor) }
    var medium: Color { Color(hex: mediumColor) }
    var light: Color { Color(hex: lightColor) }
    var veryLight: Color { Color(hex: veryLightColor) }
    var overlay: Color { Color(hex: overlayColor) }
    
    var colorPalette: (dark: Color, medium: Color, light: Color, veryLight: Color, overlay: Color) {
        (dark: dark, medium: medium, light: light, veryLight: veryLight, overlay: overlay)
    }
}

// MARK: - Camera Configuration
struct CameraConfig: Codable, Equatable {
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let eulerX: Float?
    let eulerY: Float?
    let eulerZ: Float?
    
    var position: SCNVector3 {
        SCNVector3(x: positionX, y: positionY, z: positionZ)
    }
    
    var eulerAngles: SCNVector3? {
        guard let x = eulerX, let y = eulerY, let z = eulerZ else { return nil }
        return SCNVector3(x: x, y: y, z: z)
    }
    
    static let `default` = CameraConfig(
        positionX: 0, positionY: 0, positionZ: 3.2,
        eulerX: nil, eulerY: nil, eulerZ: nil
    )
}

// MARK: - Download State
enum Model3DDownloadState: Equatable {
    case notNeeded           // Modelo local en bundle
    case notDownloaded       // Necesita descarga
    case downloading(Double) // Progreso 0.0 - 1.0
    case downloaded          // Descargado y listo
    case failed(String)      // Error con mensaje
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 128, 128, 128)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
