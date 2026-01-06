import SwiftUI
import MapKit
import CoreLocation

/// Vista de selección de ubicación para el perfil
/// El usuario toca el mapa para seleccionar su ubicación
struct ProfileLocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var userLocationManager = UserLocationManager.shared

    @State private var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    ))
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var isConfirming = false
    @State private var addressText = "Toca en el mapa para seleccionar"
    @State private var showConfirmation = false

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
                                    .foregroundColor(.llegoPrimary)
                                Image(systemName: "arrowtriangle.down.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.llegoPrimary)
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
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        userLocationManager.requestPermission()
                        userLocationManager.getCurrentDeviceLocation()
                        if let location = userLocationManager.userLocation {
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
                            .foregroundColor(.llegoPrimary)
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
                            .foregroundColor(showConfirmation ? .llegoAccent : .llegoPrimary)
                        
                        Text(showConfirmation ? "¡Ubicación guardada!" : addressText)
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
                            if isConfirming || userLocationManager.isUpdatingLocation {
                                ProgressView()
                                    .tint(.white)
                            } else if showConfirmation {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                            }
                            Text(showConfirmation ? "Listo" : (selectedCoordinate == nil ? "Selecciona una ubicación" : "Confirmar ubicación"))
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(showConfirmation ? Color.llegoAccent : (selectedCoordinate == nil ? Color.gray : Color.llegoPrimary))
                        .cornerRadius(16)
                    }
                    .disabled(selectedCoordinate == nil || isConfirming || userLocationManager.isUpdatingLocation)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 20, y: -5)
                )
            }
        }
        .onAppear {
            // Cargar ubicación existente si hay
            if let location = userLocationManager.userLocation {
                selectedCoordinate = location
                mapPosition = .region(MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))
                addressText = userLocationManager.userAddress
            }
        }
    }
    
    private func confirmLocation() {
        guard let coordinate = selectedCoordinate else { return }
        
        if showConfirmation {
            dismiss()
            return
        }
        
        isConfirming = true
        
        Task {
            await userLocationManager.updateLocation(coordinate: coordinate)
            
            await MainActor.run {
                isConfirming = false
                withAnimation(.spring(response: 0.4)) {
                    showConfirmation = true
                }
            }
            
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        }
    }
    
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        Task {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    var components: [String] = []
                    if let name = placemark.name { components.append(name) }
                    else if let thoroughfare = placemark.thoroughfare { components.append(thoroughfare) }
                    if let locality = placemark.locality { components.append(locality) }
                    
                    await MainActor.run {
                        addressText = components.isEmpty ? "Ubicación seleccionada" : components.joined(separator: ", ")
                    }
                }
            } catch {
                await MainActor.run {
                    addressText = "Ubicación seleccionada"
                }
            }
        }
    }
}

#Preview {
    ProfileLocationPickerView()
}
