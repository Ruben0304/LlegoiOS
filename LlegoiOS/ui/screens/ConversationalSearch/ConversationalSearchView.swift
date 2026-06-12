//
//  ConversationalSearchView.swift
//  LlegoiOS
//
//  Pantalla de búsqueda conversacional minimalista
//  Input estilo iMessage + selector de modo
//

import Combine
import MapKit
import SwiftUI

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
    @ObservedObject private var gradientManager = GradientStateManager.shared
    @Environment(\.colorScheme) private var colorScheme

    // Índice de categoría desde HomeView para mantener el mismo fondo
    let categoryIndex: Int

    // Search mode
    @State private var searchMode: SearchMode = .search

    // Message input
    @State private var messageText: String = ""
    @State private var selectedProductId: String?
    @FocusState private var isMessageFocused: Bool

    var body: some View {
        ZStack {
            // Fondo gradiente sutil que se sincroniza con ProductFeedView
            feedGradientBackground
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: gradientManager.currentCategoryIndex)

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
                                    MessageBubble(
                                        message: message,
                                        selectedProductId: $selectedProductId
                                    )
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
                    .onChange(of: $viewModel.messages.count) { _, _ in
                        if let lastMessage = $viewModel.messages.last {
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
                BackButton(action: {
                    dismiss()  // Acción para el botón plus (adjuntar archivos, etc.)
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

            // Input en el toolbar inferior
            ToolbarItem(placement: .bottomBar) {
                messageInputToolbar
            }

            // Botón de enviar en el toolbar inferior - estilo estándar
            ToolbarItem(placement: .bottomBar) {
                Button(action: handleSendAction) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(gradientManager.currentAccentColor)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            print("\n╔═══════════════════════════════════════════════════╗")
            print("║  [VIEW] onAppear - ConversationalSearchView       ║")
            print("╚═══════════════════════════════════════════════════╝")
            print("🎨 [VIEW] categoryIndex: \(categoryIndex)")
            print("📊 [VIEW] Mensajes actuales: \(viewModel.messages.count)")
            print("🔍 [VIEW] Search Mode: \(searchMode.title)")

            // Establecer el índice de categoría para mantener el mismo fondo de HomeView
            gradientManager.setCategoryIndex(categoryIndex)
            print("✅ [VIEW] Gradient actualizado\n")

            // Mensaje inicial del asistente
            if $viewModel.messages.isEmpty {
                print("📭 [VIEW] Lista de mensajes vacía - enviando mensaje de bienvenida en 0.4s\n")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation {
                        viewModel.sendWelcomeMessage(mode: searchMode)
                    }
                }
            } else {
                print("📬 [VIEW] Ya hay mensajes - omitiendo mensaje de bienvenida\n")
            }
        }
        .fullScreenCover(item: $selectedProductId) { productId in
            ProductDetailView(productId: productId)
        }
    }

    // MARK: - Feed Gradient Background (más notable para conversational search)
    private var feedGradientBackground: some View {
        let palette = gradientManager.getCurrentGradientPalette()

        return ZStack {
            // Base color - más visible
            palette.veryLight
                .opacity(0.6)

            // Gradiente más notable
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.light.opacity(0.3), location: 0.0),
                    .init(color: palette.veryLight.opacity(0.5), location: 0.4),
                    .init(
                        color: Color.white.opacity(colorScheme == .dark ? 0.1 : 0.9), location: 1.0),
                ]),
                center: UnitPoint(x: 0.85, y: 0.15),
                startRadius: 10,
                endRadius: 600
            )
        }
    }

    // MARK: - Message Input Toolbar
    private var messageInputToolbar: some View {
        TextField("Mensaje", text: $messageText)
            .autocorrectionDisabled()
            .focused($isMessageFocused)
            .submitLabel(.send)
            .onSubmit {
                handleSendAction()
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Send Action Handler
    private func handleSendAction() {
        print("\n╔═══════════════════════════════════════════════════╗")
        print("║  [VIEW] handleSendAction                          ║")
        print("╚═══════════════════════════════════════════════════╝")
        print("📝 [VIEW] Texto del mensaje: \"\(messageText)\"")

        if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("⚠️ [VIEW] Mensaje vacío - mostrando feedback de error")

            // Mostrar feedback de error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

            print("❌ [VIEW] Error: Escribe un mensaje\n")
        } else {
            print("✅ [VIEW] Mensaje válido - llamando sendMessage()\n")
            sendMessage()
        }
    }

    // MARK: - Actions
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ [VIEW] sendMessage() llamado con mensaje vacío - abortando\n")
            return
        }

        let textToSend = messageText
        messageText = ""

        print("╔═══════════════════════════════════════════════════╗")
        print("║  [VIEW] sendMessage                               ║")
        print("╚═══════════════════════════════════════════════════╝")
        print("📤 [VIEW] Enviando al ViewModel: \"\(textToSend)\"")
        print("🧹 [VIEW] TextField limpiado\n")

        // Enviar al ViewModel
        viewModel.sendMessage(textToSend)
    }

}

