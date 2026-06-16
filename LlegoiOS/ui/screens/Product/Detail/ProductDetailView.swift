import SwiftUI
import UIKit

struct ProductDetailView: View {
    let productId: String
    var catalogOnly: Bool = false

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProductDetailViewModel()
    @ObservedObject private var cartManager = CartManager.shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var gradientManager = GradientStateManager.shared

    @State private var heroAppeared = false
    @State private var contentAppeared = false
    @State private var quantity: Int = 1
    @State private var showAddedToCartFeedback = false
    @State private var selectedSimilarProductId: String?
    @State private var showCart = false

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

    private var totalPriceDecimal: Decimal {
        guard let detail = viewModel.productDetail else { return .zero }
        return viewModel.finalTotalPrice(for: detail, quantity: quantity)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.white.ignoresSafeArea()

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
                        VStack(spacing: 0) {
                            heroSection(product: product)
                                .opacity(heroAppeared ? 1 : 0)
                                .offset(y: heroAppeared ? 0 : 20)

                            contentArea(product: product)
                                .opacity(contentAppeared ? 1 : 0)
                                .offset(y: contentAppeared ? 0 : 14)
                        }
                        .padding(.bottom, 80)
                    }
                    .ignoresSafeArea(edges: .top)
                    .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                if !catalogOnly {
                    bottomBarView
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { toggleFavorite() }) {
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: favoritesManager.isFavorite(productId: productId) ? "heart.fill" : "heart")
                                .font(.system(size: 17, weight: .semibold))
                            if !favoritesManager.isFavorite(productId: productId) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .background(Circle().fill(Color.white))
                                    .offset(x: 2, y: 2)
                            }
                        }
                        .foregroundColor(gradientManager.currentAccentColor)
                    }
                    .accessibilityLabel(
                        favoritesManager.isFavorite(productId: productId)
                            ? "Quitar de favoritos" : "Agregar a favoritos"
                    )
                    .accessibilityHint("Este botón agrega o quita este producto de favoritos")
                }

                if !catalogOnly {
                    ToolbarItem(placement: .topBarTrailing) {
                        if cartManager.cartItemCount > 0 {
                            Button(action: {
                                showCart = true
                            }) {
                                Image(systemName: "cart")
                                    .foregroundColor(gradientManager.currentAccentColor)
                            }
                            .badge(cartManager.cartItemCount)
                            .id("cart-toolbar-badge-\(cartManager.cartItemCount)")
                            .accessibilityLabel("Carrito")
                        } else {
                            Button(action: {
                                showCart = true
                            }) {
                                Image(systemName: "cart")
                                    .foregroundColor(gradientManager.currentAccentColor)
                            }
                            .accessibilityLabel("Carrito")
                        }
                    }
                }

            }
            .onAppear {
                viewModel.loadProductDetail(id: productId)
            }
            .onChange(of: viewModel.productDetail) { _, detail in
                if detail != nil {
                    startEntranceAnimations()
                }
            }
            .fullScreenCover(item: $selectedSimilarProductId) { productId in
                ProductDetailView(productId: productId)
            }
            .fullScreenCover(isPresented: $showCart) {
                CartView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .prepareOpenOrdersFromCart)) { _ in
                // Si este detalle está presentado como fullScreen, cerrarlo para que
                // MainAppView pueda presentar OrderListView.
                dismiss()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(gradientManager.currentAccentColor)

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
                .foregroundColor(gradientManager.currentAccentColor)

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
                .background(gradientManager.currentAccentColor)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sections

    private func heroSection(product: Product) -> some View {
        GeometryReader { geometry in
            CachedAsyncImage(
                url: URL(string: product.imageUrl),
                cacheKey: "product_\(product.id)",
                content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width)
                        .frame(height: 420 + geometry.safeAreaInsets.top)
                },
                placeholder: {
                    ZStack {
                        Color.gray.opacity(0.12)
                        ProgressView()
                    }
                }
            )
            .frame(width: geometry.size.width)
            .frame(height: 420 + geometry.safeAreaInsets.top)
            .clipped()
            .offset(y: -geometry.safeAreaInsets.top)
        }
        .frame(height: 420)
        .ignoresSafeArea(edges: .top)
    }

    private func contentArea(product: Product) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            // Store Info
            storeInfoRow(product: product)

            // Product Header (Title + Price)
            productHeaderSection(product: product)

            // Variants Section
            if let detail = viewModel.productDetail,
               let variantLists = detail.variantLists,
               !variantLists.isEmpty {
                variantsSection
            }

            // Description
            descriptionSection

            // Similar Products
            similarProductsSection
        }
        .padding(20)
        .padding(.bottom, 100)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 24,
                style: .continuous
            )
            .fill(Color.white)
        )
        .offset(y: -24)
    }

    @ViewBuilder
    private func storeInfoRow(product: Product) -> some View {
        if let branchId = viewModel.productDetail?.branchId {
            NavigationLink(destination: StoreDetailView(storeId: branchId)) {
                storeInfoContent(product: product)
            }
            .buttonStyle(.plain)
        } else {
            storeInfoContent(product: product)
        }
    }

    private func storeInfoContent(product: Product) -> some View {
        HStack(spacing: 10) {
            // Store Avatar Circle
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
                        .fill(Color(.systemGray5))
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.6)
                        )
                }
            )
            .frame(width: 36, height: 36)
            .clipShape(Circle())

            // Store Details
            HStack(spacing: 6) {
                Text(product.shop)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Text("•")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)

                Text("4.8 ★")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
        }
    }

    private func productHeaderSection(product: Product) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(product.name)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.primary)
                .tracking(-0.5)

            if let detail = viewModel.productDetail {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Text(
                            viewModel.formatPrice(
                                decimal: viewModel.finalUnitPrice(for: detail),
                                currency: detail.currency)
                        )
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.primary)

                        if !viewModel.selectedVariantOptions.isEmpty {
                            Text(
                                "(base \(viewModel.formatPrice(price: detail.price, currency: detail.currency)))"
                            )
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        }
                    }

                    // Precio convertido + tasa de cambio (cuando la tienda acepta ambas monedas)
                    if let convertedPrice = detail.convertedPrice,
                       let convertedCurrency = detail.convertedCurrency {
                        HStack(spacing: 6) {
                            Text("≈ \(viewModel.formatPrice(price: convertedPrice, currency: convertedCurrency))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            if let rate = detail.exchangeRate {
                                Text("·")
                                    .foregroundColor(.secondary)
                                Text("1 USD = \(rate) CUP")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } else {
                Text(product.price)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
    }

    private var variantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let detail = viewModel.productDetail,
               let variantLists = detail.variantLists,
               !variantLists.isEmpty {
                ForEach(variantLists, id: \.id) { list in
                    if !list.options.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(list.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)

                                Spacer()

                                Text("Requerido")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(gradientManager.currentAccentColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(gradientManager.currentAccentColor.opacity(0.15))
                                    .cornerRadius(6)
                            }
                            
                            // Show description if available
                            if let description = list.description, !description.isEmpty {
                                Text(description)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 4)
                            }

                            VStack(spacing: 4) {
                                ForEach(list.options, id: \.self) { option in
                                    variantOptionRow(list: list, option: option)
                                }
                            }
                            .padding(4)
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                        }
                    } else {
                        Text("\(list.name): sin opciones")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func variantOptionRow(list: VariantList, option: VariantOption) -> some View {
        let isSelected = viewModel.selectedByListId[list.id] == option
        let currency = viewModel.productDetail?.currency ?? "USD"
        
        return Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectOption(option, in: list)
            }
        }) {
            HStack {
                // Left side (radio + name)
                HStack(spacing: 12) {
                    // Radio button
                    ZStack {
                        Circle()
                            .strokeBorder(
                                isSelected
                                    ? Color.clear
                                    : Color(.systemGray4),
                                lineWidth: 2
                            )
                            .frame(width: 22, height: 22)

                        if isSelected {
                            Circle()
                                .fill(gradientManager.currentAccentColor)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 8, height: 8)
                                )
                        }
                    }

                    Text(option.name)
                        .font(
                            .system(
                                size: 15, weight: isSelected ? .medium : .regular
                            )
                        )
                        .foregroundColor(.primary)
                }

                Spacer()

                // Right side (price)
                Text(
                    viewModel.formatPriceAdjustment(
                        decimal: option.priceAdjustment, currency: currency)
                )
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(option.priceAdjustment > .zero ? .secondary : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? gradientManager.currentAccentColor
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Descripción")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            // Usar descripción del backend si está disponible
            if let detail = viewModel.productDetail, !detail.description.isEmpty {
                Text(detail.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineSpacing(1.5)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(
                    "Disfruta de un producto de calidad preparado con ingredientes frescos y el mejor servicio."
                )
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
                .lineSpacing(1.5)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var similarProductsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Productos similares")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.top, 8)

            if viewModel.isLoadingSimilarProducts {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(gradientManager.currentAccentColor)
                    Text("Cargando similares...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 14)
            } else if viewModel.similarProducts.isEmpty {
                Text("No hay productos similares por ahora.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                    ],
                    alignment: .center,
                    spacing: 20
                ) {
                    ForEach(viewModel.similarProducts) { similarProduct in
                        ProductCard(
                            product: similarProduct,
                            count: .constant(0),
                            onIncrement: {},
                            onDecrement: {},
                            onProductTap: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedSimilarProductId = similarProduct.id
                            }
                        )
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBarView: some View {
        HStack(spacing: 12) {
            quantityControlView
            addToCartButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var quantityControlView: some View {
        HStack(spacing: 0) {
            Button(action: decrementQuantity) {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .medium))

                    .frame(width: 36, height: 36)
            }

            Text("\(quantity)")
                .font(.system(size: 17, weight: .semibold))

                .frame(minWidth: 28)

            Button(action: incrementQuantity) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))

                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 4)
        .tint(gradientManager.currentAccentColor)
    }

    private var addToCartButton: some View {
        ZStack {
            Button(action: addToCart) {
                HStack(spacing: 8) {
                    Image(systemName: showAddedToCartFeedback ? "checkmark" : "cart")
                        .contentTransition(.symbolEffect(.replace))
                    Text(showAddedToCartFeedback ? "¡Agregado!" : "Añadir \(formatTotalPrice())")

                }
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            .modifier(GlassProminentButtonModifier())
            .tint(showAddedToCartFeedback ? .green : gradientManager.currentAccentColor)
            .scaleEffect(showAddedToCartFeedback ? 1.05 : 1.0)
            .animation(
                .spring(response: 0.35, dampingFraction: 0.6), value: showAddedToCartFeedback
            )
            .disabled(showAddedToCartFeedback)
        }
    }

    // MARK: - Helpers

    private func formatTotalPrice() -> String {
        guard let detail = viewModel.productDetail else {
            return "$0.00"
        }
        return viewModel.formatPrice(decimal: totalPriceDecimal, currency: detail.currency)
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

    private func toggleFavorite() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            favoritesManager.toggleFavorite(productId: productId)
        }
    }

    private func addToCart() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        let selected = viewModel.selectedVariantOptions
        let basePrice = viewModel.productDetail?.price
        let finalUnitPrice = viewModel.productDetail.map { detail in
            NSDecimalNumber(decimal: viewModel.finalUnitPrice(for: detail)).doubleValue
        }
        cartManager.addToCart(
            productId: productId,
            quantity: quantity,
            selectedVariants: selected,
            basePrice: basePrice,
            finalUnitPrice: finalUnitPrice
        )
        print("🛒 ProductDetailView: Added to cart with \(selected.count) selected variants")

        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            showAddedToCartFeedback = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.25)) {
                showAddedToCartFeedback = false
            }
        }
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

private struct GlassProminentButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ProductDetailView(productId: "6777f74afe6bab27db6c4aa0")
}
