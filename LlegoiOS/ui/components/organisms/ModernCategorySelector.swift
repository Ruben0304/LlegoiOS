import SwiftUI

struct ModernCategorySelector: View {
    let currentIndex: Int
    let totalCount: Int
    let categoryName: String
    let categoryDescription: String
    let slideOffset: CGFloat
    let canGoPrevious: Bool
    let canGoNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Nombre de la categoría actual con animación
            Text(categoryName)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .id(currentIndex)
                .transition(.asymmetric(
                    insertion: .move(edge: slideOffset < 0 ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: slideOffset < 0 ? .leading : .trailing).combined(with: .opacity)
                ))

            // Descripción de la categoría
            Text(categoryDescription)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .id("desc-\(currentIndex)")
                .transition(.opacity)

            // Controles de navegación modernos
            navigationControls
        }
        .padding(.top, 20)
    }

    private var navigationControls: some View {
        HStack(spacing: 40) {
            // Botón anterior
            previousButton

            // Indicadores de página (dots)
            pageIndicators

            // Botón siguiente
            nextButton
        }
        .padding(.top, 8)
    }

    private var previousButton: some View {
        Button(action: onPrevious) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(canGoPrevious ? 0.2 : 0.1))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )

                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .disabled(!canGoPrevious)
        .scaleEffect(canGoPrevious ? 1 : 0.9)
        .opacity(canGoPrevious ? 1 : 0.5)
    }

    private var pageIndicators: some View {
        HStack(spacing: 12) {
            ForEach(0..<totalCount, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(
                        width: index == currentIndex ? 10 : 8,
                        height: index == currentIndex ? 10 : 8
                    )
                    .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var nextButton: some View {
        Button(action: onNext) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(canGoNext ? 0.2 : 0.1))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )

                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .disabled(!canGoNext)
        .scaleEffect(canGoNext ? 1 : 0.9)
        .opacity(canGoNext ? 1 : 0.5)
    }
}
