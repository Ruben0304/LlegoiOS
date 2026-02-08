import SwiftUI

struct HDRCinematicFilmPalette {
    let deep: Color
    let mid: Color
    let bright: Color
    let flare: Color
    let frame: Color
}

extension HDRCinematicFilmPalette {
    static let emerald = HDRCinematicFilmPalette(
        deep: Color(red: 0.01, green: 0.08, blue: 0.05),
        mid: Color(red: 0.06, green: 0.28, blue: 0.17),
        bright: Color(red: 0.18, green: 0.74, blue: 0.42),
        flare: Color(red: 0.4, green: 1.0, blue: 0.65),
        frame: Color(red: 0.01, green: 0.04, blue: 0.03)
    )
}

struct HDRCinematicFilmView: View {
    let palette: HDRCinematicFilmPalette
    let progress: CGFloat
    let hdrScale: CGFloat

    init(palette: HDRCinematicFilmPalette, progress: CGFloat, hdrScale: CGFloat = 1.0) {
        self.palette = palette
        self.progress = progress
        self.hdrScale = hdrScale
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let normalizedProgress = max(0, min(1, progress))
            let glow = 0.2 + max(0.1, min(hdrScale, 1.0)) * 0.5
            let sweep = CGFloat((sin(t * 0.75) + 1.0) * 0.5)

            ZStack {
                LinearGradient(
                    colors: [palette.frame, palette.deep, palette.mid],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        palette.flare.opacity(0.45 * normalizedProgress),
                        palette.bright.opacity(0.28 * normalizedProgress),
                        .clear
                    ],
                    center: UnitPoint(x: 0.25 + 0.5 * sweep, y: 0.35),
                    startRadius: 0,
                    endRadius: 420
                )
                .blendMode(.screen)

                LinearGradient(
                    colors: [
                        .clear,
                        palette.bright.opacity(glow * normalizedProgress),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .rotationEffect(.degrees(-18))
                .blendMode(.plusLighter)
            }
            .opacity(0.3 + 0.7 * normalizedProgress)
        }
        .allowsHitTesting(false)
    }
}
