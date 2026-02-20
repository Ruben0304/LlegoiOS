import SwiftUI
import MapKit

// Extension to make CLLocationCoordinate2D conform to Equatable
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject private var userLocationManager = UserLocationManager.shared
    @State private var showingLocationPicker = false
    @State private var showingEditName = false
    @State private var showingPaymentMethods = false
    @State private var showingWallet = false
    @State private var navigateToPlansAndPricing = false
    @State private var cachedProfile: ProfileLocalCache.Snapshot? = ProfileLocalCache.load()
    @State private var didTriggerRefresh = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedOrderId: String = ""
    private let defaultCustomerLevel: CustomerLevel = .gold
    private let defaultCurrentPoints: Int = 847
    private let defaultNextLevelPoints: Int = 1000
    private let walletBalance: String = "$120.50"

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        Group {
            switch viewModel.state {
            case .unauthenticated, .idle:
                // Mostrar pantalla de login
                LoginView(viewModel: viewModel)

            case .authenticated:
                // Mostrar perfil del usuario
                authenticatedProfileView

            case .loading:
                // Loading state
                loadingView

            case .error(let message):
                // Error state
                errorView(message: message)
            }
        }
        .onAppear {
            viewModel.checkAuthenticationStatus()
            loadCachedProfile()
            userLocationManager.requestPermission()
            if let location = userLocationManager.userLocation {
                region.center = location
            }
            if !didTriggerRefresh {
                didTriggerRefresh = true
                Task {
                    await viewModel.refreshProfile()
                }
            }
        }
        .onChange(of: userLocationManager.userLocation) { newLocation in
            if let location = newLocation {
                withAnimation {
                    region.center = location
                }
            }
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                Task {
                    await viewModel.uploadAvatar(image: image)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ProfileImagePicker(image: $selectedImage)
        }
        .fullScreenCover(isPresented: Binding(
            get: { !selectedOrderId.isEmpty },
            set: { if !$0 { selectedOrderId = "" } }
        )) {
            NavigationStack {
                OrderDetailView(orderId: selectedOrderId) {
                    // Recargar los pedidos recientes cuando se cierra el detalle
                    Task {
                        await viewModel.loadRecentOrders()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        CloseButton {
                            selectedOrderId = ""
                        }
                    }
                }
            }
        }
    }

    private var customerLevelProgress: Double {
        let points = effectiveCurrentPoints
        let maxPoints = effectiveNextLevelPoints
        guard maxPoints > 0 else { return 0 }
        return min(max(Double(points) / Double(maxPoints), 0), 1)
    }

    private var nextCustomerLevel: CustomerLevel? {
        CustomerLevel(rawValue: effectiveCustomerLevel.rawValue + 1)
    }

    private var pointsToNextLevel: Int {
        max(effectiveNextLevelPoints - effectiveCurrentPoints, 0)
    }

    private var effectiveCustomerLevel: CustomerLevel {
        if let raw = cachedProfile?.customerLevelRaw, let level = CustomerLevel(rawValue: raw) {
            return level
        }
        return defaultCustomerLevel
    }

    private var effectiveCurrentPoints: Int {
        cachedProfile?.currentPoints ?? defaultCurrentPoints
    }

    private var effectiveNextLevelPoints: Int {
        cachedProfile?.nextLevelPoints ?? defaultNextLevelPoints
    }

    private func loadCachedProfile() {
        let cached = ProfileLocalCache.load()
        cachedProfile = cached

        // Usar ubicación del UserLocationManager global
        if let location = userLocationManager.userLocation {
            region.center = location
        }

        guard viewModel.currentUser != nil else { return }

        ProfileLocalCache.update { snapshot in
            if snapshot.customerLevelRaw == nil {
                snapshot.customerLevelRaw = defaultCustomerLevel.rawValue
            }
            if snapshot.currentPoints == nil {
                snapshot.currentPoints = defaultCurrentPoints
            }
            if snapshot.nextLevelPoints == nil {
                snapshot.nextLevelPoints = defaultNextLevelPoints
            }
            if snapshot.fullName == nil {
                snapshot.fullName = viewModel.currentUser?.fullName
            }
            if snapshot.email == nil {
                snapshot.email = viewModel.currentUser?.email
            }
        }

        cachedProfile = ProfileLocalCache.load()
    }

    // MARK: - Authenticated Profile View
    private var authenticatedProfileView: some View {
        NavigationStack{
            ZStack {
                Color.llegoBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header futurista con mapa como portada y avatar flotante
                        futuristicProfileHeader

                        VStack(spacing: 24) {
                            if viewModel.isRefreshingProfile {
                                profileLoadingIndicator
                            }

                            // Información de ubicación compacta
                            compactLocationSection

                            savedAddressesSection

                            // TODO: Reactivar en post-MVP (Cliente Oro / niveles)
                            // customerLevelSection

                            if !viewModel.isRefreshingProfile {
                                walletQuickAccessSection

                                // Vista previa de pedidos recientes
                                recentOrdersSection
                                
                                // Modelos 3D descargados
                                DownloadedModelsSection()

                                // Tutoriales
                                tutorialsSection

                                // Notificaciones
                                notificationsSection

                                // Botón de cerrar sesión
                                signOutButton
                            }

                            Spacer(minLength: 60)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }

            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton(action: {
                        dismiss()
                    })
                }
                // TODO: Reactivar en post-MVP (Cliente Oro / niveles)
                // ToolbarItem(placement: .navigationBarTrailing) {
                //     customerLevelToolbarItem
                // }
                ToolbarSpacer(.fixed,placement:.navigationBarTrailing)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        navigateToPlansAndPricing = true
                    }) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.llegoSecondary)
                    }
                    .accessibilityLabel("Planes y precios")
                }
            }
            .navigationDestination(isPresented: $navigateToPlansAndPricing) {
                PlansAndPricingView()
            }
        }
        .fullScreenCover(isPresented: $showingWallet) {
            WalletView()
        }
        .sheet(isPresented: $showingLocationPicker) {
            ProfileLocationPickerView()
        }
        .sheet(isPresented: $showingEditName) {
            EditNameView(userName: Binding(
                get: { viewModel.currentUser?.fullName ?? "Usuario" },
                set: { _ in }
            ))
        }
        .sheet(isPresented: $showingPaymentMethods) {
            PaymentMethodsSheet()
        }
        .sheet(isPresented: $viewModel.showEditUsernameSheet) {
            EditUsernameSheet(viewModel: viewModel)
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        ZStack {
            Color.llegoBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                LottieView(name: "loading")
                    .frame(width: 150, height: 150)

                Text("Cargando perfil...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
    }

    private var profileLoadingIndicator: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.llegoPrimary)

            Text("Cargando datos del perfil...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Error View
    private func errorView(message: String) -> some View {
        ZStack {
            Color.llegoBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)

                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button(action: {
                    viewModel.checkAuthenticationStatus()
                }) {
                    Text("Reintentar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 150, height: 50)
                        .background(Color.llegoButton)
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Sign Out Button
    private var signOutButton: some View {
        Button(action: {
            viewModel.signOut()
        }) {
            HStack(spacing: 14) {
                Image(systemName: "arrow.right.square")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.red)

                Text("Cerrar sesión")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Futuristic Profile Header con Mapa como Portada
    private var futuristicProfileHeader: some View {
        ZStack(alignment: .bottom) {
            // Mapa como portada de fondo
            Map(coordinateRegion: .constant(region), interactionModes: [])
                .frame(height: 380)
                .opacity(0.6) // Opacidad base del mapa
                .overlay(
                    // Gradient overlay para efecto de desvanecimiento progresivo
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.llegoBackground.opacity(0.3), location: 0.0),
                            .init(color: Color.clear, location: 0.25),
                            .init(color: Color.clear, location: 0.5),
                            .init(color: Color.llegoBackground.opacity(0.4), location: 0.85),
                            .init(color: Color.llegoBackground, location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // Efecto de blur sutil en los bordes
                    VStack(spacing: 0) {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.2),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)

                        Spacer()
                    }
                )
                .disabled(true)

            // Contenedor del avatar y nombre (flotante)
            VStack(spacing: 16) {
                // Avatar flotante con efecto de profundidad
                ZStack {
                    // Shadow exterior para profundidad
                    Circle()
                        .fill(Color.black.opacity(0.15))
                        .frame(width: 128, height: 128)
                        .blur(radius: 20)
                        .offset(y: 8)

                    // Border con gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.llegoBackground.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 124, height: 124)

                    // Avatar principal
                    Group {
                        if let avatarUrl = viewModel.currentUser?.avatarUrl, !avatarUrl.isEmpty {
                            // Mostrar imagen del avatar
                            AsyncImage(url: URL(string: avatarUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 116, height: 116)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 116, height: 116)
                                        .clipShape(Circle())
                                case .failure:
                                    // Mostrar icono por defecto si falla
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.llegoAccent.opacity(0.3),
                                                    Color.llegoPrimary.opacity(0.2)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 116, height: 116)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 48, weight: .medium))
                                                .foregroundColor(.llegoPrimary)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            // Mostrar icono por defecto
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.llegoAccent.opacity(0.3),
                                            Color.llegoPrimary.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 116, height: 116)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 48, weight: .medium))
                                        .foregroundColor(.llegoPrimary)
                                )
                        }
                    }
                    
                    // Loading overlay
                    if viewModel.isUploadingAvatar {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 116, height: 116)
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    }

                    // Botón de editar superpuesto
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.llegoPrimary)
                                        .frame(width: 38, height: 38)
                                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

                                    Image(systemName: viewModel.isUploadingAvatar ? "hourglass" : "camera.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .disabled(viewModel.isUploadingAvatar)
                            .offset(x: 8, y: 8)
                        }
                    }
                    .frame(width: 116, height: 116)
                }
                .padding(.bottom, 12)

                // Información del usuario
                VStack(spacing: 8) {
                    Text(viewModel.currentUser?.fullName ?? cachedProfile?.fullName ?? "Usuario")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.llegoPrimary)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.llegoAccent)

                        Text(viewModel.currentUser?.email ?? cachedProfile?.email ?? "")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    )
                    
                    // Username section
                    Button(action: {
                        viewModel.editingUsername = viewModel.currentUser?.username ?? ""
                        viewModel.showEditUsernameSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "at")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.llegoPrimary)

                            Text(viewModel.currentUser?.username ?? "")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, 30)
            }
            .offset(y: 12)
        }
    }

    // MARK: - Compact Location Section
    private var compactLocationSection: some View {
        Button(action: {
            showingLocationPicker = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "location.circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ubicación de entrega")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.llegoPrimary)

                    Text(userLocationManager.userAddress)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var savedAddressesSection: some View {
        NavigationLink(destination: SavedAddressesView(isSelectingDeliveryAddress: false, onSelectAddress: nil)) {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mis direcciones")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.llegoPrimary)

                    Text("Gestiona tus lugares de entrega")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var walletQuickAccessSection: some View {
        Button(action: {
            showingWallet = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "creditcard")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Wallet")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.llegoPrimary)

                    Text("Saldo disponible")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(walletBalance)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.llegoPrimary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Customer Level Section
    private var customerLevelSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.llegoSecondary)

                Text("Nivel de Cliente")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)

                Spacer()
            }

            VStack(spacing: 16) {
                // Badge de nivel actual
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.llegoSecondary.opacity(0.3),
                                        Color.llegoSecondary.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)

                        Image(systemName: "star.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.llegoSecondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cliente \(effectiveCustomerLevel.name)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.llegoPrimary)

                        Text("\(effectiveCurrentPoints) puntos de \(effectiveNextLevelPoints)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    // Indicador de siguiente nivel
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(pointsToNextLevel)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.llegoAccent)

                        Text(nextCustomerLevel.map { "para \($0.name)" } ?? "Nivel máximo")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }

                // Barra de progreso nativa de iOS
                VStack(spacing: 8) {
                    ProgressView(value: customerLevelProgress)
                        .tint(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.llegoSecondary,
                                    Color.llegoAccent
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(x: 1, y: 2, anchor: .center)

                    // Indicadores de niveles
                    HStack(spacing: 4) {
                        ForEach(CustomerLevel.allCases, id: \.self) { level in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(level.rawValue <= 3 ? level.color : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)

                                Text(level.name)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(level.rawValue <= 3 ? .llegoPrimary : .gray.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            )
        }
    }

    private var customerLevelToolbarItem: some View {
        let level = effectiveCustomerLevel
        let contentWidth: CGFloat = 128
        let checkpointLevels: [CustomerLevel] = [.bronze, .silver, .gold, .platinum]

        return NavigationLink(destination: CustomerLevelBenefitsView()) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(level.name)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)

                    Spacer(minLength: 6)

                    Text("\(effectiveCurrentPoints) pts")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.08))

                    Capsule()
                        .fill(level.color)
                        .frame(width: contentWidth * CGFloat(customerLevelProgress))

                    HStack(spacing: 0) {
                        ForEach(checkpointLevels.indices, id: \.self) { index in
                            let checkpoint = checkpointLevels[index]
 
                            Circle()
                                .fill(checkpoint.rawValue <= level.rawValue ? checkpoint.color : Color.black.opacity(0.25))
                                .frame(width: 4, height: 4)

                            if index != checkpointLevels.count - 1 {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .frame(width: contentWidth, height: 6)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .tint(level.color)
        .buttonStyle(.glassProminent)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nivel \(level.name)")
        .accessibilityValue("\(effectiveCurrentPoints) de \(effectiveNextLevelPoints) puntos")
    }

    // MARK: - Recent Orders Preview Section
    private var recentOrdersSection: some View {
        let orders = viewModel.recentOrders

        return VStack(spacing: 12) {
            HStack {
                Text("Pedidos recientes")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.llegoPrimary)

                Spacer()

                NavigationLink(destination: OrderListView()) {
                    Text("Ver todos")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            
            if viewModel.isLoadingOrders {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(.llegoPrimary)
                    Text("Cargando pedidos...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
            } else if orders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bag")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No tienes pedidos aún")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(orders.enumerated()), id: \.element.id) { index, order in
                        Button {
                            selectedOrderId = order.id
                        } label: {
                            minimalOrderRow(order, isLast: index == orders.count - 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
            }
        }
    }

    private func minimalOrderRow(_ order: RecentOrder, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.storeName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.llegoPrimary)

                    Text(order.formattedDate)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(order.formattedTotal)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.llegoPrimary)

                    Text(order.status.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(order.status.color)
                }
            }
            .padding(16)

            if !isLast {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }

    // MARK: - Preferred Payment Method Section
    private var preferredPaymentMethodSection: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.llegoPrimary)

                Text("Método de Pago Preferido")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)

                Spacer()
            }

            Button(action: {
                showingPaymentMethods = true
            }) {
                HStack(spacing: 16) {
                    // Ícono de tarjeta
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.llegoPrimary,
                                        Color.llegoPrimary.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)

                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("Visa")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.llegoPrimary)

                            // Badge de preferido
                            Text("PREFERIDA")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.llegoAccent)
                                )
                        }

                        HStack(spacing: 4) {
                            Text("•••• •••• •••• 4532")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            Text("•")
                                .foregroundColor(.gray.opacity(0.5))

                            Text("Vence 08/26")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.5))
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Tutorials Section
    private var tutorialsSection: some View {
        VStack(spacing: 12) {
            // Enlace a página de tutoriales
            NavigationLink(destination: TutorialsView()) {
                HStack(spacing: 12) {
                    Image(systemName: "play.rectangle")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tutoriales")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.llegoPrimary)

                        Text("Aprende a usar Llego")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.6))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Botón para mostrar tutoriales en feed
            if !TutorialsHelper.areTutorialsVisible {
                Button(action: {
                    TutorialsHelper.showTutorials()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.llegoAccent)

                        Text("Mostrar tutoriales en el feed")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.llegoPrimary)

                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.llegoAccent.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Notifications Section
    private var notificationsSection: some View {
        Button(action: {
            // Acción para notificaciones
        }) {
            HStack(spacing: 12) {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Notificaciones")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.llegoPrimary)

                    Text("Personaliza tus avisos")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

}


struct EditNameView: View {
    @Binding var userName: String
    @Environment(\.presentationMode) var presentationMode
    @State private var tempName: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.llegoBackground.ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nombre completo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.llegoPrimary)

                        HStack(spacing: 16) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.llegoAccent)

                            TextField("Ingresa tu nombre", text: $tempName)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.llegoPrimary)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.llegoAccent.opacity(0.3), lineWidth: 2)
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                    }
                    .padding(.top, 40)

                    Spacer()

                    Button(action: {
                        if !tempName.isEmpty {
                            userName = tempName
                        }
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Guardar")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.llegoAccent, Color.llegoPrimary]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(27)
                            .shadow(color: Color.llegoAccent.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Editar nombre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton(action: {
                        presentationMode.wrappedValue.dismiss()
                    })
                }
            }
        }
        .onAppear {
            tempName = userName
        }
    }
}

