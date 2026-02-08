import SwiftUI

struct HDRHotspotView: View {
    let hotspots: [Hotspot]
    let animate: Bool

    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let maxSide = max(proxy.size.width, proxy.size.height)

            ZStack {
                ForEach(hotspots.indices, id: \.self) { index in
                    let spot = hotspots[index]
                    let pulse = animate ? (1.0 + 0.12 * sin(phase * .pi * 2 + CGFloat(index))) : 1.0
                    let diameter = maxSide * max(spot.radius, 0.01) * 2 * pulse

                    Circle()
                        .fill(spot.color.opacity(0.3 * max(spot.intensity, 0.1)))
                        .frame(width: diameter, height: diameter)
                        .position(
                            x: proxy.size.width * spot.position.x,
                            y: proxy.size.height * spot.position.y
                        )
                        .blur(radius: diameter * 0.15)
                        .blendMode(.plusLighter)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard animate else { return }
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }

    struct Hotspot {
        let position: CGPoint
        let color: Color
        let intensity: CGFloat
        let radius: CGFloat
    }
}
