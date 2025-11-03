import SwiftUI

struct ProductListItem: View {
    let product: Product
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
            // Imagen cuadrada con esquinas redondeadas más pequeña
            CachedAsyncImage(
                url: URL(string: product.imageUrl),
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
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Contenido del producto
            VStack(alignment: .leading, spacing: 3) {
                // Nombre del producto
                Text(product.name)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .foregroundColor(Color(red: 27/255, green: 27/255, blue: 27/255))
                    .lineLimit(1)

                // Shop y peso
                Text("\(product.shop) • \(product.weight)")
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Precio
                Text(product.price)
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundColor(.llegoPrimary)
            }

            Spacer()

            // Botón de añadir más pequeño
            Button(action: {
                // Acción de añadir al carrito
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.llegoPrimary)
            }
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
            // Imagen cuadrada con esquinas redondeadas
            CachedAsyncImage(
                url: URL(string: product.imageUrl),
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
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Contenido del producto
            VStack(alignment: .leading, spacing: 6) {
                // Nombre del producto
                Text(product.name)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(Color(red: 27/255, green: 27/255, blue: 27/255))
                    .lineLimit(2)

                // Shop y peso
                HStack(spacing: 4) {
                    Text(product.shop)
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)

                    Text(product.weight)
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(.secondary)
                }

                // Precio
                Text(product.price)
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(.llegoPrimary)
            }

            Spacer()

            // Botón de añadir
            Button(action: {
                // Acción de añadir al carrito
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.llegoPrimary)
            }
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
        ProductListItem(
            product: Product(
                id: "1",
                name: "Aguacate orgánico",
                shop: "FreshMart",
                weight: "500g",
                price: "$2.50",
                imageUrl: "https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=400"
            )
        )

        ProductListItem(
            product: Product(
                id: "2",
                name: "Mango maduro de temporada",
                shop: "EcoFruit",
                weight: "1kg",
                price: "$3.99",
                imageUrl: "https://images.unsplash.com/photo-1553279768-865429fa0078?w=400"
            )
        )
    }
    .padding()
    .background(Color.llegoBackground)
}
