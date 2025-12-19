//
//  ConversationalSearchViewModel.swift
//  LlegoiOS
//
//  ViewModel para manejar el estado de la búsqueda conversacional con IA
//

import Foundation
import SwiftUI
import Combine

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
    private let sessionId = "simulador" // Hardcoded por ahora
    
    func sendMessage(_ text: String) {
        // Agregar mensaje del usuario
        let userMessage = ConversationalChatMessage(
            text: text,
            isFromUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // Mostrar indicador de escritura
        isTyping = true
        state = .loading
        
        // Enviar al backend
        repository.sendMessage(message: text, sessionId: sessionId) { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isTyping = false
                
                switch result {
                case .success(let chatData):
                    // Crear mensaje del asistente
                    let assistantMessage = ConversationalChatMessage(
                        text: chatData.aiText,
                        isFromUser: false,
                        timestamp: Date(),
                        responseType: chatData.type,
                        productEntities: chatData.productEntities,
                        branchEntities: chatData.branchEntities,
                        paymentEntities: chatData.paymentEntities
                    )
                    
                    self.messages.append(assistantMessage)
                    self.state = .success
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.state = .error(error.localizedDescription)
                    
                    // Agregar mensaje de error
                    let errorMessage = ConversationalChatMessage(
                        text: "Lo siento, hubo un error al procesar tu mensaje. Por favor intenta de nuevo.",
                        isFromUser: false,
                        timestamp: Date()
                    )
                    self.messages.append(errorMessage)
                }
            }
        }
    }
    
    func sendWelcomeMessage(mode: SearchMode) {
        let welcomeText: String
        switch mode {
        case .search:
            welcomeText = "Hola! Dime qué producto buscas y te ayudo a encontrarlo 😊"
        case .purchase:
            welcomeText = "Modo compra activado. Dime qué quieres comprar y te ayudo con el pedido."
        }
        
        let welcomeMessage = ConversationalChatMessage(
            text: welcomeText,
            isFromUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }
}
