//
//  FullLoadingView.swift
//  LlegoiOS
//
//  Indicador de carga fullscreen con Lottie centrado y texto.
//  Mismo tamaño y disposición que el loading state del ProductFeedView.
//

import SwiftUI

struct FullLoadingView: View {
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            CircularLoadingIndicator(
                color: color,
                lineWidth: 6,
                size: 440
            )
            .frame(width: 640, height: 640)
            .offset(y: -85)

            Text("Cargando...")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .offset(y: 30)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FullLoadingView(color: .green)
}
