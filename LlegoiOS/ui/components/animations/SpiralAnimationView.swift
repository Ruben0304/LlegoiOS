import SwiftUI

/// Vista de animación espiral con gradientes radiales concéntricos
/// Usado en: HomeView para efecto visual de presión larga
struct SpiralAnimationView: View {
    let progress: CGFloat

    var body: some View {
        ZStack {
            // Capa externa - Wave radial suave
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.15 * progress),
                            Color.white.opacity(0.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 200 * progress
                    )
                )
                .frame(width: 400 * progress, height: 400 * progress)
                .blur(radius: 15)
                .opacity(progress)

            // Capa intermedia - Gradiente principal
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.6 * progress),
                            Color.white.opacity(0.4 * progress),
                            Color.white.opacity(0.2 * progress),
                            Color.white.opacity(0.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 120 * progress
                    )
                )
                .frame(width: 240 * progress, height: 240 * progress)
                .blur(radius: 8)

            // Capa interna - Centro brillante
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.9 * progress),
                            Color.white.opacity(0.6 * progress),
                            Color.white.opacity(0.2 * progress),
                            Color.white.opacity(0.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 60 * progress
                    )
                )
                .frame(width: 120 * progress, height: 120 * progress)
                .blur(radius: 4)

            // Centro core - Punto focal
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(1.0 * progress),
                            Color.white.opacity(0.7 * progress),
                            Color.white.opacity(0.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 30 * progress
                    )
                )
                .frame(width: 60 * progress, height: 60 * progress)

            // Anillo de borde sutil para definición
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5 * progress),
                            Color.white.opacity(0.2 * progress)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 100 * progress, height: 100 * progress)
                .blur(radius: 1)
        }
        .scaleEffect(0.5 + 0.5 * progress) // Crece suavemente desde 50% a 100%
        .opacity(min(1.0, progress * 1.2)) // Fade in rápido
        .animation(.easeOut(duration: 0.3), value: progress)
    }
}
