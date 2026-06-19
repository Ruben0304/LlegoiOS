import Combine
import SwiftUI
import UIKit

// MARK: - Media Slot
enum OnboardingMedia {
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

    // Estado de la animación de salida 3D
    @State private var triggerExitAnimation = false
    @State private var isExiting = false
    @State private var exitToHome = false   // mapea el SCNView a la pose EXACTA del restaurante en el Home
    @State private var overlayBackgroundHidden = false   // al llegar: revela Home detrás, el restaurante sigue encima

    // Long press para empezar (intro phase)
    @State private var isHoldVibrating = false
    @State private var isPressing = false
    @State private var pressProgress = 0.0
    @State private var pressLocation: CGPoint = .zero
    @State private var pressTimer: Timer?

    // Índice de paleta forzado para el gradiente (nil = cicla automáticamente)
    @State private var forcedGradientIndex: Int? = nil

    // Cinemática automática
    @State private var cinematicStep = 0       // 0=bienvenida, 1=modelos, 2-5=highlights, 6=listo
    @State private var modelsVisible = false
    @State private var highlightedModelIndex: Int? = nil
    @State private var cinematicFinished = false
    @State private var gradientVisible = false     // el gradiente entra suave con los modelos

    private let pages: [OnboardingPageData] = [
        OnboardingPageData(
            title: "Llegó",
            description: "Delivery en Cuba. Pide en minutos y recibe en la puerta de tu casa",
            media: .placeholder(icon: "bag.fill", label: "Llegó"),
            style: .introVideoFullscreen
        ),
        OnboardingPageData(
            title: "Mira las cartas de\ntus lugares favoritos",
            description: "Explora los menús completos de restaurantes, tiendas y dulcerías de tu zona.",
            media: .placeholder(icon: "fork.knife", label: "Menús completos"),
            style: .devicePreview
        ),
        OnboardingPageData(
            title: "Pide a domicilio",
            description: "Lo que quieras, directo a tu puerta. Pago seguro y entrega rápida.",
            media: .placeholder(icon: "box.truck.fill", label: "Entrega rápida"),
            style: .devicePreview
        ),
        OnboardingPageData(
            title: "Encuentra lugares\nnuevos cerca de ti",
            description: "Descubre los mejores negocios de tu zona basados en tu ubicación.",
            media: .placeholder(icon: "map.fill", label: "Explora tu zona"),
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
                        ZStack {
                            // Fondo base claro: la bienvenida (paso 0) aparece sobre esto, sin gradiente.
                            // Al llegar al Home (overlayBackgroundHidden) se vuelve transparente para
                            // revelar Home detrás mientras el restaurante del onboarding sigue encima.
                            Color(red: 0.96, green: 0.975, blue: 0.965)
                                .opacity(overlayBackgroundHidden ? 0 : 1)

                            // El gradiente de categorías entra con un fundido suave junto con los modelos.
                            OnboardingHomeStyleGradient(forcedIndex: forcedGradientIndex)
                                .opacity(overlayBackgroundHidden ? 0 : (gradientVisible ? 1 : 0))
                                .animation(.easeInOut(duration: 1.2), value: gradientVisible)

                            OnboardingScene3DView(
                                triggerExit: triggerExitAnimation,
                                isHoldVibrating: isHoldVibrating,
                                modelsVisible: modelsVisible,
                                highlightedIndex: highlightedModelIndex,
                                cinematicFinished: cinematicFinished,
                                exitHandoffScale: homeHandoffScale(in: geometry.size),
                                onExitComplete: { completeOnboarding() }
                            )
                            // Handoff: el TAMAÑO se bakea en la escala del modelo 3D (evita que el modelo
                            // se renderice gigante y se recorte por los lados). SwiftUI solo TRASLADA el
                            // SCNView al punto exacto del restaurante en el Home.
                            // La animación la conduce el withAnimation(completion:) de completeHoldPress,
                            // así el overlay se retira justo cuando esta traslación termina (sin holgura).
                            .offset(
                                x: exitToHome ? homeHandoffOffset(in: geometry.size).width : 0,
                                y: exitToHome ? homeHandoffOffset(in: geometry.size).height : 0
                            )
                        }
                    } else {
                        OnboardingAmbientBackground(
                            accentColor: gradientManager.currentAccentColor
                        )
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)

                // ------ Overlay de la cinemática (solo intro) ------
                if isIntroPhase && !isExiting {
                    CinematicOverlay(
                        step: cinematicStep,
                        size: geometry.size,
                        safeTop: geometry.safeAreaInsets.top,
                        safeBottom: geometry.safeAreaInsets.bottom
                    )
                    .allowsHitTesting(false)
                }

                // ------ Páginas de preview (no intro) ------
                if !isIntroPhase {
                    OnboardingPreviewPhase(
                        previewPages: previewPages,
                        activeIndex: activePreviewIndex,
                        accentColor: gradientManager.currentAccentColor,
                        geometry: geometry,
                        framePressed: framePressed
                    )
                    .transition(.scale(scale: 0.88).combined(with: .opacity))
                }

                // ------ Bottom controls ------
                if !isExiting {
                    VStack {
                        Spacer()
                        if isIntroPhase {
                            // "Mantén presionado" — solo visible cuando termina la cinemática
                            Text("Mantén presionado\npara empezar...")
                                .font(.system(size: 26, weight: .light, design: .rounded))
                                .foregroundColor(Color(red: 0.32, green: 0.35, blue: 0.4))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 40)
                                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 24) + 80)
                                .opacity(cinematicFinished && !isPressing ? 1 : 0)
                                .animation(.easeIn(duration: 0.5), value: cinematicFinished)
                                .animation(.easeOut(duration: 0.2), value: isPressing)
                        } else {
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
                    .transition(.opacity)
                }

