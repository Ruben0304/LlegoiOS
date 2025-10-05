import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var selectedStore: Store? = nil
    @State private var showStoreDetail = false
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Map
                Map(position: $cameraPosition) {
                    ForEach(viewModel.stores) { store in
                        Annotation(store.name, coordinate: storeCoordinate(for: store)) {
                            Button(action: {
                                selectedStore = store
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.llegoPrimary)
                                        .frame(width: 40, height: 40)
                                        .shadow(radius: 4)

                                    Image(systemName: "storefront.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18))
                                }
                            }
                        }
                    }
                }
                .mapStyle(.standard(pointsOfInterest: .excludingAll))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }

                // Loading overlay
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        LottieView(name: "loader")
                            .frame(width: 150, height: 150)
                        Text("Cargando negocios...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.9))
                }

                // Bottom sheet with store info
                if let store = selectedStore {
                    StoreInfoSheet(
                        store: store,
                        onViewStore: {
                            showStoreDetail = true
                        },
                        onDismiss: {
                            selectedStore = nil
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Negocios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel.filterByCategory(nil)
                        }) {
                            HStack {
                                Text("Todas")
                                if viewModel.selectedCategory == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }

                        Divider()

                        ForEach(viewModel.categories, id: \.self) { category in
                            Button(action: {
                                viewModel.filterByCategory(category)
                            }) {
                                HStack {
                                    Text(category)
                                    if viewModel.selectedCategory == category {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.llegoPrimary)
                    }
                }
            }
            .onAppear {
                if case .idle = viewModel.state {
                    viewModel.loadBranches()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $showStoreDetail) {
            if let store = selectedStore {
                NavigationView {
                    StoreDetailView(store: store)
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
    }

    // Helper to get coordinates for a store
    private func storeCoordinate(for store: Store) -> CLLocationCoordinate2D {
        return viewModel.coordinate(for: store.id)
    }
}

// MARK: - Store Info Sheet
struct StoreInfoSheet: View {
    let store: Store
    let onViewStore: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 16)

            // Content
            HStack(alignment: .top, spacing: 16) {
                // Store logo
                AsyncImage(url: URL(string: store.logoUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "storefront")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 60)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Store info
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    if let address = store.address {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Text(address)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.llegoAccent)
                        Text("\(store.etaMinutes) min")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.llegoAccent)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)

            // Buttons
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Text("Cerrar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.llegoPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.llegoPrimary, lineWidth: 2)
                        )
                }

                Button(action: onViewStore) {
                    Text("Ver negocio")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.llegoPrimary)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        .padding(.horizontal, 0)
    }
}

#Preview {
    MapView()
}
