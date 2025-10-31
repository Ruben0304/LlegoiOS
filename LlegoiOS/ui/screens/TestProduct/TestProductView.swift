import SwiftUI

struct TestProductView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var imageLoaded = false
    @State private var showStoreSelector = false
    @State private var showVariantsSheet = false
    @State private var navigateToSimilar = false
    @State private var selectedStore: Store? = Store(
        id: "3",
        name: "TropicalFresh Market",
        etaMinutes: 20,
        logoUrl: "https://images.unsplash.com/photo-1534723328310-e82dad3ee43f?w=200&h=200&fit=crop&crop=center",
        bannerUrl: "https://images.unsplash.com/photo-1506617420156-8e4536971650?w=500&h=200&fit=crop&crop=center",
        address: "Calle 10 #234, Plaza",
        rating: 4.9
    )

    // URL de la imagen de prueba
    private let imageURL = "https://recetasdecocina.elmundo.es/wp-content/uploads/2025/02/brocoli-al-vapor.jpg"

    var body: some View {
        NavigationStack {
            ZStack {
                // Background with blur effect
                BackgroundImageWithBlur(imageURL: imageURL, imageLoaded: $imageLoaded)
                    .ignoresSafeArea()

            
                    // Bottom content
                    VStack(alignment: .leading, spacing: 16) {
                        // Brand/Source
                        Text("Serious Eats")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        // Product title
                        Text("Foolproof Pan Pizza")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        // Author
                        Text("J. Kenji López-Alt")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))

                        // Recipe info
                        HStack(spacing: 24) {
                            RecipeInfoItem(
                                label: "TOTAL TIME",
                                value: "10hr 45min"
                            )

                            RecipeInfoItem(
                                label: "COOK TIME",
                                value: "20min"
                            )

                            RecipeInfoItem(
                                label: "YIELD",
                                value: "4"
                            )
                        }
                        .padding(.vertical, 8)

                        // Store selector card
                        Button(action: {
                            showStoreSelector = true
                        }) {
                            HStack(spacing: 12) {
                                // Store logo or icon
                                if let store = selectedStore {
                                    AsyncImage(url: URL(string: store.logoUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .overlay(
                                                ProgressView()
                                                    .tint(.white)
                                            )
                                    }
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 60, height: 60)

                                        Image(systemName: "storefront.fill")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("VENDEDOR")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))

                                    Text(selectedStore?.name ?? "Seleccionar vendedor")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Action buttons
                        HStack(spacing: 12) {
                            ActionButton(
                                icon: "cart.fill",
                                title: "Agregar",
                                style: .secondary,
                                action: {
                                    // Agregar al carrito
                                    print("Producto agregado al carrito")
                                }
                            )

                            ActionButton(
                                icon: "rectangle.grid.2x2",
                                title: "Similares",
                                style: .secondary,
                                action: {
                                    navigateToSimilar = true
                                }
                            )

                            ActionButton(
                                icon: "slider.horizontal.3",
                                title: "Variantes",
                                style: .secondary,
                                action: {
                                    showVariantsSheet = true
                                }
                            )
                        }

                       
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 75)
                    .padding(.bottom, 32)
                
            }
            .navigationBarBackButtonHidden(true)
            .toolbar{
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton(action: {
                        dismiss()
                    })
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Acción de opciones
                    }) {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .sheet(isPresented: $showStoreSelector) {
            StoreSelectorSheet(selectedStore: $selectedStore)
        }
        .sheet(isPresented: $showVariantsSheet) {
            VariantsSheet()
        }
        .fullScreenCover(isPresented: $navigateToSimilar) {
            NavigationView {
                ShopView(category: nil)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - Background Image with Blur Effect
struct BackgroundImageWithBlur: View {
    let imageURL: String
    @Binding var imageLoaded: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Imagen inferior (CON blur) - INVERTIDA para efecto de reflejo
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Color.black
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .rotation3DEffect(
                                .degrees(180),
                                axis: (x: 1, y: 0, z: 0)
                            )
                            .blur(radius: 70) // Blur más pronunciado
                            .clipped()
                    case .failure:
                        Color.black
                    @unknown default:
                        Color.black
                    }
                }

                // Imagen superior (SIN blur) - Solo ocupa el espacio visible
                VStack {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width)
                                .clipped()
                                .mask {
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: .white, location: 0.0),
                                            .init(color: .white, location: 0.60),
                                            .init(color: .white.opacity(0.7), location: 0.72),
                                            .init(color: .white.opacity(0.3), location: 0.85),
                                            .init(color: .clear, location: 0.95)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                                .onAppear {
                                    imageLoaded = true
                                }
                        default:
                            EmptyView()
                        }
                    }
                    Spacer()
                }
            }
            .overlay {
                // Gradient overlay for better text readability
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .clear,
                        .black.opacity(0.3),
                        .black.opacity(0.7),
                        .black.opacity(0.85)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

// MARK: - Recipe Info Item
struct RecipeInfoItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let style: ActionButtonStyle
    var action: (() -> Void)? = nil

    enum ActionButtonStyle {
        case primary
        case secondary
    }

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(style == .primary ? .black : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(style == .primary ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Store Selector Sheet
struct StoreSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedStore: Store?
    @State private var searchText = ""

    private let allStores: [Store] = [
        Store(id: "1", name: "FreshMart Premium", etaMinutes: 25,
              logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
              bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center",
              address: "Calle 23 #456, Vedado",
              rating: 4.8),
        Store(id: "2", name: "EcoFruit Orgánico", etaMinutes: 30,
              logoUrl: "https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=200&h=200&fit=crop&crop=center",
              bannerUrl: "https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=500&h=200&fit=crop&crop=center",
              address: "Av. 5ta #789, Miramar",
              rating: 4.6),
        Store(id: "3", name: "TropicalFresh Market", etaMinutes: 20,
              logoUrl: "https://images.unsplash.com/photo-1534723328310-e82dad3ee43f?w=200&h=200&fit=crop&crop=center",
              bannerUrl: "https://images.unsplash.com/photo-1506617420156-8e4536971650?w=500&h=200&fit=crop&crop=center",
              address: "Calle 10 #234, Plaza",
              rating: 4.9),
        Store(id: "4", name: "Berry Farm Co.", etaMinutes: 35,
              logoUrl: "https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=200&h=200&fit=crop&crop=center",
              bannerUrl: "https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=500&h=200&fit=crop&crop=center",
              address: "Calle L #567, Vedado",
              rating: 4.5),
        Store(id: "5", name: "CitrusMax Express", etaMinutes: 15,
              logoUrl: "https://images.unsplash.com/photo-1587334207814-e80e8e0adf11?w=200&h=200&fit=crop&crop=center",
              bannerUrl: "https://images.unsplash.com/photo-1597714026720-8f74c62310c9?w=500&h=200&fit=crop&crop=center",
              address: "Av. Paseo #890, Nuevo Vedado",
              rating: 4.7),
        Store(id: "6", name: "GreenGarden Local", etaMinutes: 40,
              logoUrl: "https://images.unsplash.com/photo-1516594798947-e65505dbb29d?w=200&h=200&fit=crop&crop=center",
              bannerUrl: "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&h=200&fit=crop&crop=center",
              address: "Calle 42 #123, Playa",
              rating: 4.3)
    ]

    private var filteredStores: [Store] {
        if searchText.isEmpty {
            return allStores
        }
        return allStores.filter { store in
            store.name.localizedCaseInsensitiveContains(searchText) ||
            (store.address?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.llegoBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Buscar vendedor...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    // Stores list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredStores) { store in
                                Button(action: {
                                    selectedStore = store
                                    dismiss()
                                }) {
                                    StoreCard(
                                        storeName: store.name,
                                        etaMinutes: store.etaMinutes,
                                        logoUrl: store.logoUrl,
                                        bannerUrl: store.bannerUrl,
                                        address: store.address,
                                        rating: store.rating,
                                        size: .expanded
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    }

                    if filteredStores.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "storefront.fill")
                                .font(.system(size: 60, weight: .light))
                                .foregroundColor(.gray.opacity(0.5))

                            Text("No se encontraron vendedores")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.gray)

                            Text("Intenta con otros términos de búsqueda")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 80)
                    }
                }
            }
            .navigationTitle("Seleccionar Vendedor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Variants Sheet
struct VariantsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSize = "Mediano"
    @State private var selectedExtras: Set<String> = []

    private let sizes = ["Pequeño", "Mediano", "Grande"]
    private let extras = [
        ("Queso extra", "$2.00"),
        ("Aceitunas", "$1.50"),
        ("Champiñones", "$2.50"),
        ("Pepperoni extra", "$3.00"),
        ("Jalapeños", "$1.00")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.llegoBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Size section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tamaño")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.llegoPrimary)

                            VStack(spacing: 8) {
                                ForEach(sizes, id: \.self) { size in
                                    Button(action: {
                                        selectedSize = size
                                    }) {
                                        HStack {
                                            Text(size)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.primary)

                                            Spacer()

                                            if selectedSize == size {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.llegoAccent)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(.gray.opacity(0.3))
                                            }
                                        }
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedSize == size ? Color.llegoAccent.opacity(0.1) : Color.white)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedSize == size ? Color.llegoAccent : Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Extras section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Agregados (Opcional)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.llegoPrimary)

                            VStack(spacing: 8) {
                                ForEach(extras, id: \.0) { extra in
                                    Button(action: {
                                        if selectedExtras.contains(extra.0) {
                                            selectedExtras.remove(extra.0)
                                        } else {
                                            selectedExtras.insert(extra.0)
                                        }
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(extra.0)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.primary)

                                                Text(extra.1)
                                                    .font(.system(size: 14, weight: .regular))
                                                    .foregroundColor(.gray)
                                            }

                                            Spacer()

                                            if selectedExtras.contains(extra.0) {
                                                Image(systemName: "checkmark.square.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.llegoAccent)
                                            } else {
                                                Image(systemName: "square")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.gray.opacity(0.3))
                                            }
                                        }
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedExtras.contains(extra.0) ? Color.llegoAccent.opacity(0.1) : Color.white)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedExtras.contains(extra.0) ? Color.llegoAccent : Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Variantes del Producto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Aplicar") {
                        // Apply variants
                        print("Tamaño: \(selectedSize)")
                        print("Extras: \(selectedExtras)")
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    TestProductView()
}