                // Spiral de progreso
                if isPressing && isIntroPhase {
                    SpiralAnimationView(progress: pressProgress)
                        .position(pressLocation)
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                isIntroPhase && cinematicFinished && !isExiting
                ? DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isPressing {
                            isPressing = true
                            pressLocation = value.location
                            startHoldPress()
                        }
                    }
                    .onEnded { _ in cancelHoldPress() }
                : nil
            )
            .onAppear {
                if isIntroPhase { startCinematic() }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Cinematic

    private func startCinematic() {
        // Paso 0: Bienvenida centrada (ya visible al aparecer)
        // Paso 1: El logo sube a header y los modelos forman el círculo (2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { cinematicStep = 1 }
            gradientVisible = true   // fundido suave (lo anima el modificador .animation del gradiente)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation { modelsVisible = true }
            }
        }
        // Paso 2: Restaurantes al frente (3.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
            withAnimation(.easeInOut(duration: 0.45)) {
                cinematicStep = 2
                highlightedModelIndex = 0
            }
        }
        // Paso 3: Tiendas (5.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.4) {
            withAnimation(.easeInOut(duration: 0.45)) {
                cinematicStep = 3
                highlightedModelIndex = 1
            }
        }
        // Paso 4: Dulcerías (7.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.4) {
            withAnimation(.easeInOut(duration: 0.45)) {
                cinematicStep = 4
                highlightedModelIndex = 2
            }
        }
        // Paso 5: Perfumerías (9.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 9.4) {
            withAnimation(.easeInOut(duration: 0.45)) {
                cinematicStep = 5
                highlightedModelIndex = 3
            }
        }
        // Paso 6: Todos giran suavemente + "mantén presionado" (11.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 11.4) {
            withAnimation(.easeInOut(duration: 0.5)) {
                cinematicStep = 6
                highlightedModelIndex = nil
                cinematicFinished = true
            }
        }
    }

    // MARK: - Long press (intro phase)

    private func startHoldPress() {
        pressProgress = 0
        isHoldVibrating = true

        // Vibración fuerte, sin sonido
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()

        pressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.pressProgress >= 1.0 {
                    self.completeHoldPress()
                    return
                }
                self.pressProgress += 0.05 / 0.9  // ~0.9s de duración
                // Haptic fuerte y continuo: golpe en cada tick (~20 Hz) a intensidad máxima.
                generator.impactOccurred(intensity: 1.0)
                generator.prepare()
            }
        }
    }

    private func cancelHoldPress() {
        pressTimer?.invalidate()
        pressTimer = nil
        pressProgress = 0
        isPressing = false
        isHoldVibrating = false
    }

    private func completeHoldPress() {
        pressTimer?.invalidate()
        pressTimer = nil
        pressProgress = 1.0

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        isExiting = true
        triggerExitAnimation = true

        // A los 0.26s (tras la vibración breve) el restaurante inicia su viaje a la pose del Home,
        // sincronizado con el movimiento 3D. El overlay se retira en la COMPLETION exacta de esa
        // animación → el resto del Home aparece justo al llegar, sin holgura: se siente como un
        // cambio de estado, no como una navegación.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            withAnimation(.easeInOut(duration: 1.6)) {
                self.forcedGradientIndex = 0   // gradiente → paleta del restaurante, para casar con el Home
            }
            withAnimation(.easeInOut(duration: 1.6)) {
                self.exitToHome = true
            } completion: {
                // Justo al llegar: revela Home POR DETRÁS (fondo del overlay transparente), pero el
                // restaurante del onboarding sigue encima, solapado exactamente sobre el del Home.
                self.overlayBackgroundHidden = true
                // Unos ms después, retira el overlay. Como Home (con su restaurante) ya está debajo,
                // no hay ningún frame sin modelo → sin saltito en el relevo de un modelo a otro.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    self.completeOnboarding()
                }
            }
        }
    }

    // MARK: - Handoff al Home (pose exacta del restaurante)
    // Mantener en sync con HomeView + MultiModel3DCarouselView:
    //  • frame del carrusel: 460×600
    //  • offset(x: -153 + carouselFloat/2, y: -50 + carouselFloat); carouselFloat reposa ≈ -4 (oscila 0..-8)
    //  • scaleEffect(scaleEffect * 1.05), con scaleEffect = 1.0 en reposo
    //  • restaurante centrado en el frame (cámara cenital sobre el modelo en el origen)
    // ⇒ centro del modelo en pantalla ≈ (75, safeTopReal + 246), proyectado en un viewport de 460 de ancho.
    private enum HomeHandoff {
        static let frameW: CGFloat = 460
        static let frameH: CGFloat = 600
        static let restOffsetX: CGFloat = -153 + (-4 / 2)   // ≈ -155
        static let restOffsetY: CGFloat = -50 + (-4)        // ≈ -54
        static let displayScale: CGFloat = 1.05
        // El NavigationStack del Home muestra una nav bar visible (toolbar con items, sin fondo oculto),
        // que insetea su contenido ~44pt bajo el safe-area top. deviceSafeTop NO lo incluye ⇒ hay que sumarlo.
        static let navBar: CGFloat = 44
        static var modelCenterX: CGFloat { frameW / 2 + restOffsetX }   // ≈ 75 (desde el borde izq.)
        static var modelCenterY: CGFloat { frameH / 2 + restOffsetY }   // ≈ 246 (desde el top del contenido)
    }

    /// Safe-area top real del dispositivo (UIKit): fiable aunque el overlay ignore el safe area.
    private static var deviceSafeTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.safeAreaInsets.top ?? 47
    }

    /// Factor (bakeado en la escala del modelo 3D) para que el restaurante, proyectado a pantalla
    /// completa, iguale el tamaño en píxeles del Home (viewport de 600 de alto × scaleEffect 1.05).
    /// El FOV de SceneKit es VERTICAL por defecto ⇒ la proyección ∝ ALTO del viewport.
    /// (Si alguna vez sale mal el tamaño, la alternativa sería por ancho: frameW*displayScale/size.width.)
    private func homeHandoffScale(in size: CGSize) -> CGFloat {
        HomeHandoff.frameH * HomeHandoff.displayScale / size.height
    }

    /// Desplazamiento para llevar el restaurante (centrado en pantalla) al centro exacto del Home.
    private func homeHandoffOffset(in size: CGSize) -> CGSize {
        let targetX = HomeHandoff.modelCenterX
        let targetY = Self.deviceSafeTop + HomeHandoff.navBar + HomeHandoff.modelCenterY
        return CGSize(width: targetX - size.width / 2, height: targetY - size.height / 2)
    }

    // MARK: - Navigation
    private func advance() {
        if isIntroPhase {
            // Ya no se usa — el avance desde intro se hace por long press
            return
        }

        if isLastPage {
            completeOnboarding()
            return
        }

        // Coordinated animation: button tap → device frame "press" → rail slide + text swap.
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
        isOnboardingCompleted = true  // ContentView maneja el fade-out del overlay
    }
}

