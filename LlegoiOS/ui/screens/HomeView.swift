import SwiftUI

struct CartPositionKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var productCounts: [Int: Int] = [:]
    @State private var searchText: String = ""
    @State private var animationTrigger: AnimationData? = nil
    @State private var cartPosition: CGPoint = .zero
    @State private var triggerCartBounce = false
    @State private var navigateToPlans = false
    @State private var navigateToCart = false
    @State private var selectedProduct: Product? = nil
    @State private var selectedStore: Store? = nil

    private var totalCartItems: Int {
        productCounts.values.reduce(0, +)
    }

    var body: some View {
        NavigationView {
            CurvedBackground {
                ZStack(alignment: .top) {
                    // Contenido principal
                    VStack(spacing: 0) {
                        // Header: SearchBar + CartButton
                        HStack(spacing: 8) {
                            LlegoSearchBar(
                                text: $searchText,
                                onValueChange: { newValue in
                                    // Manejar búsqueda
                                    print("Búsqueda: \(newValue)")
                                }
                            )
                            .frame(height: 50)

                            LlegoCartButton(
                                icon: "cart",
                                badgeCount: totalCartItems > 0 ? totalCartItems : nil,
                                triggerBounce: triggerCartBounce,
                                onBounceEnd: {
                                    triggerCartBounce = false
                                },
                                onClick: {
                                    navigateToCart = true
                                }
                            )
                            .frame(width: 50, height: 50)
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.preference(
                                        key: CartPositionKey.self,
                                        value: CGPoint(
                                            x: geometry.frame(in: .global).midX,
                                            y: geometry.frame(in: .global).midY
                                        )
                                    )
                                }
                            )
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .zIndex(1)

                        // Ubicación
                        VStack(spacing: 5) {
                            Text("Ubicación actual")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.llegoSurfaceVariant)

                            HStack(spacing: 4) {
                                Text("La Habana, Cuba")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.llegoAccent)

                                Image(systemName: "location.fill")
                                    .foregroundColor(Color.llegoAccent)
                                    .font(.system(size: 16))
                            }
                            Spacer()
                                .frame(height: 120)
                        }
                        .padding(.vertical, 15)
                        .zIndex(0)

                        // Contenido scrolleable
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // Loading state
                                if viewModel.isLoading {
                                    VStack(spacing: 20) {
                                        ProgressView()
                                            .scaleEffect(1.5)
                                        Text("Cargando...")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding(.top, 100)
                                }
                                // Error state
                                else if case .error(let message) = viewModel.state {
                                    VStack(spacing: 16) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.orange)
                                        Text(message)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 32)
                                        Button("Reintentar") {
                                            viewModel.loadHomeData()
                                        }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(Color.llegoPrimary)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding(.top, 100)
                                }
                                // Success state
                                else if case .success = viewModel.state {
                                    // Product Section
                                    ProductSection(
                                        products: viewModel.products,
                                        productCounts: $productCounts,
                                        cardWidth: 155,
                                        cardHeight: 310,
                                        onSeeMoreClick: {
                                            print("Ver más clicked!")
                                        },
                                        onAddToCartAnimation: { imageUrl, startPosition in
                                            print("📥 Received in HomeView - Start: \(startPosition), Cart: \(cartPosition)")
                                            animationTrigger = AnimationData(
                                                imageUrl: imageUrl,
                                                startPosition: startPosition,
                                                endPosition: cartPosition
                                            )
                                            print("✅ AnimationData created - Start: \(animationTrigger!.startPosition), End: \(animationTrigger!.endPosition)")
                                        },
                                        onProductTap: { product in
                                            selectedProduct = product
                                        }
                                    )

                                    // Store Section
                                    StoreSection(
                                        stores: viewModel.stores,
                                        onSeeMoreTap: {
                                            print("Ver más tiendas clicked!")
                                        },
                                        onStoreTap: { store in
                                            selectedStore = store
                                        }
                                    )
                                }

                                // Promo Section
                                PromoSection(
                                    onSubscriptionTap: {
                                        navigateToPlans = true
                                    },
                                    onFamilyPaymentTap: {
                                        print("Family payment tapped!")
                                        // TODO: Navigate to family payment info
                                    }
                                )
                                .padding(.top, 8)

                                // Navigation link for Plans & Pricing
                                NavigationLink(
                                    destination: PlansAndPricingView(),
                                    isActive: $navigateToPlans
                                ) {
                                    EmptyView()
                                }
                                .hidden()

                                // Navigation link for Cart
                                NavigationLink(
                                    destination: CartView(
                                        productCounts: $productCounts,
                                        products: viewModel.products
                                    ),
                                    isActive: $navigateToCart
                                ) {
                                    EmptyView()
                                }
                                .hidden()

                                // Navigation link for Product Detail
                                NavigationLink(
                                    destination: selectedProduct.map { ProductDetailView(product: $0) },
                                    isActive: Binding(
                                        get: { selectedProduct != nil },
                                        set: { if !$0 { selectedProduct = nil } }
                                    )
                                ) {
                                    EmptyView()
                                }
                                .hidden()

                                // Navigation link for Store Detail
                                NavigationLink(
                                    destination: selectedStore.map { StoreDetailView(store: $0) },
                                    isActive: Binding(
                                        get: { selectedStore != nil },
                                        set: { if !$0 { selectedStore = nil } }
                                    )
                                ) {
                                    EmptyView()
                                }
                                .hidden()


                            }
                        }
                    }

                    // Semicircular Slider - en ZStack por encima
                    VStack {
                        Spacer()
                            .frame(height: 130)

                        SemicircularSlider()
                            .padding(.horizontal, 0)
                            .padding(.top, -70)
                    }
                    .zIndex(2)
                }
                .onPreferenceChange(CartPositionKey.self) { position in
                    cartPosition = position
                    print("🛒 Cart position updated: \(position)")
                }
            }
            .addToCartOverlay(animationTrigger: $animationTrigger) {
                triggerCartBounce = true
            }
            .onAppear {
                if case .idle = viewModel.state {
                    viewModel.loadHomeData()
                }
            }

        }
        .navigationViewStyle(StackNavigationViewStyle())

    }
}
