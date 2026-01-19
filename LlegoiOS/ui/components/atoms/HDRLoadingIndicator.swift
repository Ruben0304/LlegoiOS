import SwiftUI

/// Loading indicator con efectos HDR brillantes
/// Usado para estados de carga con feedback visual premium
struct HDRLoadingIndicator: View {
    let size: CGFloat
    let color: Color
    
    @State private var rotation: Double = 0
    
    init(size: CGFloat = 60, color: Color = .llegoPrimary) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            // Múltiples glows HDR rotando
            ForEach(0..<3, id: \.self) { index in
                HDRGlowView(
                    color: color.opacity(0.8),
                    intensity: 2.0,
                    radius: 0.4
                )
                .frame(width: size * 0.6, height: size * 0.6)
                .blur(radius: 15)
                .offset(x: size * 0.3)
                .rotationEffect(.degrees(rotation + Double(index) * 120))
            }
            
            // Círculo central con glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.8), color.opacity(0.3)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.2
                    )
                )
                .frame(width: size * 0.4, height: size * 0.4)
                .overlay(
                    HDRGlowView(
                        color: color,
                        intensity: 1.5,
                        radius: 0.5
                    )
                    .frame(width: size * 0.4, height: size * 0.4)
                    .blur(radius: 10)
                )
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

/// Loading indicator compacto con pulso HDR
struct HDRPulseLoadingIndicator: View {
    let size: CGFloat
    let color: Color
    
    @State private var pulse: CGFloat = 0.8
    
    init(size: CGFloat = 40, color: Color = .llegoPrimary) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            // Glow HDR pulsante
            HDRGlowView(
                color: color,
                intensity: 1.5 + (pulse * 0.5),
                radius: 0.5
            )
            .frame(width: size, height: size)
            .blur(radius: 12)
            .scaleEffect(pulse)
            
            // Círculo central
            Circle()
                .fill(color)
                .frame(width: size * 0.5, height: size * 0.5)
                .scaleEffect(pulse)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulse = 1.2
            }
        }
    }
}

/// Loading indicator tipo dots con HDR
struct HDRDotsLoadingIndicator: View {
    let dotSize: CGFloat
    let spacing: CGFloat
    let color: Color
    
    @State private var animationPhase: CGFloat = 0
    
    init(dotSize: CGFloat = 12, spacing: CGFloat = 8, color: Color = .llegoPrimary) {
        self.dotSize = dotSize
        self.spacing = spacing
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<3, id: \.self) { index in
                ZStack {
                    // Glow HDR
                    HDRGlowView(
                        color: color,
                        intensity: CGFloat(dotIntensity(for: index)),
                        radius: 0.5
                    )
                    .frame(width: dotSize * 1.5, height: dotSize * 1.5)
                    .blur(radius: 8)
                    
                    // Dot
                    Circle()
                        .fill(color)
                        .frame(width: dotSize, height: dotSize)
                }
                .scaleEffect(dotScale(for: index))
                .animation(
                    .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                    value: animationPhase
                )
            }
        }
        .onAppear {
            animationPhase = 1.0
        }
    }
    
    private func dotScale(for index: Int) -> CGFloat {
        let phase = (animationPhase + CGFloat(index) * 0.33).truncatingRemainder(dividingBy: 1.0)
        return 0.8 + (sin(phase * .pi * 2) * 0.4)
    }
    
    private func dotIntensity(for index: Int) -> Float {
        let phase = (animationPhase + CGFloat(index) * 0.33).truncatingRemainder(dividingBy: 1.0)
        return Float(1.0 + (sin(phase * .pi * 2) * 0.5))
    }
}

#Preview("HDR Loading Indicators") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 60) {
            VStack(spacing: 12) {
                Text("Rotating Glow")
                    .foregroundColor(.white)
                    .font(.caption)
                HDRLoadingIndicator(size: 80, color: .llegoPrimary)
            }
            
            VStack(spacing: 12) {
                Text("Pulse")
                    .foregroundColor(.white)
                    .font(.caption)
                HDRPulseLoadingIndicator(size: 60, color: .llegoAccent)
            }
            
            VStack(spacing: 12) {
                Text("Dots")
                    .foregroundColor(.white)
                    .font(.caption)
                HDRDotsLoadingIndicator(dotSize: 14, spacing: 10, color: .llegoPrimary)
            }
        }
    }
}
