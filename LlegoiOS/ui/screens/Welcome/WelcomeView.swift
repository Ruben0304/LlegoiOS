import SwiftUI
import UIKit
import SceneKit

struct WelcomeView: View {
    // Global gradient state manager
    @StateObject private var gradientManager = GradientStateManager.shared

    // Cart manager
    @StateObject private var cartManager = CartManager.shared

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
    @State private var navigateToCart: Bool = false

    // Carousel state
    @State private var currentIndex: Int = 0
    @State private var scaleEffect: CGFloat = 1.0

    // User data (placeholder)
    let balance: String = "3.99$"
    
    // Models data - Orden: Restaurantes, Tienda de Ropa, Agro, Mercadito
    let models: [CategoryModel3D] = [
        CategoryModel3D(
            name: "Restaurantes",
            fileName: "restaurant.usdz",
            description: "Comida y Bebidas",
            icon: "fork.knife",
            cameraPosition: SCNVector3(x: 0, y: 1.5, z: 3.2), // Elevar cámara
            cameraEulerAngles: SCNVector3(x: -.pi / 6, y: 0, z: 0) // Ángulo intermedio: ~30 grados desde arriba
            
        ),
        CategoryModel3D(
            name: "Ropa",
            fileName: "ropa.usdz",
            description: "Moda y Accesorios",
            icon: "tshirt.fill"
        ),
        CategoryModel3D(
            name: "Mercado",
            fileName: "mercadito.usdz",
            description: "Productos Agrícolas",
            icon: "leaf.fill"
        ),
        CategoryModel3D(
            name: "Agro",
            fileName: "agro.usdz",
            description: "Frutas y Vegetales Frescos",
            icon: "cart.fill",
            cameraPosition: SCNVector3(x: 0, y: 1.5, z: 3.2), // Elevar cámara
            cameraEulerAngles: SCNVector3(x: -.pi / 6, y: 0, z: 0) // Ángulo intermedio: ~30 grados desde arriba
        )
    ]

    var body: some View {
        NavigationStack{
            ZStack(alignment: .top) {
                // Dynamic gradient background that changes based on selected model
                WelcomeGradientBackground()
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.8), value: gradientManager.currentCategoryIndex)
                
                VStack(alignment: .center, spacing: 0) {
                    // Carrusel 3D con cámara móvil
                    MultiModel3DCarouselView(
                        models: models,
                        currentIndex: currentIndex,
                        allowsCameraControl: false,
                        isAnimated: true
                    )
                    .frame(height: 400)
                    .scaleEffect(scaleEffect)
                    .offset(y: carouselAppeared ? carouselFloat : 50)
                    .opacity(carouselAppeared ? 1 : 0)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Selector simple con flechas (estilo original)
                    HStack(spacing: 12) {
                        // Flecha izquierda
                        if #available(iOS 26.0, *) {
                            // iOS 26+: Sin fondo ni opacidad
                            Button(action: previousModel) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 44, height: 44)
                            }
                            .glassEffect(.regular.interactive(), in: .circle)
                            .disabled(currentIndex == 0)
                        } else {
                            // iOS anterior: Con fondo y opacidad
                            Button(action: previousModel) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.15))
                                    )
                            }
                            .opacity(currentIndex > 0 ? 1 : 0.3)
                            .disabled(currentIndex == 0)
                        }

                        // Nombre de la categoría con subtítulo
                        VStack(spacing: 4) {
                            Text(models[currentIndex].name)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Text(models[currentIndex].description)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                        }
                        .frame(width: 180)

                        // Flecha derecha
                        if #available(iOS 26.0, *) {
                            // iOS 26+: Sin fondo ni opacidad
                            Button(action: nextModel) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 44, height: 44)
                            }
                            .glassEffect(.regular.interactive(), in: .circle)
                            .disabled(currentIndex == models.count - 1)
                        } else {
                            // iOS anterior: Con fondo y opacidad
                            Button(action: nextModel) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.15))
                                    )
                            }
                            .opacity(currentIndex < models.count - 1 ? 1 : 0.3)
                            .disabled(currentIndex == models.count - 1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)

                    Spacer()
                    
                    // Texto "Presiona para encontrar lo que buscas..." pegado abajo
                    Text("Presiona para encontrar lo que buscas...")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(Color(red: 0.32, green: 0.35, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 0)

                // Ripple overlay
                RippleOverlay(ripplePoints: $ripplePoints)
            }
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in
                handleTap(at: location)
            }
            .fullScreenCover(isPresented: $navigateToIntroVideo) {
                OrderFlowCoordinatorView()
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView(viewModel: ProfileViewModel())
            }
            .navigationDestination(isPresented: $navigateToCart) {
                CartView()
            }
            .toolbar {
                // Cart button con badge
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        navigateToCart = true
                    }) {
                            Image(systemName: "cart")
//                                .foregroundStyle(.secondary)
                            
                    }
                    .badge(cartManager.cartItemCount)
                }
                   
            ToolbarSpacer(.fixed,placement: .navigationBarTrailing)
            ToolbarItem(placement: .navigationBarTrailing) {
                // Avatar
                Button(action: { navigateToLogin = true }) {
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

    // MARK: - Tap Handler with Haptics
    private func handleTap(at location: CGPoint) {
        // Generar feedback háptico elegante
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Añadir ripple en el punto de toque
        let newRipple = RipplePoint(location: location)
        ripplePoints.append(newRipple)

        // Limitar a máximo 5 ripples activos
        if ripplePoints.count > 5 {
            ripplePoints.removeFirst()
        }

        // Navegar después del delay para ver el ripple
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            navigateToIntroVideo = true
        }
    }
}

