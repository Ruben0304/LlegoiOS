//
//  LoginWatchView.swift
//  LeegoWatchOS Watch App
//
//  Created by Claude on 10/27/25.
//

import SwiftUI

struct LoginWatchView: View {
    @Binding var isLoggedIn: Bool
    @State private var isLoading = false
    @State private var showSuccess = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: geometry.size.height * 0.04) {
                    // Logo y título
                    VStack(spacing: geometry.size.height * 0.02) {
                        // Logo circular con gradiente
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.llegoPrimary,
                                            Color.llegoButton
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35)
                                .shadow(color: Color.llegoPrimary.opacity(0.3), radius: 8)

                            Image(systemName: "bicycle")
                                .font(.system(size: geometry.size.width * 0.18, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        // Título
                        Text("Llegó")
                            .font(.system(size: geometry.size.width * 0.14, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.7)

                        Text("Delivery rápido")
                            .font(.system(size: geometry.size.width * 0.07, weight: .medium))
                            .foregroundColor(.secondary)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.top, geometry.size.height * 0.02)

                    // Botones de autenticación
                    VStack(spacing: geometry.size.height * 0.015) {
                        // Botón de Face ID / Touch ID
                        Button(action: {
                            authenticateWithBiometrics()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "faceid")
                                    .font(.system(size: geometry.size.width * 0.09, weight: .semibold))

                                Text("Face ID")
                                    .font(.system(size: geometry.size.width * 0.08, weight: .semibold))
                                    .minimumScaleFactor(0.7)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, geometry.size.height * 0.055)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.llegoPrimary,
                                                Color.llegoButton
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)

                        // Botón de continuar en iPhone
                        Button(action: {
                            // Acción para continuar en iPhone
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "iphone")
                                    .font(.system(size: geometry.size.width * 0.07, weight: .medium))

                                Text("iPhone")
                                    .font(.system(size: geometry.size.width * 0.07, weight: .medium))
                                    .minimumScaleFactor(0.7)
                            }
                            .foregroundColor(.llegoPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, geometry.size.height * 0.045)
                            .background(
                                Capsule()
                                    .strokeBorder(Color.llegoPrimary, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 4)

                    // Indicador de carga
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .llegoPrimary))
                            .scaleEffect(0.7)
                    }

                    // Mensaje de éxito
                    if showSuccess {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: geometry.size.width * 0.08))
                                .foregroundColor(.llegoAccent)

                            Text("Autenticado")
                                .font(.system(size: geometry.size.width * 0.07, weight: .medium))
                                .foregroundColor(.llegoAccent)
                                .minimumScaleFactor(0.7)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 10)
                .frame(minHeight: geometry.size.height)
            }
        }
    }

    private func authenticateWithBiometrics() {
        isLoading = true

        // Simular autenticación
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            withAnimation(.spring()) {
                showSuccess = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    isLoggedIn = true
                }
            }
        }
    }
}

#Preview {
    LoginWatchView(isLoggedIn: .constant(false))
}
