//
//  CircularLoadingIndicator.swift
//  LlegoiOS
//
//  Indicador de carga circular personalizado con degradado de iluminación
//

import SwiftUI

struct CircularLoadingIndicator: View {
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    let useHDR: Bool
    
    @State private var rotation: Double = 0
    
    init(color: Color = .blue, lineWidth: CGFloat = 6, size: CGFloat = 50, useHDR: Bool = true) {
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
        self.useHDR = useHDR
    }
    
    var body: some View {
        if useHDR {
            hdrVersion
        } else {
            standardVersion
        }
    }
    
    // Versión HDR con glow brillante
    private var hdrVersion: some View {
        ZStack {
            // Glow HDR rotando
            HDRGlowView(
                color: color,
                intensity: 1.8,
                radius: 0.5
            )
            .frame(width: size * 1.2, height: size * 1.2)
            .blur(radius: 15)
            .rotationEffect(.degrees(rotation))
            
            // Círculo base con degradado angular
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: color.opacity(0.1), location: 0.0),
                            .init(color: color.opacity(0.3), location: 0.2),
                            .init(color: color.opacity(0.6), location: 0.4),
                            .init(color: color, location: 0.65),
                            .init(color: color.mix(with: .white, by: 0.3), location: 0.85),
                            .init(color: .white, location: 1.0)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
                .shadow(color: color.opacity(0.5), radius: 6, x: 0, y: 0)
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
    
    // Versión estándar sin HDR (fallback)
    private var standardVersion: some View {
        ZStack {
            // Círculo base con degradado angular
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: color.opacity(0.1), location: 0.0),
                            .init(color: color.opacity(0.3), location: 0.2),
                            .init(color: color.opacity(0.6), location: 0.4),
                            .init(color: color, location: 0.65),
                            .init(color: color.mix(with: .white, by: 0.3), location: 0.85),
                            .init(color: .white, location: 1.0)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 0)
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
}

// Extensión para mezclar colores
extension Color {
    func mix(with color: Color, by percentage: Double) -> Color {
        let percentage = min(max(percentage, 0), 1)
        
        guard let components1 = self.cgColor?.components,
              let components2 = color.cgColor?.components else {
            return self
        }
        
        let r = components1[0] + (components2[0] - components1[0]) * percentage
        let g = components1[1] + (components2[1] - components1[1]) * percentage
        let b = components1[2] + (components2[2] - components1[2]) * percentage
        
        return Color(red: r, green: g, blue: b)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            VStack(spacing: 8) {
                Text("HDR Version")
                    .foregroundColor(.white)
                    .font(.caption)
                CircularLoadingIndicator(color: .blue, useHDR: true)
            }
            
            VStack(spacing: 8) {
                Text("HDR Cyan")
                    .foregroundColor(.white)
                    .font(.caption)
                CircularLoadingIndicator(color: .cyan, lineWidth: 7, size: 60, useHDR: true)
            }
            
            VStack(spacing: 8) {
                Text("Standard (no HDR)")
                    .foregroundColor(.white)
                    .font(.caption)
                CircularLoadingIndicator(color: .purple, lineWidth: 5, size: 40, useHDR: false)
            }
        }
    }
}
