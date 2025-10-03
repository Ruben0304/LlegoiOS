import Foundation

// Helper para gestionar el estado del onboarding
struct OnboardingHelper {
    private static let onboardingKey = "onboardingCompleted"

    // Verificar si el onboarding fue completado
    static var isOnboardingCompleted: Bool {
        return UserDefaults.standard.bool(forKey: onboardingKey)
    }

    // Marcar el onboarding como completado
    static func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    // Resetear el onboarding (útil para desarrollo y testing)
    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: onboardingKey)
    }

    // Forzar mostrar el onboarding en la próxima apertura
    static func showOnboardingNextLaunch() {
        UserDefaults.standard.set(false, forKey: onboardingKey)
    }
}