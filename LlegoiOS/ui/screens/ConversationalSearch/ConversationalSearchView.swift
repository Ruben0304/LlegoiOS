//
//  ConversationalSearchView.swift
//  LlegoiOS
//
//  Búsqueda conversacional - Escribe tu consulta en lenguaje natural
//

import SwiftUI

struct ConversationalSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var queryText: String = ""
    @State private var isTextFieldFocused: Bool = false
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        ZStack {
            // Fondo gradiente elegante
            WelcomeGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Contenedor principal
                VStack(spacing: 24) {
                    // Título
                    Text("¿Qué necesitas hoy?")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Campo de texto elegante
                    HStack(spacing: 16) {
                        // Input field
                        TextField("Escribe tu consulta aquí...", text: $queryText, axis: .vertical)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.primary)
                            .lineLimit(1...5)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
                            )
                            .focused($textFieldFocused)
                            .onChange(of: textFieldFocused) { newValue in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isTextFieldFocused = newValue
                                }
                            }

                        // Botón de enviar
                        Button(action: sendQuery) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundColor(queryText.isEmpty ? .gray.opacity(0.3) : .llegoPrimary)
                                .scaleEffect(queryText.isEmpty ? 1.0 : 1.05)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: queryText.isEmpty)
                        }
                        .disabled(queryText.isEmpty)
                    }
                    .padding(.horizontal, 32)

                    // Sugerencias
                    if !isTextFieldFocused {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ejemplos:")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.7))

                            VStack(spacing: 10) {
                                SuggestionButton(text: "Quiero 2 kg de arroz", queryText: $queryText)
                                SuggestionButton(text: "Necesito vegetales frescos para hoy", queryText: $queryText)
                                SuggestionButton(text: "Busco una bodega cerca de mi casa", queryText: $queryText)
                            }
                        }
                        .padding(.horizontal, 32)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Spacer()
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
        .onAppear {
            // Auto-focus después de un pequeño delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                textFieldFocused = true
            }
        }
    }

    // MARK: - Actions
    private func sendQuery() {
        guard !queryText.isEmpty else { return }

        print("📤 Consulta enviada: \(queryText)")

        // Aquí iría la lógica de procesamiento de la consulta
        // Por ejemplo: enviar al backend, analizar con IA, etc.

        // Animación de feedback
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            queryText = ""
        }

        // TODO: Navegar a resultados o mostrar respuesta
    }
}

// MARK: - Supporting Views
struct SuggestionButton: View {
    let text: String
    @Binding var queryText: String

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                queryText = text
            }
        }) {
            HStack {
                Text(text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.primary.opacity(0.7))
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "arrow.up.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview("Conversational Search") {
    NavigationStack {
        ConversationalSearchView()
    }
}
