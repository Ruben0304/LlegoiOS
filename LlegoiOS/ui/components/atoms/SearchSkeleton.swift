import SwiftUI

struct SearchSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 16) {
                    // Imagen skeleton (cuadrada con esquinas redondeadas)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .shimmer(isAnimating: isAnimating)

                    // Contenido skeleton
                    VStack(alignment: .leading, spacing: 8) {
                        // Título
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 16)
                            .frame(maxWidth: .infinity)
                            .shimmer(isAnimating: isAnimating)

                        // Subtítulo
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 14)
                            .frame(maxWidth: 180)
                            .shimmer(isAnimating: isAnimating)

                        // Precio
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 18)
                            .frame(maxWidth: 100)
                            .shimmer(isAnimating: isAnimating)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Extensión para efecto shimmer
extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self.overlay(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0),
                    Color.white.opacity(0.4),
                    Color.white.opacity(0)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .offset(x: isAnimating ? 300 : -300)
            .animation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
        )
        .mask(self)
    }
}

#Preview {
    ZStack {
        Color.llegoBackground.ignoresSafeArea()
        SearchSkeleton()
    }
}
