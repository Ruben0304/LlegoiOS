import SwiftUI
import Combine
import UIKit

/// Toolbar items can live in a different hosting view. Measure every anchor
/// in window coordinates so the flight crosses the navigation bar correctly.
struct CartFlightFrameReader: UIViewRepresentable {
    let onChange: (CGRect) -> Void

    func makeUIView(context: Context) -> FrameView {
        let view = FrameView()
        view.isUserInteractionEnabled = false
        view.report = onChange
        return view
    }

    func updateUIView(_ uiView: FrameView, context: Context) {
        uiView.report = onChange
        uiView.setNeedsLayout()
    }

    final class FrameView: UIView {
        var report: ((CGRect) -> Void)?
        private var lastFrame: CGRect?

        override func layoutSubviews() {
            super.layoutSubviews()
            reportFrame()
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            lastFrame = nil
            reportFrame()
        }

        private func reportFrame() {
            guard let window, !bounds.isEmpty else { return }
            let frame = convert(bounds, to: window)
            guard frame != lastFrame else { return }
            lastFrame = frame
            DispatchQueue.main.async { [weak self] in
                guard let self, self.window != nil else { return }
                self.report?(frame)
            }
        }
    }
}

struct CartFlightPhoto {
    let url: URL?
    let cachedImage: UIImage?

    init(imageURL: String?, cacheKey: String?) {
        url = imageURL.flatMap(URL.init(string:))
        // Reuse the hero's already decoded photo so it is visible immediately.
        // Never block the purchase on another image request or a disk decode.
        let urlKey = url?.absoluteString ?? ""
        let heroKey = cacheKey.map { urlKey.isEmpty ? $0 : "\($0)|\(urlKey)" } ?? urlKey
        cachedImage = ImageCacheManager.shared.getMemoryImage(for: heroKey)
            ?? ImageCacheManager.shared.getMemoryImage(for: urlKey)
    }
}

@MainActor
final class CartPackageAnimation: ObservableObject {
    struct Flight: Identifiable {
        let id = UUID()
        let source: CGPoint
        let destination: CGPoint
        let photo: CartFlightPhoto
        let isFirstAddition: Bool
        let historyKey: String
    }

    var sourceFrame: CGRect = .zero
    var destinationFrame: CGRect = .zero
    @Published private(set) var flight: Flight?
    @Published private(set) var arrivalCount = 0

    private let defaults: UserDefaults

    #if DEBUG
    // Re-arm one celebration for a device test without removing the app's data.
    private static var pendingCelebrationReplay = ProcessInfo.processInfo.arguments.contains("--replay-cart-celebration")
    #endif

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func launch(imageURL: String?, cacheKey: String?, reduceMotion: Bool) {
        let customer = AuthManager.shared.userId ?? "guest"
        let historyKey = "llego.cart.first-add-animation.v12.\(customer)"
        var firstAddition = !defaults.bool(forKey: historyKey)
        #if DEBUG
        firstAddition = firstAddition || Self.pendingCelebrationReplay
        #endif
        if !firstAddition && (reduceMotion || sourceFrame.isEmpty || destinationFrame.isEmpty) {
            arrivalCount += 1
            return
        }
        flight = Flight(
            source: CGPoint(x: sourceFrame.midX, y: sourceFrame.midY),
            destination: CGPoint(x: destinationFrame.midX, y: destinationFrame.midY),
            photo: CartFlightPhoto(imageURL: imageURL, cacheKey: cacheKey),
            isFirstAddition: firstAddition, historyKey: historyKey)
    }

    func arrive(id: UUID) {
        guard flight?.id == id else { return }
        if let flight, flight.isFirstAddition {
            defaults.set(true, forKey: flight.historyKey)
            #if DEBUG
            Self.pendingCelebrationReplay = false
            #endif
        }
        flight = nil
        arrivalCount += 1
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.65)
    }

    func cancel() {
        flight = nil
    }
}

/// Lives above the NavigationStack so the package can reach the toolbar.
struct CartPackageFlightOverlay: View {
    @ObservedObject var animation: CartPackageAnimation
    let accent: Color
    @State private var overlayFrame: CGRect = .zero

    var body: some View {
        GeometryReader { proxy in
            if let flight = animation.flight {
                let origin = overlayFrame.origin
                Group {
                    if flight.isFirstAddition {
                        FirstCartCelebration(photo: flight.photo, accent: accent) {
                            animation.arrive(id: flight.id)
                        }
                    } else {
                        CartPackageFlight(
                            source: CGPoint(x: flight.source.x - origin.x, y: flight.source.y - origin.y),
                            destination: CGPoint(x: flight.destination.x - origin.x, y: flight.destination.y - origin.y),
                            accent: accent, photo: flight.photo,
                            viewportWidth: proxy.size.width,
                            onArrival: { animation.arrive(id: flight.id) })
                    }
                }
                .id(flight.id)
            }
        }
        .background(CartFlightFrameReader {
            overlayFrame = $0
        })
        .ignoresSafeArea()
        .allowsHitTesting(animation.flight?.isFirstAddition == true)
        .accessibilityHidden(animation.flight?.isFirstAddition != true)
    }
}

struct CartPackageFlight: View {
    let source: CGPoint
    let destination: CGPoint
    let accent: Color
    let photo: CartFlightPhoto
    let viewportWidth: CGFloat
    let onArrival: () -> Void
    var trajectory: CartFlightTrajectory? = nil
    @State private var progress: CGFloat = 0

