import SwiftUI
import UIKit
import SceneKit
import AVFoundation

struct WelcomeView: View {
    // Global gradient state manager
    @StateObject private var gradientManager = GradientStateManager.shared

    // Global branch type manager
    @StateObject private var branchTypeManager = BranchTypeManager.shared

    // Cart manager
    @StateObject private var cartManager = CartManager.shared
    @ObservedObject private var authManager = AuthManager.shared

    // Animation states
    @State private var carouselAppeared = false
    @State private var toolbarAppeared = false

    // Floating animations
    @State private var carouselFloat: CGFloat = 0
    @State private var avatarFloat: CGFloat = 0
    @State private var balanceFloat: CGFloat = 0

    // Ripple effect and navigation
    @State private var ripplePoints: [RipplePoint] = []
    @State private var navigateToIntroVideo: Bool = false
    @State private var navigateToLogin: Bool = false
    @State private var navigateToProfile: Bool = false
    @State private var navigateToCart: Bool = false
    @State private var navigateToConversationalSearch: Bool = false
    @State private var showingWallet: Bool = false
    @State private var navigateToPlansAndPricing: Bool = false
    @State private var isCheckingAccount: Bool = false

    // Carousel state
    @State private var currentIndex: Int = 0
    @State private var scaleEffect: CGFloat = 1.0

    // Long press states
    @State private var isPressing: Bool = false
    @State private var pressProgress: CGFloat = 0.0
    @State private var pressLocation: CGPoint = .zero
    @State private var timer: Timer?
    @State private var pressAudioPlayer: AVAudioPlayer?
    @State private var pressSoundStopTimer: Timer?

    // User data (placeholder)
    let balance: String = "3.99$"
    
    // Color de glow dinámico basado en la categoría
    var glowColorForCategory: Color {
        switch currentIndex {
        case 0: // Restaurantes - Rojo-naranja terracota
            return Color(red: 0.9, green: 0.3, blue: 0.2)
        case 1: // Supermercado - Verde
            return Color(red: 0.2, green: 0.7, blue: 0.5)
        case 2: // Dulcería - Marrón-Dorado
            return Color(red: 0.737, green: 0.514, blue: 0.345)
        default:
            return Color(red: 0.9, green: 0.3, blue: 0.2)
        }
    }
    
    // Características dinámicas según la categoría (Subcategorías Principales - Ampliadas)
    var categoryFeatures: [Feature] {
        switch currentIndex {
        case 0: // Restaurantes
            return [
                Feature(icon: "fork.knife", title: "Gourmet", subtitle: "Alta cocina"),
                Feature(icon: "flame.fill", title: "Fast Food", subtitle: "Hamburguesas"),
                Feature(icon: "fish.fill", title: "Sushi & Mar", subtitle: "Fresco del día"),
                Feature(icon: "birthday.cake.fill", title: "Postres", subtitle: "Dulces momentos"),
                Feature(icon: "wineglass.fill", title: "Bebidas", subtitle: "Coctelería")
            ]
        case 1: // Supermercado
            return [
                Feature(icon: "carrot.fill", title: "Frescos", subtitle: "Frutas y verduras"),
                Feature(icon: "cart.fill", title: "Despensa", subtitle: "Básicos del hogar"),
                Feature(icon: "drop.fill", title: "Bebidas", subtitle: "Jugos y refrescos"),
                Feature(icon: "house.fill", title: "Hogar", subtitle: "Limpieza y más"),
                Feature(icon: "heart.fill", title: "Cuidado", subtitle: "Personal")
            ]
        case 2: // Dulcería
            return [
                Feature(icon: "birthday.cake.fill", title: "Pasteles", subtitle: "Recién horneados"),
                Feature(icon: "cup.and.saucer.fill", title: "Pan Dulce", subtitle: "Tradicional"),
                Feature(icon: "gift.fill", title: "Chocolates", subtitle: "Premium"),
                Feature(icon: "sparkles", title: "Galletas", subtitle: "Artesanales"),
                Feature(icon: "star.fill", title: "Especiales", subtitle: "Del día")
            ]
        default:
            return []
        }
    }
    
