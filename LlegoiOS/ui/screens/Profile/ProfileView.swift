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

                            // Información mínima
                            minimalInfoSection

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

    private var minimalInfoSection: some View {
        VStack(spacing: 12) {
            SimpleInfoCard(
                icon: "clock.arrow.circlepath",
                title: "Historial",
                subtitle: "27 pedidos",
                color: .llegoAccent
            ) {
                // Acción para historial
            }

            SimpleInfoCard(
                icon: "creditcard.fill",
                title: "Métodos de pago",
                subtitle: "2 tarjetas guardadas",
                color: .llegoPrimary
            ) {
                // Acción para métodos de pago
            }

            SimpleInfoCard(
                icon: "bell.fill",
                title: "Notificaciones",
                subtitle: "Configurar preferencias",
                color: .llegoSecondary
            ) {
                // Acción para notificaciones
            }
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

#Preview {
    ProfileView()
}