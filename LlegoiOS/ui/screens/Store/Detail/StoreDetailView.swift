import SwiftUI
import MapKit

struct StoreDetailView: View {
    // Support both: passing full Store OR just storeId
    let initialStore: Store?
    let storeId: String

    @StateObject private var viewModel = StoreDetailViewModel()
    @StateObject private var branchLikesManager = BranchLikesManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    @State private var selectedProductId: String?
    @State private var selectedComboId: String?
    @State private var selectedShowcase: ShowcaseGraphQL?
    @State private var showShowcaseAddedToast: Bool = false

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
                                        ZStack {
                                            Color.gray.opacity(0.1)
                                            CircularLoadingIndicator(color: .llegoPrimary, lineWidth: 5, size: 50, useHDR: true)
                                        }
                                        .frame(width: geometry.size.width, height: 280)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width, height: 280)
                                            .clipped()
                                    case .failure:
                                        Image("generic_cover")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width, height: 280)
                                            .clipped()
                                    @unknown default:
                                        Image("generic_cover")
                                            .resizable()
                                            .scaledToFill()
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
                                            ZStack {
                                                Circle()
                                                    .fill(Color.white)
                                                CircularLoadingIndicator(color: .llegoPrimary, lineWidth: 4, size: 30, useHDR: true)
                                            }
                                            .frame(width: 110, height: 110)
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
                                        Map(position: mapPositionBinding) {
                                            Marker("", coordinate: CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude))
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



                                // Branches Section - Redesigned
                                if !viewModel.siblingBranches.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Otras Sedes")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.black)
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
                                                HStack(spacing: 12) {
                                                    ForEach(viewModel.siblingBranches, id: \.id) { branch in
                                                        NavigationLink(destination: StoreDetailView(storeId: branch.id)) {
                                                            SiblingBranchCard(
                                                                branch: branch,
                                                                eta: calculateETA(deliveryRadius: branch.deliveryRadius)
                                                            )
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                    }
                                                }
                                                .padding(.horizontal, 20)
                                                .padding(.bottom, 20) // Space for shadow
                                            }
                                        }
                                    }
                                }

                                // Combos Section
                                if viewModel.isLoadingCombos || !viewModel.branchCombos.isEmpty {
                                    combosSection(store: store)
                                }

                                if viewModel.isLoadingShowcases || !viewModel.branchShowcases.isEmpty {
                                    showcasesSection()
                                }

                                // Products Section - Show branch products
                                if viewModel.isLoadingProducts || !viewModel.branchProducts.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Nuestros productos")
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
                                            LazyVGrid(
                                                columns: [
                                                    GridItem(.flexible(), spacing: 16),
                                                    GridItem(.flexible(), spacing: 16)
                                                ],
                                                alignment: .center,
                                                spacing: 20
                                            ) {
                                                ForEach(Array(viewModel.branchProducts.prefix(4)), id: \.id) { product in
                                                        ProductCard(
                                                            product: Product(
                                                                id: product.id,
                                                                name: product.name,
                                                                shop: store.name,
                                                                weight: "",
                                                                price: formatPrice(price: product.price, currency: product.currency),
                                                                imageUrl: product.imageUrl
                                                            ),
                                                            count: .constant(0),
                                                            onIncrement: {},
                                                            onDecrement: {},
                                                            onProductTap: {
                                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                                selectedProductId = product.id
                                                            }
                                                        )
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.top, 4)
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
                        toggleBranchLike()
                    }) {
                        Image(systemName: branchLikesManager.isLiked(branchId: storeId) ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(branchLikesManager.isLiked(branchId: storeId) ? .red : .primary)
                    }
                }
            }
            .onAppear {
                // ALWAYS load full details from backend, even if we have initialStore
                // This ensures we get products, siblings, business info, etc.
                viewModel.loadBranchDetail(id: storeId)
            }
            .fullScreenCover(item: $selectedProductId) { productId in
                ProductDetailView(productId: productId)
            }
            .fullScreenCover(item: $selectedComboId) { comboId in
                ComboDetailView(comboId: comboId)
            }
            .sheet(item: $selectedShowcase) { showcase in
                ShowcaseOrderSheet(
                    showcase: showcase,
                    branchId: storeId,
                    branchName: store?.name ?? "Tienda"
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showShowcaseAddedToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showShowcaseAddedToast = false
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showShowcaseAddedToast {
                    Text("Se agregó el pedido de vitrina al carrito")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.85)))
                        .padding(.bottom, 18)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var mapPositionBinding: Binding<MapCameraPosition> {
        Binding(
            get: { .region(region) },
            set: { newPosition in
                _ = newPosition
            }
        )
    }

    @ViewBuilder
    private func showcasesSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vitrinas")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    Text("Pide por descripción manual")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            if viewModel.isLoadingShowcases {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.branchShowcases, id: \.id) { showcase in
                            VStack(alignment: .leading, spacing: 10) {
                                AsyncImage(url: URL(string: showcase.imageUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        ZStack {
                                            Color.gray.opacity(0.12)
                                            ProgressView()
                                        }
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        ZStack {
                                            Color.gray.opacity(0.15)
                                            Image(systemName: "photo")
                                                .font(.system(size: 22, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                    @unknown default:
                                        Color.gray.opacity(0.12)
                                    }
                                }
                                .frame(width: 280, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 14))

                                Text(showcase.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                                    .lineLimit(2)

                                if let description = showcase.description, !description.isEmpty {
                                    Text(description)
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }

                                if let items = showcase.items, !items.isEmpty {
                                    Text("\(min(items.count, 3)) items sugeridos")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.llegoPrimary)
                                } else {
                                    Text("Pide por descripción libre")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.llegoPrimary)
                                }

                                Button(action: {
                                    selectedShowcase = showcase
                                }) {
                                    Text("Pedir desde vitrina")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.llegoPrimary)
                                        )
                                }
                            }
                            .padding(12)
                            .frame(width: 304, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 305)
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Combos Section

    @ViewBuilder
    private func combosSection(store: Store) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Combos especiales")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)

                    if !viewModel.branchCombos.isEmpty {
                        Text("\(viewModel.branchCombos.count) \(viewModel.branchCombos.count == 1 ? "combo disponible" : "combos disponibles")")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            if viewModel.isLoadingCombos {
                HStack {
                    Spacer()
                    ProgressView().padding()
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.branchCombos) { combo in
                            ComboCard(
                                combo: Combo(
                                    id: combo.id,
                                    name: combo.name,
                                    description: combo.description,
                                    imageUrl: combo.imageUrl,
                                    shop: combo.branchName,
                                    shopLogoUrl: combo.branchLogoUrl ?? "",
                                    basePrice: combo.basePrice,
                                    finalPrice: combo.finalPrice,
                                    savings: combo.savings,
                                    currency: combo.currency,
                                    discountType: combo.discountType,
                                    discountValue: combo.discountValue,
                                    slotCount: combo.slots.count,
                                    representativeImageUrls: combo.representativeProducts.map { $0.imageUrl }
                                ),
                                onTap: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedComboId = combo.id
                                }
                            )
                            .frame(width: 220)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Helper Methods

    private func toggleBranchLike() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            branchLikesManager.toggleLike(branchId: storeId)
        }
    }
}

