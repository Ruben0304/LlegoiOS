import MapKit
import SwiftUI

@available(iOS 26.0, *)
struct LiveOrderTrackingView: View {
    @ObservedObject var orderManager: OrderManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    // MARK: - Computed Properties

    private var formattedDistance: String {
        let meters = orderManager.remainingDistanceMeters
        if meters <= 0 { return "Llegó" }
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }

    private var mapAnnotations: [LiveMapAnnotation] {
        var items: [LiveMapAnnotation] = []

        if let order = orderManager.currentOrder {
            items.append(
                LiveMapAnnotation(
                    id: "store",
                    coordinate: order.restaurantCoordinates.clLocationCoordinate,
                    type: .store
                )
            )
            items.append(
                LiveMapAnnotation(
                    id: "destination",
                    coordinate: order.deliveryCoordinates.clLocationCoordinate,
                    type: .destination
                )
            )
        }

        if let driver = orderManager.driverLocation {
            items.append(
                LiveMapAnnotation(
                    id: "driver",
                    coordinate: driver,
                    type: .driver
                )
            )
        }

        return items
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Mapa limpio a pantalla completa
            Map(coordinateRegion: $region, annotationItems: mapAnnotations) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    annotationView(for: item)
                }
            }
            .ignoresSafeArea()

            // Chip flotante de distancia restante
            if orderManager.currentOrder != nil {
                VStack {
                    Spacer()

                    distanceChip
                        .padding(.bottom, 48)
                }
            }
        }
        .navigationTitle("Seguimiento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.primary)
                }
            }
        }
        .onAppear {
            fitMapToRoute()
        }
        .onChange(of: orderManager.driverLocation?.latitude) { _ in
            centerOnDriver()
        }
        .onChange(of: orderManager.driverLocation?.longitude) { _ in
            centerOnDriver()
        }
    }

    // MARK: - Distance Chip

    private var distanceChip: some View {
        HStack(spacing: 8) {
            Image(systemName: "location.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.llegoAccent)

            Text(formattedDistance)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))

            Text("•")
                .foregroundColor(.secondary)

            Text(orderManager.orderStatus.displayText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        )
    }

    // MARK: - Map Annotations

    @ViewBuilder
    private func annotationView(for item: LiveMapAnnotation) -> some View {
        switch item.type {
        case .store:
            ZStack {
                Circle()
                    .fill(Color.llegoTertiary)
                    .frame(width: 40, height: 40)
                Image(systemName: "storefront.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

        case .destination:
            ZStack {
                Circle()
                    .fill(Color.llegoPrimary)
                    .frame(width: 40, height: 40)
                Image(systemName: "house.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

        case .driver:
            ZStack {
                Circle()
                    .fill(Color.llegoAccent)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                Image(systemName: "bicycle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.llegoAccent.opacity(0.4), radius: 8, y: 2)
        }
    }

    // MARK: - Map Helpers

    private func fitMapToRoute() {
        guard let order = orderManager.currentOrder else { return }

        let store = order.restaurantCoordinates.clLocationCoordinate
        let delivery = order.deliveryCoordinates.clLocationCoordinate

        let center = CLLocationCoordinate2D(
            latitude: (store.latitude + delivery.latitude) / 2,
            longitude: (store.longitude + delivery.longitude) / 2
        )

        let latDelta = abs(store.latitude - delivery.latitude) * 2.5
        let lonDelta = abs(store.longitude - delivery.longitude) * 2.5

        withAnimation {
            region = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(
                    latitudeDelta: max(latDelta, 0.008),
                    longitudeDelta: max(lonDelta, 0.008)
                )
            )
        }
    }

    private func centerOnDriver() {
        guard let driver = orderManager.driverLocation else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            region.center = driver
        }
    }
}

// MARK: - Map Annotation Model

struct LiveMapAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: LiveAnnotationType

    enum LiveAnnotationType {
        case store, destination, driver
    }
}
