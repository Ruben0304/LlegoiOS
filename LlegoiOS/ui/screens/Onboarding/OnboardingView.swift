import AVFoundation
import SwiftUI
import UIKit

// MARK: - Onboarding Data Model
struct OnboardingPageData: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let iconName: String
    let accentColor: Color
}

// MARK: - Floating Particle Model
struct FloatingParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let duration: Double
    let delay: Double
    let color: Color
}

// MARK: - Main Onboarding View
struct OnboardingView: View {
    @Binding var isOnboardingCompleted: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var currentPage = 0
    @State private var appeared = false
    @State private var dragOffset: CGFloat = 0
    @State private var isTransitioning = false

    private let pages: [OnboardingPageData] = [
        OnboardingPageData(
            title: "Llegó",
            subtitle: "",
            description: "Delivery en Cuba. Pide en minutos y recibe en la puerta de tu casa",
            iconName: "play.rectangle.fill",
            accentColor: Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255)
        ),
        OnboardingPageData(
            title: "Bienvenido a\nLlegó",
            subtitle: "Tu delivery favorito en Cuba",
            description: "Todo lo que necesitas, directo a tu puerta",
            iconName: "shippingbox.fill",
            accentColor: Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255)  // llegoAccent
        ),
        OnboardingPageData(
            title: "Entrega\nUltrarrápida",
            subtitle: "En minutos, no en horas",
            description:
                "Nuestros repartidores están siempre listos para llevarte lo que necesitas al instante",
            iconName: "bolt.fill",
            accentColor: Color(red: 225 / 255, green: 199 / 255, blue: 142 / 255)  // llegoSecondary
        ),
        OnboardingPageData(
            title: "Miles de\nProductos",
            subtitle: "Un mundo de opciones",
            description:
                "Restaurantes, supermercados, dulcerías, perfumerías y mucho más en un solo lugar",
            iconName: "square.grid.2x2.fill",
            accentColor: Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255)  // llegoAccent
        ),
        OnboardingPageData(
            title: "Comenzar\nAhora",
            subtitle: "Estás a un toque de distancia",
            description:
                "Descubre las mejores tiendas cerca de ti y recibe todo en la puerta de tu casa",
            iconName: "location.fill",
            accentColor: Color(red: 90 / 255, green: 132 / 255, blue: 103 / 255)  // llegoButton
        ),
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated gradient background
                OnboardingGradientBackground(
                    currentPage: currentPage,
                    pageCount: pages.count
                )
                .ignoresSafeArea()

                if currentPage == 0 {
                    OnboardingIntroVideoBackground(isPlaying: scenePhase == .active)
                        .transition(.opacity)
                }

                // Floating particles layer
                OnboardingParticlesView(currentPage: currentPage)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .opacity(currentPage == 0 ? 0.0 : 1.0)

                // Main content
                VStack(spacing: 0) {
                    // Page content area
                    ZStack {
                        ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                            if index == currentPage {
                                Group {
                                    if index == 0 {
                                        OnboardingVideoIntroPage(
                                            page: page
                                        )
                                    } else {
                                        OnboardingPageContent(
                                            page: page,
                                            pageIndex: max(0, index - 1),
                                            geometry: geometry,
                                            isLastPage: index == pages.count - 1
                                        )
                                    }
                                }
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    )
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isTransitioning {
                                    dragOffset = value.translation.width
                                }
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 50
                                if value.translation.width < -threshold
                                    && currentPage < pages.count - 1
                                {
                                    goToNextPage()
                                } else if value.translation.width > threshold && currentPage > 0 {
                                    goToPreviousPage()
                                }
                                dragOffset = 0
                            }
                    )

                    // Bottom control panel
                    OnboardingBottomPanel(
                        currentPage: $currentPage,
                        pageCount: pages.count,
                        isLastPage: currentPage == pages.count - 1,
                        onNext: goToNextPage,
                        onSkip: completeOnboarding,
                        onGetStarted: completeOnboarding
                    )
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 20)
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
    }

    private func goToNextPage() {
        guard !isTransitioning, currentPage < pages.count - 1 else { return }
        isTransitioning = true
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentPage += 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isTransitioning = false
        }
    }

    private func goToPreviousPage() {
        guard !isTransitioning, currentPage > 0 else { return }
        isTransitioning = true
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentPage -= 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isTransitioning = false
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isOnboardingCompleted = true
        }
    }
}

