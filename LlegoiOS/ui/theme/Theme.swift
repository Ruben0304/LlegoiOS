import SwiftUI

struct LlegoTheme {
    // Colores primarios correspondientes al tema de Compose
    static let primaryColor = Color(red: 2/255, green: 49/255, blue: 51/255)
    static let onPrimaryColor = Color.white
    static let secondaryColor = Color(red: 225/255, green: 199/255, blue: 142/255)
    static let tertiaryColor = Color(red: 124/255, green: 65/255, blue: 43/255)
    static let backgroundColor = Color(red: 243/255, green: 243/255, blue: 243/255)
    static let surfaceColor = Color.white
    static let surfaceVariantColor = Color(red: 236/255, green: 240/255, blue: 233/255)
    static let onBackgroundColor = Color(red: 27/255, green: 27/255, blue: 27/255)
    static let onSurfaceColor = Color(red: 27/255, green: 27/255, blue: 27/255)
    static let onSurfaceVariantColor = Color(red: 19/255, green: 45/255, blue: 47/255)
    static let onTertiaryColor = Color(red: 147/255, green: 147/255, blue: 150/255)
    static let accentColor = Color(red: 178/255, green: 214/255, blue: 154/255)
    static let buttonColor = Color(red: 90/255, green: 132/255, blue: 103/255)
    static let onSecondaryContainerColor = Color(red: 157/255, green: 205/255, blue: 120/255)
    
    // MARK: - Dark Mode Colors
    static let darkBackgroundColor = Color(red: 18/255, green: 18/255, blue: 18/255)
    static let darkSurfaceColor = Color(red: 30/255, green: 30/255, blue: 30/255)
    static let darkSurfaceVariantColor = Color(red: 45/255, green: 45/255, blue: 45/255)
    static let darkOnBackgroundColor = Color(red: 230/255, green: 230/255, blue: 230/255)
    static let darkOnSurfaceColor = Color(red: 230/255, green: 230/255, blue: 230/255)
}

// Extension para aplicar los colores fácilmente
extension Color {
    static let llegoPrimary = LlegoTheme.primaryColor
    static let llegoOnPrimary = LlegoTheme.onPrimaryColor
    static let llegoSecondary = LlegoTheme.secondaryColor
    static let llegoTertiary = LlegoTheme.tertiaryColor
    static let llegoBackground = LlegoTheme.backgroundColor
    static let llegoSurface = LlegoTheme.surfaceColor
    static let llegoSurfaceVariant = LlegoTheme.surfaceVariantColor
    static let onBackgroundColor = LlegoTheme.onBackgroundColor
    static let onSurfaceColor = LlegoTheme.onSurfaceColor
    static let onSurfaceVariantColor = LlegoTheme.onSurfaceVariantColor
    static let onTertiaryColor = LlegoTheme.onTertiaryColor
    static let llegoAccent = LlegoTheme.accentColor
    static let llegoButton = LlegoTheme.buttonColor
    static let onSecondaryContainerColor = LlegoTheme.onSecondaryContainerColor
    
    // MARK: - Adaptive Colors (respond to color scheme)
    static func adaptiveBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? LlegoTheme.darkBackgroundColor : LlegoTheme.backgroundColor
    }
    
    static func adaptiveSurface(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? LlegoTheme.darkSurfaceColor : LlegoTheme.surfaceColor
    }
    
    static func adaptiveSurfaceVariant(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? LlegoTheme.darkSurfaceVariantColor : LlegoTheme.surfaceVariantColor
    }
    
    static func adaptiveOnBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? LlegoTheme.darkOnBackgroundColor : LlegoTheme.onBackgroundColor
    }
    
    static func adaptiveOnSurface(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? LlegoTheme.darkOnSurfaceColor : LlegoTheme.onSurfaceColor
    }
    
    // Feed background - slightly gray in light, dark in dark mode
    static func feedBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(red: 0.07, green: 0.07, blue: 0.08)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }
    
    // Card background
    static func cardBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(red: 0.15, green: 0.15, blue: 0.16)
            : Color.white
    }
}
