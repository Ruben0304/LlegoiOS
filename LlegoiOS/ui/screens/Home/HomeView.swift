import SwiftUI

struct CartPositionKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var walletViewModel = WalletViewModel()
    @State private var productCounts: [String: Int] = [:]
    @State private var searchText: String = ""
    @State private var animationTrigger: AnimationData? = nil
    @State private var cartPosition: CGPoint = .zero
    @State private var triggerCartBounce = false
    @State private var navigateToPlans = false
    @State private var navigateToCart = false
    @State private var navigateToWallet = false
    @State private var navigateToProductDetails: Bool = false
    @State private var selectedProduct: Product? = nil
    @State private var selectedStore: Store? = nil
    @State private var navigateToProfile = false

    private var totalCartItems: Int {
        productCounts.values.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            CurvedBackground {
                ZStack(alignment: .top) {
                    // Contenido principal
                    VStack(spacing: 0) {
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
                                        LottieView(name: "loader")
                                            .frame(width: 170, height: 170)
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
                                }

                              

                                // Navigation link for Plans & Pricing
                                NavigationLink(
                                    destination: PlansAndPricingView(),
                                    isActive: $navigateToPlans
                                ) {
                                    EmptyView()
                                }
                                .hidden()

                                // Navigation link for Cart (kept for compatibility — replaced by fullScreenCover below)
                                // The actual presentation uses a fullScreenCover so the Cart appears modally like CheckoutView
                                EmptyView()

                                // NOTE: Product and Store details are presented modally using fullScreenCover below.


                            }
                        }
                    }

                    // Semicircular Slider - Posición absoluta fija
                    SemicircularSlider()
                        .frame(maxWidth: .infinity)
                        .position(x: UIScreen.main.bounds.width / 2, y: 180)
                        .zIndex(2)
                }
                .onPreferenceChange(CartPositionKey.self) { position in
                    cartPosition = position
                    print("🛒 Cart position updated: \(position)")
                }
            }
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        navigateToWallet = true
                    }) {
                        HStack(spacing: 4) {
                            Image("cerdito")
                                .renderingMode(.original)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            
                            Text("$\(String(format: "%.2f", walletViewModel.balance))")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                }
                
                // Botón del carrito a la derecha
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        navigateToCart = true
                    }) {
                        
                            Image(systemName: "cart.fill")
                           
                    }.badge(totalCartItems)
                }
                
                // Botón de perfil a la derecha
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        navigateToProfile = true
                    }) {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .addToCartOverlay(animationTrigger: $animationTrigger) {
                triggerCartBounce = true
            }
            .onAppear {
                if case .idle = viewModel.state {
                    viewModel.loadHomeData()
                }
                walletViewModel.loadBalance()
            }

        }
        
//        .navigationViewStyle(StackNavigationViewStyle())
        // Present CartView modally using fullScreenCover to match Cart -> Checkout behavior
        // Wrap in NavigationView so the modal has its own navigation bar (title + toolbar)
        .fullScreenCover(isPresented: $navigateToCart) {
            NavigationView {
                CartView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }

        // Present WalletView modally
        .fullScreenCover(isPresented: $navigateToWallet) {
            NavigationView {
                WalletView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }

        // Present Product detail modally when a product is selected
        .fullScreenCover(item: $selectedProduct) { product in
            NavigationView {
                ProductDetailView(product: product)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }

        // Present Store detail modally when a store is selected
        .fullScreenCover(item: $selectedStore) { store in
            NavigationView {
                StoreDetailView(store: store)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }

        // Present ProfileView modally
        .fullScreenCover(isPresented: $navigateToProfile) {
            NavigationView {
                ProfileView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }

    }
}