// MARK: - Cinematic text overlay
/// Orquesta el texto de la cinemática sobre la escena 3D:
/// - Paso 0: bienvenida grande centrada.
/// - Paso ≥1: el logo + título se transforman en un header arriba (matchedGeometryEffect).
/// - Pasos 2–5: bloque de explicación abajo con una flecha decorativa apuntando al modelo.
struct CinematicOverlay: View {
    let step: Int
    let size: CGSize
    let safeTop: CGFloat
    let safeBottom: CGFloat

    @Namespace private var heroNS

    private let inkColor = Color(red: 0.13, green: 0.14, blue: 0.17)
    private let subInkColor = Color(red: 0.34, green: 0.36, blue: 0.42)

    /// Categoría explicada en los pasos 2–5 (nil en el resto).
    private var category: (title: String, subtitle: String)? {
        switch step {
        case 2: return ("Restaurantes", "Gourmet, fast food y bebidas")
        case 3: return ("Tiendas", "Mercados, hogar y mucho más")
        case 4: return ("Dulcerías", "Pasteles, dulces y repostería")
        case 5: return ("Perfumerías", "Fragancias y cuidado personal")
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            // ----- Bienvenida centrada (paso 0) → Header arriba (paso ≥1) -----
            if step == 0 {
                heroBlock
                    .position(x: size.width / 2, y: size.height * 0.45)
            } else {
                // max(safeTop, 47): garantiza que el header nunca quede bajo la Dynamic Island
                // aunque el safe area inset se reporte como 0 dentro del overlay a pantalla completa.
                headerBlock
                    .position(x: size.width / 2, y: max(safeTop, 47) + 44)
            }

            // ----- Explicación por modelo (pasos 2–5) -----
            if let category {
                explanationBlock(title: category.title, subtitle: category.subtitle)
                    .position(x: size.width / 2, y: size.height * 0.80)
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .frame(width: size.width, height: size.height)
        .animation(.spring(response: 0.55, dampingFraction: 0.86), value: step)
    }

    // MARK: Hero (paso 0)

    private var heroBlock: some View {
        VStack(spacing: 16) {
            Image("icon")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
                .matchedGeometryEffect(id: "logo", in: heroNS)

            Text("Llegó")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundColor(inkColor)
                .matchedGeometryEffect(id: "title", in: heroNS)

            Text("Bienvenido a tu delivery en Cuba")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(subInkColor)
                .multilineTextAlignment(.center)
                .transition(.opacity)
        }
        .padding(.horizontal, 32)
    }

    // MARK: Header (paso ≥1)

    private var headerBlock: some View {
        HStack(spacing: 13) {
            Image("icon")
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
                .matchedGeometryEffect(id: "logo", in: heroNS)

            Text("Llegó")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(inkColor)
                .matchedGeometryEffect(id: "title", in: heroNS)
        }
    }

    // MARK: Explicación (flecha decorativa + texto)

    private func explanationBlock(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            // Flecha decorativa: va entre el modelo (arriba) y el texto (abajo).
            DecorativeArrow()
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .foregroundColor(inkColor.opacity(0.8))
                .frame(width: 50, height: 44)

            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(inkColor)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(subInkColor)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 36)
    }
}

// MARK: - Decorative hand-drawn arrow (apunta hacia arriba, al modelo)
struct DecorativeArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Cola (abajo, ligeramente a la izquierda) → punta (arriba, centrada).
        let tail = CGPoint(x: rect.midX - w * 0.22, y: rect.maxY)
        let tip  = CGPoint(x: rect.midX,            y: rect.minY + h * 0.16)

