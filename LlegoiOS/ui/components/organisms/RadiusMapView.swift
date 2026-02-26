//
//  RadiusMapView.swift
//  LlegoiOS
//
//  Created by Claude on 2024
//

import SwiftUI
import MapKit

struct RadiusMapView: View {
    @Binding var radiusKm: Double
    @ObservedObject private var userLocationManager = UserLocationManager.shared

    @State private var pulseAnimation = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666),
        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )

    var body: some View {
        ZStack {
            // Mapa interactivo
            Map(coordinateRegion: $region, interactionModes: [.pan, .zoom])
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.llegoPrimary.opacity(0.2), lineWidth: 1)
                )

            // Círculo de radio
            Circle()
                .stroke(Color.llegoPrimary.opacity(0.3), lineWidth: 2)
                .fill(Color.llegoPrimary.opacity(0.08))
                .frame(width: circleSize, height: circleSize)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.llegoPrimary.opacity(0.6),
                                    Color.llegoAccent.opacity(0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, dash: [8, 5])
                        )
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: radiusKm)

            // Marcador central (ubicación actual)
            ZStack {
                // Pulso animado
                Circle()
                    .fill(Color.llegoPrimary.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                    .opacity(pulseAnimation ? 0 : 0.6)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: pulseAnimation)

                // Pin principal
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.llegoPrimary,
                                Color.llegoPrimary.opacity(0.8)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: Color.llegoPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
            }

            // Indicador de distancia en el borde del círculo
            GeometryReader { geometry in
                distanceBadge
                    .position(
                        x: geometry.size.width - 40,
                        y: geometry.size.height / 2 - circleSize / 2 + 10
                    )
            }

            // Overlay de información superior
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Tu ubicación")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.llegoPrimary.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                )
                Spacer()
            }
            .padding(12)
        }
        .frame(minHeight: 300)
        .onAppear {
            pulseAnimation = true
            // Centrar en la ubicación del usuario si está disponible
            if let userLocation = userLocationManager.userLocation {
                region.center = userLocation
            }
        }
        .onReceive(userLocationManager.$userLocation) { newLocation in
            if let location = newLocation {
                withAnimation(.easeInOut(duration: 0.3)) {
                    region.center = location
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var circleSize: CGFloat {
        // Mapear el radio de 1-50 km a un tamaño visual de 80-240 puntos
        let minSize: CGFloat = 80
        let maxSize: CGFloat = 240
        let normalizedRadius = (radiusKm - 1) / 49 // Normalizar a 0-1
        return minSize + (maxSize - minSize) * normalizedRadius
    }

    private var distanceBadge: some View {
        VStack(spacing: 2) {
            Text(radiusKm < 50 ? "\(Int(radiusKm))" : "∞")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.llegoPrimary)

            Text("km")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.llegoPrimary.opacity(0.3),
                            Color.llegoAccent.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .id(radiusKm) // Forzar recreación cuando cambia el radio
    }
}

#Preview {
    VStack {
        RadiusMapView(radiusKm: .constant(10))
            .padding()
    }
    .background(Color.llegoBackground)
}