// MARK: - Customer Level Enum
enum CustomerLevel: Int, CaseIterable {
    case basic = 0
    case bronze = 1
    case silver = 2
    case gold = 3
    case platinum = 4

    var name: String {
        switch self {
        case .basic: return "Básico"
        case .bronze: return "Bronze"
        case .silver: return "Plata"
        case .gold: return "Oro"
        case .platinum: return "Platino"
        }
    }

    var color: Color {
        switch self {
        case .basic: return Color.gray.opacity(0.6)
        case .bronze: return Color(red: 0.72, green: 0.45, blue: 0.20)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .gold: return Color.llegoSecondary
        case .platinum: return Color(red: 0.53, green: 0.48, blue: 0.63)
        }
    }

    var icon: String {
        switch self {
        case .basic: return "circle"
        case .bronze: return "circle.fill"
        case .silver: return "sparkle"
        case .gold: return "star.fill"
        case .platinum: return "crown.fill"
        }
    }
}



// MARK: - Payment Methods Sheet
struct PaymentMethodsSheet: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                Color.llegoBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Tarjeta actual
                        PaymentCardView(
                            type: "Visa",
                            lastFour: "4532",
                            expiryDate: "08/26",
                            isPreferred: true,
                            cardColor: .llegoPrimary
                        )

                        PaymentCardView(
                            type: "Mastercard",
                            lastFour: "8821",
                            expiryDate: "12/25",
                            isPreferred: false,
                            cardColor: .llegoTertiary
                        )

                        // Botón para agregar tarjeta
                        Button(action: {
                            // Acción para agregar tarjeta
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.llegoAccent)

                                Text("Agregar método de pago")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.llegoPrimary)

                                Spacer()
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.llegoAccent.opacity(0.3), lineWidth: 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(Color.white)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Métodos de Pago")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloseButton {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Payment Card View Component
struct PaymentCardView: View {
    let type: String
    let lastFour: String
    let expiryDate: String
    let isPreferred: Bool
    let cardColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: cardIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if isPreferred {
                    Text("PREFERIDA")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(cardColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                }
            }

