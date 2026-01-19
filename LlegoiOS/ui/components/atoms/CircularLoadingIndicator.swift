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
    
    @State private var rotation: Double = 0
    
    init(color: Color = .blue, lineWidth: CGFloat = 6, size: CGFloat = 50) {
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
    }
    
    var body: some View {
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
    VStack(spacing: 40) {
        CircularLoadingIndicator(color: .blue)
        CircularLoadingIndicator(color: .cyan, lineWidth: 7, size: 60)
        CircularLoadingIndicator(color: .purple, lineWidth: 5, size: 40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
