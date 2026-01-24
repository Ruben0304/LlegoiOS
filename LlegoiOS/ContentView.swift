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
                .preferredColorScheme(.light) // Onboarding siempre en modo claro
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
    @StateObject private var gradientManager = GradientStateManager.shared
    @ObservedObject private var userLocationManager = UserLocationManager.shared
    @ObservedObject private var branchTypeManager = BranchTypeManager.shared
    @ObservedObject private var appUpdateViewModel = AppUpdateViewModel.shared
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
        ZStack {
            Group {
                if #available(iOS 26.0, *) {

                        TabView() {
                            Tab("Inicio", systemImage: "house") {
                                HomeView()
                                    .ignoresSafeArea(.container, edges: .bottom)
                            }
                            Tab("Para ti", systemImage: "flame") {
                                ProductFeedView()
                                    .ignoresSafeArea(.container, edges: .bottom)
                            }
                            Tab("Lugares", systemImage: "map") {
                                StoreMapView()
                                    .ignoresSafeArea(.container, edges: .bottom)
                            }
                            
                            // Tab de búsqueda con role: .search
                            // Cuando se selecciona, el campo de búsqueda reemplaza la barra de pestañas
                            Tab(role: .search) {
                              
                                    SearchView(searchText: $searchText)
                                    
                                       
                           
                               
                            }
                            
                        
                        }
                        // .searchToolbarBehavior(.minimize)
                        .tabBarMinimizeBehavior(.onScrollDown)
                        .tint(gradientManager.currentAccentColor)
                      

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

                        ProductFeedView()
                            .ignoresSafeArea(.container, edges: .bottom)
                            .tabItem {
                                Image(systemName: "flame")
                                Text("Para ti")
                            }
                            .tag(1)

                        StoreMapView()
                            .ignoresSafeArea(.container, edges: .bottom)
                            .tabItem {
                                Image(systemName: "map")
                                Text("Lugares")
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
                    .tint(gradientManager.currentAccentColor)
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

            // Overlay de actualización de app
            if appUpdateViewModel.showUpdateAlert {
                AppUpdateModal(viewModel: appUpdateViewModel)
                    .transition(.opacity)
                    .zIndex(200) // Mayor que el overlay de ubicación
            }
        }
        .animation(.easeInOut(duration: 0.3), value: userLocationManager.hasLocation)
        .animation(.easeInOut(duration: 0.3), value: appUpdateViewModel.showUpdateAlert)
        .onAppear {
            // Iniciar verificación periódica de actualizaciones
            appUpdateViewModel.startPeriodicCheck()
        }
        .onDisappear {
            // Detener verificación cuando la vista desaparece
            appUpdateViewModel.stopPeriodicCheck()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
            selectedTab = 0
        }
    }
}
