import SwiftUI
import MapKit
import Combine

@available(iOS 26.0, *)
struct LiveOrderTrackingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var trackingManager = OrderTrackingManager()
    @State private var showDriverInfo = false
    @State private var hasAppeared = false

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1143, longitude: -82.3673),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Mapa principal
                Map(coordinateRegion: $region, annotationItems: [
                    MapMarkerItem(
                        id: "driver",
                        coordinate: trackingManager.driverLocation,
                        type: .driver
                    ),
                    MapMarkerItem(
                        id: "destination",
                        coordinate: trackingManager.destinationLocation,
                        type: .destination
                    )
                ]) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        Button(action: {
                            if item.type == .driver {
                                withAnimation(.spring()) {
                                    showDriverInfo.toggle()
                                }
                            }
                        }) {
                            AnnotationMarker(type: item.type)
                        }
                    }
                }
                .ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Rastreando pedido")
                        .font(.headline)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showDriverInfo.toggle()
                    }) {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showDriverInfo) {
                orderDetailsSheet
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            trackingManager.startTracking()
            updateMapRegion()
        }
        .onDisappear {
            trackingManager.stopTracking()
        }
        .onChange(of: trackingManager.driverLocation) { _ in
            updateMapRegion()
        }
    }

    private var orderDetailsSheet: some View {
        VStack(spacing: 0) {

            // Header con botón de llamar
            HStack {
                VStack(alignment: .leading, spacing: 4) {

                    HStack(spacing: 6) {
                    
                        Text("Pedido en camino")
                            .font(.headline)
                    }
                    .padding(.top, 14)

                    Text("\(trackingManager.estimatedMinutes) min aprox.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    // Acción para llamar al mensajero
                }) {
                    Label("Llamar", systemImage: "phone.fill")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(Capsule().fill(Color.llegoPrimary))
                }
            }
            .padding()
            .padding(.top, 8)

            Divider()

            // Dirección de entrega
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "location.fill")
                    .foregroundColor(.gray)
                    .font(.body)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Dirección de entrega")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Calle 23 #456, Vedado, Havana")
                        .font(.subheadline)
                }

                Spacer()
            }
            .padding()

            Divider()

            // Contenido del pedido
            VStack(alignment: .leading, spacing: 5) {
                Text("Contenido del pedido")
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(spacing: 8) {
                    OrderProductRow(
                        imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen PNG.png",
                        name: "Pizza",
                        quantity: 2
                    )

                    OrderProductRow(
                        imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (13).png",
                        name: "Tres leches",
                        quantity: 1
                    )

                    OrderProductRow(
                        imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (17).png",
                        name: "Batido de mamey",
                        quantity: 1
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            Spacer()
        }
    }

    private func updateMapRegion() {
        let locations = [trackingManager.driverLocation, trackingManager.destinationLocation]
        let latitudes = locations.map { $0.latitude }
        let longitudes = locations.map { $0.longitude }

        guard let maxLat = latitudes.max(),
              let minLat = latitudes.min(),
              let maxLon = longitudes.max(),
              let minLon = longitudes.min() else { return }

        let center = CLLocationCoordinate2D(
            latitude: (maxLat + minLat) / 2,
            longitude: (maxLon + minLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.8, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.8, 0.01)
        )

        withAnimation {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

// MARK: - Order Product Row

struct OrderProductRow: View {
    let imageUrl: String
    let name: String
    let quantity: Int

    var body: some View {
        HStack(spacing: 12) {
            // Imagen del producto
            AsyncImage(url: URL(string: imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 35, height: 35)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 35, height: 35)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .frame(width: 35 ,height: 35)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                @unknown default:
                    EmptyView()
                }
            }

            // Nombre del producto
            Text(name)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            // Cantidad
            Text("\(quantity)x")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Supporting Types

struct MapMarkerItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: MarkerType
}

enum MarkerType {
    case driver
    case destination
}

struct AnnotationMarker: View {
    let type: MarkerType

    var body: some View {
        ZStack {
            if type == .driver {
                // Marcador del mensajero
                Circle()
                    .fill(.blue)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 3)
                    )
                    .shadow(radius: 4)

                Image(systemName: "bicycle")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .semibold))
            } else {
                // Marcador del destino
                VStack(spacing: 0) {
                    Circle()
                        .fill(.green)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        )
                        .overlay(
                            Image(systemName: "house.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        )

                    // Pin inferior
                    Triangle()
                        .fill(.green)
                        .frame(width: 12, height: 8)
                        .offset(y: -1)
                }
                .shadow(radius: 3)
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Order Tracking Manager

@available(iOS 26.0, *)
class OrderTrackingManager: ObservableObject {
    @Published var driverLocation = CLLocationCoordinate2D(latitude: 23.1150, longitude: -82.3680)
    @Published var destinationLocation = CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666)
    @Published var estimatedMinutes = 15

    private var timer: Timer?

    func startTracking() {
        // Simular actualización de ubicación del repartidor cada 3 segundos
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.updateDriverLocation()
        }
    }

    func stopTracking() {
        timer?.invalidate()
        timer = nil
    }

    private func updateDriverLocation() {
        // Simular movimiento del repartidor hacia el destino
        let latDiff = destinationLocation.latitude - driverLocation.latitude
        let lonDiff = destinationLocation.longitude - driverLocation.longitude

        withAnimation(.easeInOut(duration: 2.0)) {
            driverLocation.latitude += latDiff * 0.08
            driverLocation.longitude += lonDiff * 0.08

            // Actualizar tiempo estimado
            estimatedMinutes = max(2, estimatedMinutes - 1)
        }
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        NavigationStack {
            LiveOrderTrackingView()
        }
    }
}

