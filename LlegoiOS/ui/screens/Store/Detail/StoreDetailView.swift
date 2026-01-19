import SwiftUI
import MapKit

struct StoreDetailView: View {
    // Support both: passing full Store OR just storeId
    let initialStore: Store?
    let storeId: String

    @StateObject private var viewModel = StoreDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    @State private var showShareSheet = false

    // Default images - Empty strings to trigger AsyncImage failure -> shows generic assets
    private let defaultLogoUrl = ""
    private let defaultBannerUrl = ""

    // Helper functions
    private func calculateETA(deliveryRadius: Double?) -> Int {
        guard let radius = deliveryRadius else { return 20 }
        return Int(radius * 5 + 10)
    }

    private func formatPrice(price: Double, currency: String) -> String {
        let symbol: String
        switch currency.uppercased() {
        case "USD":
            symbol = "$"
        case "EUR":
            symbol = "€"
        case "CUP":
            symbol = "₱"
        default:
            symbol = currency
        }
        return "\(symbol)\(String(format: "%.2f", price))"
    }

    // Computed property to get current store (prefer viewModel data when available)
    private var store: Store? {
        // Prioritize fresh data from ViewModel if available
        if let detail = viewModel.branchDetail {
            return Store(
                id: detail.id,
                name: detail.name,
                etaMinutes: viewModel.calculateETA(deliveryRadius: detail.deliveryRadius),
                logoUrl: viewModel.getLogoUrl(),
                bannerUrl: viewModel.getBannerUrl(),
                address: detail.address,
                rating: nil
            )
        }

        // Fallback to initial store while loading
        if let initial = initialStore {
            return initial
        }

        return nil
    }

    // Initializer that accepts full Store (existing code compatibility)
    init(store: Store) {
        self.initialStore = store
        self.storeId = store.id
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 4.6097, longitude: -74.0817),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    // New initializer that accepts only ID (will load details)
    init(storeId: String) {
        self.initialStore = nil
        self.storeId = storeId
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 4.6097, longitude: -74.0817),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        NavigationStack{
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    Color.llegoSurface.ignoresSafeArea()

                    // LOADING STATE - Indicador nativo
                    if initialStore == nil && viewModel.isLoading {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.llegoPrimary)

                            Text("Cargando información...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // ERROR STATE
                    else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.red)

                            Text(errorMessage)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()

                            Button("Reintentar") {
                                viewModel.loadBranchDetail(id: storeId)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.llegoPrimary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // SUCCESS STATE - Show store details
                    else if let store = store {
                        ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Banner and Profile Section
                            ZStack(alignment: .bottomLeading) {
                                // Banner Image
                                AsyncImage(url: URL(string: store.bannerUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        Image("generic_cover")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: 280)
                                            .clipped()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: 280)
                                            .clipped()
                                    case .failure:
                                        Image("generic_cover")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: 280)
                                            .clipped()
                                    @unknown default:
                                        Image("generic_cover")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: 280)
                                            .clipped()
                                    }
                                }
                                .frame(width: geometry.size.width, height: 280)
                                
