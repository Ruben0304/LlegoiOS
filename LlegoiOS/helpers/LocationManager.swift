import Foundation
import CoreLocation
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var location: CLLocationCoordinate2D?
    @Published var address: String = "Seleccionar ubicación"
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func getCurrentLocation() {
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first?.coordinate else { return }
        self.location = location
        reverseGeocode(coordinate: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        Task {
            let location = CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )

            guard let request = MKReverseGeocodingRequest(location: location) else {
                await MainActor.run {
                    self.address = "Ubicación seleccionada"
                }
                return
            }

            do {
                let mapItems = try await request.mapItems
                guard let mapItem = mapItems.first else {
                    await MainActor.run {
                        self.address = "Ubicación seleccionada"
                    }
                    return
                }

                // Keep it really simple - just use the name from mapItem
                let addressString: String
                if let name = mapItem.name, !name.isEmpty {
                    addressString = name
                } else {
                    // Fallback to coordinate display
                    addressString = "Lat: \(String(format: "%.4f", coordinate.latitude)), Lng: \(String(format: "%.4f", coordinate.longitude))"
                }

                await MainActor.run {
                    self.address = addressString
                }
            } catch {
                print("Error reverse geocoding: \(error.localizedDescription)")
                await MainActor.run {
                    self.address = "Ubicación seleccionada"
                }
            }
        }
    }

    func updateLocation(coordinate: CLLocationCoordinate2D) {
        self.location = coordinate
        reverseGeocode(coordinate: coordinate)
    }
}
