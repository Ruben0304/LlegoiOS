import Foundation

// Helper para gestionar el estado del onboarding
struct OnboardingHelper {
    private static let onboardingKey = "onboardingCompleted"
    private static let onboardingShownOnceKey = "onboardingShownOnce"

    // Verificar si el onboarding fue completado
    static var isOnboardingCompleted: Bool {
        return UserDefaults.standard.bool(forKey: onboardingKey)
    }

    // Mostrar onboarding solo la primera vez que se abre la app
    static var shouldShowOnboardingOnLaunch: Bool {
        return !UserDefaults.standard.bool(forKey: onboardingShownOnceKey)
    }

    // Marcar el onboarding como completado
    static func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        UserDefaults.standard.set(true, forKey: onboardingShownOnceKey)
    }

    // Marcar que el onboarding ya fue mostrado al menos una vez
    static func markOnboardingShown() {
        UserDefaults.standard.set(true, forKey: onboardingShownOnceKey)
    }

    // Resetear el onboarding (útil para desarrollo y testing)
    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: onboardingKey)
        UserDefaults.standard.removeObject(forKey: onboardingShownOnceKey)
    }

    // Forzar mostrar el onboarding en la próxima apertura
    static func showOnboardingNextLaunch() {
        UserDefaults.standard.set(false, forKey: onboardingKey)
        UserDefaults.standard.set(false, forKey: onboardingShownOnceKey)
    }
}