// MARK: - Animated Gradient Background
struct OnboardingGradientBackground: View {
    let currentPage: Int
    let pageCount: Int

    private var gradientColors: [GradientPalette] {
        [
            // Page 0 - Video intro: Deep cinematic
            GradientPalette(
                dark: Color(red: 0.01, green: 0.07, blue: 0.09),
                medium: Color(red: 0.03, green: 0.14, blue: 0.17),
                light: Color(red: 0.06, green: 0.20, blue: 0.24),
                accent: Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255).opacity(0.10)
            ),
            // Page 1 - Welcome: Deep teal
            GradientPalette(
                dark: Color(red: 0.01, green: 0.15, blue: 0.16),
                medium: Color(red: 0.02, green: 0.22, blue: 0.24),
                light: Color(red: 0.04, green: 0.32, blue: 0.34),
                accent: Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255).opacity(0.15)
            ),
            // Page 1 - Delivery: Warm teal-gold
            GradientPalette(
                dark: Color(red: 0.04, green: 0.12, blue: 0.14),
                medium: Color(red: 0.08, green: 0.20, blue: 0.18),
                light: Color(red: 0.15, green: 0.30, blue: 0.25),
                accent: Color(red: 225 / 255, green: 199 / 255, blue: 142 / 255).opacity(0.2)
            ),
            // Page 2 - Products: Green-teal
            GradientPalette(
                dark: Color(red: 0.02, green: 0.16, blue: 0.14),
                medium: Color(red: 0.05, green: 0.25, blue: 0.22),
                light: Color(red: 0.10, green: 0.35, blue: 0.30),
                accent: Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255).opacity(0.2)
            ),
            // Page 3 - Get Started: Rich teal
            GradientPalette(
                dark: Color(red: 0.01, green: 0.12, blue: 0.13),
                medium: Color(red: 0.02, green: 0.19, blue: 0.20),
                light: Color(red: 0.05, green: 0.28, blue: 0.30),
                accent: Color(red: 90 / 255, green: 132 / 255, blue: 103 / 255).opacity(0.25)
            ),
        ]
    }

    private var currentPalette: GradientPalette {
        guard currentPage >= 0, currentPage < gradientColors.count else {
            return gradientColors[0]
        }
        return gradientColors[currentPage]
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let driftX = sin(time * 0.15) * 0.08
            let driftY = cos(time * 0.12) * 0.06

            ZStack {
                // Base radial gradient
                RadialGradient(
                    stops: [
                        .init(color: currentPalette.light, location: 0.0),
                        .init(color: currentPalette.medium, location: 0.4),
                        .init(color: currentPalette.dark, location: 0.85),
                        .init(color: currentPalette.dark, location: 1.0),
                    ],
                    center: UnitPoint(x: 0.5 + driftX, y: 0.3 + driftY),
                    startRadius: 50,
                    endRadius: 600
                )

                // Secondary ambient glow
                RadialGradient(
                    stops: [
                        .init(color: currentPalette.accent, location: 0.0),
                        .init(color: Color.clear, location: 0.7),
                    ],
                    center: UnitPoint(x: 0.8 + driftY * 0.5, y: 0.2 + driftX * 0.5),
                    startRadius: 0,
                    endRadius: 400
                )
                .blendMode(.screen)

                // Tertiary subtle glow
                RadialGradient(
                    stops: [
                        .init(color: currentPalette.accent.opacity(0.5), location: 0.0),
                        .init(color: Color.clear, location: 0.6),
                    ],
                    center: UnitPoint(x: 0.2 - driftX * 0.3, y: 0.7 - driftY * 0.4),
                    startRadius: 0,
                    endRadius: 300
                )
                .blendMode(.screen)
            }
            .animation(.easeInOut(duration: 1.0), value: currentPage)
        }
    }

    struct GradientPalette {
        let dark: Color
        let medium: Color
        let light: Color
        let accent: Color
    }
}

