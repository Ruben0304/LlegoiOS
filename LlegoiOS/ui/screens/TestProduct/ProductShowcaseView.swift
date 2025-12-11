import SwiftUI

struct ProductShowcaseView: View {
    let product: Product

    @Environment(\.dismiss) private var dismiss
    @StateObject private var cartManager = CartManager.shared

    @State private var heroAppeared = false
    @State private var contentAppeared = false
    @State private var showFloatingBar = true

    @State private var quantity: Int = 1
    @State private var selectedStyle = "Clásico"
    @State private var selectedDelivery = "Express 25-35m"
    @State private var similarCounts: [String: Int] = [:]
    
    // Animation states
    @State private var isBottomLoading = false
    @State private var showBottomSuccess = false
    @State private var showGeneralToast = false

    private let styleOptions = ["Clásico", "Ligero", "Extra queso"]
    private let deliveryOptions = ["Express 25-35m", "Programar hoy", "Recoger en tienda"]
    private let similarProducts: [Product] = [
        Product(
            id: "sim1",
            name: "Pizza Pepperoni",
            shop: "Pizza Place",
            weight: "900g",
            price: "$16.90",
            imageUrl: "https://images.unsplash.com/photo-1548365328-95f0cbb89ffd?w=1200"
        ),
        Product(
            id: "sim2",
            name: "Pizza Cuatro Quesos",
            shop: "La Nonna",
            weight: "850g",
            price: "$15.50",
            imageUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=1200"
        ),
        Product(
            id: "sim3",
            name: "Pizza Vegetariana",
            shop: "Green Bites",
            weight: "780g",
            price: "$14.20",
            imageUrl: "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=1200"
        ),
        Product(
            id: "sim4",
            name: "Pizza Hawaiana",
            shop: "TropicalFresh",
            weight: "820g",
            price: "$15.80",
            imageUrl: "https://images.unsplash.com/photo-1548365328-95f0cbb89ffd?w=1200"
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.llegoBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        heroSection
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .opacity(heroAppeared ? 1 : 0)
                            .offset(y: heroAppeared ? 0 : 20)

                        VStack(spacing: 16) {
                            infoSection
                            optionsSection
                            similarProductsSection
                        }
                        .padding(.horizontal, 20)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 14)
                    }
                    .padding(.bottom, 140)
                }

                bottomBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
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
                   
                    

                        Button(action: triggerStandardAdd) {
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
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: startEntranceAnimations)
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        let isPNG = {
            if let ext = URL(string: product.imageUrl)?.pathExtension.lowercased(), ext == "png" {
                return true
            }
            return product.imageUrl.lowercased().contains(".png")
        }()

        return VStack(alignment: .leading, spacing: 12) {
            CachedAsyncImage(
                url: URL(string: product.imageUrl),
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

            HStack(spacing: 10) {
                infoChip(icon: "storefront.fill", text: product.shop)
                infoChip(icon: "scalemass.fill", text: product.weight)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.yellow)
                    Text("4.8")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        .frame(height: 320)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(product.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Spacer()

                Button(action: triggerStandardAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.llegoPrimary)
                        .shadow(color: .llegoPrimary.opacity(0.2), radius: 8, x: 0, y: 4)
                }
            }

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

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Cantidad")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                quantitySelector
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

    private var bottomBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.shop)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Text(product.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            Spacer()

            Button(action: triggerBottomButtonAdd) {
                HStack(spacing: 8) {
                    if isBottomLoading {
                        ProgressView()
                            .tint(.white)
                    } else if showBottomSuccess {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                    } else {
                        Text(product.price)
                            .fontWeight(.semibold)
                    }
                }
            }
            .buttonStyle(.glassProminent)
            .tint(.llegoPrimary)
        }
        .padding(16)
//        .background(.ultraThinMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .glassEffect(.regular,in: .rect(cornerRadius: 22))
//        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: -2)
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

    private func triggerBottomButtonAdd() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isBottomLoading = true
        }
        
        performAdd {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isBottomLoading = false
                showBottomSuccess = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showBottomSuccess = false
                }
            }
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
            cartManager.addToCart(productId: product.id, quantity: quantity)
            completion()
        }
    }

    private func shareProduct() {
        // Placeholder para futuras acciones de share
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


#Preview {
    ProductShowcaseView(
        product: Product(
            id: "1",
            name: "Pizza Margherita",
            shop: "TropicalFresh Market",
            weight: "800g",
            price: "$14.50",
            imageUrl: "https://images.unsplash.com/photo-1548365328-95f0cbb89ffd?w=1200"
        )
    )
}
