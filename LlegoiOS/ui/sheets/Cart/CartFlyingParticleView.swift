import SwiftUI

// MARK: - Flying Particle Model & View

struct FlyingParticle: Identifiable {
    let id: UUID
    let imageUrl: String
    let source: CGPoint
    let destination: CGPoint
}

struct FlyingParticleView: View {
    let particle: FlyingParticle
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    var body: some View {
        let pos = currentPosition(progress: progress)

        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 44, height: 44)
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)

            CachedAsyncImage(
                url: URL(string: particle.imageUrl),
                content: { image in
                    image.resizable().scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                },
                placeholder: {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 40, height: 40)
                },
                failure: {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                }
            )
            .frame(width: 40, height: 40)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .position(pos)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55)) {
                progress = 1.0
            }
            withAnimation(.easeIn(duration: 0.15).delay(0.40)) {
                scale = 0.4
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
                onComplete()
            }
        }
    }

    /// Computes a quadratic bezier arc between source and destination.
    private func currentPosition(progress: CGFloat) -> CGPoint {
        let dx = particle.destination.x - particle.source.x
        let dy = particle.destination.y - particle.source.y
        // Control point: slightly left and upward relative to the midpoint
        let control = CGPoint(
            x: particle.source.x + dx * 0.3 - 60,
            y: particle.source.y + dy * 0.3 - abs(dy) * 0.6 - 80
        )
        let t = progress
        let mt = 1 - t
        let x =
            mt * mt * particle.source.x + 2 * mt * t * control.x + t * t * particle.destination.x
        let y =
            mt * mt * particle.source.y + 2 * mt * t * control.y + t * t * particle.destination.y
        return CGPoint(x: x, y: y)
    }
}
