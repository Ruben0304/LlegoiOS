import SwiftUI
import MapKit
import Combine

@available(iOS 26.0, *)
struct LiveOrderTrackingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var orderManager = OrderManager.shared
    @State private var showDriverInfo = false
    @State private var showChat = false
    @State private var hasAppeared = false
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var currentDriverIndex: Int = 0

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1143, longitude: -82.3673),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Mapa principal
                Map(coordinateRegion: $region, annotationItems: mapMarkers) { item in
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
                .overlay(
                    RouteOverlay(
                        startCoordinate: orderManager.currentOrder?.restaurantCoordinates.clLocationCoordinate ?? CLLocationCoordinate2D(),
                        endCoordinate: orderManager.currentOrder?.deliveryCoordinates.clLocationCoordinate ?? CLLocationCoordinate2D(),
                        driverLocation: orderManager.driverLocation,
                        region: $region
                    )
                )
                .ignoresSafeArea()

                // Botones flotantes sobre el mapa
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            // Botón de info
                            Button(action: {
                                showDriverInfo.toggle()
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Circle().fill(Color.llegoPrimary))
                                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                            }

                            // Botón de chat
                            Button(action: {
                                showChat = true
                            }) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Circle().fill(Color.llegoAccent))
                                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(action: {
                        dismiss()
                    })
                }

                ToolbarItem(placement: .principal) {
                    Text("Rastreando pedido")
                        .font(.headline)
                }
            }
            .sheet(isPresented: $showDriverInfo) {
                orderDetailsSheet
                    .presentationDetents([.height(350)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showChat) {
                ChatView()
            }
        }
        .onAppear {
            generateRoute()
            updateMapRegion()
        }
        .onChange(of: orderManager.driverLocation) { _ in
            updateMapRegion()
            updateDriverRouteIndex()
        }
    }

    private func generateRoute() {
        guard let order = orderManager.currentOrder else { return }

        let start = order.restaurantCoordinates.clLocationCoordinate
        let end = order.deliveryCoordinates.clLocationCoordinate

        routeCoordinates = generateRoutePoints(from: start, to: end)
    }

    private func generateRoutePoints(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        var points: [CLLocationCoordinate2D] = []
        let numberOfPoints = 40

        for i in 0...numberOfPoints {
            let progress = Double(i) / Double(numberOfPoints)
            let baseLat = start.latitude + (end.latitude - start.latitude) * progress
            let baseLon = start.longitude + (end.longitude - start.longitude) * progress
            let variation = sin(progress * .pi * 3) * 0.0005

            points.append(CLLocationCoordinate2D(
                latitude: baseLat + variation,
                longitude: baseLon + variation * 0.7
            ))
        }

        return points
    }

    private func updateDriverRouteIndex() {
        guard let driverLoc = orderManager.driverLocation else { return }

        // Encontrar el punto más cercano en la ruta
        var minDistance = Double.infinity
        var closestIndex = 0

        for (index, point) in routeCoordinates.enumerated() {
            let distance = sqrt(pow(point.latitude - driverLoc.latitude, 2) + pow(point.longitude - driverLoc.longitude, 2))
            if distance < minDistance {
                minDistance = distance
                closestIndex = index
            }
        }

        currentDriverIndex = closestIndex
    }

    // MARK: - Map Markers
    private var mapMarkers: [MapMarkerItem] {
        guard let order = orderManager.currentOrder,
              let driverLocation = orderManager.driverLocation else {
            return []
        }

        return [
            MapMarkerItem(
                id: "driver",
                coordinate: driverLocation,
                type: .driver
            ),
            MapMarkerItem(
                id: "destination",
                coordinate: order.deliveryCoordinates.clLocationCoordinate,
                type: .destination
            )
        ]
    }

    private var orderDetailsSheet: some View {
        VStack(spacing: 0) {

            // Header con estado del pedido
            HStack {
                VStack(alignment: .leading, spacing: 4) {

                    HStack(spacing: 6) {
                        Image(systemName: orderManager.orderStatus.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.llegoPrimary)

                        Text(orderManager.orderStatus.displayText)
                            .font(.headline)
                    }
                    .padding(.top, 14)

                    Text("\(orderManager.estimatedMinutesRemaining) min aprox.")
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
            if let order = orderManager.currentOrder {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.gray)
                        .font(.body)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dirección de entrega")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(order.deliveryLocation)
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

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(order.products) { product in
                                OrderProductRow(
                                    imageUrl: product.imageUrl,
                                    name: product.name,
                                    quantity: product.quantity
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }

            Spacer()
        }
    }

    private func updateMapRegion() {
        guard let order = orderManager.currentOrder,
              let driverLocation = orderManager.driverLocation else {
            return
        }

        let destinationLocation = order.deliveryCoordinates.clLocationCoordinate
        let locations = [driverLocation, destinationLocation]
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

                Image(systemName: "motorcycle")
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


#Preview {
    if #available(iOS 26.0, *) {
        NavigationStack {
            LiveOrderTrackingView()
        }
    }
}