struct ShowcaseOrderSheet: View {
    let showcase: ShowcaseGraphQL
    let branchId: String
    let branchName: String
    let onAdded: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var requestDescription: String = ""
    @State private var quantity: Int = 1
    @State private var showValidationError: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Vitrina") {
                    Text(showcase.title)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Este pedido será confirmado por la tienda según disponibilidad y precio final.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }

                Section("Qué necesitas") {
                    TextEditor(text: $requestDescription)
                        .frame(minHeight: 120)
                    if showValidationError {
                        Text("Debes escribir una descripción para pedir desde vitrina.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                }

                Section("Cantidad") {
                    Stepper(value: $quantity, in: 1...20) {
                        Text("\(quantity)")
                    }
                }
            }
            .navigationTitle("Pedir desde vitrina")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Agregar") {
                        let trimmedDescription = requestDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedDescription.isEmpty else {
                            showValidationError = true
                            return
                        }

                        CartManager.shared.addShowcaseToCart(
                            showcaseId: showcase.id,
                            branchId: branchId,
                            branchName: branchName,
                            title: showcase.title,
                            imageUrl: showcase.imageUrl,
                            requestDescription: trimmedDescription,
                            quantity: quantity
                        )
                        onAdded()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
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

// New Card Design for Sibling Branches
struct SiblingBranchCard: View {
    let branch: BranchGraphQL
    let eta: Int

    var body: some View {
        HStack(spacing: 0) {
            // Image
            AsyncImage(url: URL(string: branch.avatarUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.1)
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image("generic_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                @unknown default:
                    Color.gray.opacity(0.1)
                }
            }
            .frame(width: 80, height: 80)
            .clipped()

            // Info Content
            VStack(alignment: .leading, spacing: 6) {
                Text(branch.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)

                if !branch.address.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(branch.address)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.llegoPrimary)
                    Text("\(eta) min")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.llegoPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.llegoPrimary.opacity(0.1))
                .cornerRadius(6)
            }
            .padding(12)
            .frame(height: 80)

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.trailing, 12)
        }
        .frame(width: 300, height: 80)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

struct StoreDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoreDetailView(storeId: "1")
        }
    }
}