    // Models data - Orden: Restaurantes, Supermercado, Dulcería
    let models: [CategoryModel3D] = [
        CategoryModel3D(
            name: "Restaurantes",
            fileName: "restaurant.usdz",
            description: "Comida y Bebidas",
            icon: "fork.knife",
            cameraPosition: SCNVector3(x: 0, y: 4.0, z: 0), // Cámara más arriba, vista cenital
            cameraEulerAngles: SCNVector3(x: -Float.pi / 2, y: 0, z: 0) // Vista casi completamente desde arriba
            
        ),
        CategoryModel3D(
            name: "Tiendas",
            fileName: "mercadito.usdz",
            description: "Productos del Hogar",
            icon: "cart.fill"
        ),
        CategoryModel3D(
            name: "Dulcería",
            fileName: "dulce.usdz",
            description: "Pan y Repostería",
            icon: "birthday.cake.fill",
            customScale: 0.8
        )
    ]

    var body: some View {
        NavigationStack{
            ZStack(alignment: .top) {
                // Dynamic gradient background that changes based on selected model
                WelcomeGradientBackground()
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.8), value: gradientManager.currentCategoryIndex)
                
                ZStack(alignment: .topLeading) {
                    // Modelo 3D - optimizado
                    MultiModel3DCarouselView(
                        models: models,
                        currentIndex: currentIndex,
                        allowsCameraControl: false,
                        isAnimated: true
                    )
                    .frame(width: 460, height: 600)
                    .scaleEffect(scaleEffect * 1.05)
                    .offset(
                        x: -153 + (carouselAppeared ? carouselFloat / 2 : -30), // Más cortado
                        y: carouselAppeared ? -50 + carouselFloat : -20
                    )
                    .opacity(carouselAppeared ? 1 : 0)
                    .shadow(color: .black.opacity(0.3), radius: 30, x: 10, y: 10)
                    // Efecto glow sutil basado en la categoría
                    .shadow(color: glowColorForCategory.opacity(0.4), radius: 50, x: 0, y: 0)
                    .shadow(color: glowColorForCategory.opacity(0.2), radius: 80, x: 0, y: 0)
                    // .allowsHitTesting(false) eliminada para permitir rotación manual

                    // Contenido principal - layout vertical
                    VStack(alignment: .center, spacing: 0) {
                        Spacer()
                            .frame(height: 60)
                        
                        // Título pequeño a la derecha arriba + Info minimalista
                        HStack(spacing: 0) {
                            Spacer() // Spacer flexible para empujar todo a la derecha
                            
                            VStack(alignment: .trailing, spacing: 16) {
                                // Título pequeño de la categoría - arriba a la derecha
                                VStack(alignment: .center, spacing: 2) {
                                    Text(models[currentIndex].name)
                                        .font(.system(size: 24, weight: .black, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.white, .white.opacity(0.9)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                                    
                                    Text(models[currentIndex].description)
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                                }
                                
                                // Características minimalistas (Categorías Principales)
                                VStack(alignment: .leading, spacing: 18) {
                                    ForEach(Array(categoryFeatures.enumerated()), id: \.offset) { index, feature in
                                        HStack(spacing: 12) {
                                            Image(systemName: feature.icon)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.9))
                                                .frame(width: 20, height: 20)
                                            
                                            VStack(alignment: .leading, spacing: 0) {
                                                Text(feature.title)
                                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white)
                                                
                                                Text(feature.subtitle)
                                                    .font(.system(size: 9, weight: .regular, design: .rounded))
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                            .padding(.trailing, 4) // Un tin de padding derecho extra
                                        }
                                        // Animación de entrada de arriba a abajo, uno a uno

                                    }
                                }
                            }
                            .padding(.trailing, 48) // Un poco más de separación con el borde derecho
                            .padding(.top, 20) // Un poco de espacio arriba
                        }
                        
                        // Espaciador para empujar el contenido hacia arriba
                        Spacer()
                            .frame(height: 200) // Espacio reducido para subir las flechas
                        
                        // Selector de categorías - justo debajo del modelo 3D
                        HStack(spacing: 10) {
                            // Flecha izquierda
                            if #available(iOS 26.0, *) {
                                Button(action: previousModel) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 40, height: 40)
                                }
                                .glassEffect(.regular.interactive(), in: .circle)
                                .disabled(currentIndex == 0)
                            } else {
                                Button(action: previousModel) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                        )
                                }
                                .opacity(currentIndex > 0 ? 1 : 0.3)
                                .disabled(currentIndex == 0)
                            }
                            
                            // Indicadores de página (puntos)
                            HStack(spacing: 8) {
                                ForEach(0..<models.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                                        .frame(width: index == currentIndex ? 10 : 8, height: index == currentIndex ? 10 : 8)
                                        .scaleEffect(index == currentIndex ? 1.0 : 0.8)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                                }
                            }
                            .padding(.horizontal, 8)

                            // Flecha derecha
                            if #available(iOS 26.0, *) {
                                Button(action: nextModel) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 40, height: 40)
                                }
                                .glassEffect(.regular.interactive(), in: .circle)
                                .disabled(currentIndex == models.count - 1)
                            } else {
                                Button(action: nextModel) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                        )
                                }
                                .opacity(currentIndex < models.count - 1 ? 1 : 0.3)
                                .disabled(currentIndex == models.count - 1)
                            }
                        }
                        .padding(.top, -6) // Espacio entre el modelo y las flechas
                        .padding(.bottom, 28) // Más separación con el texto inferior
                        .zIndex(200) // Asegura que las flechas estén sobre el modelo 3D
                        
                        Spacer()
                        
                        // Texto "Manten presionado..."
                        Text("Manten presionado\npara encontrar lo que buscas...")
                            .font(.system(size: 20, weight: .light, design: .rounded))
                            .foregroundColor(Color(red: 0.32, green: 0.35, blue: 0.4))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 44)
                            .opacity(isPressing ? 0 : 1) // Ocultar texto al presionar
                            .animation(.easeOut(duration: 0.2), value: isPressing)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Spiral Animation Overlay - Posicionada donde se toca
                    if isPressing {
                        SpiralAnimationView(progress: pressProgress)
                            .position(pressLocation) // Colocar exactamente donde se presiona
                            .transition(.opacity)
                            .zIndex(100)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 0)

                // Ripple overlay (mantenido por si acaso)
                // RippleOverlay(ripplePoints: $ripplePoints) 
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isPressing {
                            isPressing = true
                            pressLocation = value.location
                            startPressAnimation()
                        }
                    }
                    .onEnded { _ in
                        isPressing = false
                        cancelPressAnimation()
                    }
            )
            .fullScreenCover(isPresented: $navigateToIntroVideo) {
                OrderFlowCoordinatorView()
            }
            .fullScreenCover(isPresented: $navigateToConversationalSearch) {
                NavigationStack {
                    ConversationalSearchView(categoryIndex: currentIndex)
                }
            }
            .fullScreenCover(isPresented: $showingWallet) {
                WalletView()
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView(viewModel: ProfileViewModel()) {
                    navigateToLogin = false
                    DispatchQueue.main.async {
                        navigateToProfile = true
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToProfile) {
                ProfileView()
            }
            .navigationDestination(isPresented: $navigateToPlansAndPricing) {
                PlansAndPricingView()
            }
            .sheet(isPresented: $navigateToCart) {
                if #available(iOS 16.0, *) {
                    NavigationView {
                        CartView()
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                } else {
                    NavigationView {
                        CartView()
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingWallet = true
                    }) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.llegoPrimary)
                    }
                    .accessibilityLabel("Wallet")
                   
                }
                ToolbarSpacer(.fixed, placement: .navigationBarTrailing)
                // Cart button con badge
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        navigateToCart = true
                    }) {
                        Image(systemName: "cart")
                    }
                    .badge(cartManager.cartItemCount)
                }
                   
            ToolbarSpacer(.fixed,placement: .navigationBarTrailing)
            ToolbarItem(placement: .navigationBarTrailing) {
                // Avatar
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    guard !isCheckingAccount else { return }
                    guard authManager.getAccessToken() != nil else {
                        authManager.signOut()
                        navigateToLogin = true
                        return
                    }

                    isCheckingAccount = true
                    navigateToProfile = true
                    DispatchQueue.main.async {
                        isCheckingAccount = false
                    }
                }) {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
//                        .foregroundStyle(.secondary)
//                    AsyncImage(url: URL(string: "https://i.pravatar.cc/100?img=3")) { phase in
//                        switch phase {
//                        case .empty:
//                            // Simple placeholder circle
//                            Circle()
//                                .fill(Color.gray.opacity(0.3))
//                                .frame(width: 32, height: 32)
//                        case .success(let image):
//                            image
//                                .resizable()
//                                .scaledToFill()
//                                .frame(width: 50, height: 50)
//                                .clipShape(Circle())
//                        case .failure:
//                            // System placeholder avatar
//                            Image(systemName: "person.fill")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 32, height: 32)
//                                .clipShape(Circle())
//                                .foregroundStyle(.secondary)
//                        @unknown default:
//                            EmptyView()
//                        }
//                    }
                }
                .buttonStyle(.plain)
            }
            }
            .onAppear {
                startEntranceAnimations()
                startFloatingAnimations()
                preparePressSound()
                // Initialize branch type based on current category
                branchTypeManager.setTypeFromCategoryIndex(currentIndex)
            }
            .onDisappear {
                pressSoundStopTimer?.invalidate()
                pressSoundStopTimer = nil
            }
        }
    }

    // MARK: - Entrance Animations
    private func startEntranceAnimations() {
        // 3D Carousel animation - elegant entrance
        withAnimation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.3)) {
            carouselAppeared = true
        }

        // Toolbar items animation - elegant slide from top
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.5)) {
            toolbarAppeared = true
        }
    }

    // MARK: - Floating Animations
    private func startFloatingAnimations() {
        // Carousel floating - very subtle and elegant
        withAnimation(
            .easeInOut(duration: 30.0)
            .repeatForever(autoreverses: true)
            .delay(1.0)
        ) {
            carouselFloat = -8
        }

        // Avatar floating - smooth and slow
        withAnimation(
            .easeInOut(duration: 20.0)
            .repeatForever(autoreverses: true)
            .delay(1.5)
        ) {
            avatarFloat = -4
        }

        // Balance floating - slightly offset from avatar
        withAnimation(
            .easeInOut(duration: 22.0)
            .repeatForever(autoreverses: true)
            .delay(1.3)
        ) {
            balanceFloat = -5
        }
    }

    // MARK: - Navigation Functions
    private func previousModel() {
        guard currentIndex > 0 else { return }

        // Feedback háptico
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        animateModelTransition(direction: .left) {
            currentIndex -= 1
            gradientManager.setCategoryIndex(currentIndex)
            branchTypeManager.setTypeFromCategoryIndex(currentIndex)
        }
    }

    private func nextModel() {
        guard currentIndex < models.count - 1 else { return }

        // Feedback háptico
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        animateModelTransition(direction: .right) {
            currentIndex += 1
            gradientManager.setCategoryIndex(currentIndex)
            branchTypeManager.setTypeFromCategoryIndex(currentIndex)
        }
    }

    // MARK: - Carousel Transition Animation
    private func animateModelTransition(direction: Direction, completion: @escaping () -> Void) {
        // Animación sutil de escala durante la transición
        withAnimation(.easeInOut(duration: 0.3)) {
            scaleEffect = 0.95
        }

        // Cambiar el índice (la cámara se mueve automáticamente en MultiModel3DCarouselView)
        completion()

        // Restaurar escala
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) {
            scaleEffect = 1.0
        }
    }

    enum Direction {
        case left, right
    }

    // MARK: - Long Press Logic
    private func startPressAnimation() {
        pressProgress = 0
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        playPressSound()
        
        // Timer para animar el progreso y haptics
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [self] _ in
            if pressProgress >= 1.0 {
                completePressAction()
                return
            }
            pressProgress += 0.05 / 0.8 // Duración total ~0.8s
            
            // Haptic progresivo
            if Int(pressProgress * 100) % 10 == 0 {
                generator.impactOccurred(intensity: pressProgress)
            }
        }
    }
    
    private func cancelPressAnimation() {
        timer?.invalidate()
        timer = nil
        pressProgress = 0
        pressSoundStopTimer?.invalidate()
        pressSoundStopTimer = nil
        pressAudioPlayer?.stop()
        pressAudioPlayer?.currentTime = 0
    }

    private func completePressAction() {
        timer?.invalidate()
        timer = nil
        pressProgress = 1.0 // Asegurar final

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Navegar a ConversationalSearchView
        DispatchQueue.main.async {
            navigateToConversationalSearch = true
            // Resetear estado después de navegar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPressing = false
                pressProgress = 0
            }
        }
    }

    private func preparePressSound() {
        guard let url = Bundle.main.url(forResource: "sonido", withExtension: "caf") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.2
            player.prepareToPlay()
            pressAudioPlayer = player
        } catch {
            pressAudioPlayer = nil
        }
    }

    private func playPressSound() {
        if pressAudioPlayer == nil {
            preparePressSound()
        }
        guard let player = pressAudioPlayer else { return }
        player.currentTime = 0
        player.play()

        pressSoundStopTimer?.invalidate()
        let remaining = max(0, player.duration - 2.0)
        if remaining > 0 {
            pressSoundStopTimer = Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { _ in
                player.stop()
                player.currentTime = 0
            }
        }
    }
}

