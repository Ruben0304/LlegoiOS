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
    }
}

struct MainAppView: View {
    @Binding var selectedTab: Int
    @State private var searchText = ""
    @State private var showTrackingView = false
    @State private var navigateToTracking = false


    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                NavigationStack {
                    TabView() {
                        Tab("Inicio", systemImage: "house") {
                            HomeView()
                                .ignoresSafeArea(.container, edges: .bottom)
                        }
                        Tab(role: .search) {
                            SearchView(searchText: $searchText)
                                .searchable(text: $searchText)
                        }
                        Tab("Categorías", systemImage: "square.grid.2x2") {
                            CategoriesView()
                                .ignoresSafeArea(.container, edges: .bottom)
                        }

                        Tab("Cuenta", systemImage: "person") {
                            ProfileView()
                                .ignoresSafeArea(.container, edges: .bottom)
                        }
                    }
                    
                    .tabViewBottomAccessory {

                            OrderTrackingCard(onTap: {
                                navigateToTracking = true
                            })
                    }
                    .navigationDestination(isPresented: $navigateToTracking) {
                        LiveOrderTrackingView()
                    }
                    .tabBarMinimizeBehavior(.onScrollDown)
                    .accentColor(Color.llegoPrimary)
                }
                // .toolbarBackground(.hidden, for: .tabBar)
                // .background(.clear)
            } else {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        SearchTabContent(searchText: $searchText)
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
