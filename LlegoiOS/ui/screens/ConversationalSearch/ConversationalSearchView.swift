//
//  ConversationalSearchView.swift
//  LlegoiOS
//
//  Pantalla de búsqueda conversacional minimalista
//  Input estilo iMessage + selector de modo
//

import SwiftUI

enum SearchMode {
    case quick
    case manual
}

struct ConversationalSearchView: View {
    @Environment(\.dismiss) private var dismiss

    // Search mode
    @State private var searchMode: SearchMode = .quick

    // Message input
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = []
    @FocusState private var isMessageFocused: Bool

    // Loading states
    @State private var isTyping: Bool = false

    // Gradient animation state
    @State private var isGradientExpanded: Bool = false

    var body: some View {
        ZStack {
            // Background estilo WelcomeView con animación de expansión
            WelcomeGradientBackground(isExpanded: isGradientExpanded)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: isGradientExpanded)

            VStack(spacing: 0) {
                // Messages ScrollView
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            if messages.isEmpty {
                                // Estado vacío minimalista
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 48, weight: .ultraLight))
                                        .foregroundColor(.secondary.opacity(0.3))

                                    Text("¿Qué estás buscando?")
                                        .font(.system(size: 20, weight: .light))
                                        .foregroundColor(.secondary.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 120)
                            } else {
                                ForEach(messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }

                                // Typing indicator
                                if isTyping {
                                    TypingIndicator()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Back button con animación de gradiente al regresar
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // Primero animar el gradiente de vuelta
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isGradientExpanded = false
                    }
                    // Luego dismiss con un pequeño delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }

            // Mode selector - estilo simple como WelcomeView
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        searchMode = searchMode == .quick ? .manual : .quick
                    }
                }) {
                    Text(searchMode == .quick ? "Rápido" : "Manual")
                        .font(.system(size: 15, weight: .medium))
                }
            }

            // Botón plus en el toolbar inferior
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    // Acción para el botón plus (adjuntar archivos, etc.)
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.llegoPrimary)
                        .fontWeight(.semibold)
                }
            }

            ToolbarSpacer(.fixed, placement: .bottomBar)

            // Input en el toolbar inferior
            ToolbarItem(placement: .bottomBar) {
                messageInputToolbar
            }
        }
        .onAppear {
            // Esperar a que termine la animación de presentación antes de expandir el gradiente
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    isGradientExpanded = true
                }
            }

            // Mensaje inicial del asistente
            if messages.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation {
                        messages.append(ChatMessage(
                            text: searchMode == .quick ?
                                "Hola! Dime qué producto buscas y te ayudo a encontrarlo 😊" :
                                "Modo manual activado. Busca productos escribiendo aquí abajo.",
                            isFromUser: false,
                            timestamp: Date()
                        ))
                    }
                }
            }
        }
    }

    // MARK: - Message Input Toolbar (estilo ShopTabLandingView)
    private var messageInputToolbar: some View {
        HStack(spacing: 8) {
            TextField("Mensaje", text: $messageText)
                .autocorrectionDisabled()
                .focused($isMessageFocused)
                .submitLabel(.send)
                .onSubmit {
                    if !messageText.isEmpty {
                        sendMessage()
                    }
                }

            if !messageText.isEmpty {
//                Button(action: {
//                    messageText = ""
//                }) {
//                    Image(systemName: "xmark.circle.fill")
//                        .foregroundColor(.gray)
//                        .font(.system(size: 14))
//                }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
//                        .font(.system(size: 20))
                        .foregroundColor(.llegoPrimary)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(text: messageText, isFromUser: true, timestamp: Date())

        withAnimation {
            messages.append(userMessage)
        }

        messageText = ""

        // Simular respuesta del asistente
        simulateAssistantResponse(to: userMessage.text)
    }

    private func simulateAssistantResponse(to query: String) {
        isTyping = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isTyping = false

            withAnimation {
                messages.append(ChatMessage(
                    text: "Encontré varios productos para ti. ¿Te gustaría ver los resultados?",
                    isFromUser: false,
                    timestamp: Date()
                ))
            }
        }
    }
}

// MARK: - Supporting Components

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }

            Text(message.text)
                .font(.system(size: 16))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(message.isFromUser ?
                            Color.llegoPrimary :
                            Color(uiColor: .secondarySystemBackground)
                        )
                )
                .foregroundColor(message.isFromUser ? .white : .primary)

            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationPhase: Int = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationPhase == index ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: animationPhase
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            animationPhase = 1
        }
    }
}

// MARK: - Preview
#Preview("Conversational Search") {
    NavigationStack {
        ConversationalSearchView()
    }
}