                                // Gradient overlay for better contrast
                                LinearGradient(
                                    colors: [Color.clear, Color.black.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(width: geometry.size.width, height: 280)
                                
                                // Profile Logo (overlapping)
                                HStack(spacing: 16) {
                                    AsyncImage(url: URL(string: store.logoUrl)) { phase in
                                        switch phase {
                                        case .empty:
                                            Image("generic_logo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 110, height: 110)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 5)
                                                )
                                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 3)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 110, height: 110)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 5)
                                                )
                                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 3)
                                        case .failure:
                                            Image("generic_logo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 110, height: 110)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 5)
                                                )
                                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 3)
                                        @unknown default:
                                            Image("generic_logo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 110, height: 110)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 5)
                                                )
                                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 3)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, -55)
                            }
                            .frame(width: geometry.size.width)
                            .padding(.bottom, 20)

                            // Add space to show full profile logo + shadow
                            Spacer()
                                .frame(height: 65) // Space for logo (55) + reduced shadow (10)

                            // Main Content
                            VStack(spacing: 0) {
                                // Store Info Section
                                VStack(alignment: .leading, spacing: 16) {
                                    // Store Name & Rating
                                    HStack(alignment: .top, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(store.name)
                                                .font(.system(size: 30, weight: .bold))
                                                .foregroundColor(.black)
                                                .lineLimit(2)
                                            
                                            if let address = store.address {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "mappin.circle.fill")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.llegoPrimary)
                                                    
                                                    Text(address)
                                                        .font(.system(size: 15, weight: .regular))
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if let rating = store.rating {
                                            VStack(spacing: 4) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "star.fill")
                                                        .font(.system(size: 18))
                                                        .foregroundColor(.yellow)
                                                    
                                                    Text(String(format: "%.1f", rating))
                                                        .font(.system(size: 22, weight: .bold))
                                                        .foregroundColor(.black)
                                                }
                                                
                                                Text("Rating")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color.white)
                                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                                            )
                                        }
                                    }
                                    .padding(.top, 10)
                                    
                                    // Delivery Time Badge
                                    HStack(spacing: 8) {
                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.llegoPrimary)
                                        
                                        Text("Entrega en \(store.etaMinutes) min")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.llegoPrimary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(Color.llegoPrimary.opacity(0.1))
                                    )
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                                
                                // Social Links Section - Only show if has social media
                                if let socialMedia = viewModel.socialMedia, !socialMedia.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Conéctate con nosotros")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.black)

                                        HStack(spacing: 12) {
                                            // Instagram
                                            if let instagramUrl = viewModel.getSocialMediaUrl(for: "instagram") {
                                                SocialButton(
                                                    iconAsset: "Instagram",
                                                    title: "Instagram",
                                                    gradient: [Color.pink, Color.purple, Color.orange],
                                                    url: instagramUrl
                                                )
                                            }

                                            // Facebook
                                            if let facebookUrl = viewModel.getSocialMediaUrl(for: "facebook") {
                                                SocialButton(
                                                    iconAsset: "Facebook",
                                                    title: "Facebook",
                                                    color: Color.blue,
                                                    url: facebookUrl
                                                )
                                            }
                                        }
                                    }
                                    .padding(20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white)
                                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                                    )
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 24)
                                }
                                
                                // Map Section - Always show, with message if no coordinates
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.llegoPrimary)

                                        Text("Ubicación")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.black)
                                    }

                                    if viewModel.hasCoordinates,
                                       let coordinates = viewModel.branchDetail?.coordinates {
                                        // Show map with coordinates
                                        Map(coordinateRegion: $region, annotationItems: [MapLocation(coordinate: CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude))]) { location in
                                            MapMarker(coordinate: location.coordinate, tint: .llegoPrimary)
                                        }
                                        .frame(height: 200)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                        )
                                        .onAppear {
                                            region = MKCoordinateRegion(
                                                center: CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude),
                                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                            )
                                        }
                                    } else {
                                        // Show placeholder when no coordinates
                                        VStack(spacing: 12) {
                                            Image(systemName: "map.fill")
                                                .font(.system(size: 40, weight: .light))
                                                .foregroundColor(.gray.opacity(0.5))

                                            Text("Sin ubicación disponible")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.secondary)

                                            Text("Esta tienda aún no ha configurado su ubicación")
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary.opacity(0.8))
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                        )
                                    }
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                                )
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                                

                                
                                // Branches Section - Show sibling branches
                                if !viewModel.siblingBranches.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Nuestras Sedes")
                                                    .font(.system(size: 22, weight: .bold))
                                                    .foregroundColor(.black)

                                                Text("\(viewModel.siblingBranches.count) ubicaciones disponibles")
                                                    .font(.system(size: 13, weight: .regular))
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()

                                            if viewModel.siblingBranches.count > 3 {
                                                Button(action: {
                                                    // TODO: Navigate to all branches view
                                                }) {
                                                    HStack(spacing: 4) {
                                                        Text("Ver más")
                                                            .font(.system(size: 14, weight: .semibold))

                                                        Image(systemName: "chevron.right")
                                                            .font(.system(size: 12, weight: .semibold))
                                                    }
                                                    .foregroundColor(.llegoPrimary)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)

                                        if viewModel.isLoadingSiblings {
                                            HStack {
                                                Spacer()
                                                ProgressView()
                                                    .padding()
                                                Spacer()
                                            }
                                        } else {
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 16) {
                                                    ForEach(viewModel.siblingBranches, id: \.id) { branch in
                                                        StoreCard(
                                                            storeName: branch.name,
                                                            etaMinutes: calculateETA(deliveryRadius: branch.deliveryRadius),
                                                            logoUrl: branch.avatarUrl ?? defaultLogoUrl,
                                                            bannerUrl: branch.coverUrl ?? defaultBannerUrl,
                                                            address: branch.address,
                                                            rating: nil,
                                                            size: .medium
                                                        )
                                                    }
                                                }
                                                .padding(.horizontal, 20)
                                            }
                                        }
                                    }
                                    .padding(.bottom, 24)
                                }

                                // Products Section - Show branch products
                                if !viewModel.branchProducts.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Productos")
                                                    .font(.system(size: 22, weight: .bold))
                                                    .foregroundColor(.black)

                                                Text("\(viewModel.branchProducts.count) productos disponibles")
                                                    .font(.system(size: 13, weight: .regular))
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()

                                            NavigationLink(destination: ProductListView(branchId: storeId, branchName: store.name)) {
                                                HStack(spacing: 4) {
                                                    Text("Ver más")
                                                        .font(.system(size: 14, weight: .semibold))

                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 12, weight: .semibold))
                                                }
                                                .foregroundColor(.llegoPrimary)
                                            }
                                        }
                                        .padding(.horizontal, 20)

                                        if viewModel.isLoadingProducts {
                                            HStack {
                                                Spacer()
                                                ProgressView()
                                                    .padding()
                                                Spacer()
                                            }
                                        } else {
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 16) {
                                                    ForEach(viewModel.branchProducts, id: \.id) { product in
                                                        ProductCard(
                                                            product: Product(
                                                                id: product.id,
                                                                name: product.name,
                                                                shop: store.name ?? "Tienda",
                                                                weight: "",
                                                                price: formatPrice(price: product.price, currency: product.currency),
                                                                imageUrl: product.imageUrl
                                                            ),
                                                            count: .constant(0),
                                                            onIncrement: {},
                                                            onDecrement: {}
                                                        )
                                                        .frame(width: 180)
                                                    }
                                                }
                                                .padding(.horizontal, 20)
                                            }
                                        }
                                    }
                                    .padding(.bottom, 40)
                                }
                            }
                            .background(Color.llegoSurface)
                        }
                        }
                        .ignoresSafeArea(edges: .top)
                    } // End of else if let store
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .tabBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton(action: {
                        dismiss()
                    })
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let detail = viewModel.branchDetail {
                    EmptyView()
                        .onAppear {
//                            ShareHelper.shareStore(
//                                id: detail.id,
//                                name: detail.name,
//                                description: detail.address,
//                                imageURL: viewModel.getLogoUrl()
//                            )
//                            showShareSheet = false
                        }
                }
            }
            .onAppear {
                // ALWAYS load full details from backend, even if we have initialStore
                // This ensures we get products, siblings, business info, etc.
                viewModel.loadBranchDetail(id: storeId)
            }
        }
    }
}

// Social Button Component
struct SocialButton: View {
    let iconAsset: String
    let title: String
    var gradient: [Color]? = nil
    var color: Color? = nil
    var url: String? = nil

    var body: some View {
        Button(action: {
            if let urlString = url, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 8) {
                Image(iconAsset)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Group {
                    if let gradient = gradient {
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else if let color = color {
                        color
                    }
                }
            )
            .cornerRadius(14)
            .shadow(color: (color ?? Color.pink).opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

// Helper struct for map annotations
struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// ShareSheet for native sharing
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct StoreDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoreDetailView(
                store: Store(
                    id: "1",
                    name: "Fresh Market",
                    etaMinutes: 25,
                    logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
                    bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center",
                    address: "Av. Principal #123",
                    rating: 4.8
                )
            )
        }
    }
}
