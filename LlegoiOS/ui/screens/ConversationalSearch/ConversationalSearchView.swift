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
    @ObservedObject private var gradientManager = GradientStateManager.shared

    // Índice de categoría desde HomeView para mantener el mismo fondo
    let categoryIndex: Int

    // Search mode
    @State private var searchMode: SearchMode = .search
    @State private var showLlegoPlus: Bool = false

    // Message input
    @State private var messageText: String = ""
    @FocusState private var isMessageFocused: Bool

    var body: some View {
        ZStack {
            // Background exactamente igual que HomeView
            HomeGradientBackground()
                .ignoresSafeArea()
            

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

            NavigationLink(destination: LlegoPlusBenefitsView(), isActive: $showLlegoPlus) {
                EmptyView()
            }
            .hidden()
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
                    Button(action: {
                        searchMode = .search
                    }) {
                        HStack(spacing: 8) {
                            if searchMode == .search {
                                Image(systemName: "checkmark")
                            }
                            Text(SearchMode.search.title)
                        }
                    }

                    Button(action: {
                        searchMode = .purchase
                        showLlegoPlus = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(SearchMode.purchase.title)
                        }
                    }
                } label: {
                    Text(searchMode.title)
                        .font(.system(size: 15, weight: .medium))
                }
            }
            

            // Input en el toolbar inferior
            ToolbarItem(placement: .bottomBar) {
                messageInputToolbar
            }
            
            ToolbarSpacer(.fixed, placement: .bottomBar)
            
            // Botón de enviar en el toolbar inferior (siempre visible)
            ToolbarItem(placement: .bottomBar) {
                Button(action: handleSendAction) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.llegoPrimary)
                        )
                }
            }
        }
        .onAppear {
            // Establecer el índice de categoría para mantener el mismo fondo de HomeView
            gradientManager.setCategoryIndex(categoryIndex)
            
            // Mensaje inicial del asistente
            if $viewModel.messages.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation {
                        viewModel.sendWelcomeMessage(mode: searchMode)
                    }
                }
            }
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
        if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Mostrar feedback de error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            // TODO: Mostrar alerta o toast con mensaje "Escribe un mensaje"
            print("⚠️ Error: Escribe un mensaje")
        } else {
            sendMessage()
        }
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
import SwiftUI

struct LlegoPlusBenefitsView: View {
    @State private var revealBenefits = false
    @State private var ctaPulse = false

    private let comparisonRows: [LlegoPlusComparisonRow] = [
        LlegoPlusComparisonRow(
            title: "IA para recomendar",
            freeValue: "Básica",
            plusValue: "Avanzada"
        ),
        LlegoPlusComparisonRow(
            title: "Modo compra con IA",
            freeValue: "Limitado",
            plusValue: "Completo"
        ),
        LlegoPlusComparisonRow(
            title: "Mensajería",
            freeValue: "Tarifa estándar",
            plusValue: "Gratis en rango local + rebaja"
        ),
        LlegoPlusComparisonRow(
            title: "Cashback en compras",
            freeValue: "No",
            plusValue: "Sí"
        )
    ]

