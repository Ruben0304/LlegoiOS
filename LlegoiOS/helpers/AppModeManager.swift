//
//  AppModeManager.swift
//  LlegoiOS
//
//  Modo de experiencia de la app, elegido en el onboarding:
//
//  • .elegante — inicio con los modelos 3D y la cinemática (recomendado).
//  • .simple   — inicio directo al catálogo de productos, sin 3D, con un
//                selector de tipo de negocio dentro del propio feed.
//
//  La preferencia se guarda en UserDefaults y puede cambiarse luego desde Perfil.
//

import Foundation
import Combine

enum AppMode: String, CaseIterable, Identifiable {
    case elegante
    case simple

    var id: String { rawValue }

    var title: String {
        switch self {
        case .elegante: return "Elegante"
        case .simple: return "Simple"
        }
    }

    var tagline: String {
        switch self {
        case .elegante: return "La experiencia completa"
        case .simple: return "Directo al grano"
        }
    }

    var summary: String {
        switch self {
        case .elegante:
            return "Inicio con vitrina en 3D, animaciones y navegación por categorías. Así es Llegó como lo diseñamos."
        case .simple:
            return "Entras y ves todos los productos, como una tienda de toda la vida. Cambias de categoría con un toque."
        }
    }

    var isRecommended: Bool { self == .elegante }
}

@MainActor
final class AppModeManager: ObservableObject {
    static let shared = AppModeManager()

    private static let modeKey = "appMode"
    private static let chosenKey = "appModeChosen"

    /// Modo activo. Por defecto elegante (es el recomendado).
    @Published private(set) var mode: AppMode

    /// True cuando el usuario ya eligió explícitamente un modo.
    @Published private(set) var hasChosen: Bool

    /// Modo resaltado en el selector del onboarding, todavía sin confirmar.
    ///
    /// Vive aquí, fuera del árbol de vistas, a propósito: el onboarding se
    /// presenta como overlay y se re-crea entre toques, así que cualquier
    /// `@State` (propio o del padre) se perdía y la tarjeta nunca se veía
    /// seleccionada. Al ser `@Published` de un singleton, la selección
    /// sobrevive a cualquier re-creación y la UI siempre refleja el valor real.
    @Published var draftMode: AppMode

    var isSimple: Bool { mode == .simple }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.modeKey)
        let initialMode = stored.flatMap(AppMode.init(rawValue:)) ?? .elegante
        self.mode = initialMode
        self.draftMode = initialMode
        self.hasChosen = UserDefaults.standard.bool(forKey: Self.chosenKey)
    }

    func set(_ newMode: AppMode) {
        mode = newMode
        draftMode = newMode
        hasChosen = true
        UserDefaults.standard.set(newMode.rawValue, forKey: Self.modeKey)
        UserDefaults.standard.set(true, forKey: Self.chosenKey)
    }
}