// MARK: - Supporting Components

struct MessageBubble: View {
    let message: ConversationalChatMessage
    @Binding var selectedProductId: String?
    @State private var hasLoggedRender = false

    // MARK: - Debug Logging
    private static func logMessageRender(message: ConversationalChatMessage, responseType: String) {
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎨 [UI RENDER] MessageBubble - Mensaje del Asistente")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📋 [UI] Response Type: \"\(responseType)\"")
        print("💬 [UI] Texto: \"\(message.text)\"")
        print("📦 [UI] Products count: \(message.productEntities?.count ?? 0)")
        print("🏪 [UI] Branches count: \(message.branchEntities?.count ?? 0)")
        if let confidence = message.confidence {
            print("🧠 [UI] Confidence: \(confidence)")
        }

        // Log de productos si existen
        if let productEntities = message.productEntities, !productEntities.isEmpty {
            print("\n✅ [UI RENDER] Renderizando \(productEntities.count) productos:")
            for (index, product) in productEntities.enumerated() {
                print("  ├─ Producto \(index + 1): \(product.name) - $\(product.price)")
            }
        }

        // Log de branches si existen
        if let branchEntities = message.branchEntities, !branchEntities.isEmpty {
            print("\n✅ [UI RENDER] Renderizando \(branchEntities.count) tiendas:")
            for (index, branch) in branchEntities.enumerated() {
                print("  ├─ Tienda \(index + 1): \(branch.name) - \(branch.address)")
            }
        }

        // Si no hay entidades
        if (message.productEntities?.isEmpty ?? true) && (message.branchEntities?.isEmpty ?? true) {
            print("\nℹ️ [UI RENDER] Tipo: \(responseType) - Solo texto, sin entidades a renderizar")
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }

    var body: some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 8) {
            // Mensaje con avatar
            HStack(alignment: .bottom, spacing: 8) {
                // Avatar del sistema (a la izquierda)
                if !message.isFromUser {
                    Image("icon")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                }

                // Burbuja de texto
                HStack {
                    if message.isFromUser {
                        Spacer()
                    }

                    StreamingMarkdownText(
                        text: message.text,
                        isFromUser: message.isFromUser
                    )
                    .font(.system(size: 16))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        // Burbuja con backdrop blur para todos (usuario y sistema)
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.regularMaterial)
                    }
                    .foregroundColor(.primary)

                    if !message.isFromUser {
                        Spacer()
                    }
                }

                // Avatar del usuario (a la derecha)
                if message.isFromUser {
                    AsyncImage(url: URL(string: "https://i.pravatar.cc/150?img=12")) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        case .failure:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }

            // Mostrar entidades según el tipo de respuesta
            if !message.isFromUser, let responseType = message.responseType {
                let responseTypeLower = responseType.lowercased()

                // PRODUCTOS
                if responseTypeLower == "search_products",
                    let productEntities = message.productEntities,
                    !productEntities.isEmpty
                {

                    VStack(spacing: 10) {
                        ForEach(productEntities) { product in
                            AIProductCard(product: product)
                                .onTapGesture {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedProductId = product.id
                                }
                        }
                    }
                    .padding(.top, 4)
                }

                // TIENDAS / SUCURSALES
                else if responseTypeLower == "search_branches",
                    let branchEntities = message.branchEntities,
                    !branchEntities.isEmpty
                {

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

                if let confidence = message.confidence {
                    ConfidenceBadge(confidence: confidence)
                        .padding(.top, 6)
                }
            }

        }
        .onAppear {
            guard !hasLoggedRender else { return }
            guard !message.isFromUser, let responseType = message.responseType else { return }
            hasLoggedRender = true
            Self.logMessageRender(message: message, responseType: responseType)
        }
    }
}

