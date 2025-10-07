import SwiftUI

struct CategorySelectionCard: View {
    @State private var selectedCategory: CategoryType = .restaurant
    @State private var animationScale: CGFloat = 1.0
    @State private var floatOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    enum CategoryType {
        case restaurant
        case supermarket
    }

    var body: some View {
        ZStack {
            // Verdant container with layered glow
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.llegoButton.opacity(0.95),
                            Color.llegoAccent.opacity(0.85)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                )
                .shadow(color: Color.llegoPrimary.opacity(0.18), radius: 18, x: 0, y: 10)

            RoundedRectangle(cornerRadius: 26)
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.llegoAccent.opacity(0.55),
                            Color.clear
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 260
                    )
                )
                .scaleEffect(pulseScale)
                .blur(radius: 36)
                .opacity(0.75)
                .animation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true), value: pulseScale)
                .allowsHitTesting(false)

            HStack(spacing: 16) {
                // Left side: Image with animation
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    selectedCategory == .restaurant
                                        ? Color.llegoAccent.opacity(0.45)
                                        : Color.llegoButton.opacity(0.45),
                                    Color.llegoPrimary.opacity(0.05)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: pulseScale)

                    // Main image
                    Image(selectedCategory == .restaurant ? "comida" : "tienda")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 80)
                        .scaleEffect(animationScale)
                        .offset(y: floatOffset)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animationScale)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: floatOffset)
                }
                .frame(width: 120)
                .padding(.leading, 8)

                // Right side: Category buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("¿Qué necesitas?")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.llegoPrimary)

                    VStack(spacing: 10) {
                        // Restaurant button
                        CompactCategoryButton(
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

                        // Supermarket button
                        CompactCategoryButton(
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
                }
                .padding(.trailing, 16)
                .padding(.vertical, 12)
            }
        }
        .frame(height: 180)
        .onAppear {
            startContinuousAnimation()
        }
    }

    private func triggerAnimation() {
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
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            floatOffset = -4
        }

        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
    }
}

struct CompactCategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
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
                        .frame(width: 36, height: 36)
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
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? color : Color.gray)
                }

                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? color : Color.gray)

                Spacer()
            }
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        }
        .frame(height: 44)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
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
                    color: isSelected ? color.opacity(0.15) : Color.black.opacity(0.03),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: isSelected ? 4 : 2
                )
        )
    }
}

#Preview {
    CategorySelectionCard()
        .padding()
        .background(Color.llegoBackground)
}
