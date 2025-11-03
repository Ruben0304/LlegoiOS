//
//  ConversationalSearchView.swift
//  LlegoiOS
//
//  Pantalla de búsqueda conversacional premium
//  Inspirada en Gleb Kuznetsov y Apple Design Awards
//

import SwiftUI

enum ConversationalSearchState {
    case idle
    case streaming
    case waitingInput
    case searching
    case completed
}

struct ConversationalSearchView: View {
    @Environment(\.dismiss) private var dismiss

    // Search state
    @State private var state: ConversationalSearchState = .idle
    @State private var productValue: String? = nil
    @State private var storeValue: String? = nil
    @State private var productExpanded: Bool = false
    @State private var storeExpanded: Bool = false

    // Streaming animation
    @State private var showAvatar: Bool = false
    @State private var showBubble: Bool = false
    @State private var startStreaming: Bool = false

    var body: some View {
        ZStack {
            // Mismo fondo que WelcomeView
            WelcomeGradientBackground()
                .ignoresSafeArea()

            // Contenido principal centrado
            VStack {
                Spacer()
                    .frame(height: 100) // Offset hacia arriba desde el centro

                // Avatar y burbuja de conversación
                chatBubbleView

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Overlay para search expandido (si es necesario)
            if productExpanded || storeExpanded {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            productExpanded = false
                            storeExpanded = false
                        }
                    }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
        .onAppear {
            startEntranceAnimation()
        }
    }

    // MARK: - Chat Bubble View
    private var chatBubbleView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Avatar circular con sombra ligera
            if showAvatar {
                AsyncImage(url: URL(string: "https://i.pravatar.cc/100?img=3")) { phase in
                    ZStack {
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                        case .failure:
                            Circle()
                                .fill(Color.llegoAccent.opacity(0.45))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white.opacity(0.95))
                                )
                        default:
                            Circle()
                                .fill(Color.llegoAccent.opacity(0.3))
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.85)))
                                )
                        }
                    }
                    .frame(width: 48, height: 48)
                }
                .padding(.leading, 32)
                .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
                .transition(
                    .scale(scale: 0.85)
                    .combined(with: .opacity)
                )
            }

            // Texto conversacional (sin fondo)
            if showBubble {
                VStack(alignment: .leading, spacing: 16) {
                    // Streaming text con pills integrados
                    if startStreaming {
                        StreamingTextView(
                            segments: [
                                .text("Quiero ordenar"),
                                .component(id: "product_pill", AnyView(
                                    InlineSelectField(
                                        type: .products,
                                        selectedValue: $productValue,
                                        isExpanded: $productExpanded,
                                        onSearch: { query in
                                            print("🔍 Buscando productos: \(query)")
                                        }
                                    )
                                )),
                                .text("del vendedor"),
                                .component(id: "store_pill", AnyView(
                                    InlineSelectField(
                                        type: .stores,
                                        selectedValue: $storeValue,
                                        isExpanded: $storeExpanded,
                                        onSearch: { query in
                                            print("🔍 Buscando vendedores: \(query)")
                                        }
                                    )
                                ))
                            ],
                            font: .system(size: 28, weight: .medium),
                            color: Color.primary.opacity(0.75),
                            wordDelay: 0.2,
                            onComplete: {
                                state = .waitingInput
                            }
                        )
                    }
                }
                .padding(.horizontal, 32)
                .transition(
                    .scale(scale: 0.98)
                    .combined(with: .opacity)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Animations
    private func startEntranceAnimation() {
        // Avatar aparece primero con animación más suave
        withAnimation(.spring(response: 0.8, dampingFraction: 0.85).delay(0.4)) {
            showAvatar = true
        }

        // Burbuja aparece después con animación más fluida
        withAnimation(.spring(response: 0.9, dampingFraction: 0.88).delay(0.7)) {
            showBubble = true
        }

        // Streaming empieza un poco después con más delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            startStreaming = true
            state = .streaming
        }
    }
}

// MARK: - Preview
#Preview("Conversational Search") {
    NavigationStack {
        ConversationalSearchView()
    }
}

#Preview("With Selected Values") {
    struct PreviewWithValues: View {
        @State private var productValue: String? = "Frutas frescas"
        @State private var storeValue: String? = "La Bodeguita"

        var body: some View {
            NavigationStack {
                ConversationalSearchView()
            }
        }
    }

    return PreviewWithValues()
}
