import Foundation
import SwiftUI
import MapKit
import Combine

@MainActor
class StoreMapViewModel: ObservableObject {
    @Published var stores: [StoreWithCoordinates] = []
    @Published var isLoading: Bool = false
    
    private var hasLoaded: Bool = false
    private let repository = StoreListRepository()
    
    func loadStores(isRefreshing: Bool = false) {
        if hasLoaded && !isRefreshing {
            return
        }
        
        if isRefreshing {
            stores = []
            hasLoaded = false
        }
        
        if !isRefreshing {
            isLoading = true
        }
        
        // Cargar todas las tiendas para el mapa (sin paginación limitada)
        repository.fetchBranches(first: 100, after: nil) { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isLoading = false
                
                switch result {
                case .success(let (branchesGraphQL, _)):
                    self.stores = branchesGraphQL.map { branchGraphQL in
                        StoreWithCoordinates(
                            id: branchGraphQL.id,
                            name: branchGraphQL.name,
                            etaMinutes: self.calculateETA(deliveryRadius: branchGraphQL.deliveryRadius),
                            logoUrl: branchGraphQL.avatarUrl ?? "",
                            bannerUrl: branchGraphQL.coverUrl ?? "",
                            address: branchGraphQL.address,
                            rating: nil,
                            description: "Descripción de la tienda que estará disponible próximamente",
                            coordinate: CLLocationCoordinate2D(
                                latitude: branchGraphQL.coordinates.latitude,
                                longitude: branchGraphQL.coordinates.longitude
                            )
                        )
                    }
                    self.hasLoaded = true
                    
                case .failure(let error):
                    print("❌ Error loading stores for map: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func calculateETA(deliveryRadius: Double?) -> Int {
        guard let radius = deliveryRadius else { return 20 }
        return Int(radius * 5 + 10)
    }
}
