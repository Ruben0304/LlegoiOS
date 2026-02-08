//
//  CircularLoadingIndicator.swift
//  LlegoiOS
//
//  Indicador de carga circular personalizado con degradado de iluminación
//

import SwiftUI
import Lottie

struct CircularLoadingIndicator: View {
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    let useHDR: Bool
    
    init(color: Color = .blue, lineWidth: CGFloat = 6, size: CGFloat = 50, useHDR: Bool = true) {
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
        self.useHDR = useHDR
    }
    
    var body: some View {
        LottieView(
            dotLottieName: "loader",
            loopMode: .loop,
            contentMode: .scaleAspectFit,
            speed: 2.2
        )
        .frame(width: size, height: size)
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
