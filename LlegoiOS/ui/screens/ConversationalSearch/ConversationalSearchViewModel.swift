//
//  ConversationalSearchViewModel.swift
//  LlegoiOS
//
//  ViewModel para manejar el estado de la búsqueda conversacional con IA
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

enum ConversationalSearchState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class ConversationalSearchViewModel: ObservableObject {
    @Published var state: ConversationalSearchState = .idle
    @Published var messages: [ConversationalChatMessage] = []
    @Published var isTyping: Bool = false
    @Published var errorMessage: String?

    private let repository = ConversationalSearchRepository()
    private let locationManager = UserLocationManager.shared

    func sendMessage(_ text: String) {
        print("\n╔═══════════════════════════════════════════════════╗")
        print("║  [VIEWMODEL] sendMessage iniciado                 ║")
        print("╚═══════════════════════════════════════════════════╝")
        print("📤 [VIEWMODEL] Mensaje del usuario: \"\(text)\"")

        // Agregar mensaje del usuario
        let userMessage = ConversationalChatMessage(
            text: text,
            isFromUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        print("✅ [VIEWMODEL] Mensaje del usuario agregado a la lista")

        // Mostrar indicador de escritura
        isTyping = true
        state = .loading
        print("⏳ [VIEWMODEL] Estado cambiado a LOADING\n")

        // Enviar al backend
        repository.sendMessage(message: text) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                print("\n╔═══════════════════════════════════════════════════╗")
                print("║  [VIEWMODEL] Respuesta del Repository recibida    ║")
                print("╚═══════════════════════════════════════════════════╝")

                self.isTyping = false

                switch result {
                case .success(let chatData):
                    print("✅ [VIEWMODEL] SUCCESS - Procesando respuesta")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    print("📋 [VIEWMODEL] Datos recibidos:")
                    print("  ├─ Response Type: \(chatData.responseType)")
                    print("  ├─ AI Text: \"\(chatData.aiText)\"")
                    print("  ├─ Confidence: \(chatData.confidence)")
                    print("  ├─ Products: \(chatData.productEntities.count)")
                    if !chatData.productEntities.isEmpty {
                        print("  ├─ Productos:")
                        chatData.productEntities.enumerated().forEach { index, product in
                            print("  │  \(index + 1). \(product.name) - \(product.currency) $\(product.price)")
                            print("  │     └─ Imagen: \(product.imageUrl)")
                        }
                    }
                    print("  ├─ Branches: \(chatData.branchEntities.count)")
                    if !chatData.branchEntities.isEmpty {
                        print("  ├─ Tiendas:")
                        chatData.branchEntities.enumerated().forEach { index, branch in
                            print("  │  \(index + 1). \(branch.name) - \(branch.address)")
                            print("  │     └─ Avatar: \(branch.avatarUrl ?? "N/A")")
                        }
                    }
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

                    // Crear mensaje del asistente
                    print("📦 [VIEWMODEL] Pasando \(chatData.productEntities.count) productos al mensaje")
                    print("🏪 [VIEWMODEL] Pasando \(chatData.branchEntities.count) branches al mensaje")
                    
                        let assistantMessage = ConversationalChatMessage(
                        text: chatData.aiText,
                        isFromUser: false,
                        timestamp: Date(),
                        responseType: chatData.responseType,
                        productEntities: chatData.productEntities.isEmpty ? nil : chatData.productEntities,
                        branchEntities: chatData.branchEntities.isEmpty ? nil : chatData.branchEntities,
                        confidence: chatData.confidence
                    )

                    self.messages.append(assistantMessage)
                    self.state = .success

                    print("✅ [VIEWMODEL] Mensaje del asistente agregado")
                    print("✅ [VIEWMODEL] Estado cambiado a SUCCESS")
                    print("📊 [VIEWMODEL] Total mensajes: \(self.messages.count)\n")

                case .failure(let error):
                    print("❌ [VIEWMODEL] FAILURE - Error recibido")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    print("📛 [VIEWMODEL] Error: \(error.localizedDescription)")
                    print("🔍 [VIEWMODEL] Error completo: \(error)")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

                    if let backendError = error as? AIChatBackendError {
                        self.errorMessage = backendError.fallbackMessage
                        self.state = .error(backendError.fallbackMessage)
                        let assistantErrorMessage = self.makeAssistantErrorMessage(from: backendError)
                        self.messages.append(assistantErrorMessage)
                        print("⚠️ [VIEWMODEL] Error tipado por código: \(backendError.code.rawValue)")
                        return
                    }

                    self.errorMessage = error.localizedDescription
                    self.state = .error(error.localizedDescription)

                    let errorMessage = ConversationalChatMessage(
                        text: "Lo siento, hubo un error al procesar tu mensaje. Por favor intenta de nuevo.",
                        isFromUser: false,
                        timestamp: Date()
                    )
                    self.messages.append(errorMessage)

                    print("⚠️ [VIEWMODEL] Mensaje de error agregado a la UI")
                    print("📊 [VIEWMODEL] Total mensajes: \(self.messages.count)\n")
                }
            }
        }
    }
    
    func sendWelcomeMessage(mode: SearchMode) {
        print("\n╔═══════════════════════════════════════════════════╗")
        print("║  [VIEWMODEL] sendWelcomeMessage                   ║")
        print("╚═══════════════════════════════════════════════════╝")
        print("🎯 [VIEWMODEL] Modo: \(mode.title)")

        let welcomeText: String
        switch mode {
        case .search:
            welcomeText = "Hola! Dime qué producto buscas y te ayudo a encontrarlo 😊"
        case .purchase:
            welcomeText = "Modo compra activado. Dime qué quieres comprar y te ayudo con el pedido."
        }

        print("💬 [VIEWMODEL] Texto de bienvenida: \"\(welcomeText)\"")

        let welcomeMessage = ConversationalChatMessage(
            text: welcomeText,
            isFromUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)

        print("✅ [VIEWMODEL] Mensaje de bienvenida agregado")
        print("📊 [VIEWMODEL] Total mensajes: \(messages.count)\n")
    }

    private func makeAssistantErrorMessage(from backendError: AIChatBackendError) -> ConversationalChatMessage {
        let quotaSummary = quotaSummaryText(backendError.quota)
        switch backendError.code {
        case .freeQuotaExceeded:
            return ConversationalChatMessage(
                text: """
Se acabó tu cuota gratuita.
Ya usaste tus consultas gratis en este dispositivo. Pásate a Plan Pro para seguir usando AI Chat.\(quotaSummary)
""",
                isFromUser: false,
                timestamp: Date(),
                actionTitle: "Ir a Planes",
                action: .openPlans
            )
        case .quotaExceeded:
            return ConversationalChatMessage(
                text: """
Alcanzaste tu límite de consultas.
Llegaste al máximo de consultas de tu plan actual. Mejora tu plan para continuar.\(quotaSummary)
""",
                isFromUser: false,
                timestamp: Date(),
                actionTitle: "Ver planes",
                action: .openPlans
            )
        case .deviceIdRequired:
            return ConversationalChatMessage(
                text: "No pudimos validar tu dispositivo.\nActualiza la app o inténtalo de nuevo para continuar con AI Chat.",
                isFromUser: false,
                timestamp: Date()
            )
        }
    }

    private func quotaSummaryText(_ quota: AIChatQuotaInfo?) -> String {
        guard quota != nil else { return "" }
        var lines: [String] = []
        if let used = quota?.used, let limit = quota?.limit {
            lines.append("Usadas \(used) de \(limit)")
        }
        if let remaining = quota?.remaining {
            lines.append("Restantes \(remaining)")
        }
        guard !lines.isEmpty else { return "" }
        return "\n\n" + lines.joined(separator: "\n")
    }
}