// MARK: - Gradient Press Animation View
struct SpiralAnimationView: View {
    let progress: CGFloat
    
    var body: some View {
        ZStack {
            // Capa externa - Wave radial suave
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.15 * progress),
                            Color.white.opacity(0.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 200 * progress
                    )
                )
                .frame(width: 400 * progress, height: 400 * progress)
                .blur(radius: 15)
                .opacity(progress)
            
            // Capa intermedia - Gradiente principal
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.6 * progress),
                            Color.white.opacity(0.4 * progress),
                            Color.white.opacity(0.2 * progress),
                            Color.white.opacity(0.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 120 * progress
                    )
                )
                .frame(width: 240 * progress, height: 240 * progress)
                .blur(radius: 8)
            
            // Capa interna - Centro brillante
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.9 * progress),
                            Color.white.opacity(0.6 * progress),
                            Color.white.opacity(0.2 * progress),
                            Color.white.opacity(0.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 60 * progress
                    )
                )
                .frame(width: 120 * progress, height: 120 * progress)
                .blur(radius: 4)
            
            // Centro core - Punto focal
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(1.0 * progress),
                            Color.white.opacity(0.7 * progress),
                            Color.white.opacity(0.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 30 * progress
                    )
                )
                .frame(width: 60 * progress, height: 60 * progress)
            
            // Anillo de borde sutil para definición
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5 * progress),
                            Color.white.opacity(0.2 * progress)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 100 * progress, height: 100 * progress)
                .blur(radius: 1)
        }
        .scaleEffect(0.5 + 0.5 * progress) // Crece suavemente desde 50% a 100%
        .opacity(min(1.0, progress * 1.2)) // Fade in rápido
        .animation(.easeOut(duration: 0.3), value: progress)
    }
}

