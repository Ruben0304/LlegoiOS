import SwiftUI
import UIKit
import SceneKit
import AVFoundation

struct HomeView: View {
    // Global gradient state manager
    @StateObject private var gradientManager = GradientStateManager.shared

    // Global branch type manager
    @StateObject private var branchTypeManager = BranchTypeManager.shared

    // Business type config manager (dynamic types)
    @StateObject private var configManager = BusinessTypeConfigManager.shared

    // Cart manager
    @StateObject private var cartManager = CartManager.shared
    @ObservedObject private var authManager = AuthManager.shared

    // Wallet manager (shared)
    @StateObject private var walletManager = WalletViewModel.shared

    // Home ViewModel
    @StateObject private var viewModel = HomeViewModel()

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
    @State private var navigateToOrders: Bool = false
    @State private var navigateToConversationalSearch: Bool = false
    @State private var showingWallet: Bool = false
    @State private var navigateToPlansAndPricing: Bool = false
    @State private var isCheckingAccount: Bool = false
    @State private var redirectToOrdersAfterLogin: Bool = false

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
        // Usar ConfigManager si hay datos y el índice existe
        if !configManager.businessTypes.isEmpty && currentIndex < configManager.businessTypes.count {
            return configManager.getGlowColor(at: currentIndex)
        }

        // Fallback
        switch currentIndex {
        case 0: // Restaurantes - Rojo-naranja terracota
            return Color(red: 0.9, green: 0.3, blue: 0.2)
        case 1: // Supermercado - Verde
            return Color(red: 0.2, green: 0.7, blue: 0.5)
        case 2: // Dulcería - Marrón-Dorado
            return Color(red: 0.737, green: 0.514, blue: 0.345)
        case 3: // Perfume - Azul morado/Lavanda (estilo Sauvage)
            return Color(red: 0.50, green: 0.45, blue: 0.70)
        default:
            return Color(red: 0.9, green: 0.3, blue: 0.2)
        }
    }
    
    // Características dinámicas según la categoría (desde ConfigManager o fallback)
    var categoryFeatures: [Feature] {
        // Usar ConfigManager si hay datos y el índice existe
        if !configManager.businessTypes.isEmpty && currentIndex < configManager.businessTypes.count {
            return configManager.getFeatures(at: currentIndex)
        }

        // Fallback hardcodeado
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
        case 3: // Perfume
            return [
                Feature(icon: "drop.fill", title: "Eau de Parfum", subtitle: "Larga duración"),
                Feature(icon: "sparkles", title: "Eau de Toilette", subtitle: "Frescura diaria"),
                Feature(icon: "gift.fill", title: "Sets Regalo", subtitle: "Colecciones"),
                Feature(icon: "star.fill", title: "Exclusivos", subtitle: "Edición limitada"),
                Feature(icon: "heart.fill", title: "Bestsellers", subtitle: "Los más vendidos")
            ]
        default:
            return []
        }
    }
    
    // Models data - Orden: Restaurantes, Supermercado, Dulcería, Perfume
    // Siempre usa modelos hardcodeados con posiciones de cámara fijas
    var models: [CategoryModel3D] {
        return [
            CategoryModel3D(
                name: "Restaurantes",
                fileName: "restaurant.usdz",
                description: "Comida y Bebidas",
                icon: "fork.knife",
                cameraPosition: SCNVector3(x: 0, y: 4.0, z: 0),
                cameraEulerAngles: SCNVector3(x: -Float.pi / 2, y: 0, z: 0)
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
            ),
            CategoryModel3D(
                name: "Perfumes",
                fileName: "perfume.usdz",
                description: "Fragancias Exclusivas",
                icon: "drop.fill",
                cameraPosition: SCNVector3(x: -0.3, y: 1.2, z: 3.5),
                customScale: 0.9,
                initialRotationY: Float.pi
            )
        ]
    }
    
    // Verifica si el modelo actual necesita descarga (siempre false para modelos locales)
    var currentModelNeedsDownload: Bool {
        return false
    }
    
    // Estado de descarga del modelo actual (siempre notNeeded para modelos locales)
    var currentDownloadState: Model3DDownloadState {
        return .notNeeded
    }

    var body: some View {
        NavigationStack{
            ZStack(alignment: .top) {
                // Dynamic gradient background that changes based on selected model
                HomeGradientBackground()
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.8), value: gradientManager.currentCategoryIndex)
                
                ZStack(alignment: .topLeading) {
                    // Modelo 3D - optimizado
                    ZStack {
                        MultiModel3DCarouselView(
                            models: models,
                            currentIndex: currentIndex,
                            allowsCameraControl: false,
                            isAnimated: true
                        )
                    }
                    .frame(width: 460, height: 600)
                    .scaleEffect(scaleEffect * 1.05)
                    .offset(
                        x: -153 + (carouselAppeared ? carouselFloat / 2 : -30),
                        y: carouselAppeared ? -50 + carouselFloat : -20
                    )
                    .opacity(carouselAppeared ? 1 : 0)
                    .shadow(color: .black.opacity(0.3), radius: 30, x: 10, y: 10)

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
                            } else {
                                Button(action: previousModel) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                        )
                                }
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
                            } else {
                                Button(action: nextModel) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                        )
                                }
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
                        if redirectToOrdersAfterLogin {
                            navigateToOrders = true
                        } else {
                            navigateToProfile = true
                        }
                        redirectToOrdersAfterLogin = false
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToProfile) {
                ProfileView()
            }
            .navigationDestination(isPresented: $navigateToOrders) {
                OrderListView()
            }
            .navigationDestination(isPresented: $navigateToPlansAndPricing) {
                PlansAndPricingView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingWallet = true
                    }) {
                        if walletManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(String(format: "$%.2f", walletManager.balance))
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.black)
                        }
                    }
                    .accessibilityLabel("Wallet")
                }

                ToolbarSpacer(.fixed,placement: .navigationBarTrailing)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        guard authManager.getAccessToken() != nil else {
                            redirectToOrdersAfterLogin = true
                            authManager.signOut()
                            navigateToLogin = true
                            return
                        }
                        navigateToOrders = true
                    }) {
                        Image(systemName: "bag")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .accessibilityLabel("Pedidos")
                }

                ToolbarSpacer(.fixed,placement: .navigationBarTrailing)
                ToolbarItem(placement: .navigationBarTrailing) {
                // Avatar
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    guard !isCheckingAccount else { return }
                    guard authManager.getAccessToken() != nil else {
                        redirectToOrdersAfterLogin = false
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
                        .foregroundColor(.black)
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
                // Load wallet balance
                walletManager.loadBalance()
                // DEBUG: Print full JWT token on Home screen appear
                if let jwt = authManager.getAccessToken() {
                    print("🔐 JWT (FULL): \(jwt)")
                } else {
                    print("🔐 JWT not available (no session)")
                }
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
        // Feedback háptico
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        animateModelTransition(direction: .left) {
            // Loop circular: si está en el primero, va al último
            if currentIndex == 0 {
                currentIndex = models.count - 1
            } else {
                currentIndex -= 1
            }
            gradientManager.setCategoryIndex(currentIndex)
            branchTypeManager.setTypeFromCategoryIndex(currentIndex)
        }
    }

    private func nextModel() {
        // Feedback háptico
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        animateModelTransition(direction: .right) {
            // Loop circular: si está en el último, va al primero
            if currentIndex == models.count - 1 {
                currentIndex = 0
            } else {
                currentIndex += 1
            }
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



// MARK: - Feature Model
struct Feature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

