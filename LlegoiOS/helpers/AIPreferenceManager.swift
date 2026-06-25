//
//  AIPreferenceManager.swift
//  LlegoiOS
//
//  Gestiona la preferencia del usuario entre Apple Intelligence local y API de Llego en la nube
//

import Foundation
import SwiftUI
import Combine

enum AIRecommendationEngine: String, CaseIterable {
    case appleIntelligence = "apple"
    case llegoCloud = "cloud"

    var displayName: String {
        switch self {
        case .appleIntelligence:
            return "Apple Intelligence (Local)"
        case .llegoCloud:
            return "Llego AI (Nube)"
        }
    }

    var description: String {
        switch self {
        case .appleIntelligence:
            return "Usa el modelo de IA en tu dispositivo. Requiere iOS 26+ e iPhone 15 Pro."
        case .llegoCloud:
            return "Usa el modelo de IA de Llego en la nube. Funciona en todos los dispositivos."
        }
    }

    var icon: String {
        switch self {
        case .appleIntelligence:
            return "sparkles"
        case .llegoCloud:
            return "cloud.fill"
        }
    }
}

@MainActor
final class AIPreferenceManager: ObservableObject {
    static let shared = AIPreferenceManager()

    // Forzado a la nube: toda la IA de la app usa el modelo de Llego en la nube.
    // Ignoramos cualquier preferencia guardada o intento de cambiar a Apple Intelligence.
    @Published var selectedEngine: AIRecommendationEngine = .llegoCloud {
        didSet {
            if selectedEngine != .llegoCloud {
                selectedEngine = .llegoCloud  // snap back; el didSet interno ya ve .llegoCloud y se detiene
                return
            }
            savePreference()
        }
    }

    private let userDefaultsKey = "ai_recommendation_engine_preference"

    private init() {
        // Siempre nube, sin importar lo que hubiera guardado de antes.
        self.selectedEngine = .llegoCloud
        UserDefaults.standard.set(
            AIRecommendationEngine.llegoCloud.rawValue, forKey: userDefaultsKey
        )
    }

    private func savePreference() {
        UserDefaults.standard.set(selectedEngine.rawValue, forKey: userDefaultsKey)
        print("💾 [AIPreferenceManager] Preferencia guardada: \(selectedEngine.displayName)")
    }

    /// Verifica si Apple Intelligence está realmente disponible
    func isAppleIntelligenceAvailable() -> Bool {
        return RecommendationEngine.shared.isAvailable()
    }

    /// Obtiene el estado de disponibilidad de Apple Intelligence
    func getAppleIntelligenceStatus() -> (isAvailable: Bool, message: String) {
        return RecommendationEngine.shared.getAvailabilityStatus()
    }
}
