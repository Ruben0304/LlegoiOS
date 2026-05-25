import AVFoundation
import SwiftUI
import UIKit

// MARK: - Media Slot
/// Define el tipo de contenido visual que ocupa la zona principal de cada página.
/// Mantén esto en mente cuando reemplaces el placeholder por contenido real:
/// - `.video`     → archivo .mov / .mp4 dentro del bundle (carpeta resources/videos o raíz)
/// - `.image`     → asset registrado en Assets.xcassets (PNG / HEIC)
/// - `.lottie`    → archivo .json de Lottie dentro del bundle
/// - `.placeholder` → fallback decorativo con icono SF Symbol mientras no haya media real
enum OnboardingMedia {
    case video(name: String, ext: String)
    case image(assetName: String)
    case lottie(jsonName: String)
    case placeholder(icon: String, label: String)
}

// MARK: - Onboarding Data Model
struct OnboardingPageData: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let media: OnboardingMedia
    let style: PageStyle

    enum PageStyle {
        /// Primera pantalla: video a pantalla completa con texto encima.
        case introVideoFullscreen
        /// Pantallas siguientes: previsualización dentro del marco del teléfono.
        case devicePreview
    }
}

// MARK: - Main Onboarding View
struct OnboardingView: View {
    @Binding var isOnboardingCompleted: Bool
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var gradientManager = GradientStateManager.shared
    @State private var currentPage = 0
    @State private var framePressed = false

    private let pages: [OnboardingPageData] = [
        OnboardingPageData(
            title: "Llegó",
            description: "Delivery en Cuba. Pide en minutos y recibe en la puerta de tu casa",
            media: .video(name: "onboarding", ext: "mov"),
            style: .introVideoFullscreen
        ),
        OnboardingPageData(
            title: "Mira las cartas de\ntus lugares favoritos",
            description: "Explora los menús completos de restaurantes, tiendas y dulcerías de tu zona.",
            media: .placeholder(icon: "menucard.fill", label: "Foto / video de menús reales"),
            style: .devicePreview
        ),
        OnboardingPageData(
            title: "Pide a domicilio",
            description: "Lo que quieras, directo a tu puerta. Pago seguro y entrega rápida.",
            media: .placeholder(icon: "bag.fill.badge.plus", label: "Video del flujo de pedido"),
            style: .devicePreview
        ),
        OnboardingPageData(
            title: "Encuentra lugares\nnuevos cerca de ti",
            description: "Descubre los mejores negocios de tu zona basados en tu ubicación.",
            media: .placeholder(icon: "map.fill", label: "Mapa real con pines de negocios"),
            style: .devicePreview
        ),
    ]

    private var previewPages: [OnboardingPageData] {
        Array(pages.dropFirst())
    }

    private var activePreviewIndex: Int {
        max(0, currentPage - 1)
    }

    private var isIntroPhase: Bool { currentPage == 0 }
    private var isLastPage: Bool { currentPage == pages.count - 1 }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // ------ Background ------
                Group {
                    if isIntroPhase {
                        OnboardingIntroVideoBackground(
                            media: pages[0].media,
                            isPlaying: scenePhase == .active
                        )
                    } else {
                        OnboardingAmbientBackground(
                            accentColor: gradientManager.currentAccentColor
                        )
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)

                // ------ Content phase ------
                Group {
                    if isIntroPhase {
                        OnboardingIntroPage(
                            page: pages[0],
                            topPadding: geometry.safeAreaInsets.top + 24
                        )
                        .transition(.opacity)
                    } else {
                        OnboardingPreviewPhase(
                            previewPages: previewPages,
                            activeIndex: activePreviewIndex,
                            accentColor: gradientManager.currentAccentColor,
                            geometry: geometry,
                            framePressed: framePressed
                        )
                        .transition(
                            .scale(scale: 0.88)
                                .combined(with: .opacity)
                        )
                    }
                }

                // ------ Bottom controls (always visible) ------
                VStack {
                    Spacer()

                    VStack(spacing: 22) {
                        OnboardingPageIndicator(
                            count: pages.count,
                            currentIndex: currentPage,
                            accentColor: gradientManager.currentAccentColor
                        )

                        OnboardingPrimaryButton(
                            title: isLastPage ? "Comenzar" : "Siguiente",
                            accentColor: gradientManager.currentAccentColor,
                            onTap: advance
                        )
                        .padding(.horizontal, 32)
                    }
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 24) + 24)
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Navigation
    private func advance() {
        if isLastPage {
            completeOnboarding()
            return
        }

        // Coordinated animation: button tap → device frame "press" → rail slide + text swap.
        // All using the same withAnimation block so SwiftUI interpolates everything together.
        withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) {
            framePressed = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(response: 0.68, dampingFraction: 0.82)) {
                currentPage += 1
                framePressed = false
            }
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isOnboardingCompleted = true
        }
    }
}

// MARK: - Ambient Background (preview phase)
struct OnboardingAmbientBackground: View {
    let accentColor: Color

