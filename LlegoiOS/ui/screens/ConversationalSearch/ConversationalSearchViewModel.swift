//
//  ConversationalSearchViewModel.swift
//  LlegoiOS
//
//  ViewModel para manejar el estado de la búsqueda conversacional con IA
//

import Combine
import CoreLocation
import Foundation
import SwiftUI

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
    let selectedProvider: ConversationalAIProvider = .llegoAI

    private let repository = ConversationalSearchRepository()
    private let locationManager = UserLocationManager.shared
    private var activeStreamingAssistantMessageId: UUID?

    func refreshAppleIntelligenceAvailability() {}

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

        // Enviar según proveedor seleccionado
        activeStreamingAssistantMessageId = nil

        repository.sendMessage(
            message: text,
            provider: selectedProvider,
            onStreamEvent: { [weak self] event in
                Task { @MainActor in
                    guard let self else { return }

                    switch event {
                    case .started:
                        // Mantener typing visible hasta recibir el primer chunk real.
                        break
                    case .partialText(let text):
                        self.isTyping = false
                        self.updateStreamingAssistantMessageText(text)
                    }
                }
            }
        ) { [weak self] result in
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
                            print(
                                "  │  \(index + 1). \(product.name) - \(product.currency) $\(product.price)"
                            )
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

                    self.finalizeAssistantMessage(with: chatData)
                    self.state = .success

                    print("✅ [VIEWMODEL] Mensaje del asistente finalizado")
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
                        self.removeStreamingAssistantMessageIfNeeded()
                        let assistantErrorMessage = self.makeAssistantErrorMessage(
                            from: backendError)
                        self.messages.append(assistantErrorMessage)
                        print(
                            "⚠️ [VIEWMODEL] Error tipado por código: \(backendError.code.rawValue)")
                        return
                    }

                    if let localError = error as? LocalAIAssistantError {
                        self.errorMessage = localError.localizedDescription
                        self.state = .error(localError.localizedDescription)
                        self.removeStreamingAssistantMessageIfNeeded()
                        let assistantErrorMessage = self.makeAssistantErrorMessage(from: localError)
                        self.messages.append(assistantErrorMessage)
                        return
                    }

                    self.errorMessage = error.localizedDescription
                    self.state = .error(error.localizedDescription)
                    self.removeStreamingAssistantMessageIfNeeded()

                    let errorMessage = ConversationalChatMessage(
                        text:
                            "Lo siento, hubo un error al procesar tu mensaje. Por favor intenta de nuevo.",
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

    private func ensureStreamingAssistantMessage() {
        if let activeStreamingAssistantMessageId,
            messages.contains(where: { $0.id == activeStreamingAssistantMessageId })
        {
            return
        }

        let streamId = UUID()
        let streamingMessage = ConversationalChatMessage(
            id: streamId,
            text: "",
            isFromUser: false,
            timestamp: Date()
        )
        activeStreamingAssistantMessageId = streamId
        messages.append(streamingMessage)
    }

    private func updateStreamingAssistantMessageText(_ text: String) {
        ensureStreamingAssistantMessage()
        guard let activeStreamingAssistantMessageId else { return }
        guard let index = messages.firstIndex(where: { $0.id == activeStreamingAssistantMessageId }) else {
            return
        }

        let current = messages[index]
        let updated = ConversationalChatMessage(
            id: current.id,
            text: text,
            isFromUser: current.isFromUser,
            timestamp: current.timestamp,
            responseType: current.responseType,
            productEntities: current.productEntities,
            branchEntities: current.branchEntities,
            confidence: current.confidence,
            actionTitle: current.actionTitle,
            action: current.action
        )
        messages[index] = updated
    }

    private func finalizeAssistantMessage(with chatData: AIChatData) {
        let assistantMessage = ConversationalChatMessage(
            text: chatData.aiText,
            isFromUser: false,
            timestamp: Date(),
            responseType: chatData.responseType,
            productEntities: chatData.productEntities.isEmpty
                ? nil : chatData.productEntities,
            branchEntities: chatData.branchEntities.isEmpty
                ? nil : chatData.branchEntities,
            confidence: chatData.confidence
        )

        if let activeStreamingAssistantMessageId,
            let index = messages.firstIndex(where: { $0.id == activeStreamingAssistantMessageId })
        {
            let updated = ConversationalChatMessage(
                id: activeStreamingAssistantMessageId,
                text: chatData.aiText,
                isFromUser: false,
                timestamp: messages[index].timestamp,
                responseType: chatData.responseType,
                productEntities: chatData.productEntities.isEmpty
                    ? nil : chatData.productEntities,
                branchEntities: chatData.branchEntities.isEmpty
                    ? nil : chatData.branchEntities,
                confidence: chatData.confidence
            )
            messages[index] = updated
        } else {
            messages.append(assistantMessage)
        }

        self.activeStreamingAssistantMessageId = nil
    }

    private func removeStreamingAssistantMessageIfNeeded() {
        guard let activeStreamingAssistantMessageId else { return }
        messages.removeAll { $0.id == activeStreamingAssistantMessageId }
        self.activeStreamingAssistantMessageId = nil
    }

    func sendWelcomeMessage(mode: SearchMode) {
        print("\n╔═══════════════════════════════════════════════════╗")
        print("║  [VIEWMODEL] sendWelcomeMessage                   ║")
        print("╚═══════════════════════════════════════════════════╝")
        print("🎯 [VIEWMODEL] Modo: \(mode.title)")

        let welcomeText: String
        switch mode {
        case .search:
            welcomeText = "Hola. Dime qué producto buscas y te ayudo a encontrarlo."
        case .purchase:
            welcomeText = "Modo compra activado. Dime qué quieres comprar y te ayudo."
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

    private func makeAssistantErrorMessage(from backendError: AIChatBackendError)
        -> ConversationalChatMessage
    {
        let quotaSummary = quotaSummaryText(backendError.quota)
        switch backendError.code {
        case .freeQuotaExceeded:
            return ConversationalChatMessage(
                text: """
                    Se acabó tu cuota gratuita.
                    Ya usaste tus consultas gratis en este dispositivo. Pásate a Plan Pro para seguir usando AI Chat.\(quotaSummary)
                    """,
                isFromUser: false,
                timestamp: Date()
                // Suscripciones ocultas para revisión App Store (sin venta de planes por ahora)
                // actionTitle: "Ir a Planes",
                // action: .openPlans
            )
        case .quotaExceeded:
            return ConversationalChatMessage(
                text: """
                    Alcanzaste tu límite de consultas.
                    Llegaste al máximo de consultas de tu plan actual. Mejora tu plan para continuar.\(quotaSummary)
                    """,
                isFromUser: false,
                timestamp: Date()
                // Suscripciones ocultas para revisión App Store (sin venta de planes por ahora)
                // actionTitle: "Ver planes",
                // action: .openPlans
            )
        case .deviceIdRequired:
            return ConversationalChatMessage(
                text:
                    "No pudimos validar tu dispositivo.\nActualiza la app o inténtalo de nuevo para continuar con AI Chat.",
                isFromUser: false,
                timestamp: Date()
            )
        case .messageTooLong:
            return ConversationalChatMessage(
                text:
                    "Tu mensaje es muy largo. Envíalo en menos palabras para que pueda ayudarte mejor.",
                isFromUser: false,
                timestamp: Date()
            )
        case .dailyDeviceQuotaExceeded:
            return ConversationalChatMessage(
                text:
                    "Llegaste al límite diario de consultas para este dispositivo. Vuelve mañana.\(quotaSummary)",
                isFromUser: false,
                timestamp: Date()
            )
        case .rateLimitExceeded:
            let retryText: String
            if let retryAfter = backendError.retryAfter {
                retryText = "\n\nInténtalo de nuevo en \(retryAfter)s."
            } else {
                retryText = ""
            }
            return ConversationalChatMessage(
                text: "Espera un momento antes de enviar otro mensaje.\(retryText)",
                isFromUser: false,
                timestamp: Date()
            )
        case .serviceError:
            return ConversationalChatMessage(
                text: "El servicio de AI no está disponible temporalmente. Intenta de nuevo en breve.",
                isFromUser: false,
                timestamp: Date()
            )
        case .invalidRequest:
            return ConversationalChatMessage(
                text:
                    "No pudimos procesar esta solicitud. Verifica tu sesión e inténtalo de nuevo.",
                isFromUser: false,
                timestamp: Date()
            )
        case .unknown:
            return ConversationalChatMessage(
                text: backendError.fallbackMessage,
                isFromUser: false,
                timestamp: Date()
            )
        }
    }

    private func makeAssistantErrorMessage(from localError: LocalAIAssistantError)
        -> ConversationalChatMessage
    {
        switch localError {
        case .appleIntelligenceUnsupported:
            return ConversationalChatMessage(
                text:
                    "Para usar Apple Intelligence local, tu dispositivo debe ser iPhone 15 Pro o superior.",
                isFromUser: false,
                timestamp: Date()
            )
        case .appleIntelligenceDisabled:
            return ConversationalChatMessage(
                text:
                    "Apple Intelligence está desactivado. Actívalo en Configuración para usar el modo local.",
                isFromUser: false,
                timestamp: Date()
            )
        case .appleIntelligenceUnavailable(let reason):
            return ConversationalChatMessage(
                text: "Apple Intelligence no está disponible ahora mismo: \(reason)",
                isFromUser: false,
                timestamp: Date()
            )
        case .unauthenticated:
            return ConversationalChatMessage(
                text: "Inicia sesión para usar la búsqueda semántica local.",
                isFromUser: false,
                timestamp: Date()
            )
        case .invalidModelResponse:
            return ConversationalChatMessage(
                text: "No se pudo procesar la respuesta del modelo local. Inténtalo de nuevo.",
                isFromUser: false,
                timestamp: Date()
            )
        case .semanticSearchFailed(let message):
            return ConversationalChatMessage(
                text: "No se pudo ejecutar la búsqueda semántica: \(message)",
                isFromUser: false,
                timestamp: Date()
            )
        case .contextWindowExceeded:
            return ConversationalChatMessage(
                text:
                    "La consulta tenía demasiado contexto para Apple Intelligence local. Intenta con una petición más corta.",
                isFromUser: false,
                timestamp: Date()
            )
        case .storageUnavailable(let message):
            return ConversationalChatMessage(
                text: "No se pudo acceder al almacenamiento local del chat: \(message)",
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