    private let benefits: [LlegoPlusBenefit] = [
        LlegoPlusBenefit(
            systemImage: "sparkles",
            title: "IA más inteligente",
            description: "Resultados precisos y recomendaciones personalizadas."
        ),
        LlegoPlusBenefit(
            systemImage: "cart.fill",
            title: "Compra asistida por IA",
            description: "Cierra pedidos en menos pasos y con menos fricción."
        ),
        LlegoPlusBenefit(
            systemImage: "paperplane.fill",
            title: "Mensajería con ahorro",
            description: "Gratis en rango local y rebaja en el resto."
        ),
        LlegoPlusBenefit(
            systemImage: "dollarsign.circle.fill",
            title: "Cashback en cada compra",
            description: "Acumula saldo y úsalo en tus próximos pedidos."
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                backgroundHighlights

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                            .opacity(revealBenefits ? 1 : 0)
                            .offset(y: revealBenefits ? 0 : 14)
                            .animation(.easeOut(duration: 0.45), value: revealBenefits)

                        pricingSection
                            .opacity(revealBenefits ? 1 : 0)
                            .offset(y: revealBenefits ? 0 : 18)
                            .animation(.easeOut(duration: 0.5).delay(0.05), value: revealBenefits)

                        comparisonCard
                            .opacity(revealBenefits ? 1 : 0)
                            .offset(y: revealBenefits ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: revealBenefits)

                        benefitsCard
                            .opacity(revealBenefits ? 1 : 0)
                            .offset(y: revealBenefits ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.15), value: revealBenefits)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton()
                }
            }
            .onAppear {
                revealBenefits = true
                withAnimation(
                    Animation.easeInOut(duration: 1.8)
                        .repeatForever(autoreverses: true)
                ) {
                    ctaPulse = true
                }
            }
        }
    }

    private var backgroundHighlights: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.llegoPrimary.opacity(0.08),
                            Color.llegoPrimary.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 260, height: 260)
                .offset(x: -140, y: -180)
                .opacity(0.25)

            RoundedRectangle(cornerRadius: 80)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.llegoPrimary.opacity(0.06),
                            Color.llegoPrimary.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 240, height: 160)
                .rotationEffect(.degrees(18))
                .offset(x: 150, y: -120)
        }
        .allowsHitTesting(false)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text("LLEGÓ+")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.llegoPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.llegoPrimary.opacity(0.08))
                        )

                    Text("Obtener Llegó+")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(.llegoPrimary)
                }
            }

            Text("Compra más rápido, ahorra en mensajería y recibe cashback en cada pedido.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.onBackgroundColor.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("USD 10")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)

                Text("/ mes")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.onBackgroundColor.opacity(0.6))
            }

            Text("El plan se paga solo con el ahorro en mensajería y cashback.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.onBackgroundColor.opacity(0.7))

            Button(action: {}) {
                HStack(spacing: 10) {
                    Text("Activar Llegó+")
                        .font(.system(size: 16, weight: .semibold))
                    Text("USD 10/mes")
                        .font(.system(size: 14, weight: .medium))
                        .opacity(0.9)
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.llegoPrimary)
                        .shadow(
                            color: Color.llegoPrimary.opacity(ctaPulse ? 0.28 : 0.18),
                            radius: ctaPulse ? 18 : 10,
                            x: 0,
                            y: 8
                        )
                )
            }

            Text("Cancela cuando quieras • Sin compromisos")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.onBackgroundColor.opacity(0.6))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }

    private var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparación rápida")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.onBackgroundColor)

            HStack {
                Text("Beneficio")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.onBackgroundColor.opacity(0.55))
                Spacer()
                Text("Gratis")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.onBackgroundColor.opacity(0.55))
                Spacer()
                Text("Llegó+")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.llegoPrimary)
            }

            VStack(spacing: 14) {
                ForEach(comparisonRows) { row in
                    LlegoPlusComparisonRowView(row: row)
                    if row.id != comparisonRows.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }

    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Beneficios incluidos")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.onBackgroundColor)

            VStack(spacing: 14) {
                ForEach(Array(benefits.enumerated()), id: \.element.id) { index, benefit in
                    LlegoPlusBenefitRow(benefit: benefit)
                        .opacity(revealBenefits ? 1 : 0)
                        .offset(y: revealBenefits ? 0 : 8)
                        .animation(
                            .easeOut(duration: 0.35).delay(0.05 * Double(index)),
                            value: revealBenefits
                        )

                    if benefit.id != benefits.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }
}

struct LlegoPlusBenefit: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let description: String
}

struct LlegoPlusBenefitRow: View {
    let benefit: LlegoPlusBenefit

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.llegoPrimary.opacity(0.12))
                    .frame(width: 34, height: 34)

                Image(systemName: benefit.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.llegoPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(benefit.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.onBackgroundColor)

                Text(benefit.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.onBackgroundColor.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct LlegoPlusComparisonRow: Identifiable {
    let id = UUID()
    let title: String
    let freeValue: String
    let plusValue: String
}

struct LlegoPlusComparisonRowView: View {
    let row: LlegoPlusComparisonRow

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(row.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.onBackgroundColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.freeValue)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.onBackgroundColor.opacity(0.65))
                .frame(width: 90, alignment: .leading)

            Text(row.plusValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.llegoPrimary)
                .frame(width: 120, alignment: .leading)
        }
    }
}



// Preview
#Preview {
    LlegoPlusBenefitsView()
}

// MARK: - Supporting Components

struct MessageBubble: View {
    let message: ConversationalChatMessage

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

                    Text(message.text)
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
        HStack(alignment: .bottom, spacing: 8) {
            // Avatar del sistema
            Image("icon")
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            // Indicador de escritura
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
                    .fill(.regularMaterial)
            )
            
            Spacer()
        }
        .onAppear {
            animationPhase = 1
        }
    }
}

// MARK: - Preview
#Preview("Conversational Search") {
    NavigationStack {
        ConversationalSearchView(categoryIndex: 0)
    }
}
