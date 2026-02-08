import SwiftUI
import UIKit

struct HDRAnimatedGradientPalette {
    let dark: Color
    let medium: Color
    let light: Color
    let veryLight: Color
    let overlay: Color
}

struct HDRAnimatedGradientView: View {
    let fromPalette: HDRAnimatedGradientPalette
    let toPalette: HDRAnimatedGradientPalette
    let transitionProgress: CGFloat
    let center: CGPoint
    let isExpanded: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let blend = max(0, min(1, transitionProgress))
            let driftX = sin(time * 0.25) * 0.04
            let driftY = cos(time * 0.21) * 0.04
            let resolvedCenter = UnitPoint(
                x: max(0, min(1, center.x + driftX)),
                y: max(0, min(1, center.y + driftY))
            )
            let radiusScale: CGFloat = isExpanded ? 1.15 : 0.9

            ZStack {
                RadialGradient(
                    stops: [
                        .init(color: mix(fromPalette.veryLight, toPalette.veryLight, t: blend), location: 0.0),
                        .init(color: mix(fromPalette.light, toPalette.light, t: blend), location: 0.28),
                        .init(color: mix(fromPalette.medium, toPalette.medium, t: blend), location: 0.62),
                        .init(color: mix(fromPalette.dark, toPalette.dark, t: blend), location: 1.0)
                    ],
                    center: resolvedCenter,
                    startRadius: 0,
                    endRadius: 600 * radiusScale
                )

                LinearGradient(
                    colors: [
                        mix(fromPalette.overlay, toPalette.overlay, t: blend).opacity(0.2),
                        .clear,
                        mix(fromPalette.overlay, toPalette.overlay, t: blend).opacity(0.35)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.screen)
            }
        }
        .allowsHitTesting(false)
    }

    private func mix(_ lhs: Color, _ rhs: Color, t: CGFloat) -> Color {
        let clamped = max(0, min(1, t))
        let left = UIColor(lhs)
        let right = UIColor(rhs)

        var lR: CGFloat = 0
        var lG: CGFloat = 0
        var lB: CGFloat = 0
        var lA: CGFloat = 0
        var rR: CGFloat = 0
        var rG: CGFloat = 0
        var rB: CGFloat = 0
        var rA: CGFloat = 0

        left.getRed(&lR, green: &lG, blue: &lB, alpha: &lA)
        right.getRed(&rR, green: &rG, blue: &rB, alpha: &rA)

        let red = lR + (rR - lR) * clamped
        let green = lG + (rG - lG) * clamped
        let blue = lB + (rB - lB) * clamped
        let alpha = lA + (rA - lA) * clamped

        return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