struct ConfidenceBadge: View {
    let confidence: Double

    private var percentageText: String {
        "\(Int(confidence * 100))%"
    }

    private var badgeColor: Color {
        if confidence < 0.5 {
            return .red
        }
        if confidence < 0.7 {
            return .orange
        }
        return .green
    }

    var body: some View {
        Text("Confianza (\(percentageText))")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(badgeColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(badgeColor.opacity(0.12))
            )
    }
}

struct TypingIndicator: View {
    @State private var shimmerOffset: CGFloat = -1.0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Avatar del sistema
            Image("icon")
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

            // AI Skeleton con gradiente rosa/morado
            VStack(alignment: .leading, spacing: 8) {
                // Línea 1 - larga
                RoundedRectangle(cornerRadius: 8)
                    .fill(aiGradient)
                    .frame(width: 220, height: 12)

                // Línea 2 - media
                RoundedRectangle(cornerRadius: 8)
                    .fill(aiGradient)
                    .frame(width: 180, height: 12)

                // Línea 3 - corta
                RoundedRectangle(cornerRadius: 8)
                    .fill(aiGradient)
                    .frame(width: 140, height: 12)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.regularMaterial)
            )
            .overlay(
                // Shimmer effect
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.6),
                        Color.white.opacity(0.0),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 100)
                .offset(x: shimmerOffset * 300)
            )
            .mask(
                RoundedRectangle(cornerRadius: 18)
            )

            Spacer()
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 2.0
            }
        }
    }

    // Gradiente AI con colores rosa/morado
    private var aiGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.9, green: 0.4, blue: 0.9).opacity(0.3),  // Rosa
                Color(red: 0.6, green: 0.4, blue: 0.9).opacity(0.3),  // Morado
                Color(red: 0.8, green: 0.5, blue: 1.0).opacity(0.3),  // Lila
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - StreamingMarkdownText
struct StreamingMarkdownText: View {
    let text: String
    let isFromUser: Bool

    @State private var displayedText: String = ""
    @State private var currentIndex: Int = 0
    @State private var opacity: Double = 0
    @State private var timer: Timer?

    var body: some View {
        Text(attributedText)
            .opacity(opacity)
            .onAppear {
                startStreaming()
            }
            .onChange(of: text) { _, newValue in
                updateForIncomingText(newValue)
            }
            .onDisappear {
                timer?.invalidate()
            }
    }

    private var attributedText: AttributedString {
        // Intentar parsear como Markdown
        if let attributed = try? AttributedString(
            markdown: displayedText,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace))
        {
            return attributed
        }
        // Si falla, devolver texto plano
        return AttributedString(displayedText)
    }

    private func startStreaming() {
        // Si es del usuario, mostrar todo de inmediato
        if isFromUser {
            displayedText = text
            withAnimation(.easeIn(duration: 0.2)) {
                opacity = 1.0
            }
            return
        }

        // Para mensajes del asistente, el backend ya entrega chunks;
        // reflejamos el texto directamente para no duplicar efecto de streaming.
        displayedText = text
        withAnimation(.easeIn(duration: 0.3)) {
            opacity = 1.0
        }
    }

    private func updateForIncomingText(_ newText: String) {
        timer?.invalidate()

        if isFromUser {
            displayedText = newText
            if opacity < 1.0 {
                withAnimation(.easeIn(duration: 0.2)) {
                    opacity = 1.0
                }
            }
            return
        }

        displayedText = newText
        if opacity < 1.0 {
            withAnimation(.easeIn(duration: 0.2)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - Preview
#Preview("Conversational Search") {
    NavigationStack {
        ConversationalSearchView(categoryIndex: 0)
    }
}
