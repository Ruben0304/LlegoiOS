import SwiftUI

struct SimilarProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Product Image
            AsyncImage(url: URL(string: product.imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 140)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 140)
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 140)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(product.shop)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)

                Text(product.price)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.llegoPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ProductDetailView: View {
    let product: Product
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedVariant = "Queso extra"
    @State private var selectedStoreId: String? = nil
    @State private var selectedStoreForNav: Store? = nil
    @State private var cartItemCount = 3

    private let variants = [
        "Queso extra",
        "Pepperoni",
        "Vegetariana",
        "Hawaiana"
    ]

    private let sampleStores: [Store] = [
        Store(
            id: "1",
            name: "Fresh Market",
            etaMinutes: 25,
            logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"
        ),
        Store(
            id: "2",
            name: "Local Grocery",
            etaMinutes: 30,
            logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=500&h=200&fit=crop&crop=center"
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                CurvedBackground(
                    curveStartAbsolute: 150,
                    curveEndAbsolute: 150,
                    curveInclinationAbsolute: 50,
                    invertCurve: true
                ) {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Product Image
                            AsyncImage(url: URL(string: product.imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 300)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 300)
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 300)
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                            
                            // Product Details Section
                            HStack(alignment: .top, spacing: 16) {
                                // Left side - Product Info
                                VStack(alignment: .leading, spacing: 12) {
                                    // Category Tag
                                    Text("Italiana")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.llegoOnPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.llegoAccent)
                                        .cornerRadius(8)

                                    // Product Name
                                    Text(product.name)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.black)

                                    // Weight
                                    Text(product.weight)
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)

                                    // Variant Picker
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Variante")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)

                                        Picker("", selection: $selectedVariant) {
                                            ForEach(variants, id: \.self) { variant in
                                                Text(variant).tag(variant)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .tint(.llegoPrimary)
                                    }
                                    .padding(.top, 4)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                // Right side - Animated Delivery Status
                                VStack(spacing: 0) {
                                    ZStack {
                                        // Circular progress background
                                        Circle()
                                            .stroke(Color.llegoPrimary.opacity(0.2), lineWidth: 6)
                                            .frame(width: 85, height: 85)

                                        Circle()
                                            .trim(from: 0, to: 0.65)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.llegoPrimary, Color.llegoPrimary.opacity(0.6)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                            )
                                            .frame(width: 85, height: 85)
                                            .rotationEffect(.degrees(-90))

                                        // Center content
                                        VStack(spacing: 2) {
                                            Image(systemName: "bicycle")
                                                .font(.system(size: 22, weight: .semibold))
                                                .foregroundColor(.llegoPrimary)

                                            Text("25'")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.black)
                                        }
                                    }
                                    .padding(.bottom, 8)

                                    // Distance badge
                                    HStack(spacing: 4) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("2.5 km")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.llegoPrimary, Color.llegoPrimary.opacity(0.8)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                                }
                                .frame(width: 95)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                            Divider()
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)

                            // Price and Add to Cart Button
                            HStack(alignment: .center, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Precio")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)

                                    Text(product.price)
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundColor(.llegoPrimary)
                                }

                                Spacer()

                                Button(action: {
                                    print("Agregar al carrito tapped")
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "cart.fill.badge.plus")
                                            .font(.system(size: 17, weight: .semibold))
                                        Text("Agregar")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(Color.llegoPrimary)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 20)

                            // Store Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Selecciona vendedor")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(sampleStores, id: \.id) { store in
                                            StoreCard(
                                                storeName: store.name,
                                                etaMinutes: store.etaMinutes,
                                                logoUrl: store.logoUrl,
                                                bannerUrl: store.bannerUrl,
                                                address: store.address,
                                                rating: store.rating,
                                                size: .medium
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(
                                                        selectedStoreId == store.id ? Color.llegoPrimary : Color.clear,
                                                        lineWidth: 3
                                                    )
                                            )
                                            .onTapGesture {
                                                selectedStoreForNav = store
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.top, 24)

                            // Similar Products Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Productos similares")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(0..<5) { index in
                                            SimilarProductCard(
                                                product: Product(
                                                    id: String(index),
                                                    name: "Producto \(index + 1)",
                                                    shop: "Shop",
                                                    weight: "500g",
                                                    price: "$4.99",
                                                    imageUrl: product.imageUrl
                                                )
                                            )
                                            .frame(width: 160, height: 280)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.top, 24)
                            .padding(.bottom, 32)

                            // Navigation link for Store Detail
                            NavigationLink(
                                destination: selectedStoreForNav.map { StoreDetailView(store: $0) },
                                isActive: Binding(
                                    get: { selectedStoreForNav != nil },
                                    set: { if !$0 { selectedStoreForNav = nil } }
                                )
                            ) {
                                EmptyView()
                            }
                            .hidden()
                        }.padding(.top,-45)
                    }
                    .padding(.top, 60)
                    .zIndex(100)
                    .clipped()
                }.zIndex(200)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.llegoPrimary)
                        .font(.system(size: 18, weight: .semibold))
                }.buttonStyle(.glassProminent)
                    .tint(Color.white)
            }

            ToolbarItem(placement: .principal) {
                Text(product.name)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                ZStack(alignment: .topTrailing) {
                    Button(action: {
                        print("Cart tapped")
                    }) {
                        Image(systemName: "cart")
                            .foregroundColor(Color.llegoPrimary)
                            .font(.system(size: 18, weight: .semibold))
                    }.badge(cartItemCount)
                        .buttonStyle(.glassProminent)
                            .tint(Color.white)

                }
            }
        }
    }
}

struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProductDetailView(
                product: Product(
                    id: "1",
                    name: "Pizza",
                    shop: "FreshMart",
                    weight: "500g",
                    price: "$4.99",
                    imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen PNG.png"
                )
            )
        }
    }
}
