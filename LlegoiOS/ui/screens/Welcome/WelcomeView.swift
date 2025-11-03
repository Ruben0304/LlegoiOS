import SwiftUI

struct WelcomeView: View {
    // Animation states
    @State private var titleAppeared = false
    @State private var subtitleAppeared = false
    @State private var toolbarAppeared = false
    @State private var categorySelectorAppeared = false

    // Floating animations
    @State private var titleFloat: CGFloat = 0
    @State private var avatarFloat: CGFloat = 0
    @State private var balanceFloat: CGFloat = 0
    @State private var categoryFloat: CGFloat = 0

    // Category selection
    @State private var selectedCategory: CategoryType = .restaurant

    enum CategoryType {
        case restaurant
        case supermarket
    }

    // User data (placeholder)
    let userName: String = "Usuario"
    let balance: String = "3.99$"

    var body: some View {
        NavigationStack{
            ZStack {
                // Custom green gradient background - dark green top-right, white/light elsewhere
                WelcomeGradientBackground()
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    
                    // Main content - left aligned but vertically centered
                    VStack(alignment: .leading, spacing: 24) {
                        // Greeting title with elegant typography
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hola \(userName),")
                                .font(.system(size: 38, weight: .light, design: .rounded))
                                .foregroundColor(Color.black.opacity(0.7))
                                .offset(y: titleAppeared ? titleFloat : 50)
                                .opacity(titleAppeared ? 1 : 0)
                            
                            Text("Bienvenido")
                                .font(.system(size: 58, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.black.opacity(0.7))
                                .offset(y: subtitleAppeared ? titleFloat : 50)
                                .opacity(subtitleAppeared ? 1 : 0)
                        }
                        
                        // Minimal category selector
                        HStack(spacing: 12) {
                            // Restaurant pill
                            CategoryPill(
                                title: "Restaurante",
                                icon: "fork.knife",
                                isSelected: selectedCategory == .restaurant
                            ) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    selectedCategory = .restaurant
                                }
                            }
                            
                            // Supermarket pill
                            CategoryPill(
                                title: "Supermercado",
                                icon: "cart",
                                isSelected: selectedCategory == .supermarket
                            ) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    selectedCategory = .supermarket
                                }
                            }
                        }
                        .offset(y: categorySelectorAppeared ? categoryFloat : 50)
                        .opacity(categorySelectorAppeared ? 1 : 0)

                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()

                    Text("Presiona para encontrar lo que buscas...")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(Color(red: 0.32, green: 0.35, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                }
            }
            .toolbar {
                // Avatar with floating animation
                ToolbarItem(placement: .navigationBarTrailing) {


                        
                        Text(balance)
                            .font(.system(size: 15, weight: .bold))
                            .padding()
                           
                    }
                   
            ToolbarSpacer(.fixed,placement: .navigationBarTrailing)
            ToolbarItem(placement: .navigationBarTrailing) {
                // Avatar
                Button(action: {}) {
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
        }
    }

    // MARK: - Entrance Animations
    private func startEntranceAnimations() {
        // Title animation - smooth slide and fade
        withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.2)) {
            titleAppeared = true
        }

        // Subtitle animation - cascading effect
        withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.4)) {
            subtitleAppeared = true
        }

        // Category selector animation
        withAnimation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.6)) {
            categorySelectorAppeared = true
        }

        // Toolbar items animation - elegant slide from top
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.5)) {
            toolbarAppeared = true
        }
    }

    // MARK: - Floating Animations
    private func startFloatingAnimations() {
        // Title floating - very subtle
        withAnimation(
            .easeInOut(duration: 4.0)
            .repeatForever(autoreverses: true)
            .delay(1.0)
        ) {
            titleFloat = -6
        }

        // Category floating - gentle
        withAnimation(
            .easeInOut(duration: 3.8)
            .repeatForever(autoreverses: true)
            .delay(1.1)
        ) {
            categoryFloat = -5
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
}

// MARK: - Welcome Gradient Background
struct WelcomeGradientBackground: View {
    var body: some View {
        ZStack {
            // Base gradient - dark green top-right to white/light
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.05, green: 0.3, blue: 0.25), location: 0.0),
                    .init(color: Color(red: 0.1, green: 0.45, blue: 0.38), location: 0.2),
                    .init(color: Color(red: 0.4, green: 0.65, blue: 0.55), location: 0.45),
                    .init(color: Color(red: 0.85, green: 0.92, blue: 0.88), location: 0.7),
                    .init(color: Color(red: 0.95, green: 0.98, blue: 0.96), location: 1.0)
                ]),
                center: UnitPoint(x: 0.85, y: 0.15),
                startRadius: 10,
                endRadius: 800
            )

            // Secondary overlay for more depth
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.05, green: 0.25, blue: 0.2).opacity(0.3), location: 0.0),
                    .init(color: Color.clear, location: 0.5)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }
}

// MARK: - Category Pill (Minimal Design)
struct CategoryPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))

                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected
                        ? AnyShapeStyle(.ultraThinMaterial)
                        : AnyShapeStyle(Color.white.opacity(0.15))
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: isSelected
                                    ? [Color.white.opacity(0.6), Color.white.opacity(0.3)]
                                    : [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? Color.white.opacity(0.2) : Color.clear,
                radius: isSelected ? 10 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
}
