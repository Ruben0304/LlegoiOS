import SwiftUI

struct CartPositionKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

struct HomeView: View {
    @State private var productCounts: [Int: Int] = [:]
    @State private var searchText: String = ""
    @State private var animationTrigger: AnimationData? = nil
    @State private var cartPosition: CGPoint = .zero
    @State private var triggerCartBounce = false
    @State private var navigateToPlans = false
    @State private var navigateToCart = false
    @State private var selectedProduct: Product? = nil

    private var totalCartItems: Int {
        productCounts.values.reduce(0, +)
    }

    // Local test data that matches the structure
    private let sampleProducts: [Product] = [
        Product(
            id: 1,
            name: "Pizza",
            shop: "FreshMart",
            weight: "500g",
            price: "$4.99",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen PNG.png"
        ),
        Product(
            id: 2,
            name: "Tres leches",
            shop: "EcoFruit",
            weight: "1kg",
            price: "$2.49",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (13).png"
        ),
        Product(
            id: 3,
            name: "Batido de mamey",
            shop: "TropicalFresh",
            weight: "2 unidades",
            price: "$6.99",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (17).png"
        ),
        Product(
            id: 4,
            name: "Arroz con pescado y papas fritas",
            shop: "Berry Farm",
            weight: "250g",
            price: "$3.99",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (14).png"
        ),
        Product(
            id: 6,
            name: "Spaguetti",
            shop: "GreenGarden",
            weight: "300g",
            price: "$5.49",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (11).png"
        ),
        Product(
            id: 7,
            name: "Cheese Cake",
            shop: "GreenGarden",
            weight: "300g",
            price: "$5.49",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (15).png"
        ),
        Product(
            id: 8,
            name: "Batido de fresa",
            shop: "GreenGarden",
            weight: "300g",
            price: "$5.49",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Pasted Graphic.png"
        ),
        Product(
            id: 9,
            name: "Carne de res y vegetales",
            shop: "GreenGarden",
            weight: "300g",
            price: "$5.49",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (12).png"
        )
    ]

    // Sample store data
    private let sampleStores: [Store] = [
        Store(
            id: "1",
            name: "Fresh Market",
            etaMinutes: 25,
            logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"
        ),
        Store(
            id: "3",
            name: "Local Grocery",
            etaMinutes: 30,
            logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=500&h=200&fit=crop&crop=center"
        ),
        Store(
            id: "4",
            name: "Express Market",
            etaMinutes: 12,
            logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1604719312566-878b831d929b?w=500&h=200&fit=crop&crop=center"
        )
    ]

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
                                // Espacio para el slider que está en ZStack



                                // Product Section
                                ProductSection(
                                    products: sampleProducts,
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
                                    stores: sampleStores,
                                    onSeeMoreTap: {
                                        print("Ver más tiendas clicked!")
                                    }
                                )

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
                                        products: sampleProducts
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

        }
        .navigationViewStyle(StackNavigationViewStyle())
        
    }
}
