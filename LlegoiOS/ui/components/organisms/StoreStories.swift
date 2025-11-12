import SwiftUI

/// Componente de historias estilo Instagram para tiendas
/// Muestra un scroll horizontal de círculos con bordes de gradiente
struct StoreStories: View {
    let stores: [Store]
    let storyData: [StoryData]?
    var onStoryTap: ((Store) -> Void)? = nil

    @State private var animationDelay: Double = 0
    @State private var viewedStories: Set<String> = []

    // Inicializador para stores simples (backward compatibility)
    init(stores: [Store], onStoryTap: ((Store) -> Void)? = nil) {
        self.stores = stores
        self.storyData = nil
        self.onStoryTap = onStoryTap
    }

    // Inicializador para story data (nuevo)
    init(storyData: [StoryData], onStoryTap: ((Store) -> Void)? = nil) {
        self.stores = storyData.map { $0.store }
        self.storyData = storyData
        self.onStoryTap = onStoryTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Título de la sección
            Text("Destacados")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.top, 4)

            // Scroll horizontal de historias
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(Array(stores.enumerated()), id: \.element.id) { index, store in
                        StoryCircle(
                            store: store,
                            isViewed: isStoryViewed(storeId: store.id),
                            onTap: {
                                handleStoryTap(store)
                            }
                        )
                        .opacity(animationDelay > Double(index) * 0.08 ? 1 : 0)
                        .scaleEffect(animationDelay > Double(index) * 0.08 ? 1 : 0.8)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                                .delay(Double(index) * 0.05),
                            value: animationDelay
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .onAppear {
                    triggerAnimation(for: stores.count)
                }
                .onChange(of: stores.map(\.id)) { _ in
                    triggerAnimation(for: stores.count)
                }
            }
            .frame(height: 100) // Altura fija para el scroll de historias
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func isStoryViewed(storeId: String) -> Bool {
        // Si tenemos storyData, usar su estado
        if let storyData = storyData,
           let story = storyData.first(where: { $0.store.id == storeId }) {
            return story.isViewed
        }
        // Fallback al state local
        return viewedStories.contains(storeId)
    }

    private func handleStoryTap(_ store: Store) {
        // Marcar como visto (solo si no hay storyData)
        if storyData == nil {
            viewedStories.insert(store.id)
        }

        // Feedback háptico
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Callback
        onStoryTap?(store)
    }

    private func triggerAnimation(for count: Int) {
        animationDelay = 0
        guard count > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animationDelay = Double(count) * 0.08 + 0.1
        }
    }
}

/// Círculo individual de historia estilo Instagram
struct StoryCircle: View {
    let store: Store
    let isViewed: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    private let storySize: CGFloat = 72
    private let borderWidth: CGFloat = 3

    var body: some View {
        VStack(spacing: 6) {
            // Círculo con borde de gradiente
            ZStack {
                // Borde gradiente (estilo Instagram)
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: isViewed ? viewedGradient : activeGradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: storySize, height: storySize)

                // Círculo blanco interior (padding para el borde)
                Circle()
                    .fill(Color.white)
                    .frame(width: storySize - borderWidth * 2, height: storySize - borderWidth * 2)

                // Imagen de la tienda
                AsyncImage(url: URL(string: store.logoUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: storySize - borderWidth * 2 - 4, height: storySize - borderWidth * 2 - 4)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: storySize - borderWidth * 2 - 4, height: storySize - borderWidth * 2 - 4)
                            .clipShape(Circle())
                    case .failure(_):
                        Circle()
                            .fill(Color.llegoBackground)
                            .frame(width: storySize - borderWidth * 2 - 4, height: storySize - borderWidth * 2 - 4)
                            .overlay(
                                Image(systemName: "storefront")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onTapGesture {
                withAnimation {
                    isPressed = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        isPressed = false
                    }
                    onTap()
                }
            }

            // Nombre de la tienda
            Text(store.name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.black)
                .lineLimit(1)
                .frame(width: storySize + 8)
                .multilineTextAlignment(.center)
        }
    }

    // Gradiente para historias activas (no vistas)
    private var activeGradient: [Color] {
        [
            Color(red: 214/255, green: 41/255, blue: 118/255),  // Instagram pink
            Color(red: 247/255, green: 119/255, blue: 55/255),  // Instagram orange
            Color(red: 252/255, green: 175/255, blue: 69/255)   // Instagram yellow
        ]
    }

    // Gradiente para historias vistas
    private var viewedGradient: [Color] {
        [
            Color.gray.opacity(0.3),
            Color.gray.opacity(0.3)
        ]
    }
}

// MARK: - Preview
struct StoreStories_Previews: PreviewProvider {
    static var previews: some View {
        let sampleStores = [
            Store(
                id: "1",
                name: "Fresh Market",
                etaMinutes: 25,
                logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
                bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"
            ),
            Store(
                id: "2",
                name: "SuperMart",
                etaMinutes: 15,
                logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
                bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"
            ),
            Store(
                id: "3",
                name: "Local Grocery Store",
                etaMinutes: 30,
                logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
                bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"
            ),
            Store(
                id: "4",
                name: "Bodega",
                etaMinutes: 20,
                logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
                bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"
            ),
            Store(
                id: "5",
                name: "Mercado",
                etaMinutes: 35,
                logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
                bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"
            )
        ]

        ZStack {
            Color.llegoBackground.ignoresSafeArea()

            VStack {
                StoreStories(stores: sampleStores) { store in
                    print("Tapped story: \(store.name)")
                }
                Spacer()
            }
            .padding(.top, 20)
        }
    }
}
