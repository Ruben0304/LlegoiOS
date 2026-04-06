import Combine
import MapKit
import SwiftUI

struct OrderTrackingView: View {
    @StateObject private var viewModel: OrderTrackingViewModel
    @ObservedObject private var cartManager = CartManager.shared
    @State private var now = Date()
    @State private var showReplaceCartAlert = false
    @State private var showCartEditor = false
    private let deadlineTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    init(orderId: String) {
        _viewModel = StateObject(wrappedValue: OrderTrackingViewModel(orderId: orderId))
    }

    var body: some View {
        ZStack {
            if viewModel.isPickupOrder {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            } else {
                // Map
                Map(position: mapPositionBinding) {
                    ForEach(mapAnnotations) { item in
                        Annotation("", coordinate: item.coordinate) {
                            annotationView(for: item)
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)
            }

            // Bottom sheet
            VStack {
                Spacer()
                trackingSheet
            }
        }
        .navigationTitle("Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reemplazar carrito", isPresented: $showReplaceCartAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Continuar", role: .destructive) {
                openCartEditor()
            }
        } message: {
            Text("Los productos del carrito actual se reemplazarán por los de este pedido.")
        }
        .fullScreenCover(isPresented: $showCartEditor) {
            NavigationStack {
                CartView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            CloseButton {
                                showCartEditor = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            updateMapRegion()
        }
        .onReceive(viewModel.$currentDeliveryLocation) { _ in
            updateMapRegion()
        }
        .onReceive(deadlineTimer) { now = $0 }
    }

    // MARK: - Map Annotations

    private var mapAnnotations: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = []

        if let store = viewModel.storeLocation {
            items.append(MapAnnotationItem(id: "store", coordinate: store, type: .store))
        }

        if let delivery = viewModel.deliveryLocation {
            items.append(MapAnnotationItem(id: "delivery", coordinate: delivery, type: .delivery))
        }

        if let driver = viewModel.currentDeliveryLocation {
            items.append(MapAnnotationItem(id: "driver", coordinate: driver, type: .driver))
        }

        return items
    }

    private func annotationView(for item: MapAnnotationItem) -> some View {
        ZStack {
            Circle()
                .fill(item.type.color)
                .frame(width: 36, height: 36)

            Image(systemName: item.type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .shadow(radius: 4)
    }

    private func updateMapRegion() {
        guard !viewModel.isPickupOrder else { return }
        guard let store = viewModel.storeLocation,
            let delivery = viewModel.deliveryLocation
        else { return }

        let center = CLLocationCoordinate2D(
            latitude: (store.latitude + delivery.latitude) / 2,
            longitude: (store.longitude + delivery.longitude) / 2
        )

        let latDelta = abs(store.latitude - delivery.latitude) * 1.5
        let lonDelta = abs(store.longitude - delivery.longitude) * 1.5

        region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.01), longitudeDelta: max(lonDelta, 0.01))
        )
    }

    private var mapPositionBinding: Binding<MapCameraPosition> {
        Binding(
            get: { .region(region) },
            set: { newPosition in
                _ = newPosition
            }
        )
    }

    // MARK: - Tracking Sheet

    private var trackingSheet: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            if viewModel.isLoading {
                ProgressView()
                    .padding(40)
            } else if let order = viewModel.order {
                let displayStatus = order.displayStatus
                VStack(spacing: 16) {
                    // Status header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayStatus.displayName)
                                .font(.headline)
                            let eta = viewModel.formattedETA
                            if eta != "--", !viewModel.isPickupOrder {
                                Text("Llegada estimada: \(eta)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else if viewModel.isPickupOrder {
                                Text("Estado de recogida en tienda")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // Status icon
                        Image(systemName: displayStatus.icon)
                            .font(.title)
                            .foregroundColor(displayStatus.color)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    if canEditProducts(order) {
                        Button {
                            handleEditProductsTap()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Modificar productos")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.llegoPrimary)
                        .padding(.horizontal, 20)
                    }

                    if OrderPermissionPolicy.shouldShowDeadline(status: order.status),
                        let deadlineAt = order.deadlineAt
                    {
                        HStack(spacing: 8) {
                            Image(systemName: deadlineAt <= now ? "clock.badge.xmark" : "hourglass")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(deadlineAt <= now ? .red : .orange)
                            Text(deadlineText(deadlineAt))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }

                    if OrderPermissionPolicy.isTimedOutCancellation(
                        status: order.status,
                        deadlineAt: order.deadlineAt
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                            Text("Pedido cancelado automáticamente por tiempo vencido")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }

                    // Progress bar
                    ProgressView(value: viewModel.statusProgress)
                        .tint(displayStatus.color)
                        .padding(.horizontal, 20)

                    Divider()

                    // Delivery person info
                    if let deliveryPerson = viewModel.deliveryPerson, !viewModel.isPickupOrder {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: deliveryPerson.profileImageUrl ?? "")) {
                                image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(deliveryPerson.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.yellow)
                                    Text(deliveryPerson.formattedRating)
                                        .font(.caption)
                                    Text("• \(deliveryPerson.vehicleType ?? "")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            // Call button
                            Button {
                                if let url = URL(string: "tel:\(deliveryPerson.phone)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.llegoPrimary)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Divider()

                    // Order summary
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(order.branchName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(order.items.count) items • \(order.formattedTotal)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        let distance = viewModel.formattedDistance
                        if distance != "--", !viewModel.isPickupOrder {
                            Text(distance)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Reintentar") { viewModel.load() }
                        .buttonStyle(.bordered)
                }
                .padding(40)
            }
        }
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }

    private func deadlineText(_ deadlineAt: Date) -> String {
        let remaining = Int(deadlineAt.timeIntervalSince(now))
        if remaining <= 0 {
            return "Tiempo vencido"
        }
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "Vence en %02d:%02d", minutes, seconds)
    }

    private func canEditProducts(_ order: OrderTrackingOrder) -> Bool {
        let status = order.displayStatus.normalizedForContract
        return status == .modifiedByStore || status == .accepted
    }

    private func handleEditProductsTap() {
        guard let order = viewModel.order, canEditProducts(order) else { return }
        let hasExistingCart = !cartManager.localItems.isEmpty || !cartManager.localShowcaseItems.isEmpty
        if hasExistingCart {
            showReplaceCartAlert = true
        } else {
            openCartEditor()
        }
    }

    private func openCartEditor() {
        guard let order = viewModel.order, canEditProducts(order) else { return }
        let cartItems = order.items.map { item in
            CartItemLocal(
                productId: item.productId,
                quantity: item.quantity,
                basePrice: item.price,
                finalUnitPrice: item.price
            )
        }
        cartManager.replaceCart(items: cartItems)
        showCartEditor = true
    }
}

// MARK: - Map Annotation Item

struct MapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType

    enum AnnotationType {
        case store, delivery, driver

        var icon: String {
            switch self {
            case .store: return "storefront.fill"
            case .delivery: return "house.fill"
            case .driver: return "car.fill"
            }
        }

        var color: Color {
            switch self {
            case .store: return .orange
            case .delivery: return .llegoPrimary
            case .driver: return .blue
            }
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        OrderTrackingView(orderId: "test-order-id")
    }
}
