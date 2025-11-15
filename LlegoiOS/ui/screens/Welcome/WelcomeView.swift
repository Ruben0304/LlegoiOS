import SwiftUI
import UIKit
import SceneKit

struct WelcomeView: View {
    // Global gradient state manager
    @StateObject private var gradientManager = GradientStateManager.shared

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
    @State private var showWallet: Bool = false

    // Carousel state
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var scaleEffect: CGFloat = 1.2

    // User data (placeholder)
    let balance: String = "3.99$"
    
    // Models data - Orden: Tienda de Ropa, Agro, Mercadito
    let models: [CategoryModel3D] = [
        CategoryModel3D(
            name: "Tienda de Ropa",
            fileName: "Adidas_display_-_Visual_Merchandising_guideline.usdz",
            description: "Moda y Accesorios",
            icon: "tshirt.fill"
        ),
        CategoryModel3D(
            name: "Agro",
            fileName: "Snack_Shelf.usdz",
            description: "Productos Agrícolas",
            icon: "leaf.fill"
        ),
        CategoryModel3D(
            name: "Mercadito",
            fileName: "Fruit_Veg_Market.usdz",
            description: "Frutas y Vegetales Frescos",
            icon: "cart.fill"
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
                    // Componente 3D - Justo debajo del toolbar
                    SceneKitView(modelName: models[currentIndex].fileName)
                        .frame(height: 400)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(scaleEffect)
                        .offset(x: dragOffset, y: carouselAppeared ? carouselFloat : 50)
                        .opacity(carouselAppeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: scaleEffect)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .clipped()
                        .contentShape(Rectangle())
                    
                    // Texto con flechas - Debajo del componente 3D (más pequeño y compacto)
                    HStack(spacing: 12) {
                        ArrowButton(direction: .left, size: .small) {
                            // Feedback háptico pronunciado
                            let impact = UIImpactFeedbackGenerator(style: .heavy)
                            impact.impactOccurred()

                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                if currentIndex > 0 {
                                    currentIndex -= 1
                                    gradientManager.setCategoryIndex(currentIndex)
                                    animateTransition()
                                }
                            }
                        }
                        .opacity(currentIndex > 0 ? 1 : 0.3)
                        .disabled(currentIndex == 0)

                        Text(models[currentIndex].name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 140)  // Más pequeño
                            .multilineTextAlignment(.center)

                        ArrowButton(direction: .right, size: .small) {
                            // Feedback háptico pronunciado
                            let impact = UIImpactFeedbackGenerator(style: .heavy)
                            impact.impactOccurred()

                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                if currentIndex < models.count - 1 {
                                    currentIndex += 1
                                    gradientManager.setCategoryIndex(currentIndex)
                                    animateTransition()
                                }
                            }
                        }
                        .opacity(currentIndex < models.count - 1 ? 1 : 0.3)
                        .disabled(currentIndex == models.count - 1)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)  // Centrado
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
            .navigationDestination(isPresented: $navigateToIntroVideo) {
                OrderFlowCoordinatorView()
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView(viewModel: ProfileViewModel())
            }
            .toolbar {
                // Avatar with floating animation
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        showWallet = true
                    }) {
                        Text(balance)
                    }
                }
                   
            ToolbarSpacer(.fixed,placement: .navigationBarTrailing)
            ToolbarItem(placement: .navigationBarTrailing) {
                // Avatar
                Button(action: { navigateToLogin = true }) {
                    AsyncImage(url: URL(string: "https://i.pravatar.cc/100?img=3")) { phase in
                        switch phase {
                        case .empty:
                            // Simple placeholder circle
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        case .failure:
                            // System placeholder avatar
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .foregroundStyle(.secondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            }
            .onAppear {
                startEntranceAnimations()
                startFloatingAnimations()
            }
            .fullScreenCover(isPresented: $showWallet) {
                WalletView()
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
            .easeInOut(duration: 5.0)
            .repeatForever(autoreverses: true)
            .delay(1.0)
        ) {
            carouselFloat = -8
        }

        // Avatar floating - smooth and slow
        withAnimation(
            .easeInOut(duration: 3.8)
            .repeatForever(autoreverses: true)
            .delay(1.5)
        ) {
            avatarFloat = -4
        }

        // Balance floating - slightly offset from avatar
        withAnimation(
            .easeInOut(duration: 4.2)
            .repeatForever(autoreverses: true)
            .delay(1.3)
        ) {
            balanceFloat = -5
        }
    }

    // MARK: - Carousel Transition Animation
    private func animateTransition() {
        // Scale animation for smooth transition
        scaleEffect = 0.92
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            scaleEffect = 1.0
        }
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

    // Color palettes for each category
    private var colorPalette: (dark: Color, medium: Color, light: Color, veryLight: Color, overlay: Color) {
        switch gradientManager.currentCategoryIndex {
        case 0: // Tienda de Ropa - Verde
            return (
                dark: Color(red: 0.05, green: 0.3, blue: 0.25),
                medium: Color(red: 0.1, green: 0.45, blue: 0.38),
                light: Color(red: 0.4, green: 0.65, blue: 0.55),
                veryLight: Color(red: 0.85, green: 0.92, blue: 0.88),
                overlay: Color(red: 0.05, green: 0.25, blue: 0.2)
            )
        case 1: // Agro - Azul
            return (
                dark: Color(red: 0.05, green: 0.2, blue: 0.3),
                medium: Color(red: 0.1, green: 0.35, blue: 0.45),
                light: Color(red: 0.4, green: 0.55, blue: 0.65),
                veryLight: Color(red: 0.85, green: 0.9, blue: 0.92),
                overlay: Color(red: 0.05, green: 0.15, blue: 0.25)
            )
        case 2: // Mercadito - Amarillo
            return (
                dark: Color(red: 0.3, green: 0.25, blue: 0.05),
                medium: Color(red: 0.45, green: 0.38, blue: 0.1),
                light: Color(red: 0.65, green: 0.6, blue: 0.4),
                veryLight: Color(red: 0.92, green: 0.9, blue: 0.85),
                overlay: Color(red: 0.25, green: 0.2, blue: 0.05)
            )
        default: // Default to green
            return (
                dark: Color(red: 0.05, green: 0.3, blue: 0.25),
                medium: Color(red: 0.1, green: 0.45, blue: 0.38),
                light: Color(red: 0.4, green: 0.65, blue: 0.55),
                veryLight: Color(red: 0.85, green: 0.92, blue: 0.88),
                overlay: Color(red: 0.05, green: 0.25, blue: 0.2)
            )
        }
    }
    
    var body: some View {
        let palette = colorPalette
        
        ZStack {
            // Base gradient - dynamic colors based on category
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.dark, location: 0.0),
                    .init(color: palette.medium, location: 0.2),
                    .init(color: palette.light, location: 0.45),
                    .init(color: palette.veryLight, location: 0.7),
                    .init(color: Color(red: 0.95, green: 0.98, blue: 0.96), location: 1.0)
                ]),
                center: UnitPoint(x: 0.85, y: 0.15),
                startRadius: 10,
                endRadius: 800
            )

            // Secondary overlay for more depth
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.overlay.opacity(0.3), location: 0.0),
                    .init(color: Color.clear, location: 0.5)
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
