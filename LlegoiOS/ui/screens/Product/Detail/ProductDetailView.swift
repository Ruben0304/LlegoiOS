import SwiftUI

struct ProductDetailView: View {
    let productId: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProductDetailViewModel()
    @StateObject private var cartManager = CartManager.shared
    @StateObject private var gradientManager = GradientStateManager.shared

    @State private var heroAppeared = false
    @State private var contentAppeared = false
    @State private var quantity: Int = 1
    @State private var selectedStyle = "Clásico"
    @State private var selectedDelivery = "Express 25-35m"
    @State private var similarCounts: [String: Int] = [:]
    @State private var showQuantitySheet = false

    // Animation states
    @State private var showGeneralToast = false

    // Computed property to get current product from ViewModel
    private var product: Product? {
        guard let detail = viewModel.productDetail else {
            return nil
        }

        let formattedPrice = viewModel.formatPrice(price: detail.price, currency: detail.currency)
        return Product(
            id: detail.id,
            name: detail.name,
            shop: detail.businessName,
            shopLogoUrl: detail.businessLogoUrl ?? "",
            weight: detail.weight,
            price: formattedPrice,
            imageUrl: detail.imageUrl
        )
    }

    private let styleOptions = ["Clásico", "Ligero", "Extra queso"]
    private let deliveryOptions = ["Express 25-35m", "Programar hoy", "Recoger en tienda"]
    // TODO: Reemplazar con productos similares reales del backend
    private let similarProducts: [Product] = []

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.llegoBackground.ignoresSafeArea()

