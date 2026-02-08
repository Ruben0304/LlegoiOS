import SwiftUI

struct HDRGradientView: View {
    let colors: [HDRColor]
    let locations: [Float]
    let center: CGPoint
    let startRadius: CGFloat
    let endRadius: CGFloat
    let type: GradientType

    enum GradientType {
        case radial
        case linear(startPoint: CGPoint, endPoint: CGPoint)
    }

    struct HDRColor {
        let color: Color
        let intensity: Float
    }

    var body: some View {
        GeometryReader { proxy in
            let gradient = Gradient(stops: gradientStops)

            switch type {
            case .radial:
                RadialGradient(
                    gradient: gradient,
                    center: UnitPoint(x: center.x, y: center.y),
                    startRadius: startRadius,
                    endRadius: resolvedEndRadius(for: proxy.size)
                )
            case .linear(let startPoint, let endPoint):
                LinearGradient(
                    gradient: gradient,
                    startPoint: UnitPoint(x: startPoint.x, y: startPoint.y),
                    endPoint: UnitPoint(x: endPoint.x, y: endPoint.y)
                )
            }
        }
        .allowsHitTesting(false)
    }

    private var gradientStops: [Gradient.Stop] {
        if colors.isEmpty {
            return [
                .init(color: .clear, location: 0),
                .init(color: .clear, location: 1)
            ]
        }

        if colors.count == locations.count {
            return zip(colors, locations).map { hdrColor, location in
                Gradient.Stop(
                    color: tonedColor(for: hdrColor),
                    location: Double(max(0, min(1, location)))
                )
            }
        }

        let denominator = Double(max(colors.count - 1, 1))
        return colors.enumerated().map { index, hdrColor in
            Gradient.Stop(color: tonedColor(for: hdrColor), location: Double(index) / denominator)
        }
    }

    private func tonedColor(for hdrColor: HDRColor) -> Color {
        let clamped = max(0.05, min(Double(hdrColor.intensity), 2.0))
        return hdrColor.color.opacity(min(1.0, 0.7 + (clamped - 1.0) * 0.3))
    }

    private func resolvedEndRadius(for size: CGSize) -> CGFloat {
        if endRadius > 0 {
            return endRadius
        }
        return max(size.width, size.height)
    }
}
