import Foundation
import CoreLocation
import MapKit
import Combine
import Apollo

/// Manager global para el estado de ubicación del usuario
/// Maneja la persistencia y sincronización con el backend
@MainActor
class UserLocationManager: NSObject, ObservableObject {
    static let shared = UserLocationManager()
    
    private let clManager = CLLocationManager()
    
    // Estado de ubicación
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var userAddress: String = "Seleccionar ubicación"
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationSet: Bool = false
    @Published var isUpdatingLocation: Bool = false

    // Radio de búsqueda seleccionado (nil = sin límite)
    @Published var searchRadiusKm: Double? = nil

    // true cuando la ubicación activa es el fallback de La Habana (puede ser sobreescrita por GPS)
    private(set) var isAutoFallback: Bool = false

    private static let havanaCoordinate = CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666)
    private static let havanaAddress = "La Habana, Cuba"

    private let locationKey = "user_location_v1"
    private let radiusKey = "user_search_radius_v1"

    private override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = clManager.authorizationStatus
        loadSavedLocation()
    }
    
    // MARK: - Public Methods

    var hasLocation: Bool {
        return userLocation != nil && isLocationSet
    }

    /// Arranca el GPS silenciosamente. Llamar al inicio de la app.
    func startAutoLocation() {
        guard !isLocationSet || isAutoFallback else { return }
        switch clManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            clManager.requestLocation()
        case .notDetermined:
            clManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    /// Si todavía no hay ubicación al renderizar Home, usa La Habana como fallback.
    func applyHavanaFallbackIfNeeded() {
        guard !isLocationSet else { return }
        userLocation = Self.havanaCoordinate
        userAddress = Self.havanaAddress
        isLocationSet = true
        isAutoFallback = true
        saveLocation(Self.havanaCoordinate, isAutoFallback: true)
    }

    /// Solicita permisos de ubicación
    func requestPermission() {
        clManager.requestWhenInUseAuthorization()
    }

    /// Obtiene la ubicación actual del dispositivo
    func getCurrentDeviceLocation() {
        clManager.requestLocation()
    }

    /// Actualiza la ubicación del usuario (desde el mapa o GPS automático)
    func updateLocation(coordinate: CLLocationCoordinate2D) async {
        isUpdatingLocation = true

        userLocation = coordinate
        isLocationSet = true
        isAutoFallback = false

        saveLocation(coordinate)

        await reverseGeocode(coordinate: coordinate)
        await syncLocationWithBackend(coordinate: coordinate)

        isUpdatingLocation = false
    }
    
    /// Establece el radio de búsqueda
    func setSearchRadius(_ radiusKm: Double?) {
        if let radius = radiusKm, radius >= 50 {
            // 50+ significa sin límite
            searchRadiusKm = nil
        } else {
            searchRadiusKm = radiusKm
        }
        saveRadius()
    }
    
    /// Limpia la ubicación del usuario
    func clearLocation() {
        userLocation = nil
        userAddress = "Seleccionar ubicación"
        isLocationSet = false
        UserDefaults.standard.removeObject(forKey: locationKey)
    }
    
    // MARK: - Private Methods
    
    private func loadSavedLocation() {
        if let data = UserDefaults.standard.data(forKey: locationKey),
           let saved = try? JSONDecoder().decode(SavedLocation.self, from: data) {
            userLocation = CLLocationCoordinate2D(latitude: saved.latitude, longitude: saved.longitude)
            userAddress = saved.address
            isLocationSet = true
            isAutoFallback = saved.isAutoFallback
        }

        if let radius = UserDefaults.standard.object(forKey: radiusKey) as? Double {
            searchRadiusKm = radius > 0 ? radius : nil
        }
    }

    private func saveLocation(_ coordinate: CLLocationCoordinate2D, isAutoFallback: Bool = false) {
        let saved = SavedLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            address: userAddress,
            isAutoFallback: isAutoFallback
        )
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: locationKey)
        }
    }
    
    private func saveRadius() {
        if let radius = searchRadiusKm {
            UserDefaults.standard.set(radius, forKey: radiusKey)
        } else {
            UserDefaults.standard.removeObject(forKey: radiusKey)
        }
    }
    
    private func reverseGeocodeAsync(coordinate: CLLocationCoordinate2D) async -> String {
        await Task.detached(priority: .userInitiated) { () -> String in
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            if #available(iOS 26.0, *), let request = MKReverseGeocodingRequest(location: location) {
                do {
                    let mapItems = try await request.mapItems
                    if let mapItem = mapItems.first {
                        var addressComponents: [String] = []
                        if let name = mapItem.name, !name.isEmpty {
                            addressComponents.append(name)
                        }
                        if let locality = mapItem.addressRepresentations?.cityName, !locality.isEmpty {
                            addressComponents.append(locality)
                        }

                        if !addressComponents.isEmpty {
                            return addressComponents.joined(separator: ", ")
                        }
                    }
                    return "Lat: \(String(format: "%.4f", coordinate.latitude)), Lng: \(String(format: "%.4f", coordinate.longitude))"
                } catch {
                    print("Error reverse geocoding: \(error.localizedDescription)")
                    return "Ubicación seleccionada"
                }
            } else {
                let geocoder = CLGeocoder()
                do {
                    let placemarks = try await geocoder.reverseGeocodeLocation(location)
                    if let placemark = placemarks.first {
                        let parts = [placemark.name, placemark.locality].compactMap { $0 }
                        return parts.isEmpty ? "Ubicación seleccionada" : parts.joined(separator: ", ")
                    }
                    return "Ubicación seleccionada"
                } catch {
                    print("Error reverse geocoding: \(error.localizedDescription)")
                    return "Ubicación seleccionada"
                }
            }
        }.value
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) async {
        let address = await reverseGeocodeAsync(coordinate: coordinate)
        userAddress = address
        // Actualizar el guardado con la dirección
        saveLocation(coordinate)
    }
    
    private func syncLocationWithBackend(coordinate: CLLocationCoordinate2D) async {
        guard let token = AuthManager.shared.getAccessToken() else {
            print("⚠️ No hay token para sincronizar ubicación")
            return
        }
        
        do {
            try await LocationSyncRepository.shared.updateLocation(
                longitude: coordinate.longitude,
                latitude: coordinate.latitude,
                jwt: token
            )
            print("✅ Ubicación sincronizada con backend")
        } catch {
            print("❌ Error sincronizando ubicación: \(error.localizedDescription)")
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension UserLocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.first?.coordinate else { return }
        Task { @MainActor in
            // Aplicar GPS si aún no hay ubicación o si sólo tenemos el fallback de La Habana
            guard !self.isLocationSet || self.isAutoFallback else { return }
            await self.updateLocation(coordinate: coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if (status == .authorizedWhenInUse || status == .authorizedAlways) &&
               (!self.isLocationSet || self.isAutoFallback) {
                self.clManager.requestLocation()
            }
        }
    }
}

// MARK: - Models
private struct SavedLocation: Codable {
    let latitude: Double
    let longitude: Double
    let address: String
    var isAutoFallback: Bool = false
}

// MARK: - Location Sync Repository
final class LocationSyncRepository: @unchecked Sendable {
    static let shared = LocationSyncRepository()
    private let apolloClient = ApolloClientManager.shared.apollo
    
    private init() {}
    
    func updateLocation(longitude: Double, latitude: Double, jwt: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let input = LlegoAPI.UpdateLocationInput(longitude: longitude, latitude: latitude)
            let mutation = LlegoAPI.UpdateLocationMutation(input: input, jwt: .some(jwt))
            
            apolloClient.performCompat(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (updateLocation):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error desconocido"]
                        ))
                        return
                    }
                    continuation.resume()
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
