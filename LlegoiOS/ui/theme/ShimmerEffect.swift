//
//  ShimmerEffect.swift
//  LlegoiOS
//
//  Efecto shimmer reutilizable para skeleton loading
//

import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -300

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0), location: 0),
                            .init(color: Color.white.opacity(0.4), location: 0.3),
                            .init(color: Color.white.opacity(0.6), location: 0.5),
                            .init(color: Color.white.opacity(0.4), location: 0.7),
                            .init(color: Color.white.opacity(0), location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 150)
                    .offset(x: phase)
                    .mask(content)
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: 1.2)
                                .repeatForever(autoreverses: false)
                        ) {
                            phase = geometry.size.width + 150
                        }
                    }
                }
            )
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}