            Spacer()

            Text("•••• •••• •••• \(lastFour)")
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("VENCE")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))

                    Text(expiryDate)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                Spacer()

                Text(type)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(24)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            cardColor,
                            cardColor.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: cardColor.opacity(0.4), radius: 20, x: 0, y: 10)
        )
    }

    private var cardIcon: String {
        switch type.lowercased() {
        case "visa":
            return "creditcard.fill"
        case "mastercard":
            return "creditcard.circle.fill"
        default:
            return "creditcard.fill"
        }
    }
}

// MARK: - Profile Image Picker
struct ProfileImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ProfileImagePicker

        init(_ parent: ProfileImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}



#Preview {
    ProfileView()
}


// MARK: - Edit Username Sheet
struct EditUsernameSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isUsernameFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.llegoPrimary.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "at.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.llegoPrimary)
                    }
                    
                    Text("Editar nombre de usuario")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Tu nombre de usuario es único y otros usuarios pueden usarlo para enviarte dinero.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nombre de usuario")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Text("@")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        TextField("usuario", text: $viewModel.editingUsername)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .font(.system(size: 18, weight: .medium))
                            .focused($isUsernameFocused)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    
                    Text("Solo letras, números, puntos y guiones bajos")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
                .padding(.horizontal)
                
                if let errorMessage = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                }
                
                Button(action: {
                    Task {
                        await viewModel.updateUsername(newUsername: viewModel.editingUsername)
                    }
                }) {
                    ZStack {
                        if viewModel.isUpdatingUsername {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Guardar cambios")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.llegoPrimary)
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .disabled(viewModel.editingUsername.isEmpty || viewModel.isUpdatingUsername)
                .opacity(viewModel.editingUsername.isEmpty ? 0.6 : 1)
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Editar username")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isUsernameFocused = true
            }
        }
    }
}
