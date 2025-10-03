import SwiftUI

// Curve constants matching the Compose version
struct CurveConstants {
    static let cornerRadius: CGFloat = 12.0
    static let bottomCornerRadius: CGFloat = 6.0
    static let bottomCurveHeight: CGFloat = 8.0
    static let bottomDip: CGFloat = 24.0
}

struct CurvedBottomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let cornerRadius = CurveConstants.cornerRadius
        let bottomCornerRadius = CurveConstants.bottomCornerRadius
        let bottomDip = CurveConstants.bottomDip

        let w = rect.width
        let h = rect.height

        // Start at top-left corner with rounding
        path.move(to: CGPoint(x: 0, y: cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )

        // Top straight line
        path.addLine(to: CGPoint(x: w - cornerRadius, y: 0))

        // Top-right rounded corner
        path.addQuadCurve(
            to: CGPoint(x: w, y: cornerRadius),
            control: CGPoint(x: w, y: 0)
        )

        // Right straight side until bottom curve begins
        path.addLine(to: CGPoint(x: w, y: h - bottomDip * 0.3))

        // Less pronounced bottom curve
        path.addCurve(
            to: CGPoint(x: 0, y: h - bottomDip * 0.3),
            control1: CGPoint(x: w - bottomCornerRadius * 0.3, y: h + bottomDip * 0.7),
            control2: CGPoint(x: bottomCornerRadius * 0.3, y: h + bottomDip * 0.7)
        )

        // Left side back to top corner
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))

        return path
    }
}
