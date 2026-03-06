import SwiftUI

// MARK: - Shimmer Effect
/// Animación shimmer/skeleton para estados de carga de imágenes
struct ShimmerView: View {
    var cornerRadius: CGFloat = 0
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                Color(red: 230/255, green: 232/255, blue: 236/255)

                LinearGradient(
                    stops: [
                        .init(color: Color.clear, location: 0),
                        .init(color: Color.white.opacity(0.55), location: 0.4),
                        .init(color: Color.white.opacity(0.55), location: 0.6),
                        .init(color: Color.clear, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: width * 2.5)
                .offset(x: phase * width * 2.5)
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.4)
                .repeatForever(autoreverses: false)
            ) {
                phase = 1
            }
        }
    }
}

// MARK: - Dark Mode Aware Shimmer
struct AdaptiveShimmerView: View {
    var cornerRadius: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    @State private var phase: CGFloat = -1

    var body: some View {
        let baseColor = colorScheme == .dark
            ? Color(red: 50/255, green: 52/255, blue: 58/255)
            : Color(red: 230/255, green: 232/255, blue: 236/255)
        let highlightOpacity: Double = colorScheme == .dark ? 0.12 : 0.55

        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                baseColor

                LinearGradient(
                    stops: [
                        .init(color: Color.clear, location: 0),
                        .init(color: Color.white.opacity(highlightOpacity), location: 0.4),
                        .init(color: Color.white.opacity(highlightOpacity), location: 0.6),
                        .init(color: Color.clear, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: width * 2.5)
                .offset(x: phase * width * 2.5)
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.4)
                .repeatForever(autoreverses: false)
            ) {
                phase = 1
            }
        }
    }
}
