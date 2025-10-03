import SwiftUI

struct LlegoCartButton: View {
    var icon: String = "cart"
    var badgeCount: Int? = nil
    var triggerBounce: Bool = false
    var onBounceEnd: () -> Void = {}
    var onClick: () -> Void

    @State private var shouldBounce = false
    @State private var showBadge = false
    @State private var pendingBadgeCount: Int? = nil
    @State private var bounceScale: CGFloat = 1.0

    var body: some View {
        Button(action: onClick) {
            ZStack(alignment: .topTrailing) {
                // Botón circular
                Circle()

                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .medium))
                    )

                // Badge contador
                if showBadge, let count = badgeCount, count > 0 {
                    ZStack {
                        Circle()

                            .frame(width: 20, height: 20)

                        Text(count > 99 ? "99+" : "\(count)")
                            .foregroundColor(Color.onSurfaceVariantColor)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .offset(x: 4, y: -4)
                }
            }
            .scaleEffect(bounceScale)
        }
        .glassEffect(.regular.interactive())
        .onAppear {
            // Inicializar badge si hay items
            if let count = badgeCount, count > 0 {
                showBadge = true
            }
        }
        .onChange(of: triggerBounce) { _, newValue in
            if newValue {
                shouldBounce = true
                showBadge = false
                pendingBadgeCount = badgeCount

                // Animación de bounce
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    bounceScale = 1.4
                }

                // Regresar a tamaño normal y mostrar badge
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                        bounceScale = 1.0
                    }

                    // Mostrar badge después del bounce
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        shouldBounce = false
                        if let count = pendingBadgeCount, count > 0 {
                            showBadge = true
                        }
                        pendingBadgeCount = nil
                        onBounceEnd()
                    }
                }
            }
        }
        .onChange(of: badgeCount) { _, newValue in
            // Solo actualizar badge si no hay bounce activo
            if !shouldBounce && pendingBadgeCount == nil {
                showBadge = (newValue ?? 0) > 0
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LlegoCartButton(badgeCount: nil, onClick: {})
            .frame(width: 50, height: 50)

        LlegoCartButton(badgeCount: 3, onClick: {})
            .frame(width: 50, height: 50)

        LlegoCartButton(badgeCount: 15, onClick: {})
            .frame(width: 50, height: 50)

        LlegoCartButton(badgeCount: 99, onClick: {})
            .frame(width: 50, height: 50)

        LlegoCartButton(badgeCount: 120, onClick: {})
            .frame(width: 50, height: 50)
    }
    .padding()
    .background(Color.llegoBackground)
}