import SwiftUI
import MapKit

struct ShopTabLandingView: View {
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var isSearchExpanded = false

    var body: some View {
        NavigationStack {
            ZStack {
                // LinearGradient(
                //     gradient: Gradient(colors: [
                //         Color(red: 12/255, green: 53/255, blue: 49/255),
                //         Color(red: 236/255, green: 240/255, blue: 233/255)
                //     ]),
                //     startPoint: .top,
                //     endPoint: .bottom
                // )
                // .ignoresSafeArea()

                VStack {
                    Spacer(minLength: 40)

                    RadialShopMapView()
                        .frame(height: 360)

                    Spacer(minLength: 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    searchToolbar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: isSearchFocused) { focused in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    isSearchExpanded = focused
                }
            }
        }
    }

    private var searchToolbar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 14))

            TextField("Buscar productos...", text: $searchText)
                .font(.system(size: 15))
                .autocorrectionDisabled()
                .focused($isSearchFocused)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
            }

            if isSearchExpanded {
                Button(action: {
                    isSearchFocused = false
                    searchText = ""
                }) {
                    Text("Cancelar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.llegoPrimary)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
}

private struct RadialShopMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1345, longitude: -82.3589),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )

    @State private var isPulsing = false

    private let shopPins: [ShopPin] = [
        ShopPin(
            coordinate: CLLocationCoordinate2D(latitude: 23.1355, longitude: -82.3600),
            type: .restaurant,
            imageUrl: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&h=200&fit=crop"
        ),
        ShopPin(
            coordinate: CLLocationCoordinate2D(latitude: 23.1338, longitude: -82.3575),
            type: .supermarket,
            imageUrl: "https://images.unsplash.com/photo-1583258292688-d0213dc5a3a8?w=200&h=200&fit=crop"
        )
    ]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * 1.5
            let height = geometry.size.height * 2.5
            let maxDimension = max(width, height)

            ZStack {
                // Mapa rectangular con máscara radial y anotaciones
                Map(coordinateRegion: $region, annotationItems: shopPins) { pin in
                    MapAnnotation(coordinate: pin.coordinate) {
                        ShopMapPinView(
                            pin: pin,
                            action: {
                                print("\(pin.type.label) seleccionado")
                            }
                        )
                    }
                }
                .frame(width: width, height: height)
                .mask(
                    Rectangle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .white.opacity(0.75), location: 0.0),
                                    .init(color: .white.opacity(0.1), location: 0.6),
                                    .init(color: .white.opacity(0.05), location: 0.7),
                                    .init(color: .white.opacity(0.02), location: 0.8),
                                    .init(color: .white.opacity(0.00), location: 0.9),
                                    .init(color: .clear, location: 1.0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: maxDimension * 0.6
                            )
                        )
                        .frame(width: width, height: height)
                )

                // Indicador central
                ShopMapCenterIndicator(isPulsing: isPulsing)
                    .frame(width: 80, height: 80)
                    .allowsHitTesting(false)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

struct ShopPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: ShopPinType
    let imageUrl: String
}

enum ShopPinType {
    case restaurant
    case supermarket

    var icon: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .supermarket: return "cart.fill"
        }
    }

    var color: Color {
        switch self {
        case .restaurant: return Color(red: 255/255, green: 89/255, blue: 94/255)
        case .supermarket: return Color(red: 90/255, green: 132/255, blue: 103/255)
        }
    }

    var label: String {
        switch self {
        case .restaurant: return "Restaurante"
        case .supermarket: return "Supermercado"
        }
    }
}

private struct ShopMapPinView: View {
    let pin: ShopPin
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 0) {
                // Pin head con imagen
                ZStack {
                    // Borde con color
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    pin.type.color,
                                    pin.type.color.opacity(0.85)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    // Imagen de internet
                    AsyncImage(url: URL(string: pin.imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 42, height: 42)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 42, height: 42)
                                .clipShape(Circle())
                        case .failure:
                            Image(systemName: pin.type.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 42, height: 42)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                .shadow(color: pin.type.color.opacity(0.4), radius: 8, x: 0, y: 4)

                // Pin point
                PinTriangle()
                    .fill(pin.type.color)
                    .frame(width: 16, height: 12)
                    .offset(y: -1)

                // Shadow
                Ellipse()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.25),
                                Color.black.opacity(0)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 15
                        )
                    )
                    .frame(width: 30, height: 8)
                    .offset(y: 4)
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .buttonStyle(PlainButtonStyle())
    }
}

private struct PinTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private struct ShopMapCenterIndicator: View {
    let isPulsing: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.llegoPrimary.opacity(0.18))
                .scaleEffect(isPulsing ? 1.2 : 0.9)
                .opacity(isPulsing ? 0 : 0.6)

            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.llegoPrimary,
                            Color.llegoPrimary.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                )
                .shadow(color: Color.llegoPrimary.opacity(0.4), radius: 10, x: 0, y: 5)
        }
        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false), value: isPulsing)
    }
}

#Preview {
    ShopTabLandingView()
}
