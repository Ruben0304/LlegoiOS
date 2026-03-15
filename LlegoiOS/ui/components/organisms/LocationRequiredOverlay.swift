import SwiftUI
import MapKit
import CoreLocation

/// Overlay de pantalla completa para seleccionar ubicación
/// El usuario toca el mapa para seleccionar su ubicación
struct LocationRequiredOverlay: View {
    @ObservedObject var locationManager = UserLocationManager.shared
    @ObservedObject private var gradientManager = GradientStateManager.shared

    @State private var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    ))
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var isConfirming = false
    @State private var addressText = "Toca en el mapa para seleccionar"
    
    var body: some View {
        ZStack {
            // Mapa interactivo
            MapReader { proxy in
                Map(position: $mapPosition) {
                    if let coord = selectedCoordinate {
                        Annotation("", coordinate: coord) {
                            VStack(spacing: 0) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(gradientManager.currentAccentColor)
                                Image(systemName: "arrowtriangle.down.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(gradientManager.currentAccentColor)
                                    .offset(y: -6)
                            }
                        }
                    }
                }
                .mapStyle(.standard(pointsOfInterest: .excludingAll))
                .onTapGesture { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCoordinate = coordinate
                        }
                        reverseGeocode(coordinate)
                    }
                }
            }
            .ignoresSafeArea()
            
            // UI superpuesta
            VStack {
                // Header minimalista
                HStack {
                    Spacer()
                    
                    Button(action: {
                        locationManager.requestPermission()
                        locationManager.getCurrentDeviceLocation()
                        if let location = locationManager.userLocation {
                            withAnimation {
                                selectedCoordinate = location
                                mapPosition = .region(MKCoordinateRegion(
                                    center: location,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                ))
                            }
                            reverseGeocode(location)
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(gradientManager.currentAccentColor)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
                
                Spacer()
                
                // Panel inferior
                VStack(spacing: 16) {
                    // Dirección seleccionada
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(gradientManager.currentAccentColor)
                        
                        Text(addressText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Botón confirmar
                    Button(action: confirmLocation) {
                        HStack(spacing: 8) {
                            if isConfirming || locationManager.isUpdatingLocation {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(selectedCoordinate == nil ? "Selecciona una ubicación" : "Confirmar ubicación")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(selectedCoordinate == nil ? Color.gray : gradientManager.currentAccentColor)
                        .cornerRadius(16)
                    }
                    .disabled(selectedCoordinate == nil || isConfirming || locationManager.isUpdatingLocation)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 20, y: -5)
                )
            }
        }
    }
    
    private func confirmLocation() {
        guard let coordinate = selectedCoordinate else { return }
        isConfirming = true
        
        Task {
            await locationManager.updateLocation(coordinate: coordinate)
            isConfirming = false
        }
    }
    
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        Task {
            let resolvedAddress = await Task.detached(priority: .userInitiated) { () -> String in
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                guard let request = MKReverseGeocodingRequest(location: location) else {
                    return "Ubicación seleccionada"
                }

                do {
                    let mapItems = try await request.mapItems
                    if let mapItem = mapItems.first {
                        var components: [String] = []
                        if let name = mapItem.name, !name.isEmpty { components.append(name) }
                        if let locality = mapItem.placemark.locality, !locality.isEmpty { components.append(locality) }
                        if !components.isEmpty {
                            return components.joined(separator: ", ")
                        }
                    }
                    return "Ubicación seleccionada"
                } catch {
                    return "Ubicación seleccionada"
                }
            }.value

            await MainActor.run {
                addressText = resolvedAddress
            }
        }
    }
}

#Preview {
    LocationRequiredOverlay()
}
