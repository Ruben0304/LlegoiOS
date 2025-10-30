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
    @StateObject private var locationManager = LocationManager()
    @State private var showingLocationPicker = false
    @State private var showingEditName = false
    @State private var showingPaymentMethods = false

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
            locationManager.requestPermission()
            if let location = locationManager.location {
                region.center = location
            }
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation {
                withAnimation {
                    region.center = location
                }
            }
        }
    }

    // MARK: - Authenticated Profile View
    private var authenticatedProfileView: some View {
        NavigationView {
            ZStack {
                Color.llegoBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header futurista con mapa como portada y avatar flotante
                        futuristicProfileHeader

                        VStack(spacing: 24) {
                            // Información de ubicación compacta
                            compactLocationSection

                            // Nivel del cliente con progreso
                            customerLevelSection

                            // Vista previa de pedidos recientes
                            recentOrdersSection

                            // Método de pago preferido
                            preferredPaymentMethodSection

                            // Notificaciones
                            notificationsSection

                            // Botón de cerrar sesión
                            signOutButton

                            Spacer(minLength: 60)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton(action: {
                        dismiss()
                    })
                }
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerView(locationManager: locationManager)
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
                Image(systemName: "arrow.right.square.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.red)

                Text("Cerrar sesión")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.red)

                Spacer()
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Futuristic Profile Header con Mapa como Portada
    private var futuristicProfileHeader: some View {
        ZStack(alignment: .bottom) {
            // Mapa como portada de fondo
            Map(coordinateRegion: .constant(region), interactionModes: [])
                .frame(height: 340)
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

                    // Botón de editar superpuesto
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showingEditName = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.llegoPrimary)
                                        .frame(width: 38, height: 38)
                                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

                                    Image(systemName: "pencil")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(x: 8, y: 8)
                        }
                    }
                    .frame(width: 116, height: 116)
                }
                .padding(.bottom, 12)

                // Información del usuario
                VStack(spacing: 8) {
                    Text(viewModel.currentUser?.fullName ?? "Usuario")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.llegoPrimary)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.llegoAccent)

                        Text(viewModel.currentUser?.email ?? "")
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
                }
                .padding(.bottom, 30)
            }
        }
    }

    // MARK: - Compact Location Section
    private var compactLocationSection: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.llegoPrimary)

                Text("Ubicación de entrega")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)

                Spacer()
            }

            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.llegoAccent.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: "location.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.llegoAccent)
                    }

                    Text(locationManager.address)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.llegoPrimary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: {
                    showingLocationPicker = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Cambiar ubicación")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.llegoPrimary,
                                Color.llegoPrimary.opacity(0.85)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(26)
                    .shadow(color: Color.llegoPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            )
        }
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
                        Text("Cliente Oro")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.llegoPrimary)

                        Text("847 puntos de 1,000")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    // Indicador de siguiente nivel
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("153")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.llegoAccent)

                        Text("para Platino")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }

                // Barra de progreso nativa de iOS
                VStack(spacing: 8) {
                    ProgressView(value: 0.847)
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

    // MARK: - Recent Orders Preview Section
    private var recentOrdersSection: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.llegoAccent)

                Text("Pedidos Recientes")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)

                Spacer()

                NavigationLink(destination: OrderHistoryView()) {
                    HStack(spacing: 4) {
                        Text("Ver todos")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.llegoAccent)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.llegoAccent)
                    }
                }
            }

            VStack(spacing: 10) {
                ForEach(sampleRecentOrders) { order in
                    RecentOrderCard(order: order)
                }
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

    // MARK: - Notifications Section
    private var notificationsSection: some View {
        SimpleInfoCard(
            icon: "bell.fill",
            title: "Notificaciones",
            subtitle: "Configurar preferencias",
            color: .llegoAccent
        ) {
            // Acción para notificaciones
        }
    }

}

struct SimpleInfoCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.12))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.llegoPrimary)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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

// MARK: - Recent Order Model
struct RecentOrder: Identifiable {
    let id: String
    let storeName: String
    let date: String
    let total: String
    let status: OrderStatus
    let itemCount: Int

    enum OrderStatus {
        case delivered
        case inProgress
        case cancelled

        var text: String {
            switch self {
            case .delivered: return "Entregado"
            case .inProgress: return "En camino"
            case .cancelled: return "Cancelado"
            }
        }

        var color: Color {
            switch self {
            case .delivered: return .llegoAccent
            case .inProgress: return .llegoSecondary
            case .cancelled: return .red
            }
        }

        var icon: String {
            switch self {
            case .delivered: return "checkmark.circle.fill"
            case .inProgress: return "shippingbox.fill"
            case .cancelled: return "xmark.circle.fill"
            }
        }
    }
}

// MARK: - Recent Order Card Component
struct RecentOrderCard: View {
    let order: RecentOrder

    var body: some View {
        HStack(spacing: 14) {
            // Status icon
            ZStack {
                Circle()
                    .fill(order.status.color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: order.status.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(order.status.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(order.storeName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.llegoPrimary)

                HStack(spacing: 6) {
                    Text(order.date)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)

                    Text("•")
                        .foregroundColor(.gray.opacity(0.5))

                    Text("\(order.itemCount) productos")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(order.total)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.llegoPrimary)

                Text(order.status.text)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(order.status.color)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
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

// MARK: - Order History View (Stub)
struct OrderHistoryView: View {
    var body: some View {
        ZStack {
            Color.llegoBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(sampleRecentOrders) { order in
                        RecentOrderCard(order: order)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Historial de Pedidos")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Sample Data
private let sampleRecentOrders = [
    RecentOrder(
        id: "1",
        storeName: "Supermercado Plaza",
        date: "Hace 2 días",
        total: "$45.50",
        status: .delivered,
        itemCount: 12
    ),
    RecentOrder(
        id: "2",
        storeName: "Farmacia Central",
        date: "Hace 5 días",
        total: "$28.30",
        status: .delivered,
        itemCount: 5
    ),
    RecentOrder(
        id: "3",
        storeName: "Panadería La Estrella",
        date: "Hace 1 semana",
        total: "$15.80",
        status: .delivered,
        itemCount: 8
    )
]

#Preview {
    ProfileView()
}