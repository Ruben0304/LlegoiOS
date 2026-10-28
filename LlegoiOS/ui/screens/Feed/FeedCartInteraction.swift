import SwiftUI
import Combine

/// Reads window coordinates at the moment of use, including any intervening scroll.
@MainActor
final class CartFlightAnchor {
    weak var view: UIView?

    var frame: CGRect {
        guard let view, let window = view.window, !view.bounds.isEmpty else { return .zero }
        return view.convert(view.bounds, to: window)
    }
}

struct CartFlightAnchorReader: UIViewRepresentable {
    let anchor: CartFlightAnchor

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        anchor.view = view
        return view
    }

    func updateUIView(_ view: UIView, context: Context) { anchor.view = view }
}

@MainActor
final class FeedCartInteraction: ObservableObject {
    struct Flight: Identifiable {
        let id = UUID()
        let source: CGPoint
        let destination: CGPoint
        let photo: CartFlightPhoto
        let style: CartFlightTrajectory.CardStyle
    }

    @Published private(set) var pendingProducts: Set<String> = []
    @Published private(set) var flights: [Flight] = []
    @Published private(set) var arrivalCount = 0
    @Published var productToCustomize: String?
    @Published var errorMessage: String?
    let cartAnchor = CartFlightAnchor()
    private let repository = ProductDetailRepository()

    func add(productID: String, photo: CartFlightPhoto, source: CartFlightAnchor,
             style: CartFlightTrajectory.CardStyle, reduceMotion: Bool) async -> Bool {
        guard pendingProducts.insert(productID).inserted else { return false }
        defer { pendingProducts.remove(productID) }
        let result = await withCheckedContinuation { continuation in
            repository.fetchProductDetail(id: productID) { continuation.resume(returning: $0) }
        }
        switch result {
        case .failure:
            errorMessage = "No pudimos comprobar este producto. Inténtalo de nuevo."
            return false
        case .success(let product):
            guard product.availability else {
                errorMessage = "Este producto ya no está disponible."
                return false
            }
            // The feed doesn't contain variant metadata. Resolve it before adding a cart line.
            if !(product.variantListIds ?? []).isEmpty || !(product.variantLists ?? []).isEmpty {
                productToCustomize = productID
                return false
            }
            CartManager.shared.addToCart(productId: productID, basePrice: product.price, finalUnitPrice: product.price)
            let origin = source.frame
            let target = cartAnchor.frame
            if !reduceMotion, !origin.isEmpty, !target.isEmpty,
               let window = source.view?.window, origin.intersects(window.bounds) {
                flights.append(Flight(source: CGPoint(x: origin.midX, y: origin.midY),
                                      destination: CGPoint(x: target.midX, y: target.midY),
                                      photo: photo, style: style))
            } else {
                acknowledgeArrival()
            }
            UIAccessibility.post(notification: .announcement, argument: "\(product.name), añadido al carrito")
            return true
        }
    }

    func arrive(id: UUID) {
        guard flights.contains(where: { $0.id == id }) else { return }
        flights.removeAll { $0.id == id }
        acknowledgeArrival()
    }

    private func acknowledgeArrival() {
        arrivalCount += 1
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.65)
    }
}

struct FeedAddToCartButton: View {
    let productID: String
    let name: String
    let imageURL: String?
    let cacheKey: String
    let available: Bool
    let style: CartFlightTrajectory.CardStyle
    @EnvironmentObject private var interaction: FeedCartInteraction
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var gradientManager = GradientStateManager.shared
    @State private var anchor = CartFlightAnchor()
    @State private var added = false

    init(product: FeedProduct, style: CartFlightTrajectory.CardStyle) {
        productID = product.id
        name = product.name
        let usesHero = style == .featured && !product.imageUrlMedia.isEmpty
        imageURL = usesHero ? product.imageUrlMedia : product.imageUrlBaja
        cacheKey = usesHero ? product.cachedKeyMedia : product.cachedKeyBaja
        available = product.availability
        self.style = style
    }

    init(item: ReorderItem, style: CartFlightTrajectory.CardStyle) {
        productID = item.productId
        name = item.name
        imageURL = item.imageUrl
        cacheKey = style == .inline ? "reorder_inline_\(item.productId)" : "reorder_\(item.productId)"
        available = true
        self.style = style
    }

    private var pending: Bool { interaction.pendingProducts.contains(productID) }

    var body: some View {
        Button {
            let photo = CartFlightPhoto(imageURL: imageURL, cacheKey: cacheKey)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            Task { @MainActor in
                guard await interaction.add(productID: productID, photo: photo, source: anchor,
                                            style: style, reduceMotion: reduceMotion) else { return }
                withAnimation(reduceMotion ? nil : .spring(duration: 0.25)) { added = true }
                try? await Task.sleep(for: .milliseconds(1100))
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) { added = false }
            }
        } label: {
            HStack(spacing: 6) {
                if pending {
                    ProgressView().tint(foreground).controlSize(.small)
                } else {
                    Image(systemName: added ? "checkmark" : "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                }
                if style != .compact {
                    Text(added ? "Añadido" : "Agregar")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, style == .compact ? 0 : 14)
            .frame(width: style == .compact ? 36 : nil, height: 36)
            .background {
                if style == .featured {
                    Capsule().fill(.regularMaterial)
                } else {
                    Capsule().fill(gradientManager.currentAccentColor)
                }
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(CartFlightAnchorReader(anchor: anchor))
        .disabled(pending || added || !available)
        .opacity(available ? 1 : 0.45)
        .accessibilityLabel(available ? "Agregar \(name) al carrito" : "\(name), no disponible")
        .accessibilityValue(pending ? "Comprobando producto" : added ? "Añadido" : "")
    }

    private var foreground: Color {
        style == .featured ? gradientManager.currentAccentColor : .white
    }
}

struct FeedCartFlightOverlay: View {
    @ObservedObject var interaction: FeedCartInteraction
    let accent: Color
    @State private var overlayFrame: CGRect = .zero

    var body: some View {
        GeometryReader { geometry in
            ForEach(interaction.flights) { flight in
                let source = CGPoint(x: flight.source.x - overlayFrame.minX, y: flight.source.y - overlayFrame.minY)
                let destination = CGPoint(x: flight.destination.x - overlayFrame.minX, y: flight.destination.y - overlayFrame.minY)
                let trajectory = CartFlightTrajectory(source: source, destination: destination,
                                                      viewport: geometry.size, style: flight.style)
                CartPackageFlight(source: source, destination: destination, accent: accent,
                                  photo: flight.photo, viewportWidth: geometry.size.width,
                                  onArrival: { interaction.arrive(id: flight.id) }, trajectory: trajectory)
            }
        }
        .background(CartFlightFrameReader { overlayFrame = $0 })
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
