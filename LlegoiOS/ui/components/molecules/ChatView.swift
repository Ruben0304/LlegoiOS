import SwiftUI
import Combine

// MARK: - Chat View (Estilo iMessage)

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.llegoBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Lista de mensajes
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(chatViewModel.messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: chatViewModel.messages.count) { _ in
                            if let lastMessage = chatViewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Input de texto
                    ChatInputBar(
                        messageText: $messageText,
                        isTextFieldFocused: $isTextFieldFocused,
                        onSend: {
                            chatViewModel.sendMessage(messageText)
                            messageText = ""
                        }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(action: {
                        dismiss()
                    })
                }

                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.llegoPrimary)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mensajero")
                                .font(.system(size: 14, weight: .semibold))
                            Text("En línea")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(message.isFromUser ? Color.llegoPrimary : Color.white)
                    )
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }

            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

// MARK: - Chat Input Bar

struct ChatInputBar: View {
    @Binding var messageText: String
    var isTextFieldFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Campo de texto
            TextField("Mensaje", text: $messageText, axis: .vertical)
                .focused(isTextFieldFocused)
                .lineLimit(1...5)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(20)

            // Botón de enviar (siempre visible)
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray.opacity(0.3) : .llegoPrimary)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.llegoBackground)
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
}

// MARK: - Chat ViewModel

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []

    init() {
        // Mensajes de ejemplo
        messages = [
            ChatMessage(
                text: "Hola! Ya recogí tu pedido y voy en camino 🚴‍♂️",
                isFromUser: false,
                timestamp: Date().addingTimeInterval(-300)
            ),
            ChatMessage(
                text: "Perfecto, gracias!",
                isFromUser: true,
                timestamp: Date().addingTimeInterval(-240)
            ),
            ChatMessage(
                text: "Llego en 5 minutos aproximadamente",
                isFromUser: false,
                timestamp: Date().addingTimeInterval(-60)
            )
        ]
    }

    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let newMessage = ChatMessage(
            text: text,
            isFromUser: true,
            timestamp: Date()
        )

        messages.append(newMessage)

        // Simular respuesta del mensajero después de 1-2 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1...2)) {
            let responses = [
                "Entendido 👍",
                "Perfecto!",
                "Ok, gracias por avisar",
                "Dale, sin problema"
            ]

            let response = ChatMessage(
                text: responses.randomElement() ?? "Ok",
                isFromUser: false,
                timestamp: Date()
            )

            self.messages.append(response)
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView()
}