    var body: some View {
        PackageFlightVisual(
            source: source, destination: destination, accent: accent, photo: photo,
            arcsToRight: true, viewportWidth: viewportWidth, progress: progress, trajectory: trajectory)
            .task {
                do {
                    try await Task.sleep(for: .milliseconds(20))
                    withAnimation(.timingCurve(0.3, 0.08, 0.35, 1, duration: trajectory?.duration ?? 0.65)) {
                        progress = 1
                    }
                    try await Task.sleep(for: .seconds(trajectory?.duration ?? 0.65))
                    try Task.checkCancellation()
                    onArrival()
                } catch { /* Leaving the screen cancels the flight. */ }
            }
    }
}

/// Interpolating progress here keeps the whole flight on its curved path.
private struct PackageFlightVisual: View, Animatable {
    let source: CGPoint
    let destination: CGPoint
    let accent: Color
    let photo: CartFlightPhoto
    let arcsToRight: Bool
    let viewportWidth: CGFloat
    var progress: CGFloat
    var trajectory: CartFlightTrajectory? = nil

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        ZStack {
            // Draw the tail with the same curve parameter as the photo, so its
            // bright leading edge stays attached throughout the flight.
            Canvas { context, _ in
                let start = max(0, progress - 0.3)
                for index in 0..<28 {
                    let fraction = CGFloat(index + 1) / 28
                    let from = start + (progress - start) * CGFloat(index) / 28
                    let to = start + (progress - start) * fraction
                    var segment = Path()
                    segment.move(to: position(at: from))
                    segment.addLine(to: position(at: to))
                    let opacity = Double(pow(fraction, 1.6)) * visibility
                    context.stroke(
                        segment, with: .color(accent.opacity(opacity * 0.24)),
                        style: StrokeStyle(lineWidth: 8 + 12 * fraction, lineCap: .round))
                    context.stroke(
                        segment, with: .color(accent.opacity(opacity * 0.85)),
                        style: StrokeStyle(lineWidth: 2 + 5 * fraction, lineCap: .round))
                    context.stroke(
                        segment, with: .color(.white.opacity(opacity * 0.8)),
                        style: StrokeStyle(lineWidth: 0.5 + fraction, lineCap: .round))
                }
            }
            .shadow(color: accent.opacity(0.5), radius: 7)

            ForEach(0..<8) { index in
                let lag = CGFloat(index + 1) * 0.032
                let point = position(at: max(0, progress - lag))
                let side: CGFloat = index.isMultiple(of: 2) ? -1 : 1
                Image(systemName: index.isMultiple(of: 3) ? "sparkle" : "circle.fill")
                    .font(.system(size: index.isMultiple(of: 3) ? 10 : 4, weight: .semibold))
                    .foregroundStyle(index.isMultiple(of: 3) ? accent : accent.opacity(0.7))
                    .shadow(color: accent.opacity(0.6), radius: 4)
                    .opacity(visibility * Double(1 - lag * 2.4))
                    .scaleEffect(0.8 + 0.2 * sin(progress * 25 + CGFloat(index)))
                    .position(x: point.x + side * (10 + CGFloat(index) * 2), y: point.y + 5)
            }

            productThumbnail
                .rotationEffect(.degrees(-8 + 16 * sin(Double(progress) * .pi)))
                .scaleEffect((0.9 + sin(progress * .pi) * 0.22) * (1 - 0.78 * max(0, (progress - 0.88) / 0.12)))
                .opacity(visibility)
                .position(position(at: progress))
        }
    }

    private var productThumbnail: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.18))
                .frame(width: 68, height: 68)
                .blur(radius: 6)
            Group {
                if let image = photo.cachedImage {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    CachedAsyncImage(
                        url: photo.url, cacheKey: "cart_flight_thumbnail",
                        displaySize: CGSize(width: thumbnailSize, height: thumbnailSize),
                        content: { $0.resizable().scaledToFill() },
                        placeholder: { thumbnailPlaceholder },
                        failure: { thumbnailPlaceholder })
                }
            }
            .frame(width: thumbnailSize, height: thumbnailSize)
            .clipShape(Circle())
            .overlay { Circle().strokeBorder(.white.opacity(0.95), lineWidth: 2.5) }
            .shadow(color: .black.opacity(0.24), radius: 7, x: 0, y: 5)
        }
    }

    private var thumbnailSize: CGFloat { trajectory?.style.thumbnailSize ?? 56 }

    private var thumbnailPlaceholder: some View {
        Circle().fill(.background)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(accent)
            }
    }

    private var visibility: Double {
        Double(min(1, progress / 0.035) * min(1, (1 - progress) / 0.055))
    }

    private func position(at t: CGFloat) -> CGPoint {
        if let trajectory { return trajectory.position(at: t) }
        let u = 1 - t
        let rise = max(0, source.y - destination.y)
        // Button launches bend to the right; hero absorption keeps its own arc.
        // Keep the reversed curve inside the screen, including its photo halo.
        let direction: CGFloat = arcsToRight ? 1 : -1
        let rightEdge = max(32, viewportWidth - 32)
        let first = CGPoint(
            x: min(rightEdge, max(32, source.x + direction * min(115, rise * 0.22))),
            y: source.y - rise * 0.72)
        let second = CGPoint(
            x: min(rightEdge, max(32, destination.x + direction * min(145, rise * 0.25))),
            y: destination.y + rise * 0.08)
        return CGPoint(
            x: u * u * u * source.x + 3 * u * u * t * first.x + 3 * u * t * t * second.x + t * t * t * destination.x,
            y: u * u * u * source.y + 3 * u * u * t * first.y + 3 * u * t * t * second.y + t * t * t * destination.y)
    }
}
