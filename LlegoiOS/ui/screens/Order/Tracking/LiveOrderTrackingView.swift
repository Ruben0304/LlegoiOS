import MapKit
import SwiftUI

@available(iOS 26.0, *)
struct LiveOrderTrackingView: View {
    @ObservedObject var orderManager: OrderManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // URLs capturadas una sola vez para evitar recargas
    @State private var storeImageUrl: URL?
    @State private var userAvatarUrl: URL?
    @State private var storeUIImage: UIImage?
    @State private var userAvatarUIImage: UIImage?
    @State private var didCaptureUrls = false

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
            Map(position: mapPositionBinding) {
                ForEach(mapAnnotations) { item in
                    Annotation("", coordinate: item.coordinate) {
                        annotationView(for: item)
                    }
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
            captureUrlsOnce()
            fitMapToRoute()
        }
        .onChange(of: orderManager.currentOrder?.id) { _, _ in
            storeUIImage = nil
            userAvatarUIImage = nil
            storeImageUrl = nil
            userAvatarUrl = nil
            didCaptureUrls = false
            captureUrlsOnce()
        }
        .onChange(of: orderManager.currentOrder?.storeImageUrl) { _, _ in
            storeUIImage = nil
            storeImageUrl = nil
            didCaptureUrls = false
            captureUrlsOnce()
        }
        .onChange(of: orderManager.currentOrder?.userAvatarUrl) { _, _ in
            userAvatarUIImage = nil
            userAvatarUrl = nil
            didCaptureUrls = false
            captureUrlsOnce()
        }
        .onChange(of: orderManager.driverLocation?.latitude) { _, _ in
            centerOnDriver()
        }
        .onChange(of: orderManager.driverLocation?.longitude) { _, _ in
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

    // MARK: - Capture URLs Once

    private func captureUrlsOnce() {
        guard !didCaptureUrls, let order = orderManager.currentOrder else { return }
        if let urlString = order.storeImageUrl, !urlString.isEmpty {
            storeImageUrl = URL(string: urlString)
        }
        if let urlString = order.userAvatarUrl, !urlString.isEmpty {
            userAvatarUrl = URL(string: urlString)
        }
        preloadImages()
        didCaptureUrls = true
    }

    private var stableStoreCacheKey: String {
        "live_tracking_store_\(orderManager.currentOrder?.id ?? "none")"
    }

    private var stableUserCacheKey: String {
        "live_tracking_user_\(orderManager.currentOrder?.id ?? "none")"
    }

    private func preloadImages() {
        preloadImage(url: storeImageUrl, cacheKey: stableStoreCacheKey) { image in
            self.storeUIImage = image
        }
        preloadImage(url: userAvatarUrl, cacheKey: stableUserCacheKey) { image in
            self.userAvatarUIImage = image
        }
    }

    private func preloadImage(
        url: URL?,
        cacheKey: String,
        onLoaded: @escaping @MainActor (UIImage?) -> Void
    ) {
        guard let url else {
            Task { @MainActor in
                onLoaded(nil)
            }
            return
        }

        if let cached = ImageCacheManager.shared.getImage(for: cacheKey) {
            Task { @MainActor in
                onLoaded(cached)
            }
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let image = UIImage(data: data) else {
                Task { @MainActor in
                    onLoaded(nil)
                }
                return
            }
            ImageCacheManager.shared.setImage(image, for: cacheKey)
            Task { @MainActor in
                onLoaded(image)
            }
        }.resume()
    }

    @ViewBuilder
    private func annotationView(for item: LiveMapAnnotation) -> some View {
        switch item.type {
        case .store:
            ZStack {
                Circle()
                    .fill(Color.llegoTertiary)
                    .frame(width: 44, height: 44)
                Group {
                    if let image = storeUIImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        CachedAsyncImage(
                            url: storeImageUrl,
                            cacheKey: stableStoreCacheKey
                        ) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image("generic_logo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } failure: {
                            Image("generic_logo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            }
            .overlay(
                Circle()
                    .stroke(Color.llegoTertiary, lineWidth: 2.5)
                    .frame(width: 44, height: 44)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

        case .destination:
            ZStack {
                Circle()
                    .fill(Color.llegoPrimary)
                    .frame(width: 44, height: 44)
                Group {
                    if let image = userAvatarUIImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        CachedAsyncImage(
                            url: userAvatarUrl,
                            cacheKey: stableUserCacheKey
                        ) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        } failure: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            }
            .overlay(
                Circle()
                    .stroke(Color.llegoPrimary, lineWidth: 2.5)
                    .frame(width: 44, height: 44)
            )
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

    private var mapPositionBinding: Binding<MapCameraPosition> {
        Binding(
            get: { .region(region) },
            set: { newPosition in
                _ = newPosition
            }
        )
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
