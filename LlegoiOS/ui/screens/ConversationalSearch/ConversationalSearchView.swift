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

    // Loading states
    @State private var isTyping: Bool = false

    var body: some View {
        ZStack {
            // Background estilo WelcomeView
            WelcomeGradientBackground()
                .ignoresSafeArea()

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

                // Input estilo iMessage
                iMessageStyleInput
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Color(uiColor: .systemBackground)
                            .opacity(0.95)
                            .ignoresSafeArea(edges: .bottom)
                    )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Back button
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
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
        }
        .onAppear {
            // Mensaje inicial del asistente
            if messages.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        messages.append(ChatMessage(
                            text: searchMode == .quick ?
                                "Hola! Dime qué producto buscas y te ayudo a encontrarlo 😊" :
                                "Modo manual activado. Busca productos escribiendo aquí abajo.",
                            isUser: false
                        ))
                    }
                }
            }
        }
    }

    // MARK: - iMessage Style Input
    private var iMessageStyleInput: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Input field
            HStack(spacing: 8) {
                TextField("Mensaje", text: $messageText, axis: .vertical)
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .lineLimit(1...5)

                // Attach button (opcional)
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .padding(.trailing, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )

            // Send button
            Button(action: sendMessage) {
                Image(systemName: messageText.isEmpty ? "arrow.up.circle" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(messageText.isEmpty ? .secondary.opacity(0.3) : .blue)
            }
            .disabled(messageText.isEmpty)
        }
    }

    // MARK: - Actions
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(text: messageText, isUser: true)

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
                    isUser: false
                ))
            }
        }
    }
}

// MARK: - Supporting Components

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp = Date()
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            Text(message.text)
                .font(.system(size: 16))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(message.isUser ?
                            Color.blue :
                            Color(uiColor: .secondarySystemBackground)
                        )
                )
                .foregroundColor(message.isUser ? .white : .primary)

            if !message.isUser {
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
