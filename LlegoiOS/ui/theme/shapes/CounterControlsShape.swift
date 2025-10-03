import SwiftUI

struct CounterControlsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let cornerRadius = CurveConstants.cornerRadius
        let bottomCornerRadius = CurveConstants.bottomCornerRadius
        let topCurveDepth: CGFloat = 6.0
        let bottomDip = CurveConstants.bottomDip

        let w = rect.width
        let h = rect.height

        // Start at top-left corner with rounding
        path.move(to: CGPoint(x: 0, y: cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )

        // Pronounced top curve
        path.addQuadCurve(
            to: CGPoint(x: w - cornerRadius, y: 0),
            control: CGPoint(x: w / 2, y: topCurveDepth * 1.5)
        )

        // Top-right rounded corner
        path.addQuadCurve(
            to: CGPoint(x: w, y: cornerRadius),
            control: CGPoint(x: w, y: 0)
        )

        // Right straight side until bottom curve starts
        path.addLine(to: CGPoint(x: w, y: h - bottomDip * 0.4))

        // Smooth bottom curve using cubic Bézier for continuous transition
        path.addCurve(
            to: CGPoint(x: 0, y: h - bottomDip * 0.4),
            control1: CGPoint(x: w - bottomCornerRadius * 0.3, y: h + bottomDip * 0.6),
            control2: CGPoint(x: bottomCornerRadius * 0.3, y: h + bottomDip * 0.6)
        )

        // Left side back to top corner
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))

        return path
    }
}
