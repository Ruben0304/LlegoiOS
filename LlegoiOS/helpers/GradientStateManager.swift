import SwiftUI
import Combine

/// Manages the global gradient state across the application
/// When the category changes in HomeView, all views using HomeGradientBackground will update
@MainActor
class GradientStateManager: ObservableObject {
    /// Shared singleton instance
    static let shared = GradientStateManager()

    /// Current category index that determines the gradient colors
    @Published var currentCategoryIndex: Int = 0

    /// Dynamic accent color based on current category
    @Published var currentAccentColor: Color = Color(red: 0.9, green: 0.3, blue: 0.2)

    private init() {}

    /// Update the current category index
    func setCategoryIndex(_ index: Int) {
        currentCategoryIndex = index
        updateAccentColor(for: index)
    }

    /// Update the accent color based on category
    private func updateAccentColor(for index: Int) {
        currentAccentColor = accentColor(at: index)
    }

    /// Color de acento de una categoría cualquiera, sin cambiar el estado actual.
    /// Lo usa el selector de tipo de negocio para pintar cada opción con su
    /// propio color aunque no esté seleccionada.
    func accentColor(at index: Int) -> Color {
        let configManager = BusinessTypeConfigManager.shared

        if !configManager.businessTypes.isEmpty && index < configManager.businessTypes.count {
            return configManager.getGlowColor(at: index)
        }

        // Fallback to hardcoded colors
        switch index {
        case 0: // Restaurantes - Rojo-naranja terracota
            return Color(red: 0.9, green: 0.3, blue: 0.2)
        case 1: // Supermercado - Verde
            return Color(red: 0.2, green: 0.7, blue: 0.5)
        case 2: // Dulcería - Marrón-Dorado
            return Color(red: 0.737, green: 0.514, blue: 0.345)
        case 3: // Perfumería - Azul morado/Lavanda (estilo Sauvage)
            return Color(red: 0.50, green: 0.45, blue: 0.70)
        default:
            return Color(red: 0.9, green: 0.3, blue: 0.2)
        }
    }

    /// Paleta de gradiente de una categoría cualquiera, sin cambiar el estado actual.
    func gradientPalette(at index: Int) -> (dark: Color, medium: Color, light: Color, veryLight: Color) {
        let configManager = BusinessTypeConfigManager.shared

        if !configManager.businessTypes.isEmpty && index < configManager.businessTypes.count {
            let palette = configManager.getGradientPalette(at: index)
            return (dark: palette.dark, medium: palette.medium, light: palette.light, veryLight: palette.veryLight)
        }

        switch index {
        case 0: // Restaurantes - Rojo-naranja terracota
            return (
                dark: Color(red: 0.5, green: 0.15, blue: 0.1),
                medium: Color(red: 0.7, green: 0.25, blue: 0.15),
                light: Color(red: 0.85, green: 0.45, blue: 0.3),
                veryLight: Color(red: 0.95, green: 0.88, blue: 0.85)
            )
        case 1: // Supermercado - Verde
            return (
                dark: Color(red: 0.05, green: 0.3, blue: 0.25),
                medium: Color(red: 0.1, green: 0.45, blue: 0.38),
                light: Color(red: 0.4, green: 0.65, blue: 0.55),
                veryLight: Color(red: 0.85, green: 0.92, blue: 0.88)
            )
        case 2: // Dulcería - Marrón-Dorado-Beige
            return (
                dark: Color(red: 0.737, green: 0.514, blue: 0.345),
                medium: Color(red: 0.910, green: 0.796, blue: 0.702),
                light: Color(red: 0.85, green: 0.7, blue: 0.6),
                veryLight: Color(red: 0.96, green: 0.92, blue: 0.88)
            )
        case 3: // Perfume - Azul morado/Lavanda (estilo Sauvage)
            return (
                dark: Color(red: 0.30, green: 0.28, blue: 0.55),
                medium: Color(red: 0.48, green: 0.45, blue: 0.68),
                light: Color(red: 0.65, green: 0.62, blue: 0.78),
                veryLight: Color(red: 0.90, green: 0.88, blue: 0.94)
            )
        default:
            return (
                dark: Color(red: 0.5, green: 0.15, blue: 0.1),
                medium: Color(red: 0.7, green: 0.25, blue: 0.15),
                light: Color(red: 0.85, green: 0.45, blue: 0.3),
                veryLight: Color(red: 0.95, green: 0.88, blue: 0.85)
            )
        }
    }

    /// Get the current gradient palette for the selected category
    func getCurrentGradientPalette() -> (dark: Color, medium: Color, light: Color, veryLight: Color) {
        gradientPalette(at: currentCategoryIndex)
    }
}
