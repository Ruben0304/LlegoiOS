//
//  ConversationalSearchView.swift
//  LlegoiOS
//
//  Pantalla de búsqueda conversacional minimalista
//  Input estilo iMessage + selector de modo
//

import SwiftUI
import Combine

enum SearchMode: CaseIterable {
    case search
    case purchase

    var title: String {
        switch self {
        case .search:
            return "Busqueda"
        case .purchase:
            return "Compra"
        }
    }
}

struct ConversationalSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ConversationalSearchViewModel()

    // Search mode
    @State private var searchMode: SearchMode = .search

    // Message input
    @State private var messageText: String = ""
    @FocusState private var isMessageFocused: Bool

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
                            if $viewModel.messages.isEmpty {
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
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }

                                // Typing indicator
                                if viewModel.isTyping {
                                    TypingIndicator()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .onChange(of: $viewModel.messages.count) { _ in
                        if let lastMessage = $viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
//        .navigationTitle("Llegó IA")
//        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Back button con animación de gradiente al regresar
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton( action: {
                    dismiss()// Acción para el botón plus (adjuntar archivos, etc.)
                })
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Acción para el botón plus (adjuntar archivos, etc.)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle")
                        Text("Tutorial")
                    }
                }
            }

            ToolbarSpacer(.fixed, placement: .navigationBarTrailing)
            // Mode selector - menu nativo
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Modo", selection: $searchMode) {
                        ForEach(SearchMode.allCases, id: \.self) { mode in
                            if mode == .purchase {
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(mode.title)
                                }
                                .tag(mode)
                            } else {
                                Text(mode.title).tag(mode)
                            }
                        }
                    }
                } label: {
                  
                        Text(searchMode.title)
                    
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
            if $viewModel.messages.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation {
                        viewModel.sendWelcomeMessage(mode: searchMode)
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

        let textToSend = messageText
        messageText = ""

        // Enviar al ViewModel
        viewModel.sendMessage(textToSend)
    }
}

// MARK: - Supporting Components

struct MessageBubble: View {
    let message: ConversationalChatMessage

    var body: some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 8) {
            // Texto del mensaje
            HStack {
                if message.isFromUser {
                    Spacer()
                }

                Text(message.text)
                    .font(.system(size: 16))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        if message.isFromUser {
                            // Burbuja del usuario con color sólido sobre blur
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.llegoPrimary.opacity(0.9))
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(.ultraThinMaterial)
                                )
                        } else {
                            // Burbuja del asistente con backdrop blur
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.regularMaterial)
                        }
                    }
                    .foregroundColor(message.isFromUser ? .white : .primary)

                if !message.isFromUser {
                    Spacer()
                }
            }
            
            // Mostrar entidades según el tipo de respuesta
            if !message.isFromUser, let responseType = message.responseType {

                // LOGS DE DEBUG
                let _ = print("🔍 [DEBUG] Response Type: \(responseType)")
                let _ = print("🔍 [DEBUG] Products count: \(message.productEntities?.count ?? 0)")
                let _ = print("🔍 [DEBUG] Branches count: \(message.branchEntities?.count ?? 0)")
                let _ = print("🔍 [DEBUG] Payments count: \(message.paymentEntities?.count ?? 0)")

                // PRODUCTOS
                if responseType.lowercased() == "products",
                   let productEntities = message.productEntities,
                   !productEntities.isEmpty {

                    let _ = print("✅ [RENDER] Renderizando \(productEntities.count) productos")

                    VStack(spacing: 10) {
                        ForEach(productEntities) { product in
                            AIProductCard(product: product)
                        }
                    }
                    .padding(.top, 4)
                }

                // TIENDAS / SUCURSALES
                else if responseType.lowercased() == "businesses" || responseType.lowercased() == "branches",
                        let branchEntities = message.branchEntities,
                        !branchEntities.isEmpty {

                    let _ = print("✅ [RENDER] Renderizando \(branchEntities.count) tiendas")

                    VStack(spacing: 10) {
                        ForEach(branchEntities) { branch in
                            NavigationLink(destination: StoreDetailView(store: branch.toStore())) {
                                AIStoreCard(branch: branch)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                }

                // MÉTODOS DE PAGO
                else if responseType.lowercased() == "payment_method" || responseType.lowercased() == "payment_methods",
                        let paymentEntities = message.paymentEntities,
                        !paymentEntities.isEmpty {

                    let _ = print("✅ [RENDER] Renderizando \(paymentEntities.count) métodos de pago")

                    VStack(spacing: 10) {
                        ForEach(paymentEntities) { payment in
                            AIPaymentMethodCard(paymentMethod: payment)
                        }
                    }
                    .padding(.top, 4)
                }

                // MENSAJE (sin entidades - solo texto)
                else {
                    let _ = print("ℹ️ [RENDER] Tipo: \(responseType) - Solo texto, sin entidades")
                }
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
