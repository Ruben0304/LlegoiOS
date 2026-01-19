import SwiftUI

/// Ejemplos de uso de efectos HDR/EDR
/// Este archivo contiene ejemplos que puedes copiar y adaptar

// MARK: - Ejemplo 1: Botón con Glow HDR
struct HDRGlowButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow HDR que se intensifica al presionar
                HDRGlowView(
                    color: .blue,
                    intensity: isPressed ? 1.5 : 0.8,
                    radius: 0.5
                )
                .frame(width: 200, height: 60)
                .blur(radius: 25)
                .animation(.easeInOut(duration: 0.2), value: isPressed)
                
                // Contenido del botón
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.blue)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Ejemplo 2: Card con Borde HDR
struct HDRBorderCard: View {
    let content: String
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Glow HDR en el borde cuando está seleccionado
            if isSelected {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(lineWidth: 0)
                    .background(
                        HDRGlowView(
                            color: .green,
                            intensity: 1.0,
                            radius: 0.3
                        )
                        .blur(radius: 15)
                    )
                    .frame(width: 180, height: 120)
            }
            
            // Contenido de la card
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .frame(width: 160, height: 100)
                .overlay(
                    Text(content)
                        .font(.system(size: 16, weight: .semibold))
                )
        }
        .animation(.easeInOut(duration: 0.3), value: isSelected)
    }
}

// MARK: - Ejemplo 3: Loading Spinner con HDR
struct HDRLoadingSpinner: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Múltiples glows rotando
            ForEach(0..<3, id: \.self) { index in
                HDRGlowView(
                    color: Color(hue: Double(index) / 3.0, saturation: 0.8, brightness: 1.0),
                    intensity: 1.2,
                    radius: 0.4
                )
                .frame(width: 80, height: 80)
                .blur(radius: 20)
                .offset(x: 40)
                .rotationEffect(.degrees(rotation + Double(index) * 120))
            }
        }
        .frame(width: 120, height: 120)
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Ejemplo 4: Notificación con Hotspot HDR
struct HDRNotificationBadge: View {
    let count: Int
    @State private var shouldAnimate = true
    
    var body: some View {
        ZStack {
            // Hotspot pulsante detrás del badge
            HDRHotspotView(
                hotspots: [
                    HDRHotspotView.Hotspot(
                        position: CGPoint(x: 0.5, y: 0.5),
                        color: .red,
                        intensity: 1.0,
                        radius: 0.6
                    )
                ],
                animate: shouldAnimate
            )
            .frame(width: 40, height: 40)
            .blur(radius: 10)
            
            // Badge
            Circle()
                .fill(Color.red)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }
}

// MARK: - Ejemplo 5: Gradiente Animado con Hotspots
struct HDRAnimatedGradient: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Gradiente base
            LinearGradient(
                colors: [.purple, .blue, .cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Hotspots que se mueven
            HDRHotspotView(
                hotspots: [
                    HDRHotspotView.Hotspot(
                        position: CGPoint(
                            x: 0.5 + cos(phase * .pi * 2) * 0.3,
                            y: 0.5 + sin(phase * .pi * 2) * 0.3
                        ),
                        color: .white,
                        intensity: 1.5,
                        radius: 0.25
                    ),
                    HDRHotspotView.Hotspot(
                        position: CGPoint(
                            x: 0.5 + cos((phase + 0.5) * .pi * 2) * 0.3,
                            y: 0.5 + sin((phase + 0.5) * .pi * 2) * 0.3
                        ),
                        color: .yellow,
                        intensity: 1.2,
                        radius: 0.2
                    )
                ],
                animate: false
            )
            .blendMode(.screen)
        }
        .onAppear {
            withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }
}

// MARK: - Ejemplo 6: Highlight en Texto
struct HDRHighlightedText: View {
    let text: String
    let highlightColor: Color
    
    var body: some View {
        ZStack {
            // Glow detrás del texto
            HDRGlowView(
                color: highlightColor,
                intensity: 0.9,
                radius: 0.5
            )
            .frame(width: 200, height: 50)
            .blur(radius: 20)
            
            // Texto
            Text(text)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, highlightColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: highlightColor.opacity(0.5), radius: 10)
        }
    }
}

// MARK: - Preview
#Preview("HDR Examples") {
    ScrollView {
        VStack(spacing: 40) {
            Text("HDR Effects Examples")
                .font(.system(size: 28, weight: .bold))
                .padding(.top, 40)
            
            VStack(spacing: 20) {
                Text("Botón con Glow")
                    .font(.caption)
                HDRGlowButton(title: "Press Me") {
                    print("Button pressed")
                }
            }
            
            VStack(spacing: 20) {
                Text("Cards con Borde HDR")
                    .font(.caption)
                HStack(spacing: 20) {
                    HDRBorderCard(content: "Selected", isSelected: true)
                    HDRBorderCard(content: "Normal", isSelected: false)
                }
            }
            
            VStack(spacing: 20) {
                Text("Loading Spinner")
                    .font(.caption)
                HDRLoadingSpinner()
            }
            
            VStack(spacing: 20) {
                Text("Notification Badge")
                    .font(.caption)
                HDRNotificationBadge(count: 5)
            }
            
            VStack(spacing: 20) {
                Text("Gradiente Animado")
                    .font(.caption)
                HDRAnimatedGradient()
                    .frame(height: 200)
                    .cornerRadius(20)
            }
            
            VStack(spacing: 20) {
                Text("Texto Destacado")
                    .font(.caption)
                HDRHighlightedText(
                    text: "PREMIUM",
                    highlightColor: .orange
                )
            }
            
            Spacer(minLength: 40)
        }
        .padding()
    }
    .background(Color.black)
}
