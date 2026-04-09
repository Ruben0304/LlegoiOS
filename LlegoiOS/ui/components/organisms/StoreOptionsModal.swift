import SwiftUI

// MARK: - StoreOptionsModal (Native iOS Sheet Style)
struct StoreOptionsModal: View {
    let store: StoreWithCoordinates
    let onViewProfile: () -> Void
    let onViewProducts: () -> Void
    var onDismiss: (() -> Void)? = nil
    
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header con imagen del negocio
            ZStack(alignment: .bottom) {
                // Banner con gradiente elegante
                GeometryReader { geometry in
                    AsyncImage(url: URL(string: store.bannerUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: 180)
                                .clipped()
                        case .empty:
                            ZStack {
                                Color.gray.opacity(0.15)
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .llegoPrimary))
                            }
                            .frame(width: geometry.size.width, height: 180)
                        case .failure:
                            Color.gray.opacity(0.15)
                                .frame(width: geometry.size.width, height: 180)
                        @unknown default:
                            Color.gray.opacity(0.15)
                                .frame(width: geometry.size.width, height: 180)
                        }
                    }
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color(.systemBackground).opacity(0.3),
                                Color(.systemBackground)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
                
                // Logo flotante con cache
                CachedAsyncImage(
                    url: URL(string: store.logoUrl),
                    cacheKey: "store_logo_modal_\(store.id)",
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    },
                    placeholder: {
                        ZStack {
                            Color.gray.opacity(0.2)
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .llegoPrimary))
                        }
                    },
                    failure: {
                        ZStack {
                            Color.gray.opacity(0.15)
                            Image(systemName: "storefront")
                                .font(.system(size: 28))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                )
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(.systemBackground), lineWidth: 4)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                .offset(y: 44)
                .scaleEffect(isAnimated ? 1.0 : 0.8)
                .opacity(isAnimated ? 1 : 0)
            }
            
            Spacer().frame(height: 56)
            
            // MARK: - Información del negocio
            VStack(spacing: 8) {
                Text(store.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                if let isOpen = store.isOpenNow {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isOpen ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(isOpen ? "Abierto ahora" : "Cerrado ahora")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isOpen ? Color.green : Color.red)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill((isOpen ? Color.green : Color.red).opacity(0.1))
                    )
                }

                if let address = store.address {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(address)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .opacity(isAnimated ? 1 : 0)
            .offset(y: isAnimated ? 0 : 10)
            
            Spacer().frame(height: 20)
            
            // MARK: - Pills de información
            HStack(spacing: 16) {
                // Rating
                if let rating = store.rating {
                    InfoPill(
                        icon: "star.fill",
                        iconColor: .orange,
                        value: String(format: "%.1f", rating),
                        label: "Rating"
                    )
                }
                
                // Tiempo de entrega
                InfoPill(
                    icon: "clock.fill",
                    iconColor: .llegoAccent,
                    value: "\(store.etaMinutes)",
                    label: "min"
                )
                

            }
            .padding(.horizontal, 24)
            .opacity(isAnimated ? 1 : 0)
            .offset(y: isAnimated ? 0 : 15)
            
            Spacer().frame(height: 28)
            
            // MARK: - Botones de acción estilo Apple
            VStack(spacing: 12) {
                // Botón primario - Ver productos
                Button(action: onViewProducts) {
                    HStack(spacing: 10) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Ver Productos")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [Color.llegoPrimary, Color.llegoPrimary.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.llegoPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Botón secundario - Ver perfil
                Button(action: onViewProfile) {
                    HStack(spacing: 10) {
                        Image(systemName: "storefront")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Ver Perfil de Tienda")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        Color(.secondarySystemBackground)
                    )
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 20)
            .opacity(isAnimated ? 1 : 0)
            .offset(y: isAnimated ? 0 : 20)
            
            Spacer().frame(height: 16)
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                isAnimated = true
            }
        }
    }
}
