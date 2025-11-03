import SwiftUI

struct CategorySelectionView: View {
    @State private var selectedCategory: CategoryType = .restaurant
    @State private var animationScale: CGFloat = 1.0
    @State private var floatOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    let showContinueButton: Bool
    let onContinue: (() -> Void)?

    enum CategoryType {
        case restaurant
        case supermarket
    }

    init(showContinueButton: Bool = false, onContinue: (() -> Void)? = nil) {
        self.showContinueButton = showContinueButton
        self.onContinue = onContinue
    }

    var body: some View {
        ZStack {
            // Background gradient verde/gris (igual que el inicial de HomeView)
            SharedGradientBackground(expansionProgress: 0.0)

            VStack(spacing: 0) {
                // Header con safe area top
                VStack {
                    Text("¿Qué necesitas hoy?")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.llegoPrimary)
                        .padding(.top, 20)

                    Text("Elige tu categoría preferida")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.llegoPrimary.opacity(0.7))
                        .padding(.top, 8)
                }
                .padding(.top) // Respeta la safe area superior

                Spacer()

                // Container limpio con fondo de color y imagen más grande
                ZStack {
                    // Fondo de color suave sin bordes
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    selectedCategory == .restaurant ?
                                        Color.orange.opacity(0.15) :
                                        Color.green.opacity(0.15),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .scaleEffect(pulseScale)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: pulseScale)

                    // Imagen principal más grande y limpia
                    Image(selectedCategory == .restaurant ? "comida" : "tienda")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 350, height: 250)
                        .scaleEffect(animationScale)
                        .offset(y: floatOffset)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animationScale)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: floatOffset)
                }
                .padding(.vertical, 20)

                Spacer()

                // Navigation Buttons con espacio para safe area
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        // Restaurant Button
                        CategoryButton(
                            title: "Restaurante",
                            icon: "fork.knife",
                            isSelected: selectedCategory == .restaurant,
                            color: .orange
                        ) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                selectedCategory = .restaurant
                                triggerAnimation()
                            }
                        }

                        // Supermarket Button
                        CategoryButton(
                            title: "Supermercado",
                            icon: "cart",
                            isSelected: selectedCategory == .supermarket,
                            color: .green
                        ) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                selectedCategory = .supermarket
                                triggerAnimation()
                            }
                        }
                    }
                    .padding(.horizontal, 32)

                    // Continue Button (only show if enabled)
                    if showContinueButton {
                        Button(action: {
                            onContinue?()
                        }) {
                            HStack {
                                Text("Continuar")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))

                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .cornerRadius(28)
                        }
                        .tint(Color.llegoButton)
                        .buttonStyle(.glassProminent)
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                    }
                }
                .padding(.bottom) // Respeta la safe area inferior
                .padding(.bottom, 20) // Espacio adicional
            }
        }
        .onAppear {
            startContinuousAnimation()
        }
    }

    private func triggerAnimation() {
        // Animación simple y elegante al cambiar categoría
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            animationScale = 0.9
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animationScale = 1.0
            }
        }
    }

    private func startContinuousAnimation() {
        // Animación flotante suave y continua
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            floatOffset = -8
        }

        // Pulso muy sutil para el fondo
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.03
        }
    }
}

struct CategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    isSelected ? color.opacity(0.2) : Color.clear,
                                    isSelected ? color.opacity(0.1) : Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            isSelected ? color : Color.gray.opacity(0.3),
                                            isSelected ? color.opacity(0.6) : Color.gray.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isSelected ? 3 : 1
                                )
                        )

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(isSelected ? color : Color.gray)
                }

                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? color : Color.gray)
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            isSelected ? Color.white : Color.white.opacity(0.5),
                            isSelected ? Color.white.opacity(0.95) : Color.white.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: isSelected ? color.opacity(0.2) : Color.black.opacity(0.05),
                    radius: isSelected ? 12 : 6,
                    x: 0,
                    y: isSelected ? 6 : 3
                )
        )
    }
}

#Preview {
    CategorySelectionView()
}