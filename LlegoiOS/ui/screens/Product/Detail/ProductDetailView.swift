import SwiftUI
import UIKit

struct ProductDetailView: View {
    let productId: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProductDetailViewModel()
    @StateObject private var cartManager = CartManager.shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var gradientManager = GradientStateManager.shared

    @State private var heroAppeared = false
    @State private var contentAppeared = false
    @State private var quantity: Int = 1
    @State private var selectedVariantIndex: Int = 0

    // Variantes calculadas dinámicamente usando el precio real del producto
    private var variants: [ProductVariant] {
        guard let detail = viewModel.productDetail else {
            return []
        }
        return [
            ProductVariant(name: "Clásico", price: detail.price, isDefault: true),
            ProductVariant(name: "Con extras", price: 2.50, isDefault: false),
            ProductVariant(name: "Premium", price: 5.00, isDefault: false)
        ]
    }

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

    private var totalPrice: Double {
        guard let detail = viewModel.productDetail else { return 0 }
        let basePrice = detail.price
        let variantPrice = selectedVariantIndex == 0 ? variants[0].price : variants[selectedVariantIndex].price
        let additionalPrice = selectedVariantIndex == 0 ? 0 : variantPrice
        return (basePrice + additionalPrice) * Double(quantity)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { toggleFavorite() }) {
                        Image(systemName: favoritesManager.isFavorite(productId: productId) ? "heart.fill" : "heart")
                            .foregroundColor(favoritesManager.isFavorite(productId: productId) ? .red : .primary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                 
                      

                        Button(action: { shareProduct() }) {
                            Image(systemName: "square.and.arrow.up")
                              
                        }
                
                }

                // Bottom bar flotante - Quantity control
                ToolbarItem(placement: .bottomBar) {
                    quantityControlView
                }

                ToolbarSpacer(.fixed, placement: .bottomBar)

                // Bottom bar flotante - Add to cart button
                ToolbarItem(placement: .bottomBar) {
                    addToCartButton
                }
                
            }
            .onAppear {
                viewModel.loadProductDetail(id: productId)
            }
            .onChange(of: viewModel.productDetail) { detail in
                if detail != nil {
                    startEntranceAnimations()
                }
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
            if !variants.isEmpty {
                variantsSection
            }

            // Description
            descriptionSection
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

            HStack(spacing: 10) {
                Text(product.price)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
    }

    private var variantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Elige tu opción")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                // Required badge
                Text("Requerido")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(gradientManager.currentAccentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(gradientManager.currentAccentColor.opacity(0.15))
                    .cornerRadius(6)
            }

            // Variants Container
            VStack(spacing: 4) {
                ForEach(Array(variants.enumerated()), id: \.offset) { index, variant in
                    variantOptionRow(variant: variant, index: index)
                }
            }
            .padding(4)
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
    }

    private func variantOptionRow(variant: ProductVariant, index: Int) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedVariantIndex = index
            }
        }) {
            HStack {
                // Left side (radio + name)
                HStack(spacing: 12) {
                    // Radio button
                    ZStack {
                        Circle()
                            .strokeBorder(
                                selectedVariantIndex == index
                                    ? Color.clear
                                    : Color(.systemGray4),
                                lineWidth: 2
                            )
                            .frame(width: 22, height: 22)

                        if selectedVariantIndex == index {
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

                    Text(variant.name)
                        .font(.system(size: 15, weight: selectedVariantIndex == index ? .medium : .regular))
                        .foregroundColor(.primary)
                }

                Spacer()

                // Right side (price)
                if variant.isDefault {
                    Text(String(format: "$%.2f", variant.price))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                } else {
                    Text(String(format: "+$%.2f", variant.price))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        selectedVariantIndex == index
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
                Text("Disfruta de un producto de calidad preparado con ingredientes frescos y el mejor servicio.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineSpacing(1.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Bottom Toolbar Views

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
        Button(action: addToCart) {
            HStack(spacing: 8) {
                Image(systemName: "cart")
                Text("Añadir al carrito")
                   
            }
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
        .buttonStyle(.glassProminent)
        .tint(gradientManager.currentAccentColor)
    }

    // MARK: - Helpers

    private func formatTotalPrice() -> String {
        String(format: "$%.2f", totalPrice)
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
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()

        cartManager.addToCart(productId: productId, quantity: quantity)
    }

    private func shareProduct() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

// MARK: - Supporting Types

struct ProductVariant {
    let name: String
    let price: Double
    let isDefault: Bool
}

#Preview {
    ProductDetailView(productId: "6777f74afe6bab27db6c4aa0")
}
