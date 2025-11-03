//
//  RippleEffect.swift
//  LlegoiOS
//
//  Efecto visual premium de esfera de colores expansiva al tocar
//  Inspirado en Gleb Kuznetsov y Apple Design Awards
//

import SwiftUI

/// Representa un punto de ripple con identificador único
struct RipplePoint: Identifiable {
    let id = UUID()
    let location: CGPoint
    let timestamp: Date = Date()
}

/// Efecto visual de ripple expansivo con gradiente de colores
struct RippleEffect: View {
    let origin: CGPoint
    let maxRadius: CGFloat = 300

    @State private var animationProgress: CGFloat = 0
    @State private var opacity: Double = 0.6

    var onComplete: (() -> Void)?

    var body: some View {
        ZStack {
            // Capa externa - Color secundario
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.llegoAccent.opacity(opacity * 0.4),
                            Color.llegoSecondary.opacity(opacity * 0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: currentRadius * 0.8
                    )
                )
                .frame(width: currentRadius * 2, height: currentRadius * 2)
                .blur(radius: blurAmount)

            // Capa interna - Color accent brillante
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.llegoAccent.opacity(opacity * 0.8),
                            Color.llegoAccent.opacity(opacity * 0.3),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: currentRadius * 0.5
                    )
                )
                .frame(width: currentRadius * 1.5, height: currentRadius * 1.5)
                .blur(radius: blurAmount * 0.5)
        }
        .position(origin)
        .allowsHitTesting(false)
        .onAppear {
            startAnimation()
        }
    }

    private var currentRadius: CGFloat {
        maxRadius * animationProgress
    }

    private var blurAmount: CGFloat {
        // Blur aumenta de 0 a 20 mientras crece
        20 * animationProgress
    }

    private func startAnimation() {
        // Animación principal de crecimiento
        withAnimation(
            .timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.8)
        ) {
            animationProgress = 1.0
        }

        // Fade out comienza a mitad de la animación
        withAnimation(
            .easeOut(duration: 0.6)
            .delay(0.2)
        ) {
            opacity = 0
        }

        // Notificar completado
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onComplete?()
        }
    }
}

/// Overlay que maneja múltiples ripples simultáneos
struct RippleOverlay: View {
    @Binding var ripplePoints: [RipplePoint]
    let maxActiveRipples: Int = 5

    var body: some View {
        ZStack {
            ForEach(ripplePoints) { ripple in
                RippleEffect(origin: ripple.location) {
                    removeRipple(ripple)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func removeRipple(_ ripple: RipplePoint) {
        withAnimation(.easeOut(duration: 0.2)) {
            ripplePoints.removeAll { $0.id == ripple.id }
        }
    }
}

// MARK: - Preview
#Preview("Single Ripple") {
    ZStack {
        Color.llegoBackground.ignoresSafeArea()

        RippleEffect(origin: CGPoint(x: 200, y: 400))
    }
}

#Preview("Multiple Ripples") {
    struct MultipleRipplesPreview: View {
        @State private var ripplePoints: [RipplePoint] = []

        var body: some View {
            ZStack {
                Color.llegoBackground.ignoresSafeArea()

                RippleOverlay(ripplePoints: $ripplePoints)

                VStack {
                    Spacer()
                    Text("Toca en cualquier lugar")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.bottom, 50)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                addRipple(at: location)
            }
        }

        private func addRipple(at location: CGPoint) {
            let newRipple = RipplePoint(location: location)
            ripplePoints.append(newRipple)

            // Limitar a máximo 5 ripples activos
            if ripplePoints.count > 5 {
                ripplePoints.removeFirst()
            }
        }
    }

    return MultipleRipplesPreview()
}