    var body: some View {
        ZStack {
            Color.black

            RadialGradient(
                stops: [
                    .init(color: accentColor.opacity(0.45), location: 0.0),
                    .init(color: accentColor.opacity(0.18), location: 0.45),
                    .init(color: .black, location: 1.0),
                ],
                center: UnitPoint(x: 0.5, y: 0.25),
                startRadius: 30,
                endRadius: 600
            )

            LinearGradient(
                colors: [
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.55),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .animation(.easeInOut(duration: 0.6), value: accentColor)
    }
}

// MARK: - Preview Phase (device frame + text)
struct OnboardingPreviewPhase: View {
    let previewPages: [OnboardingPageData]
    let activeIndex: Int
    let accentColor: Color
    let geometry: GeometryProxy
    let framePressed: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: geometry.safeAreaInsets.top + 12)

            OnboardingDeviceFrame(
                pages: previewPages,
                activeIndex: activeIndex,
                accentColor: accentColor
            )
            .frame(height: geometry.size.height * 0.55)
            .scaleEffect(framePressed ? 0.985 : 1.0)
            .padding(.horizontal, 24)

            Spacer(minLength: 16)

            // Text block — overlapping pages, only the active one is visible.
            // Coordinated transition: outgoing slides left, incoming slides from right.
            ZStack {
                ForEach(Array(previewPages.enumerated()), id: \.element.id) { index, page in
                    if index == activeIndex {
                        OnboardingTextBlock(
                            title: page.title,
                            description: page.description
                        )
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            )
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 140)
            .padding(.horizontal, 24)

            Spacer(minLength: 0)
            Spacer()
                .frame(height: 180) // reserve space for bottom controls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Device Frame (iPhone-style bezel with sliding rail inside)
struct OnboardingDeviceFrame: View {
    let pages: [OnboardingPageData]
    let activeIndex: Int
    let accentColor: Color

    var body: some View {
        GeometryReader { proxy in
            let phoneHeight = proxy.size.height
            // Modern iPhone aspect ratio ≈ 19.5:9
            let phoneWidth = min(proxy.size.width, phoneHeight * (9.0 / 19.5))
            let bezel: CGFloat = 9
            let innerWidth = phoneWidth - bezel * 2
            let innerHeight = phoneHeight - bezel * 2
            let cornerRadius: CGFloat = phoneWidth * 0.13
            let innerCornerRadius: CGFloat = cornerRadius - bezel

            ZStack {
                // Outer bezel
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.14), Color.black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: phoneWidth, height: phoneHeight)
                    .shadow(color: .black.opacity(0.55), radius: 30, x: 0, y: 22)
                    .shadow(color: accentColor.opacity(0.35), radius: 45, x: 0, y: 8)

                // Inner screen with horizontal rail
                ZStack {
                    HStack(spacing: 0) {
                        ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                            OnboardingMediaSlot(
                                media: page.media,
                                accentColor: accentColor,
                                cornerRadius: 0
                            )
                            .frame(width: innerWidth, height: innerHeight)
                            // Parallax / depth: adjacent tiles shrink + dim
                            .scaleEffect(scaleFor(index: index))
                            .opacity(opacityFor(index: index))
                            .brightness(brightnessFor(index: index))
                        }
                    }
                    .frame(width: innerWidth, alignment: .leading)
                    .offset(x: -CGFloat(activeIndex) * innerWidth)
                }
                .frame(width: innerWidth, height: innerHeight)
                .mask(
                    RoundedRectangle(cornerRadius: innerCornerRadius, style: .continuous)
                )

                // Subtle glass highlight on the screen edge
                RoundedRectangle(cornerRadius: innerCornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                Color.white.opacity(0.04),
                                Color.white.opacity(0.18),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: innerWidth, height: innerHeight)
                    .allowsHitTesting(false)

                // Bezel outline highlight
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    .frame(width: phoneWidth, height: phoneHeight)
                    .allowsHitTesting(false)

                // Dynamic Island
                Capsule()
                    .fill(Color.black)
                    .frame(width: phoneWidth * 0.28, height: phoneHeight * 0.035)
                    .offset(y: -phoneHeight / 2 + bezel + (phoneHeight * 0.04))
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func scaleFor(index: Int) -> CGFloat {
        let distance = abs(CGFloat(index - activeIndex))
        return max(0.88, 1.0 - distance * 0.06)
    }

    private func opacityFor(index: Int) -> Double {
        let distance = abs(CGFloat(index - activeIndex))
        return Double(max(0.5, 1.0 - distance * 0.35))
    }

    private func brightnessFor(index: Int) -> Double {
        index == activeIndex ? 0 : -0.12
    }
}

// MARK: - Text Block (title + description, transitions per page)
struct OnboardingTextBlock: View {
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)

            Text(description)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Intro Page (page 1 with fullscreen video)
struct OnboardingIntroPage: View {
    let page: OnboardingPageData
    let topPadding: CGFloat

    @State private var copyAppeared = false

    var body: some View {
        VStack {
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image("icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 74, height: 74)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .shadow(color: .black.opacity(0.22), radius: 6, x: 0, y: 3)

                    Text(page.title)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .kerning(0.4)
                        .multilineTextAlignment(.center)
                }

                Text(page.description)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 30)
                    .padding(.top, 4)
            }
            .padding(.bottom, 36)
            .padding(.horizontal, 12)
            .offset(y: copyAppeared ? 0 : 16)
            .opacity(copyAppeared ? 1 : 0)
            .animation(
                .spring(response: 0.65, dampingFraction: 0.86).delay(0.08),
                value: copyAppeared
            )
            .padding(.top, topPadding)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            copyAppeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                copyAppeared = true
            }
        }
    }
}