        path.move(to: tail)
        path.addCurve(
            to: tip,
            control1: CGPoint(x: rect.midX - w * 0.34, y: rect.midY),
            control2: CGPoint(x: rect.midX + w * 0.12, y: rect.midY * 0.72)
        )

        // Punta de flecha (caret simétrico apuntando hacia arriba).
        path.move(to: CGPoint(x: tip.x - w * 0.16, y: tip.y + h * 0.17))
        path.addLine(to: tip)
        path.addLine(to: CGPoint(x: tip.x + w * 0.16, y: tip.y + h * 0.17))

        return path
    }
}

// MARK: - Home-style gradient background (intro 3D phase)
/// Replica el estilo de HomeGradientBackground: blanco→claro→color de categoría,
/// ciclando entre las 4 paletas de la app con transiciones suaves.
struct OnboardingHomeStyleGradient: View {

    /// Cuando se pasa un valor, el gradiente ignora el ciclo automático y muestra esa paleta.
    var forcedIndex: Int? = nil

    // Mismas paletas que HomeGradientBackground (fallback hardcodeado)
    private let palettes: [(dark: Color, medium: Color, light: Color, veryLight: Color, overlay: Color)] = [
        // Restaurantes — rojo-terracota
        ( Color(red: 0.5, green: 0.15, blue: 0.1),
          Color(red: 0.7, green: 0.25, blue: 0.15),
          Color(red: 0.85, green: 0.45, blue: 0.3),
          Color(red: 0.95, green: 0.88, blue: 0.85),
          Color(red: 0.45, green: 0.12, blue: 0.08) ),
        // Supermercado — verde
        ( Color(red: 0.05, green: 0.3, blue: 0.25),
          Color(red: 0.1, green: 0.45, blue: 0.38),
          Color(red: 0.4, green: 0.65, blue: 0.55),
          Color(red: 0.85, green: 0.92, blue: 0.88),
          Color(red: 0.05, green: 0.25, blue: 0.2) ),
        // Dulcería — marrón-dorado
        ( Color(red: 0.737, green: 0.514, blue: 0.345),
          Color(red: 0.910, green: 0.796, blue: 0.702),
          Color(red: 0.85, green: 0.7, blue: 0.6),
          Color(red: 0.96, green: 0.92, blue: 0.88),
          Color(red: 0.65, green: 0.45, blue: 0.3) ),
        // Perfumería — lavanda
        ( Color(red: 0.30, green: 0.28, blue: 0.55),
          Color(red: 0.48, green: 0.45, blue: 0.68),
          Color(red: 0.65, green: 0.62, blue: 0.78),
          Color(red: 0.90, green: 0.88, blue: 0.94),
          Color(red: 0.25, green: 0.22, blue: 0.48) ),
    ]