// MARK: - Welcome Gradient Background
struct WelcomeGradientBackground: View {
    @ObservedObject private var gradientManager = GradientStateManager.shared

    // Control para expansión del degradado (usado en ConversationalSearchView)
    var isExpanded: Bool = false
    
    // Gradiente personalizado opcional (para tiendas específicas)
    var customGradient: ExtractedGradient? = nil

    // Color palettes for each category
    private var colorPalette: (dark: Color, medium: Color, light: Color, veryLight: Color, overlay: Color) {
        if let custom = customGradient {
            return (
                dark: custom.primaryColor,
                medium: custom.secondaryColor,
                light: custom.primaryColor.opacity(0.6),
                veryLight: custom.secondaryColor.opacity(0.15),
                overlay: custom.primaryColor
            )
        }
    
        switch gradientManager.currentCategoryIndex {
        case 0: // Restaurantes - Rojo-naranja terracota (original)
            return (
                dark: Color(red: 0.5, green: 0.15, blue: 0.1),
                medium: Color(red: 0.7, green: 0.25, blue: 0.15),
                light: Color(red: 0.85, green: 0.45, blue: 0.3),
                veryLight: Color(red: 0.95, green: 0.88, blue: 0.85),
                overlay: Color(red: 0.45, green: 0.12, blue: 0.08)
            )
        case 1: // Supermercado - Verde (el que tenía ropa)
            return (
                dark: Color(red: 0.05, green: 0.3, blue: 0.25),
                medium: Color(red: 0.1, green: 0.45, blue: 0.38),
                light: Color(red: 0.4, green: 0.65, blue: 0.55),
                veryLight: Color(red: 0.85, green: 0.92, blue: 0.88),
                overlay: Color(red: 0.05, green: 0.25, blue: 0.2)
            )
        case 2: // Dulcería - Marrón-Dorado-Beige (Juankys Pan Flores)
            return (
                dark: Color(red: 0.737, green: 0.514, blue: 0.345),      // Primary - Marrón dorado
                medium: Color(red: 0.910, green: 0.796, blue: 0.702),    // Secondary - Beige claro cálido
                light: Color(red: 0.85, green: 0.7, blue: 0.6),
                veryLight: Color(red: 0.96, green: 0.92, blue: 0.88),
                overlay: Color(red: 0.65, green: 0.45, blue: 0.3)
            )
        default: // Default to Rojo-naranja terracota (restaurantes)
            return (
                dark: Color(red: 0.5, green: 0.15, blue: 0.1),
                medium: Color(red: 0.7, green: 0.25, blue: 0.15),
                light: Color(red: 0.85, green: 0.45, blue: 0.3),
                veryLight: Color(red: 0.95, green: 0.88, blue: 0.85),
                overlay: Color(red: 0.45, green: 0.12, blue: 0.08)
            )
        }
    }

    var body: some View {
        let palette = colorPalette

        ZStack {
            // Base gradient - dynamic colors based on category
            // Cuando isExpanded = true, el degradado se extiende hasta abajo
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.dark, location: 0.0),
                    .init(color: palette.medium, location: isExpanded ? 0.3 : 0.2),
                    .init(color: palette.light, location: isExpanded ? 0.6 : 0.45),
                    .init(color: palette.veryLight, location: isExpanded ? 0.85 : 0.7),
                    .init(color: isExpanded ? palette.veryLight.opacity(0.8) : Color(red: 0.95, green: 0.98, blue: 0.96), location: 1.0)
                ]),
                center: UnitPoint(x: 0.85, y: 0.15),
                startRadius: 10,
                endRadius: isExpanded ? 1200 : 800
            )

            // Secondary overlay for more depth
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.overlay.opacity(0.3), location: 0.0),
                    .init(color: Color.clear, location: isExpanded ? 0.7 : 0.5)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }
}

// MARK: - Feature Model
struct Feature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
}
