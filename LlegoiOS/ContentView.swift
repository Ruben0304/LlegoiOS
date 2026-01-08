import UIKit
import SwiftUI

struct ComposeView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        // Placeholder implementation - replace with your actual view controller
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct ContentView: View {
    @State private var selectedTab = 0
//     @State private var isOnboardingCompleted = OnboardingHelper.isOnboardingCompleted
    @State private var isOnboardingCompleted = true

    var body: some View {
        if isOnboardingCompleted {
            MainAppView(selectedTab: $selectedTab)
        } else {
            OnboardingView(isOnboardingCompleted: $isOnboardingCompleted)
                .onChange(of: isOnboardingCompleted) { completed in
                    if completed {
                        OnboardingHelper.completeOnboarding()
                    }
                }
        }
//        MainAppView(selectedTab: $selectedTab)
//            .onAppear {
//                testGraphQLConnection()
//            }
    }

    // Test GraphQL connection
//    private func testGraphQLConnection() {
//        print("🚀 Testing GraphQL connection...")
//
//        productRepository.fetchProducts { result in
//            switch result {
//            case .success(let products):
//                print("✅ Successfully fetched \(products.count) products:")
//                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
//                for (index, product) in products.enumerated() {
//                    print("\n📦 Product #\(index + 1):")
//                    print("   ID: \(product.id)")
//                    print("   Name: \(product.name)")
//                    print("   Description: \(product.description)")
//                    print("   Price: \(product.currency) \(product.price)")
//                    print("   Weight: \(product.weight)")
//                    print("   Available: \(product.availability ? "Yes" : "No")")
//                    print("   Image: \(product.image)")
//                    print("   Branch ID: \(product.branchId)")
//                    print("   Created: \(product.createdAt)")
//                }
//                print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
//
//            case .failure(let error):
//                print("❌ Failed to fetch products: \(error.localizedDescription)")
//            }
//        }
//    }
}

struct MainAppView: View {
    @Binding var selectedTab: Int
    @StateObject private var orderManager = OrderManager.shared
    @ObservedObject private var userLocationManager = UserLocationManager.shared
    @State private var searchText = ""
    @State private var showTrackingView = false
    @State private var showTrackingFullScreen = false
    
    // ViewModels persistentes a nivel del TabView para evitar recreación
    @StateObject private var productListViewModel = ProductListViewModel()
    @StateObject private var storeListViewModel = StoreListViewModel()

    // Determinar si hay un pedido activo
    private var hasActiveOrder: Bool {
        orderManager.currentOrder != nil &&
        orderManager.orderStatus != .idle &&
        orderManager.orderStatus != .cancelled &&
        orderManager.orderStatus != .delivered
    }

    var body: some View {
        ZStack {
            Group {
                if #available(iOS 26.0, *) {

                        TabView() {
                            Tab("Inicio", systemImage: "house") {
                                HomeView()
                                    .ignoresSafeArea(.container, edges: .bottom)
                            }
                            Tab("Productos", systemImage: "bag") {
                                ProductListView(viewModel: productListViewModel)
                                    .ignoresSafeArea(.container, edges: .bottom)
                            }
                            Tab("Tiendas", systemImage: "storefront") {
                                StoreListView(viewModel: storeListViewModel)
                            }
                            
    //                        Tab("Cuenta", systemImage: "person") {
    //                            HomeView()
    //                        }
    //                        Tab("Tutoriales", systemImage: "play.rectangle") {
    //                            HomeView()
    //                        }
    //                        Tab(role: .search) {
    //                            NavigationStack {
    //                                                   SearchView(searchText: $searchText)
    //                                                   }.searchable(
    //                                                    text: $searchText,
    //                                                    placement: .toolbar,
    //                                                    prompt: "Buscar productos o negocios..."
    //                                                )
    //                        }
    //                        Tab("Categorías", systemImage: "square.grid.2x2") {
    //                            CategoriesView()
    //                                .ignoresSafeArea(.container, edges: .bottom)
    //                        }
    //
    //                        Tab("Lugares", systemImage: "map") {
    //                            MapView()
    //                                .ignoresSafeArea(.container, edges: .bottom)
    //                        }
                        }
                        


                                    .searchToolbarBehavior(.minimize)
    //                    .tabViewBottomAccessory {
    //                        // Solo mostrar si hay pedido activo
    //                        if hasActiveOrder {
    //                            OrderTrackingCard(
    //                                orderManager: orderManager,
    //                                onTap: {
    //                                    print("🔵 OrderTrackingCard tapped")
    //                                    showTrackingFullScreen = true
    //                                }
    //                            )
    //                            .transition(.move(edge: .bottom).combined(with: .opacity))
    //                        }
    //                    }
                        .tabBarMinimizeBehavior(.onScrollDown)
                        .accentColor(Color.llegoPrimary)
                      

                    // .toolbarBackground(.hidden, for: .tabBar)
                    // .background(.clear)
                } else {
                    TabView(selection: $selectedTab) {
                        HomeView()
                            .ignoresSafeArea(.container, edges: .bottom)
                            .tabItem {
                                Image(systemName: "house")
                                Text("Inicio")
                            }
                            .tag(0)

                        ProductListView(viewModel: productListViewModel)
                            .ignoresSafeArea(.container, edges: .bottom)
                            .tabItem {
                                Image(systemName: "bag")
                                Text("Productos")
                            }
                            .tag(1)

                        StoreListView(viewModel: storeListViewModel)
                            .ignoresSafeArea(.container, edges: .bottom)
                            .tabItem {
                                Image(systemName: "storefront")
                                Text("Tiendas")
                            }
                            .tag(2)

                        ProfileView()
                            .ignoresSafeArea(.container, edges: .bottom)
                            .tabItem {
                                Image(systemName: "person")
                                Text("Cuenta")
                            }
                            .tag(3)
                    }
                    .accentColor(Color.llegoPrimary)
                    .toolbarBackground(.hidden, for: .tabBar)
                    .background(.clear)
                }
            }
            
            // Overlay de ubicación obligatoria
            if !userLocationManager.hasLocation {
                LocationRequiredOverlay()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: userLocationManager.hasLocation)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
            selectedTab = 0
        }
    }
}
