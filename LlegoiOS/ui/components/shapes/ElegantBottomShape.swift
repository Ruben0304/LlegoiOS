import SwiftUI

/// Shape personalizado para el fondo inferior con curvas elegantes
/// Usado en: OnboardingView para el fondo decorativo inferior
struct ElegantBottomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.size.width
        let height = rect.size.height

        // Control de curva para hacer la forma más elegante
        let curveHeight: CGFloat = 40

        // Comienza desde la parte superior izquierda con una curva elegante
        path.move(to: CGPoint(x: 0, y: curveHeight))

        // Curva superior elegante usando múltiples puntos de control
        path.addCurve(
            to: CGPoint(x: width * 0.3, y: 0),
            control1: CGPoint(x: width * 0.1, y: curveHeight * 0.3),
            control2: CGPoint(x: width * 0.2, y: 0)
        )

        // Curva del medio
        path.addCurve(
            to: CGPoint(x: width * 0.7, y: curveHeight * 0.6),
            control1: CGPoint(x: width * 0.4, y: 0),
            control2: CGPoint(x: width * 0.6, y: curveHeight * 0.6)
        )

        // Curva final hacia la esquina superior derecha
        path.addCurve(
            to: CGPoint(x: width, y: 0),
            control1: CGPoint(x: width * 0.8, y: curveHeight * 0.6),
            control2: CGPoint(x: width * 0.9, y: 0)
        )

        // Línea hacia abajo por el lado derecho
        path.addLine(to: CGPoint(x: width, y: height))

        // Línea hacia la esquina inferior izquierda
        path.addLine(to: CGPoint(x: 0, y: height))

        // Cerrar el path
        path.closeSubpath()

        return path
    }
}
