import SwiftUI

struct HDRMetallicCardView: View {
    let baseColor: Color
    let metallicIntensity: CGFloat
    let roughness: CGFloat

    @State private var shimmer: CGFloat = -1.0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        baseColor.opacity(0.95),
                        baseColor.opacity(0.8),
                        baseColor.opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.35 * max(0.1, metallicIntensity)),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .rotationEffect(.degrees(18))
                .frame(width: proxy.size.width * 0.35)
                .offset(x: proxy.size.width * shimmer)
                .blur(radius: max(0, roughness) * 6)
                .blendMode(.screen)
            }
            .clipped()
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: false)) {
                shimmer = 1.2
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black

        VStack(spacing: 40) {
            HDRMetallicCardView(
                baseColor: Color(red: 0.2, green: 0.4, blue: 0.8),
                metallicIntensity: 0.9,
                roughness: 0.2
            )
            .frame(width: 350, height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            HDRMetallicCardView(
                baseColor: Color(red: 0.8, green: 0.6, blue: 0.2),
                metallicIntensity: 0.95,
                roughness: 0.15
            )
            .frame(width: 350, height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
    .ignoresSafeArea()
}