// MARK: - Media Slot (renders image / video / lottie / placeholder)
struct OnboardingMediaSlot: View {
    let media: OnboardingMedia
    let accentColor: Color
    var cornerRadius: CGFloat = 28

    var body: some View {
        Group {
            switch media {
            case .video(let name, let ext):
                OnboardingLoopingVideoView(
                    resourceName: name,
                    resourceExtension: ext,
                    isPlaying: true,
                    videoGravity: .resizeAspectFill
                )

            case .image(let assetName):
                Image(assetName)
                    .resizable()
                    .scaledToFill()

            case .lottie(let jsonName):
                LottieView(name: jsonName)

            case .placeholder(let icon, let label):
                OnboardingMediaPlaceholder(icon: icon, label: label, accentColor: accentColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Placeholder (visible until you swap in real media)
struct OnboardingMediaPlaceholder: View {
    let icon: String
    let label: String
    let accentColor: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    accentColor.opacity(0.55),
                    accentColor.opacity(0.22),
                    Color.black.opacity(0.4),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)

                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Page Indicator
struct OnboardingPageIndicator: View {
    let count: Int
    let currentIndex: Int
    let accentColor: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? accentColor : Color.white.opacity(0.3))
                    .frame(width: index == currentIndex ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentIndex)
            }
        }
    }
}

// MARK: - Primary Button
struct OnboardingPrimaryButton: View {
    let title: String
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onTap()
        }) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .modifier(OnboardingGlassProminentModifier(accentColor: accentColor))
    }
}

// MARK: - Glass Prominent Button Modifier
private struct OnboardingGlassProminentModifier: ViewModifier {
    let accentColor: Color

    private var tintGradient: LinearGradient {
        LinearGradient(
            colors: [
                accentColor,
                accentColor.opacity(0.85),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.roundedRectangle(radius: 28))
                .tint(tintGradient)
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(tintGradient)
                        .shadow(color: accentColor.opacity(0.35), radius: 12, x: 0, y: 6)
                )
        }
    }
}

// MARK: - Fullscreen Video Background (Intro)
struct OnboardingIntroVideoBackground: View {
    let media: OnboardingMedia
    let isPlaying: Bool

    var body: some View {
        ZStack {
            videoLayer
                .scaleEffect(1.10)

            Color.black.opacity(0.06)

            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.74), location: 0.0),
                    .init(color: Color.black.opacity(0.58), location: 0.22),
                    .init(color: Color.black.opacity(0.22), location: 0.50),
                    .init(color: Color.black.opacity(0.34), location: 0.78),
                    .init(color: Color.black.opacity(0.56), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var videoLayer: some View {
        if case .video(let name, let ext) = media {
            OnboardingLoopingVideoView(
                resourceName: name,
                resourceExtension: ext,
                isPlaying: isPlaying
            )
        } else {
            Color.black
        }
    }
}

// MARK: - Video Layer (No Controls)
struct OnboardingLoopingVideoView: UIViewRepresentable {
    let resourceName: String
    let resourceExtension: String
    let isPlaying: Bool
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> OnboardingPlayerContainerView {
        let view = OnboardingPlayerContainerView()
        view.playerLayer.videoGravity = videoGravity

        guard let videoURL = resolveVideoURL() else {
            return view
        }

        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = false

        let item = AVPlayerItem(url: videoURL)
        context.coordinator.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        context.coordinator.player = queuePlayer

        view.player = queuePlayer

        if isPlaying {
            queuePlayer.play()
        }

        return view
    }

    func updateUIView(_ uiView: OnboardingPlayerContainerView, context: Context) {
        uiView.playerLayer.videoGravity = videoGravity

        guard let player = context.coordinator.player else { return }

        if isPlaying {
            player.play()
        } else {
            player.pause()
        }
    }

    static func dismantleUIView(
        _ uiView: OnboardingPlayerContainerView,
        coordinator: Coordinator
    ) {
        coordinator.player?.pause()
        uiView.player = nil
        coordinator.looper = nil
        coordinator.player = nil
    }

    private func resolveVideoURL() -> URL? {
        Bundle.main.url(
            forResource: resourceName,
            withExtension: resourceExtension,
            subdirectory: "resources/videos"
        )
            ?? Bundle.main.url(
                forResource: resourceName,
                withExtension: resourceExtension,
                subdirectory: "videos"
            )
            ?? Bundle.main.url(forResource: resourceName, withExtension: resourceExtension)
    }

    final class Coordinator {
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?
    }
}

final class OnboardingPlayerContainerView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(isOnboardingCompleted: .constant(false))
        .preferredColorScheme(.dark)
}
