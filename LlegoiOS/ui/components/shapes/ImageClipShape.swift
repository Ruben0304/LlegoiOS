import SwiftUI

/// Shape personalizado para recortar imágenes con curvas elegantes (invertido de ElegantBottomShape)
/// Usado en: OnboardingView para recortar imágenes de fondo
struct ImageClipShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.size.width
        let height = rect.size.height

        // Control de curva para hacer la forma más elegante
        let curveHeight: CGFloat = 40

        // Comienza desde la esquina superior izquierda
        path.move(to: CGPoint(x: 0, y: 0))

        // Línea superior
        path.addLine(to: CGPoint(x: width, y: 0))

        // Línea derecha
        path.addLine(to: CGPoint(x: width, y: height - curveHeight))

        // Curva final hacia la esquina inferior derecha (invertida)
        path.addCurve(
            to: CGPoint(x: width * 0.7, y: height - curveHeight * 0.6),
            control1: CGPoint(x: width * 0.9, y: height - curveHeight),
            control2: CGPoint(x: width * 0.8, y: height - curveHeight * 0.6)
        )

        // Curva del medio (invertida)
        path.addCurve(
            to: CGPoint(x: width * 0.3, y: height),
            control1: CGPoint(x: width * 0.6, y: height - curveHeight * 0.6),
            control2: CGPoint(x: width * 0.4, y: height)
        )

        // Curva superior elegante hacia la esquina inferior izquierda (invertida)
        path.addCurve(
            to: CGPoint(x: 0, y: height - curveHeight),
            control1: CGPoint(x: width * 0.2, y: height),
            control2: CGPoint(x: width * 0.1, y: height - curveHeight * 0.3)
        )

        // Línea izquierda
        path.addLine(to: CGPoint(x: 0, y: 0))

        // Cerrar el path
        path.closeSubpath()

        return path
    }
}
