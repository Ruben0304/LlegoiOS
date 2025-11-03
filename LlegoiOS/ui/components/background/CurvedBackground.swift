import SwiftUI

struct CurvedBackground<Content: View>: View {
    @Binding var curveStartAbsolute: CGFloat
    let curveEndAbsolute: CGFloat
    let curveInclinationAbsolute: CGFloat
    let invertCurve: Bool
    let content: () -> Content

    init(
        curveStartAbsolute: Binding<CGFloat>,
        curveEndAbsolute: CGFloat = 150,
        curveInclinationAbsolute: CGFloat = 50,
        invertCurve: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._curveStartAbsolute = curveStartAbsolute
        self.curveEndAbsolute = curveEndAbsolute
        self.curveInclinationAbsolute = curveInclinationAbsolute
        self.invertCurve = invertCurve
        self.content = content
    }

    init(
        curveStartAbsolute: CGFloat = 200,
        curveEndAbsolute: CGFloat = 200,
        curveInclinationAbsolute: CGFloat = 50,
        invertCurve: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._curveStartAbsolute = .constant(curveStartAbsolute)
        self.curveEndAbsolute = curveEndAbsolute
        self.curveInclinationAbsolute = curveInclinationAbsolute
        self.invertCurve = invertCurve
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.llegoBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopGreenLayer()
                    .frame(height: 340)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)

            content()
        }
    }
}

private struct TopGreenLayer: View {
    var body: some View {
        AnimatedLinearGreenGradient()
        .mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white, location: 0.7),
                    .init(color: .clear, location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct AnimatedLinearGreenGradient: View {
    private let top = Color(red: 9 / 255, green: 42 / 255, blue: 39 / 255)
    private let mid = Color(red: 23 / 255, green: 74 / 255, blue: 65 / 255)
    private let bottom = Color(red: 43 / 255, green: 113 / 255, blue: 96 / 255)

    private let speed: Double = 0.18
    private let amplitude: CGFloat = 0.05

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate * speed
            let sinValue = CGFloat(sin(time))
            let cosValue = CGFloat(cos(time * 0.9))

            let startX = (0.25 + amplitude * sinValue).clamped(to: 0.1...0.4)
            let endX = (0.85 - amplitude * cosValue).clamped(to: 0.6...0.95)

            let middleLocation = (0.48 + amplitude * 0.6 * sinValue).clamped(to: 0.3...0.7)
            let bottomLocation = max(
                middleLocation + 0.08,
                min(0.95, 0.88 + amplitude * 0.5 * cosValue)
            )

            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: top, location: 0),
                    .init(color: mid, location: middleLocation),
                    .init(color: bottom, location: min(bottomLocation, 1))
                ]),
                startPoint: UnitPoint(x: startX, y: 0),
                endPoint: UnitPoint(x: endX, y: 1)
            )
        }
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        if self < range.lowerBound {
            return range.lowerBound
        } else if self > range.upperBound {
            return range.upperBound
        }
        return self
    }
}

#Preview("Curved Background") {
    CurvedBackground {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resumen")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Text("Esta es una vista previa del nuevo fondo.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
        .padding()
    }
}
