import SwiftUI

struct SellerListItem: View {
    let store: Store
    var compact: Bool = false
    @State private var isPressed: Bool = false

    var body: some View {
        if compact {
            compactView
        } else {
            regularView
        }
    }

    // Vista compacta para búsqueda expandida
    private var compactView: some View {
        HStack(spacing: 10) {
            // Avatar circular del vendedor más pequeño
            CachedAsyncImage(
                url: URL(string: store.logoUrl),
                content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                },
                placeholder: {
                    ZStack {
                        Color.gray.opacity(0.2)
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            )
            .frame(width: 45, height: 45)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.llegoSecondary.opacity(0.3), lineWidth: 1.5)
            )

            // Contenido del vendedor
            VStack(alignment: .leading, spacing: 3) {
                // Nombre del vendedor
                Text(store.name)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .foregroundColor(Color(red: 27/255, green: 27/255, blue: 27/255))
                    .lineLimit(1)

                // Dirección
                if let address = store.address {
                    Text(address)
                        .font(.system(size: 11, weight: .regular, design: .default))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Rating y ETA
                HStack(spacing: 8) {
                    // Rating
                    if let rating = store.rating {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)

                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }

                    // ETA
                    HStack(spacing: 3) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.llegoAccent)

                        Text("\(store.etaMinutes) min")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }

            Spacer()

            // Ícono de navegación
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color.white)
//                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
//        )
    }

    // Vista regular (original)
    private var regularView: some View {
        HStack(spacing: 16) {
            // Avatar circular del vendedor
            CachedAsyncImage(
                url: URL(string: store.logoUrl),
                content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                },
                placeholder: {
                    ZStack {
                        Color.gray.opacity(0.2)
                        ProgressView()
                    }
                }
            )
            .frame(width: 70, height: 70)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.llegoSecondary.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Contenido del vendedor
            VStack(alignment: .leading, spacing: 6) {
                // Nombre del vendedor
                Text(store.name)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundColor(Color(red: 27/255, green: 27/255, blue: 27/255))
                    .lineLimit(1)

                // Dirección
                if let address = store.address {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Text(address)
                            .font(.system(size: 13, weight: .regular, design: .default))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                // Rating y ETA
                HStack(spacing: 12) {
                    // Rating
                    if let rating = store.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)

                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }

                    // ETA
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.llegoAccent)

                        Text("\(store.etaMinutes) min")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }

            Spacer()

            // Ícono de navegación
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color.white)
//                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
//        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    VStack(spacing: 16) {
        SellerListItem(
            store: Store(
                id: "1",
                name: "FreshMart Premium",
                etaMinutes: 25,
                logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
                bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center",
                address: "Calle 23 #456, Vedado",
                rating: 4.8
            )
        )

        SellerListItem(
            store: Store(
                id: "2",
                name: "EcoFruit Orgánico",
                etaMinutes: 30,
                logoUrl: "https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=200&h=200&fit=crop&crop=center",
                bannerUrl: "https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=500&h=200&fit=crop&crop=center",
                address: "Av. 5ta #789, Miramar",
                rating: 4.6
            )
        )
    }
    .padding()
    .background(Color.llegoBackground)
}
