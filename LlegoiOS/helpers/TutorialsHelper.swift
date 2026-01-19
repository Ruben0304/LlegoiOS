import Foundation

/// Helper para gestionar el estado de visibilidad de tutoriales en el feed
struct TutorialsHelper {
    private static let tutorialsVisibilityKey = "tutorialsVisible"

    /// Verificar si los tutoriales deben mostrarse en el feed
    static var areTutorialsVisible: Bool {
        // Por defecto, los tutoriales están visibles
        if UserDefaults.standard.object(forKey: tutorialsVisibilityKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: tutorialsVisibilityKey)
    }

    /// Ocultar los tutoriales del feed
    static func hideTutorials() {
        UserDefaults.standard.set(false, forKey: tutorialsVisibilityKey)
    }

    /// Mostrar los tutoriales en el feed nuevamente
    static func showTutorials() {
        UserDefaults.standard.set(true, forKey: tutorialsVisibilityKey)
    }

    /// Alternar la visibilidad de tutoriales
    static func toggleTutorials() {
        let currentState = areTutorialsVisible
        UserDefaults.standard.set(!currentState, forKey: tutorialsVisibilityKey)
    }
}