// MARK: - Floating Particles
struct OnboardingParticlesView: View {
    let currentPage: Int

    @State private var particles: [FloatingParticle] = []
    @State private var animateParticles = false

    private let particleColors: [Color] = [
        Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255).opacity(0.3),  // accent
        Color(red: 225 / 255, green: 199 / 255, blue: 142 / 255).opacity(0.2),  // secondary
        Color.white.opacity(0.15),
        Color(red: 90 / 255, green: 132 / 255, blue: 103 / 255).opacity(0.2),  // button
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .blur(radius: particle.size * 0.3)
                        .offset(
                            x: particle.x + (animateParticles ? CGFloat.random(in: -30...30) : 0),
                            y: particle.y + (animateParticles ? CGFloat.random(in: -40...40) : 0)
                        )
                        .opacity(animateParticles ? particle.opacity : 0)
                        .animation(
                            Animation
                                .easeInOut(duration: particle.duration)
                                .repeatForever(autoreverses: true)
                                .delay(particle.delay),
                            value: animateParticles
                        )
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateParticles = true
                }
            }
            .onChange(of: currentPage) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    animateParticles = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    generateParticles(in: geometry.size)
                    withAnimation(.easeInOut(duration: 0.8)) {
                        animateParticles = true
                    }
                }
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        particles = (0..<20).map { _ in
            FloatingParticle(
                x: CGFloat.random(in: -size.width * 0.4...size.width * 0.4),
                y: CGFloat.random(in: -size.height * 0.4...size.height * 0.4),
                size: CGFloat.random(in: 4...20),
                opacity: Double.random(in: 0.1...0.5),
                duration: Double.random(in: 3...7),
                delay: Double.random(in: 0...2),
                color: particleColors.randomElement() ?? .white.opacity(0.1)
            )
        }
    }
}

// MARK: - Video Intro Page
struct OnboardingVideoIntroPage: View {
    let page: OnboardingPageData

    @State private var copyAppeared = false

