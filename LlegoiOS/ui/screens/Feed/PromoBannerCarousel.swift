import SwiftUI
import UIKit

// MARK: - Promo Banner Carousel

/// Carrusel de banners promocionales 16:9 creados por Llego (`platformBanners`).
///
/// - Vacío: no ocupa espacio.
/// - Un banner: solo la tarjeta.
/// - Varios: carrusel paginado con indicador de puntos y avance automático
///   cada ~5 s, que se reinicia cuando el usuario cambia de página y se pausa
///   mientras arrastra (iOS 18+) o con Reducir movimiento activado.
struct PromoBannerCarousel: View {
    let banners: [FeedPlatformBanner]
    let accentColor: Color

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var currentId: String?
    @State private var isUserScrolling = false

    private static let autoAdvanceInterval: Duration = .seconds(5)

    var body: some View {
        if banners.count == 1, let banner = banners.first {
            PromoBannerCard(banner: banner)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
        } else if banners.count > 1 {
            carousel
                .padding(.vertical, 10)
        }
    }

    // MARK: Carousel

    private var carousel: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(banners) { banner in
                        PromoBannerCard(banner: banner)
                            .padding(.horizontal, 20)
                            .containerRelativeFrame(.horizontal)
                            .id(banner.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentId)
            .modifier(ScrollPhaseTracker(isUserScrolling: $isUserScrolling))

            pageIndicator
        }
        // Cada cambio de página (manual o automático) reinicia la cuenta atrás;
        // la tarea se cancela sola cuando el carrusel sale de pantalla.
        .task(id: AutoAdvanceKey(currentId: currentId, isPaused: isUserScrolling || reduceMotion)) {
            guard !isUserScrolling, !reduceMotion else { return }
            try? await Task.sleep(for: Self.autoAdvanceInterval)
            guard !Task.isCancelled, !isUserScrolling else { return }
            advance()
        }
        .onChange(of: banners.map(\.id)) { _, ids in
            if let currentId, !ids.contains(currentId) {
                self.currentId = nil
            }
        }
    }

    private var currentIndex: Int {
        guard let currentId, let index = banners.firstIndex(where: { $0.id == currentId }) else {
            return 0
        }
        return index
    }

    private func advance() {
        guard banners.count > 1 else { return }
        let next = (currentIndex + 1) % banners.count
        withAnimation(.easeInOut(duration: 0.45)) {
            currentId = banners[next].id
        }
    }

    // MARK: Page indicator

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(Array(banners.enumerated()), id: \.element.id) { index, _ in
                let isActive = index == currentIndex
                Capsule()
                    .fill(
                        isActive
                            ? accentColor
                            : Color.adaptiveOnSurface(colorScheme).opacity(0.18)
                    )
                    .frame(width: isActive ? 18 : 6, height: 6)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentIndex)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Promoción \(currentIndex + 1) de \(banners.count)")
    }

    private struct AutoAdvanceKey: Equatable {
        let currentId: String?
        let isPaused: Bool
    }
}

// MARK: - Scroll phase tracking

/// En iOS 18+ marca cuándo el usuario está arrastrando para pausar el avance
/// automático. En iOS 17 no hay API fiable: el temporizador simplemente se
/// reinicia en cada cambio de página.
private struct ScrollPhaseTracker: ViewModifier {
    @Binding var isUserScrolling: Bool

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollPhaseChange { _, newPhase in
                isUserScrolling = newPhase == .interacting || newPhase == .tracking
            }
        } else {
            content
        }
    }
}

// MARK: - Single banner card

private struct PromoBannerCard: View {
    let banner: FeedPlatformBanner

    private static let cornerRadius: CGFloat = 20
    /// Tamaño aproximado de render, solo para decodificar a la densidad justa.
    private static let displaySize = CGSize(width: 400, height: 225)

    var body: some View {
        if let branchId = banner.branchId {
            NavigationLink(destination: StoreDetailView(storeId: branchId)) {
                artwork
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityTitle)
        } else if let actionUrl = banner.actionUrl, let url = URL(string: actionUrl) {
            Button {
                UIApplication.shared.open(url)
            } label: {
                artwork
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityTitle)
        } else {
            artwork
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityTitle)
                .accessibilityAddTraits(.isImage)
        }
    }

    private var accessibilityTitle: String {
        banner.title ?? "Promoción"
    }

    private var artwork: some View {
        Color.clear
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay {
                CachedAsyncImage(
                    url: URL(string: banner.imageUrl),
                    // La URL es firmada y cambia en cada fetch; la ruta del objeto
                    // identifica la imagen aunque el admin la reemplace con el mismo id.
                    cacheKey: "platform_banner_\(banner.id)_\(banner.imagePath)",
                    displaySize: Self.displaySize,
                    content: { image in
                        image.resizable().aspectRatio(16 / 9, contentMode: .fill)
                    },
                    placeholder: { placeholder },
                    failure: { placeholder }
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }

    private var placeholder: some View {
        Color.gray.opacity(0.15)
    }
}