// MARK: - Welcome Gradient Background
struct WelcomeGradientBackground: View {
    @ObservedObject private var gradientManager = GradientStateManager.shared

    // Control para expansión del degradado (usado en ConversationalSearchView)
    var isExpanded: Bool = false

    // Color palettes for each category
    private var colorPalette: (dark: Color, medium: Color, light: Color, veryLight: Color, overlay: Color) {
        switch gradientManager.currentCategoryIndex {
        case 0: // Restaurantes - Rojo-naranja terracota comida
            return (
                dark: Color(red: 0.5, green: 0.15, blue: 0.1),
                medium: Color(red: 0.7, green: 0.25, blue: 0.15),
                light: Color(red: 0.85, green: 0.45, blue: 0.3),
                veryLight: Color(red: 0.95, green: 0.88, blue: 0.85),
                overlay: Color(red: 0.45, green: 0.12, blue: 0.08)
            )
        case 1: // Tienda de Ropa - Verde
            return (
                dark: Color(red: 0.05, green: 0.3, blue: 0.25),
                medium: Color(red: 0.1, green: 0.45, blue: 0.38),
                light: Color(red: 0.4, green: 0.65, blue: 0.55),
                veryLight: Color(red: 0.85, green: 0.92, blue: 0.88),
                overlay: Color(red: 0.05, green: 0.25, blue: 0.2)
            )
        case 2: // Mercado - Azul
            return (
                dark: Color(red: 0.05, green: 0.2, blue: 0.3),
                medium: Color(red: 0.1, green: 0.35, blue: 0.45),
                light: Color(red: 0.4, green: 0.55, blue: 0.65),
                veryLight: Color(red: 0.85, green: 0.9, blue: 0.92),
                overlay: Color(red: 0.05, green: 0.15, blue: 0.25)
            )
        case 3: // Agro - Amarillo
            return (
                dark: Color(red: 0.3, green: 0.25, blue: 0.05),
                medium: Color(red: 0.45, green: 0.38, blue: 0.1),
                light: Color(red: 0.65, green: 0.6, blue: 0.4),
                veryLight: Color(red: 0.92, green: 0.9, blue: 0.85),
                overlay: Color(red: 0.25, green: 0.2, blue: 0.05)
            )
        default: // Default to rojo-naranja terracota (restaurantes)
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

#Preview {
    NavigationStack {
        WelcomeView()
    }
}