    var body: some View {
        VStack {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image("icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 74, height: 74)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .shadow(color: .black.opacity(0.22), radius: 6, x: 0, y: 3)

                    Text(page.title)
                        .font(.custom("AvenirNextCondensed-DemiBold", size: 48))
                        .foregroundColor(.white)
                        .kerning(0.4)
                        .multilineTextAlignment(.center)
                }

                Text(page.description)
                    .font(.custom("AvenirNext-Medium", size: 17))
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
            .padding(.top, 30)

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

// MARK: - Fullscreen Video Background (Intro)
struct OnboardingIntroVideoBackground: View {
    let isPlaying: Bool
    private let bottomInset: CGFloat = 150
    private let overlapIntoPanel: CGFloat = 20

    var body: some View {
        GeometryReader { proxy in
            let videoHeight = max(0, proxy.size.height - bottomInset + overlapIntoPanel)

            ZStack(alignment: .top) {
                OnboardingLoopingVideoView(
                    resourceName: "onboarding",
                    resourceExtension: "mov",
                    isPlaying: isPlaying
                )
                .scaleEffect(1.10)
                .frame(width: proxy.size.width, height: videoHeight, alignment: .top)
                .clipped()

                Color.black.opacity(0.06)
                    .frame(width: proxy.size.width, height: videoHeight, alignment: .top)

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
                .frame(width: proxy.size.width, height: videoHeight, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea(edges: .top)
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

// MARK: - Page Content
struct OnboardingPageContent: View {
    let page: OnboardingPageData
    let pageIndex: Int
    let geometry: GeometryProxy
    let isLastPage: Bool

    @State private var iconAppeared = false
    @State private var titleAppeared = false
    @State private var subtitleAppeared = false
    @State private var descriptionAppeared = false
    @State private var illustrationAppeared = false
    @State private var ringPulse = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: geometry.safeAreaInsets.top + 40)

            // Hero illustration area
            ZStack {
                // Outer pulsing rings
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(
                            page.accentColor.opacity(0.1 - Double(ring) * 0.03),
                            lineWidth: 1.5
                        )
                        .frame(
                            width: CGFloat(160 + ring * 50) * (illustrationAppeared ? 1.0 : 0.6),
                            height: CGFloat(160 + ring * 50) * (illustrationAppeared ? 1.0 : 0.6)
                        )
                        .scaleEffect(ringPulse ? 1.05 : 0.95)
                        .opacity(illustrationAppeared ? 1 : 0)
                        .animation(
                            Animation
                                .easeInOut(duration: 2.0 + Double(ring) * 0.3)
                                .repeatForever(autoreverses: true)
                                .delay(Double(ring) * 0.2),
                            value: ringPulse
                        )
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.6)
                                .delay(Double(ring) * 0.1),
                            value: illustrationAppeared
                        )
                }

                // Decorative orbital dots
                ForEach(0..<6, id: \.self) { i in
                    let angle = Double(i) * 60.0
                    let radius: CGFloat = 120
                    Circle()
                        .fill(page.accentColor.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .offset(
                            x: cos(angle * .pi / 180) * radius,
                            y: sin(angle * .pi / 180) * radius
                        )
                        .opacity(illustrationAppeared ? 1 : 0)
                        .scaleEffect(illustrationAppeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.5)
                                .delay(0.4 + Double(i) * 0.08),
                            value: illustrationAppeared
                        )
                }

                // Glowing backdrop circle
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: page.accentColor.opacity(0.25), location: 0),
                                .init(color: page.accentColor.opacity(0.08), location: 0.6),
                                .init(color: Color.clear, location: 1),
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(illustrationAppeared ? 1 : 0.3)
                    .opacity(illustrationAppeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.7, dampingFraction: 0.6),
                        value: illustrationAppeared
                    )

                // Inner glass circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 130, height: 130)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.05),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: page.accentColor.opacity(0.3), radius: 30, x: 0, y: 10)
                    .scaleEffect(iconAppeared ? 1 : 0.5)
                    .opacity(iconAppeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.65).delay(0.1),
                        value: iconAppeared
                    )

                // Main icon
                Image(systemName: page.iconName)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                page.accentColor,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: page.accentColor.opacity(0.5), radius: 10, x: 0, y: 5)
                    .scaleEffect(iconAppeared ? 1 : 0)
                    .rotationEffect(.degrees(iconAppeared ? 0 : -30))
                    .opacity(iconAppeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.7, dampingFraction: 0.5).delay(0.2),
                        value: iconAppeared
                    )

                // Page-specific decorative elements
                OnboardingPageDecorations(
                    pageIndex: pageIndex, accentColor: page.accentColor,
                    appeared: illustrationAppeared)
            }
            .frame(height: geometry.size.height * 0.38)

            Spacer()
                .frame(height: 32)

            // Text content area
            VStack(spacing: 16) {
                // Title
                Text(page.title)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(y: titleAppeared ? 0 : 30)
                    .opacity(titleAppeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.75).delay(0.25),
                        value: titleAppeared
                    )

                // Subtitle
                Text(page.subtitle)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(page.accentColor)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .offset(y: subtitleAppeared ? 0 : 20)
                    .opacity(subtitleAppeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.75).delay(0.35),
                        value: subtitleAppeared
                    )

                // Description
                Text(page.description)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                    .offset(y: descriptionAppeared ? 0 : 15)
                    .opacity(descriptionAppeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.75).delay(0.45),
                        value: descriptionAppeared
                    )
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .onAppear {
            resetAnimations()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                triggerAnimations()
            }
        }
    }

    private func resetAnimations() {
        iconAppeared = false
        titleAppeared = false
        subtitleAppeared = false
        descriptionAppeared = false
        illustrationAppeared = false
        ringPulse = false
    }

    private func triggerAnimations() {
        illustrationAppeared = true
        iconAppeared = true
        titleAppeared = true
        subtitleAppeared = true
        descriptionAppeared = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            ringPulse = true
        }
    }
}

