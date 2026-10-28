import Foundation
import CoreGraphics

/// A flight is generated from the tapped card's live position, never a fixed screen origin.
struct CartFlightTrajectory {
    enum CardStyle {
        case featured, compact, inline

        var lift: CGFloat {
            switch self {
            case .featured: 100
            case .compact: 65
            case .inline: 40
            }
        }

        var thumbnailSize: CGFloat {
            switch self {
            case .featured: 60
            case .compact: 46
            case .inline: 40
            }
        }
    }

    let source: CGPoint
    let destination: CGPoint
    let viewport: CGSize
    let style: CardStyle

    var duration: TimeInterval {
        let distance = hypot(destination.x - source.x, destination.y - source.y)
        return min(0.88, max(0.48, Double(distance / 1000) + 0.36))
    }

    func position(at progress: CGFloat) -> CGPoint {
        let t = min(1, max(0, progress))
        let u = 1 - t
        let rise = max(0, source.y - destination.y)
        let dx = destination.x - source.x
        let direction: CGFloat = abs(dx) < 20 ? (source.x > viewport.width / 2 ? -1 : 1) : (dx > 0 ? 1 : -1)
        let margin = min(style.thumbnailSize / 2 + 6, viewport.width / 2)
        func inside(_ x: CGFloat) -> CGFloat { min(max(margin, x), max(margin, viewport.width - margin)) }
        let first = CGPoint(
            x: inside(source.x + direction * min(110, abs(dx) * 0.24 + style.lift * 0.6)),
            y: max(20, source.y - max(style.lift, rise * 0.42)))
        let second = CGPoint(
            x: inside(destination.x - direction * min(85, abs(dx) * 0.20 + style.lift * 0.25)),
            y: max(20, destination.y + min(100, rise * 0.14)))
        return CGPoint(
            x: u * u * u * source.x + 3 * u * u * t * first.x + 3 * u * t * t * second.x + t * t * t * destination.x,
            y: u * u * u * source.y + 3 * u * u * t * first.y + 3 * u * t * t * second.y + t * t * t * destination.y)
    }
}
