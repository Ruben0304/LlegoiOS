import SwiftUI
import MapKit

struct StoreDetailView: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    @State private var showShareSheet = false




    // Sample branch data (user will customize later)
    private let sampleBranches: [Store] = [
        Store(
            id: "branch-1",
            name: "Sede Centro",
            etaMinutes: 20,
            logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center",
            address: "Av. Principal #123",
            rating: 4.7
        ),
        Store(
            id: "branch-2",
            name: "Sede Norte",
            etaMinutes: 25,
            logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=500&h=200&fit=crop&crop=center",
            address: "Calle Comercial #456",
            rating: 4.5
        ),
        Store(
            id: "branch-3",
            name: "Sede Sur",
            etaMinutes: 30,
            logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center",
            address: "Plaza Mayor #789",
            rating: 4.8
        )
    ]

    init(store: Store) {
        self.store = store
        // Default location (user will customize later)
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
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Banner and Profile Section
                            ZStack(alignment: .bottomLeading) {
                                // Banner Image
                                AsyncImage(url: URL(string: store.bannerUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.4)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .overlay(ProgressView())
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: 280)
                                            .clipped()
                                    case .failure:
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.4)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    @unknown default:
                                        EmptyView()
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
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 110, height: 110)
                                                .overlay(ProgressView())
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 5)
                                                )
                                                .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 5)
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
                                                .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 5)
                                        case .failure:
                                            Circle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 110, height: 110)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 5)
                                                )
                                                .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 5)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, -55)
                            }
                            .frame(width: geometry.size.width)
                            .padding(.bottom, 20)
                            
                            // Add space to show full profile logo
                            Spacer()
                                .frame(height: 55)
                            
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
                                
                                // Social Links Section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Conéctate con nosotros")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                    
                                    HStack(spacing: 12) {
                                        // Instagram
                                        SocialButton(
                                            iconAsset: "Instagram",
                                            title: "Instagram",
                                            gradient: [Color.pink, Color.purple, Color.orange]
                                        )
                                        
                                        // Facebook
                                        SocialButton(
                                            iconAsset: "Facebook",
                                            title: "Facebook",
                                            color: Color.blue
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
                                
                                // Map Section
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.llegoPrimary)
                                        
                                        Text("Ubicación")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.black)
                                    }
                                    
                                    Map(coordinateRegion: $region, annotationItems: [MapLocation(coordinate: region.center)]) { location in
                                        MapMarker(coordinate: location.coordinate, tint: .llegoPrimary)
                                    }
                                    .frame(height: 200)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                    )
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
                                

                                
                                // Branches Section
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Nuestras Sedes")
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundColor(.black)
                                            
                                            Text("\(sampleBranches.count) ubicaciones disponibles")
                                                .font(.system(size: 13, weight: .regular))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {}) {
                                            HStack(spacing: 4) {
                                                Text("Ver todas")
                                                    .font(.system(size: 14, weight: .semibold))
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .semibold))
                                            }
                                            .foregroundColor(.llegoPrimary)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(sampleBranches, id: \.id) { branch in
                                                StoreCard(
                                                    storeName: branch.name,
                                                    etaMinutes: branch.etaMinutes,
                                                    logoUrl: branch.logoUrl,
                                                    bannerUrl: branch.bannerUrl,
                                                    address: branch.address,
                                                    rating: branch.rating,
                                                    size: .medium
                                                )
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.bottom, 40)
                            }
                            .background(Color.llegoSurface)
                        }
                    }
                    .ignoresSafeArea(edges: .top)
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
                
                ToolbarItem(placement: .bottomBar) {
                    
                    
                    Spacer()
                    Button(action: {
                        // WhatsApp action
                    }) {
                        HStack(spacing: 8) {
                            Image("WhatsApp")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22)
                            
                            Text("WhatsApp")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }
                    
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [URL(string: "https://llego.app/store/\(store.id)")!])
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

    var body: some View {
        Button(action: {}) {
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