// MARK: - Page-Specific Decorative Elements
struct OnboardingPageDecorations: View {
    let pageIndex: Int
    let accentColor: Color
    let appeared: Bool

    var body: some View {
        switch pageIndex {
        case 0:
            welcomeDecorations
        case 1:
            deliveryDecorations
        case 2:
            productsDecorations
        case 3:
            locationDecorations
        default:
            EmptyView()
        }
    }

    // Page 0 - Welcome: Sparkle stars
    private var welcomeDecorations: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat.random(in: 8...16)))
                    .foregroundColor(accentColor.opacity(0.6))
                    .offset(
                        x: CGFloat([-90, 95, -70, 80, -50][i]),
                        y: CGFloat([-80, -60, 70, 50, -30][i])
                    )
                    .scaleEffect(appeared ? 1 : 0)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.5)
                            .delay(0.5 + Double(i) * 0.1),
                        value: appeared
                    )
            }
        }
    }

    // Page 1 - Delivery: Speed lines
    private var deliveryDecorations: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.5), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: appeared ? CGFloat(30 + i * 12) : 0, height: 3)
                    .offset(
                        x: CGFloat(-100 + i * 10),
                        y: CGFloat(-30 + i * 20)
                    )
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.7)
                            .delay(0.4 + Double(i) * 0.1),
                        value: appeared
                    )
            }

            // Small bolt accents
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "bolt.fill")
                    .font(.system(size: CGFloat(10 + i * 2)))
                    .foregroundColor(accentColor.opacity(0.4))
                    .offset(
                        x: CGFloat([85, -95, 70][i]),
                        y: CGFloat([-75, 65, -40][i])
                    )
                    .scaleEffect(appeared ? 1 : 0)
                    .rotationEffect(.degrees(appeared ? 0 : 45))
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.5)
                            .delay(0.6 + Double(i) * 0.12),
                        value: appeared
                    )
            }
        }
    }

    // Page 2 - Products: Category mini icons
    private var productsDecorations: some View {
        let icons = ["fork.knife", "cart.fill", "birthday.cake.fill", "wineglass.fill"]
        let positions: [(CGFloat, CGFloat)] = [(-100, -70), (105, -50), (-85, 75), (95, 60)]

        return ZStack {
            ForEach(0..<icons.count, id: \.self) { i in
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 36, height: 36)

                    Image(systemName: icons[i])
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(accentColor.opacity(0.8))
                }
                .offset(x: positions[i].0, y: positions[i].1)
                .scaleEffect(appeared ? 1 : 0)
                .opacity(appeared ? 1 : 0)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.55)
                        .delay(0.5 + Double(i) * 0.1),
                    value: appeared
                )
            }
        }
    }

    // Page 3 - Location: Ripple waves
    private var locationDecorations: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(accentColor.opacity(appeared ? 0.0 : 0.3), lineWidth: 2)
                    .frame(
                        width: appeared ? CGFloat(250 + i * 60) : CGFloat(60 + i * 20),
                        height: appeared ? CGFloat(250 + i * 60) : CGFloat(60 + i * 20)
                    )
                    .animation(
                        Animation
                            .easeOut(duration: 2.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.5),
                        value: appeared
                    )
            }

            // Map pin accent
            Image(systemName: "mappin")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(accentColor.opacity(0.5))
                .offset(x: 90, y: -80)
                .scaleEffect(appeared ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.5).delay(0.7),
                    value: appeared
                )

            Image(systemName: "house.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(accentColor.opacity(0.4))
                .offset(x: -85, y: 75)
                .scaleEffect(appeared ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.5).delay(0.8),
                    value: appeared
                )
        }
    }
}

