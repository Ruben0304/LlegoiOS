import SwiftUI

struct OrderConfirmationView: View {
    let deliveryLocation: String
    let selectedPaymentMethod: String
    let onDismiss: () -> Void

    @Environment(\.presentationMode) var presentationMode
    @State private var backgroundProgress: CGFloat = 0
    @State private var ringRotation: CGFloat = 0
    @State private var showBadge = false
    @State private var showTitle = false

    private let titleColor = Color.black

    var body: some View {
        ZStack {
            AnimatedGreenBackground(progress: backgroundProgress)
                .ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer(minLength: 40)
                checkBadge
                titleBlock
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 28)
        }
        .onAppear {
            backgroundProgress = 0
            ringRotation = 0
            showBadge = false
            showTitle = false
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.easeOut(duration: 2.4)) {
                backgroundProgress = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showBadge = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showTitle = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onDismiss()
            }
        }
    }

    private var checkBadge: some View {
        ZStack {
           
            Circle()
                .fill(Color.white)
                .frame(width: 92, height: 92)

            Circle()
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                .frame(width: 92, height: 92)

            Image(systemName: "checkmark")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.black)
        }
        .drawingGroup()
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
        .opacity(showBadge ? 1 : 0)
        .scaleEffect(showBadge ? 1 : 0.88)
        .offset(y: showBadge ? 0 : 18)
        .animation(.spring(response: 0.7, dampingFraction: 0.7), value: showBadge)
    }

    private var titleBlock: some View {
        Text("Orden completada")
            .font(.system(size: 28, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundColor(titleColor)
            .multilineTextAlignment(.center)
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .opacity(showTitle ? 1 : 0)
            .offset(y: showTitle ? 0 : 18)
            .animation(.easeOut(duration: 0.6), value: showTitle)
    }

}

private struct AnimatedGreenBackground: View {
    let progress: CGFloat

    private let deep = Color(red: 0.04, green: 0.26, blue: 0.16)
    private let mid = Color(red: 0.16, green: 0.62, blue: 0.4)
    private let bright = Color(red: 0.36, green: 0.96, blue: 0.62)

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                let baseGradient = Gradient(colors: [deep, mid, bright])
                context.fill(
                    Path(rect),
                    with: .linearGradient(
                        baseGradient,
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: size.width, y: size.height)
                    )
                )

                let time = timeline.date.timeIntervalSinceReferenceDate
                let pulse = 0.55 + 0.45 * sin(time * 0.8)
                let intensity = max(0.0, min(1.0, progress))

                var glowContext = context
                glowContext.addFilter(.blur(radius: 60))
                glowContext.blendMode = .plusLighter

                for index in 0..<3 {
                    let phase = time * (0.35 + Double(index) * 0.18)
                    let x = size.width * (0.2 + 0.6 * CGFloat(sin(phase + Double(index) * 1.4) * 0.5 + 0.5))
                    let y = size.height * (0.2 + 0.6 * CGFloat(cos(phase * 1.1 + Double(index)) * 0.5 + 0.5))
                    let radius = min(size.width, size.height) * (0.35 + CGFloat(index) * 0.08)

                    let blobRect = CGRect(
                        x: x - radius * 0.7,
                        y: y - radius * 0.7,
                        width: radius * 1.4,
                        height: radius * 1.4
                    )
                    let blobGradient = Gradient(colors: [
                        bright.opacity(0.5 * intensity * CGFloat(pulse)),
                        mid.opacity(0.2 * intensity),
                        .clear
                    ])
                    glowContext.fill(
                        Path(ellipseIn: blobRect),
                        with: .radialGradient(blobGradient, center: CGPoint(x: x, y: y), startRadius: 0, endRadius: radius)
                    )
                }

                var ribbonContext = context
                ribbonContext.addFilter(.blur(radius: 18))

                let ribbonOne = ribbonPath(size: size, phase: time * 0.7, offset: 0.28)
                let ribbonTwo = ribbonPath(size: size, phase: time * 0.55 + 1.4, offset: 0.62)

                let ribbonGradient = Gradient(colors: [
                    bright.opacity(0.25 * intensity),
                    mid.opacity(0.18 * intensity),
                    deep.opacity(0.1 * intensity)
                ])

                ribbonContext.fill(
                    ribbonOne,
                    with: .linearGradient(
                        ribbonGradient,
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: size.width, y: 0)
                    )
                )
                ribbonContext.fill(
                    ribbonTwo,
                    with: .linearGradient(
                        ribbonGradient,
                        startPoint: CGPoint(x: size.width, y: 0),
                        endPoint: CGPoint(x: 0, y: 0)
                    )
                )
            }
        }
    }

    private func ribbonPath(size: CGSize, phase: Double, offset: CGFloat) -> Path {
        let width = size.width
        let height = size.height
        let amplitude = height * 0.08
        let baseY = height * offset
        let step: CGFloat = 24

        var path = Path()
        path.move(to: CGPoint(x: 0, y: baseY))

        var x: CGFloat = 0
        while x <= width + step {
            let progress = Double(x / width)
            let y = baseY + sin(progress * 6.28 + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }

        path.addLine(to: CGPoint(x: width, y: baseY + amplitude * 2.6))
        path.addLine(to: CGPoint(x: 0, y: baseY + amplitude * 2.6))
        path.closeSubpath()
        return path
    }
}

#Preview {
    OrderConfirmationView(
        deliveryLocation: "Vedado, La Habana",
        selectedPaymentMethod: "Efectivo CUP",
        onDismiss: {}
    )
}
