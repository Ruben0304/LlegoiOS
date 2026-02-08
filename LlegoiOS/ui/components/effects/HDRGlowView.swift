import SwiftUI

struct HDRGlowView: View {
    let color: Color
    let intensity: CGFloat
    let radius: CGFloat

    private var clampedIntensity: CGFloat {
        max(0.05, min(intensity, 2.5))
    }

    private var clampedRadius: CGFloat {
        max(0.1, min(radius, 2.0))
    }

    var body: some View {
        GeometryReader { proxy in
            let maxSide = max(proxy.size.width, proxy.size.height)
            let endRadius = maxSide * clampedRadius

            RadialGradient(
                stops: [
                    .init(color: color.opacity(0.9), location: 0.0),
                    .init(color: color.opacity(0.45 * clampedIntensity), location: 0.35),
                    .init(color: color.opacity(0.18 * clampedIntensity), location: 0.65),
                    .init(color: .clear, location: 1.0)
                ],
                center: .center,
                startRadius: 0,
                endRadius: endRadius
            )
            .blendMode(.screen)
        }
        .allowsHitTesting(false)
    }
}
