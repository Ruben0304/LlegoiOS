import SwiftUI

/// Fondo degradado dinámico que cambia según la categoría seleccionada
/// Usado en: HomeView, ProductListView, ConversationalSearchView para fondo visual
struct HomeGradientBackground: View {
    @ObservedObject private var gradientManager = GradientStateManager.shared
    @ObservedObject private var configManager = BusinessTypeConfigManager.shared

    // Control para expansión del degradado (usado en ConversationalSearchView)
    var isExpanded: Bool = false

    // Gradiente personalizado opcional (para tiendas específicas)
    var customGradient: ExtractedGradient? = nil

    // Color palettes for each category - ahora usa BusinessTypeConfigManager si hay datos
    private var colorPalette: (dark: Color, medium: Color, light: Color, veryLight: Color, overlay: Color) {
        if let custom = customGradient {
            return (
                dark: custom.primaryColor,
                medium: custom.secondaryColor,
                light: custom.primaryColor.opacity(0.6),
                veryLight: custom.secondaryColor.opacity(0.15),
                overlay: custom.primaryColor
            )
        }
        
        // Intentar obtener del ConfigManager primero (solo si el índice existe)
        if !configManager.businessTypes.isEmpty && gradientManager.currentCategoryIndex < configManager.businessTypes.count {
            return configManager.getGradientPalette(at: gradientManager.currentCategoryIndex)
        }

        // Fallback a colores hardcodeados
        switch gradientManager.currentCategoryIndex {
        case 0: // Restaurantes - Rojo-naranja terracota
            return (
                dark: Color(red: 0.5, green: 0.15, blue: 0.1),
                medium: Color(red: 0.7, green: 0.25, blue: 0.15),
                light: Color(red: 0.85, green: 0.45, blue: 0.3),
                veryLight: Color(red: 0.95, green: 0.88, blue: 0.85),
                overlay: Color(red: 0.45, green: 0.12, blue: 0.08)
            )
        case 1: // Supermercado - Verde
            return (
                dark: Color(red: 0.05, green: 0.3, blue: 0.25),
                medium: Color(red: 0.1, green: 0.45, blue: 0.38),
                light: Color(red: 0.4, green: 0.65, blue: 0.55),
                veryLight: Color(red: 0.85, green: 0.92, blue: 0.88),
                overlay: Color(red: 0.05, green: 0.25, blue: 0.2)
            )
        case 2: // Dulcería - Marrón-Dorado-Beige
            return (
                dark: Color(red: 0.737, green: 0.514, blue: 0.345),
                medium: Color(red: 0.910, green: 0.796, blue: 0.702),
                light: Color(red: 0.85, green: 0.7, blue: 0.6),
                veryLight: Color(red: 0.96, green: 0.92, blue: 0.88),
                overlay: Color(red: 0.65, green: 0.45, blue: 0.3)
            )
        case 3: // Perfumería - Azul morado/Lavanda (estilo Sauvage)
            return (
                dark: Color(red: 0.30, green: 0.28, blue: 0.55),
                medium: Color(red: 0.48, green: 0.45, blue: 0.68),
                light: Color(red: 0.65, green: 0.62, blue: 0.78),
                veryLight: Color(red: 0.90, green: 0.88, blue: 0.94),
                overlay: Color(red: 0.25, green: 0.22, blue: 0.48)
            )
        case 4: // Ropa - Rosa fucsia / magenta (chic fashion)
            return (
                dark: Color(red: 0.55, green: 0.12, blue: 0.32),
                medium: Color(red: 0.78, green: 0.25, blue: 0.50),
                light: Color(red: 0.92, green: 0.55, blue: 0.72),
                veryLight: Color(red: 0.98, green: 0.90, blue: 0.94),
                overlay: Color(red: 0.45, green: 0.08, blue: 0.25)
            )
        default:
            return (
                dark: Color(red: 0.5, green: 0.15, blue: 0.1),
                medium: Color(red: 0.7, green: 0.25, blue: 0.15),
                light: Color(red: 0.85, green: 0.45, blue: 0.3),
                veryLight: Color(red: 0.95, green: 0.88, blue: 0.85),
                overlay: Color(red: 0.45, green: 0.12, blue: 0.08)
            )
        }
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            gradientCore
                .compositingGroup()
                .layerEffect(
                    Shader(function: ShaderFunction(library: .default, name: "llegoSoftBloom"), arguments: []),
                    maxSampleOffset: CGSize(width: 1.2, height: 1.2),
                    isEnabled: true
                )
                .colorEffect(
                    Shader(function: ShaderFunction(library: .default, name: "llegoFilmGrain"), arguments: []),
                    isEnabled: true
                )
        } else {
            gradientCore
        }
    }

    private var gradientCore: some View {
        let palette = colorPalette

        return ZStack {
            // Base gradient - dynamic colors based on category
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.dark, location: 0.0),
                    .init(color: palette.medium, location: isExpanded ? 0.3 : 0.2),
                    .init(color: palette.light, location: isExpanded ? 0.6 : 0.45),
                    .init(color: palette.veryLight, location: isExpanded ? 0.85 : 0.7),
                    .init(color: isExpanded ? palette.veryLight.opacity(0.8) : Color(red: 0.95, green: 0.98, blue: 0.96), location: 1.0)
                ]),
                center: UnitPoint(x: 0.85, y: 0.15),
                startRadius: 10,
                endRadius: isExpanded ? 1200 : 800
            )

            // Secondary overlay for more depth
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.overlay.opacity(0.3), location: 0.0),
                    .init(color: Color.clear, location: isExpanded ? 0.7 : 0.5)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }
}
