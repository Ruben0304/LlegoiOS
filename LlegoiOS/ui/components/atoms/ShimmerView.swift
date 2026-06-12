import SwiftUI

// MARK: - Shimmer Effect
/// Animación shimmer/skeleton para estados de carga de imágenes.
/// Implementación sin `GeometryReader`: el barrido se logra animando los
/// `UnitPoint` del gradiente (Animatable), lo que es mucho más barato en GPU
/// y no fuerza medición de layout en cada frame. La animación se detiene al
/// salir de pantalla para no consumir el MainActor mientras se hace scroll.
struct ShimmerView: View {
    var cornerRadius: CGFloat = 0
    @State private var startPoint = UnitPoint(x: -1.0, y: 0.5)
    @State private var endPoint = UnitPoint(x: 0.0, y: 0.5)

    var body: some View {
        ZStack {
            Color(red: 230/255, green: 232/255, blue: 236/255)

            LinearGradient(
                stops: [
                    .init(color: Color.clear, location: 0),
                    .init(color: Color.white.opacity(0.55), location: 0.45),
                    .init(color: Color.white.opacity(0.55), location: 0.55),
                    .init(color: Color.clear, location: 1),
                ],
                startPoint: startPoint,
                endPoint: endPoint
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onAppear { startAnimating() }
        .onDisappear { stopAnimating() }
    }

    private func startAnimating() {
        startPoint = UnitPoint(x: -1.0, y: 0.5)
        endPoint = UnitPoint(x: 0.0, y: 0.5)
        withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
            startPoint = UnitPoint(x: 1.0, y: 0.5)
            endPoint = UnitPoint(x: 2.0, y: 0.5)
        }
    }

    private func stopAnimating() {
        withAnimation(.linear(duration: 0)) {
            startPoint = UnitPoint(x: -1.0, y: 0.5)
            endPoint = UnitPoint(x: 0.0, y: 0.5)
        }
    }
}

// MARK: - Dark Mode Aware Shimmer
struct AdaptiveShimmerView: View {
    var cornerRadius: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    @State private var startPoint = UnitPoint(x: -1.0, y: 0.5)
    @State private var endPoint = UnitPoint(x: 0.0, y: 0.5)

    var body: some View {
        let baseColor = colorScheme == .dark
            ? Color(red: 50/255, green: 52/255, blue: 58/255)
            : Color(red: 230/255, green: 232/255, blue: 236/255)
        let highlightOpacity: Double = colorScheme == .dark ? 0.12 : 0.55

        ZStack {
            baseColor

            LinearGradient(
                stops: [
                    .init(color: Color.clear, location: 0),
                    .init(color: Color.white.opacity(highlightOpacity), location: 0.45),
                    .init(color: Color.white.opacity(highlightOpacity), location: 0.55),
                    .init(color: Color.clear, location: 1),
                ],
                startPoint: startPoint,
                endPoint: endPoint
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onAppear { startAnimating() }
        .onDisappear { stopAnimating() }
    }

    private func startAnimating() {
        startPoint = UnitPoint(x: -1.0, y: 0.5)
        endPoint = UnitPoint(x: 0.0, y: 0.5)
        withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
            startPoint = UnitPoint(x: 1.0, y: 0.5)
            endPoint = UnitPoint(x: 2.0, y: 0.5)
        }
    }

    private func stopAnimating() {
        withAnimation(.linear(duration: 0)) {
            startPoint = UnitPoint(x: -1.0, y: 0.5)
            endPoint = UnitPoint(x: 0.0, y: 0.5)
        }
    }
}
