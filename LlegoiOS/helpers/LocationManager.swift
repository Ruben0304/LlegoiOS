import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
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

    nonisolated func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        Task {
            let location = CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )

            let addressString: String

            if #available(iOS 26.0, *), let request = MKReverseGeocodingRequest(location: location) {
                do {
                    let mapItems = try await request.mapItems
                    if let mapItem = mapItems.first, let name = mapItem.name, !name.isEmpty {
                        addressString = name
                    } else {
                        // Fallback to coordinate display
                        addressString = "Lat: \(String(format: "%.4f", coordinate.latitude)), Lng: \(String(format: "%.4f", coordinate.longitude))"
                    }
                } catch {
                    print("Error reverse geocoding: \(error.localizedDescription)")
                    addressString = "Ubicación seleccionada"
                }
            } else {
                let geocoder = CLGeocoder()
                do {
                    let placemarks = try await geocoder.reverseGeocodeLocation(location)
                    if let placemark = placemarks.first {
                        let parts = [placemark.name, placemark.locality].compactMap { $0 }
                        addressString = parts.isEmpty ? "Ubicación seleccionada" : parts.joined(separator: ", ")
                    } else {
                        addressString = "Ubicación seleccionada"
                    }
                } catch {
                    print("Error reverse geocoding: \(error.localizedDescription)")
                    addressString = "Ubicación seleccionada"
                }
            }

            await MainActor.run {
                self.address = addressString
            }
        }
    }

    func updateLocation(coordinate: CLLocationCoordinate2D) {
        self.location = coordinate
        reverseGeocode(coordinate: coordinate)
    }

    func applyCachedLocation(coordinate: CLLocationCoordinate2D, address: String?) {
        self.location = coordinate
        if let address = address, !address.isEmpty {
            self.address = address
        }
    }
}
