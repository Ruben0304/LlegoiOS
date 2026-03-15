import SwiftUI

@available(iOS 26.0, *)
struct OrderTrackingCard: View {
    @Environment(\.tabViewBottomAccessoryPlacement) var placement
    @ObservedObject var orderManager: OrderManager
    @ObservedObject private var gradientManager = GradientStateManager.shared
    var onTap: () -> Void

    // URLs capturadas una sola vez para evitar que AsyncImage se recargue
    @State private var storeImageUrl: URL?
    @State private var userAvatarUrl: URL?
    @State private var storeUIImage: UIImage?
    @State private var userAvatarUIImage: UIImage?
    @State private var didCaptureUrls = false

    // Distancia restante formateada
    private var formattedDistance: String {
        let meters = orderManager.remainingDistanceMeters
        if meters <= 0 { return "0 m" }
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }

    // Calcular progreso del camión (0.0 a 1.0)
    private var deliveryProgress: CGFloat {
        guard orderManager.currentOrder != nil else { return 0 }

        switch orderManager.orderStatus {
        case .idle, .pending: return 0
        case .confirmed: return 0.15
        case .preparing: return 0.3
        case .inTransit: return 0.6
        case .nearDestination: return 0.9
        case .delivered: return 1.0
        case .cancelled: return 0
        }
    }

    // MARK: - Store Image (cached, stable URL)

    private var storeImageView: some View {
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
    }

    // MARK: - User Avatar (cached, stable URL)

    private var userAvatarView: some View {
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
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                } failure: {
                    Image(systemName: "person.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    private var stableStoreCacheKey: String {
        "tracking_store_\(orderManager.currentOrder?.id ?? "none")"
    }

    private var stableUserCacheKey: String {
        "tracking_user_\(orderManager.currentOrder?.id ?? "none")"
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            if placement != .inline {
                expandedLayout
            } else {
                inlineLayout
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onAppear {
            captureUrlsOnce()
        }
        .onChange(of: orderManager.currentOrder?.id) { _, _ in
            // Si cambia de pedido, recapturar URLs
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
    }

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
        onLoaded: @escaping (UIImage?) -> Void
    ) {
        guard let url else {
            onLoaded(nil)
            return
        }

        if let cached = ImageCacheManager.shared.getImage(for: cacheKey) {
            onLoaded(cached)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { onLoaded(nil) }
                return
            }
            ImageCacheManager.shared.setImage(image, for: cacheKey)
            DispatchQueue.main.async { onLoaded(image) }
        }.resume()
    }

    // MARK: - Expanded Layout

    private var expandedLayout: some View {
        HStack(spacing: 0) {
            // Origen: logo de la tienda
            VStack(spacing: 4) {
                storeImageView
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .background(
                        Circle()
                            .fill(Color.llegoTertiary)
                            .frame(width: 30, height: 30)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.llegoTertiary.opacity(0.3), lineWidth: 1.5)
                    )

                Text("Origen")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)

            // Línea de progreso con bicicleta
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Línea de fondo
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: geometry.size.width, height: 3)

                    // Línea de progreso
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    gradientManager.currentAccentColor,
                                    Color.llegoAccent,
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * deliveryProgress, height: 3)
                        .animation(.easeInOut(duration: 0.8), value: deliveryProgress)

                    // Bicicleta animada
                    Image(systemName: "bicycle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(gradientManager.currentAccentColor)
                        .offset(
                            x: max(
                                0,
                                min(
                                    (geometry.size.width * deliveryProgress) - 8,
                                    geometry.size.width - 16))
                        )
                        .animation(.easeInOut(duration: 0.8), value: deliveryProgress)
                }
                .frame(height: 20)
            }
            .frame(height: 20)
            .padding(.horizontal, 8)

            // Destino: avatar del usuario
            VStack(spacing: 4) {
                userAvatarView
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .background(
                        Circle()
                            .fill(
                                deliveryProgress >= 1.0
                                    ? Color.llegoAccent : Color.gray.opacity(0.4)
                            )
                            .frame(width: 30, height: 30)
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                deliveryProgress >= 1.0
                                    ? Color.llegoAccent.opacity(0.5)
                                    : Color.gray.opacity(0.2),
                                lineWidth: 1.5
                            )
                    )

                Text("Destino")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(deliveryProgress >= 1.0 ? .llegoAccent : .secondary)
            }
            .frame(width: 50)

            // Distancia restante
            if orderManager.remainingDistanceMeters > 0 {
                VStack(spacing: 2) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.llegoAccent)
                    Text(formattedDistance)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(gradientManager.currentAccentColor)
                }
                .frame(width: 55)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Inline (Compact) Layout

    private var inlineLayout: some View {
        HStack(spacing: 0) {
            // Origen: logo de la tienda (compacto)
            storeImageView
                .frame(width: 24, height: 24)
                .clipShape(Circle())
                .background(
                    Circle()
                        .fill(Color.llegoTertiary)
                        .frame(width: 24, height: 24)
                )

            // Barra de progreso
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: geometry.size.width, height: 3)

                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    gradientManager.currentAccentColor,
                                    Color.llegoAccent,
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * deliveryProgress, height: 3)
                        .animation(.easeInOut(duration: 0.8), value: deliveryProgress)

                    Image(systemName: "bicycle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(gradientManager.currentAccentColor)
                        .offset(
                            x: max(
                                0,
                                min(
                                    (geometry.size.width * deliveryProgress) - 8,
                                    geometry.size.width - 16))
                        )
                        .animation(.easeInOut(duration: 0.8), value: deliveryProgress)
                }
                .frame(height: 20)
            }
            .frame(height: 20)
            .padding(.horizontal, 8)

            // Destino: avatar del usuario (compacto)
            userAvatarView
                .frame(width: 24, height: 24)
                .clipShape(Circle())
                .background(
                    Circle()
                        .fill(deliveryProgress >= 1.0 ? Color.llegoAccent : Color.gray.opacity(0.4))
                        .frame(width: 24, height: 24)
                )
        }
    }
}
