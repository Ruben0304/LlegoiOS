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
    @State private var isOnboardingCompleted = OnboardingHelper.isOnboardingCompleted
    private let productRepository = ProductRepository()

    var body: some View {
//        if isOnboardingCompleted {
//            MainAppView(selectedTab: $selectedTab)
//        } else {
//            OnboardingView(isOnboardingCompleted: $isOnboardingCompleted)
//                .onChange(of: isOnboardingCompleted) { completed in
//                    if completed {
//                        OnboardingHelper.completeOnboarding()
//                    }
//                }
//        }
        MainAppView(selectedTab: $selectedTab)
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
    @State private var searchText = ""
    @State private var showTrackingView = false
    @State private var showTrackingFullScreen = false

    // Determinar si hay un pedido activo
    private var hasActiveOrder: Bool {
        orderManager.currentOrder != nil &&
        orderManager.orderStatus != .idle &&
        orderManager.orderStatus != .cancelled &&
        orderManager.orderStatus != .delivered
    }

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {

                    TabView() {
                        Tab("Inicio", systemImage: "house") {
                            HomeView()
                                .ignoresSafeArea(.container, edges: .bottom)
                        }
                        Tab(role: .search) {
                            NavigationStack {
                                                   SearchView(searchText: $searchText)
                                                   }
                        }
                        Tab("Categorías", systemImage: "square.grid.2x2") {
                            CategoriesView()
                                .ignoresSafeArea(.container, edges: .bottom)
                        }

                        Tab("Mapa", systemImage: "map") {
                            MapView()
                                .ignoresSafeArea(.container, edges: .bottom)
                        }
                    }
                    .searchable(
                                    text: $searchText,
                                    placement: .toolbar,
                                    prompt: "Buscar productos o negocios..."
                                )


                                .searchToolbarBehavior(.minimize)
                    .tabViewBottomAccessory {
                        // Solo mostrar si hay pedido activo
                        if hasActiveOrder {
                            OrderTrackingCard(
                                orderManager: orderManager,
                                onTap: {
                                    print("🔵 OrderTrackingCard tapped")
                                    showTrackingFullScreen = true
                                }
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .tabBarMinimizeBehavior(.onScrollDown)
                    .accentColor(Color.llegoPrimary)
                    .fullScreenCover(isPresented: $showTrackingFullScreen) {
                        if #available(iOS 26.0, *) {
                            LiveOrderTrackingView()
                        }
                    }

                // .toolbarBackground(.hidden, for: .tabBar)
                // .background(.clear)
            } else {
                TabView(selection: $selectedTab) {
                    NavigationStack {
//                        SearchTabContent(searchText: $searchText)
                    }
                    .searchable(text: $searchText)
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Buscar")
                    }
                    .tag(-1) // Use negative tag for search to avoid conflicts
                    
                    HomeView()
                        .ignoresSafeArea(.container, edges: .bottom)
                        .tabItem {
                            Image(systemName: "house")
                            Text("Inicio")
                        }
                        .tag(0)

                    CategorySelectionView()
                        .ignoresSafeArea(.container, edges: .bottom)
                        .tabItem {
                            Image(systemName: "square.grid.2x2")
                            Text("Categoría")
                        }
                        .tag(1)

                    CategoriesView()
                        .ignoresSafeArea(.container, edges: .bottom)
                        .tabItem {
                            Image(systemName: "square.grid.2x2")
                            Text("Categorías")
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
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
            selectedTab = 0
        }
    }
}