    @State private var paletteIndex = 0
    private let timer = Timer.publish(every: 1.8, on: .main, in: .common).autoconnect()

    private var activeIndex: Int { forcedIndex ?? paletteIndex }

    private var p: (dark: Color, medium: Color, light: Color, veryLight: Color, overlay: Color) {
        palettes[activeIndex]
    }

    var body: some View {
        ZStack {
            // Gradiente radial igual al de HomeGradientBackground (arriba-derecha → blanco)
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: p.dark,      location: 0.0),
                    .init(color: p.medium,    location: 0.2),
                    .init(color: p.light,     location: 0.45),
                    .init(color: p.veryLight, location: 0.7),
                    .init(color: Color(red: 0.95, green: 0.98, blue: 0.96), location: 1.0),
                ]),
                center: UnitPoint(x: 0.85, y: 0.15),
                startRadius: 10,
                endRadius: 900
            )
            .animation(.easeInOut(duration: 1.4), value: activeIndex)

            // Overlay secundario (igual que Home)
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: p.overlay.opacity(0.28), location: 0.0),
                    .init(color: .clear, location: 0.5),
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .animation(.easeInOut(duration: 1.4), value: activeIndex)
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 1.4)) {
                paletteIndex = (paletteIndex + 1) % palettes.count
            }
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

// MARK: - Preview Phase (device frame + text overlaid sobre blur interno del video)
struct OnboardingPreviewPhase: View {
    let previewPages: [OnboardingPageData]
    let activeIndex: Int
    let accentColor: Color
    let geometry: GeometryProxy
    let framePressed: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: geometry.safeAreaInsets.top + 90)

            OnboardingDeviceFrame(
                pages: previewPages,
                activeIndex: activeIndex,
                accentColor: accentColor
            )
            .frame(height: geometry.size.height * 0.72)
            .scaleEffect(framePressed ? 0.985 : 1.0)
            .padding(.horizontal, 16)
            .overlay(alignment: .bottom) {
                // El texto va sobre la zona del video que ya está blureada por dentro del teléfono.
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
                .padding(.horizontal, 28)
                .padding(.bottom, 60)
                .allowsHitTesting(false)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Native iOS Blur (UIVisualEffectView, sin tint blanco encima del fondo oscuro)
struct OnboardingBlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemUltraThinMaterialDark

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
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

                // Inner screen: rail de videos + blur nativo en la parte inferior.
                // Todo clippeado a las esquinas redondeadas del teléfono.
                ZStack(alignment: .bottom) {
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

                    // Blur nativo iOS aplicado SOLO al video, en su parte inferior.
                    // Fuera del marco, el fondo oscuro sigue visible a pantalla completa.
                    OnboardingBlurView(style: .systemUltraThinMaterialDark)
                        .frame(width: innerWidth, height: innerHeight * 0.48)
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: .black.opacity(0.65), location: 0.22),
                                    .init(color: .black, location: 0.5),
                                    .init(color: .black, location: 1.0),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Tinte oscuro adicional sobre el blur para mejor contraste del texto.
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black.opacity(0.25), location: 0.6),
                            .init(color: .black.opacity(0.55), location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: innerWidth, height: innerHeight * 0.48)
                    .allowsHitTesting(false)
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

// MARK: - Media Slot (renders image / lottie / placeholder)
struct OnboardingMediaSlot: View {
    let media: OnboardingMedia
    let accentColor: Color
    var cornerRadius: CGFloat = 28

    var body: some View {
        Group {
            switch media {
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


// MARK: - Preview
#Preview {
    OnboardingView(isOnboardingCompleted: .constant(false))
        .preferredColorScheme(.dark)
}