            // LOADING STATE
            if viewModel.isLoading {
                loadingView
                    .transition(.opacity)
            }
            // ERROR STATE
            else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
                    .transition(.opacity)
            }
            // SUCCESS STATE
            else if let product = product {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        heroSection(product: product)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .opacity(heroAppeared ? 1 : 0)
                            .offset(y: heroAppeared ? 0 : 20)

                        VStack(spacing: 16) {
                            infoSection(product: product)
                            optionsSection
                            if !similarProducts.isEmpty {
                                similarProductsSection
                            }
                        }
                        .padding(.horizontal, 20)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 14)
                    }
                    .padding(.bottom, 140)
                }
                .transition(.opacity)
            }

        }
        .overlay(alignment: .top) {
            if showGeneralToast {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                    Text("Producto agregado")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.thinMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton(action: dismiss.callAsFunction)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showQuantitySheet = true }) {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: shareProduct) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showQuantitySheet) {
            quantitySheetView
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadProductDetail(id: productId)
        }
        .onChange(of: viewModel.productDetail) { detail in
            if detail != nil {
                startEntranceAnimations()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.llegoPrimary)

            Text("Cargando producto...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Error")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                viewModel.loadProductDetail(id: productId)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Reintentar")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.llegoPrimary)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sections

    private func heroSection(product: Product) -> some View {
        let isPNG = {
            if let ext = URL(string: product.imageUrl)?.pathExtension.lowercased(), ext == "png" {
                return true
            }
            return product.imageUrl.lowercased().contains(".png")
        }()

        return VStack(alignment: .leading, spacing: 12) {
            CachedAsyncImage(
                url: URL(string: product.imageUrl),
                cacheKey: "product_\(product.id)",
                content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 260)
                        .clipped()
                },
                placeholder: {
                    ZStack {
                        Color.gray.opacity(0.12)
                        ProgressView()
                    }
                }
            )
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                Group {
                    if !isPNG {
                        LinearGradient(
                            colors: [.black.opacity(0.25), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            )
            .shadow(color: isPNG ? .clear : Color.black.opacity(0.15), radius: isPNG ? 0 : 12, x: 0, y: isPNG ? 0 : 10)

            HStack(spacing: 12) {
                // Logo de la tienda circular
                if !product.shopLogoUrl.isEmpty {
                    CachedAsyncImage(
                        url: URL(string: product.shopLogoUrl),
                        cacheKey: "shop_logo_\(product.shop)",
                        content: { image in
                            image
                                .resizable()
                                .scaledToFill()
                        },
                        placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.6)
                                )
                        },
                        failure: {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "storefront.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                )
                        }
                    )
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.shop)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(product.weight)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.yellow)
                            Text("4.8")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .frame(height: 320)
    }

    private func infoSection(product: Product) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(product.name)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(2)

            Text("Preparado en \(product.shop) • \(product.weight)")
                .font(.system(size: 15))
                .foregroundColor(.secondary)

            Text("Disfruta de un clásico con ingredientes frescos, porciones generosas y un empaque pensado para llegar caliente.")
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
        )
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personaliza")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Estilo")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Picker("Estilo", selection: $selectedStyle) {
                    ForEach(styleOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Entrega")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Picker("Entrega", selection: $selectedDelivery) {
                    ForEach(deliveryOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
        )
    }

    private var similarProductsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Productos similares")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(similarProducts, id: \.id) { item in
                        ProductCard(
                            product: item,
                            count: Binding(
                                get: { similarCounts[item.id] ?? 0 },
                                set: { newValue in
                                    if newValue > 0 {
                                        similarCounts[item.id] = newValue
                                    } else {
                                        similarCounts.removeValue(forKey: item.id)
                                    }
                                }
                            ),
                            onIncrement: {
                                let current = similarCounts[item.id] ?? 0
                                similarCounts[item.id] = current + 1
                            },
                            onDecrement: {
                                let current = similarCounts[item.id] ?? 0
                                if current > 1 {
                                    similarCounts[item.id] = current - 1
                                } else {
                                    similarCounts.removeValue(forKey: item.id)
                                }
                            }
                        )
                        .frame(width: 220)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var quantitySelector: some View {
        HStack(spacing: 12) {
            Button(action: decrementQuantity) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.secondary)
            }

            Text("\(quantity)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(minWidth: 36)
                .foregroundColor(.primary)

            Button(action: incrementQuantity) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.llegoPrimary)
            }
        }
    }

    // MARK: - Helpers

    private var totalPriceText: String {
        guard let product = product else { return "$0.00" }

        let cleaned = product.price
            .replacingOccurrences(of: "[^0-9.,]", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)

        guard let unit = Double(cleaned) else { return product.price }
        let total = unit * Double(quantity)

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currencySymbol(from: product.price)
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSNumber(value: total)) ?? product.price
    }

    private func currencySymbol(from priceString: String) -> String {
        if priceString.contains("€") { return "€" }
        if priceString.contains("USD") { return "$" }
        if priceString.contains("CUP") { return "$" }
        if priceString.contains("$") { return "$" }
        return "$"
    }

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func pill(text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.18))
        .clipShape(Capsule())
    }

    private func statChip(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func gradientTag(text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.85),
                    Color.white.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
    }

    private func selectionChip(text: String, isSelected: Bool, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(text)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minWidth: 0, alignment: .leading)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.llegoPrimary.opacity(0.85), Color.llegoAccent.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white.opacity(0.7)
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: isSelected ? Color.llegoPrimary.opacity(0.25) : .clear, radius: 10, x: 0, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0.1 : 0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func incrementQuantity() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            quantity += 1
        }
    }

    private func decrementQuantity() {
        guard quantity > 1 else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            quantity -= 1
        }
    }

    private func triggerStandardAdd() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        performAdd {
            withAnimation(.spring) {
                showGeneralToast = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showGeneralToast = false
                }
            }
        }
    }
    
    private func performAdd(completion: @escaping () -> Void) {
        // Simulate network/processing delay if needed, or just immediate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cartManager.addToCart(productId: productId, quantity: quantity)
            completion()
        }
    }

    private func shareProduct() {
        // Placeholder para futuras acciones de share
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Quantity Sheet View
    
    private var quantitySheetView: some View {
        VStack(spacing: 24) {
            // Handle visual
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 16)
            
            VStack(spacing: 16) {
                Text("¿Cuántos deseas agregar?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                // Selector de cantidad grande y bonito
                HStack(spacing: 20) {
                    Button(action: decrementQuantity) {
                        Image(systemName: "minus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(quantity > 1 ? gradientManager.currentAccentColor : .gray.opacity(0.3))
                    }
                    .disabled(quantity <= 1)
                    
                    Text("\(quantity)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(minWidth: 80)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: quantity)
                    
                    Button(action: incrementQuantity) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                }
                
                
                // Precio total
                if let product = product {
                    Text("Total: \(totalPriceText)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Botón de agregar
            Button(action: {
                showQuantitySheet = false
                triggerStandardAdd()
            }) {
                Text("Agregar al carrito")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.glassProminent)
            .tint(gradientManager.currentAccentColor)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .presentationBackground(.clear)
    }

private func startEntranceAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.86)) {
            heroAppeared = true
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.9).delay(0.08)) {
            contentAppeared = true
        }
    }
}


#Preview {
    NavigationStack {
        ProductDetailView(productId: "6777f74afe6bab27db6c4aa0")
    }
}