// MARK: - Bottom Panel
struct OnboardingBottomPanel: View {
    @Binding var currentPage: Int
    let pageCount: Int
    let isLastPage: Bool
    let onNext: () -> Void
    let onSkip: () -> Void
    let onGetStarted: () -> Void

    @State private var buttonScale: CGFloat = 1.0
    @State private var buttonAppeared = false
    @State private var shimmerOffset: CGFloat = -1.0

    var body: some View {
        VStack(spacing: 24) {
            // Page indicators
            HStack(spacing: 10) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Capsule()
                        .fill(
                            index == currentPage
                                ? Color.white
                                : Color.white.opacity(0.3)
                        )
                        .frame(
                            width: index == currentPage ? 28 : 8,
                            height: 8
                        )
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.7),
                            value: currentPage
                        )
                }
            }
            .padding(.top, 8)

            // Action buttons
            VStack(spacing: 14) {
                if isLastPage {
                    // Get Started button with shimmer
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        onGetStarted()
                    }) {
                        ZStack {
                            // Button background
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 90 / 255, green: 132 / 255, blue: 103 / 255),
                                            Color(red: 60 / 255, green: 110 / 255, blue: 80 / 255),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            // Shimmer overlay
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(
                                                color: Color.clear, location: shimmerOffset - 0.3),
                                            .init(
                                                color: Color.white.opacity(0.25),
                                                location: shimmerOffset),
                                            .init(
                                                color: Color.clear, location: shimmerOffset + 0.3),
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            HStack(spacing: 10) {
                                Text("Comenzar")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))

                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .shadow(
                            color: Color(red: 90 / 255, green: 132 / 255, blue: 103 / 255).opacity(
                                0.4), radius: 12, x: 0, y: 6)
                    }
                    .scaleEffect(buttonScale)
                    .onAppear {
                        // Shimmer animation loop
                        withAnimation(
                            Animation.linear(duration: 2.0)
                                .repeatForever(autoreverses: false)
                        ) {
                            shimmerOffset = 1.5
                        }

                        // Subtle pulse
                        withAnimation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                        ) {
                            buttonScale = 1.03
                        }
                    }
                } else {
                    // Next button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        onNext()
                    }) {
                        HStack(spacing: 10) {
                            Text("Siguiente")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.1),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                        )
                    }

                    // Skip button
                    Button(action: onSkip) {
                        Text("Saltar")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.5))
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 28)
        .background(
            OnboardingBottomShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.07, green: 0.11, blue: 0.12),
                            Color(red: 0.03, green: 0.06, blue: 0.07),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea(edges: .bottom)
        )
        .onChange(of: currentPage) { _ in
            buttonScale = 1.0
            shimmerOffset = -1.0
        }
    }
}

// MARK: - Onboarding Bottom Shape
struct OnboardingBottomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        let curveHeight: CGFloat = 35

        path.move(to: CGPoint(x: 0, y: curveHeight))

        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: width * 0.15, y: curveHeight * 0.2),
            control2: CGPoint(x: width * 0.35, y: 0)
        )

        path.addCurve(
            to: CGPoint(x: width, y: curveHeight),
            control1: CGPoint(x: width * 0.65, y: 0),
            control2: CGPoint(x: width * 0.85, y: curveHeight * 0.2)
        )

        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(isOnboardingCompleted: .constant(false))
        .preferredColorScheme(.dark)
}
