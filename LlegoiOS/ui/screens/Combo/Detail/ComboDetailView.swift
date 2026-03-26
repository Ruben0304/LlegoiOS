import SwiftUI

struct ComboDetailView: View {
    let comboId: String

    @StateObject private var viewModel = ComboDetailViewModel()
    @ObservedObject private var gradientManager = GradientStateManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showCart = false
    @State private var showAddedToCartFeedback = false
    @State private var contentOffset: CGFloat = 60
    @State private var quantity: Int = 1

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.llegoSurface.ignoresSafeArea()

                Group {
                    if viewModel.isLoading {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(message: errorMessage)
                    } else if let combo = viewModel.comboDetail {
                        comboContent(combo: combo)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton(action: { dismiss() })
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCart = true
                    } label: {
                        Image(systemName: "cart")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                }

                if viewModel.comboDetail != nil {
                    ToolbarItem(placement: .bottomBar) {
                        quantityControlView
                    }

                    ToolbarItem(placement: .bottomBar) {
                        addComboToCartButton
                    }
                }
            }
            .onAppear {
                viewModel.loadComboDetail(id: comboId)
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.1)) {
                    contentOffset = 0
                }
            }
            .fullScreenCover(isPresented: $showCart) {
                CartView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .prepareOpenOrdersFromCart)) { _ in
                dismiss()
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
                .tint(gradientManager.currentAccentColor)
            Text("Cargando combo...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Reintentar") {
                viewModel.loadComboDetail(id: comboId, forceRefresh: true)
            }
            .frame(height: 50)
            .frame(maxWidth: 200)
            .modifier(GlassButtonStyleModifier())
            .tint(gradientManager.currentAccentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Main Content

    private func comboContent(combo: ComboDetailGraphQL) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                heroImage(combo: combo)

                VStack(alignment: .leading, spacing: 24) {
                    comboHeader(combo: combo)

                    Divider()

                    if !combo.description.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Descripción")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Text(combo.description)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .lineSpacing(3)
                        }

                        Divider()
                    }

                    // Gift products section (non-interactive)
                    if combo.hasGifts {
                        giftOptionsSection(combo: combo)
                        if !combo.slots.isEmpty {
                            Divider()
                        }
                    }

                    // Selectable slots (only show if there are slots)
                    if !combo.slots.isEmpty {
                        slotsSection(combo: combo)
                    }
                }
                .padding(20)
                .background(
                    UnevenRoundedRectangle(
                        cornerRadii: RectangleCornerRadii(
                            topLeading: 28,
                            bottomLeading: 0,
                            bottomTrailing: 0,
                            topTrailing: 28
                        ),
                        style: .continuous
                    )
                    .fill(Color.llegoSurface)
                )
                .offset(y: -28)

                Spacer().frame(height: 100)
            }
            .offset(y: contentOffset)
            .opacity(contentOffset == 0 ? 1 : 0)
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Hero Image

    private func heroImage(combo: ComboDetailGraphQL) -> some View {
        Group {
            if let imageUrl = combo.imageUrl, !imageUrl.isEmpty {
                CachedAsyncImage(
                    url: URL(string: imageUrl),
                    cacheKey: "combo_hero_\(combo.id)",
                    content: { image in
                        image.resizable().scaledToFill()
                    },
                    placeholder: {
                        ZStack {
                            Color.gray.opacity(0.1)
                            ProgressView().tint(gradientManager.currentAccentColor)
                        }
                    },
                    failure: {
                        comboHeroFallback(combo: combo)
                    }
                )
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipped()
            } else {
                comboHeroFallback(combo: combo)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
            }
        }
    }

    private func comboHeroFallback(combo: ComboDetailGraphQL) -> some View {
        let images = Array(combo.representativeProducts.prefix(3))
        return GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color.llegoAccent.opacity(0.22),
                        gradientManager.currentAccentColor.opacity(0.12),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if images.isEmpty {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))
                } else if images.count == 1 {
                    heroCircleCell(url: images[0].imageUrl, idx: 0, size: geo.size.height * 0.70)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                } else {
                    let circleSize: CGFloat = geo.size.height * 0.64
                    let overlap: CGFloat = circleSize * 0.28
                    let count = CGFloat(images.count)
                    let totalWidth = circleSize * count - overlap * (count - 1)
                    let startX = (geo.size.width - totalWidth) / 2 + circleSize / 2

                    ForEach(Array(images.enumerated()), id: \.offset) { idx, prod in
                        let xOffset = startX + CGFloat(idx) * (circleSize - overlap)
                        let yOffset = geo.size.height / 2 + (idx == 1 ? 10 : 0)

                        heroCircleCell(url: prod.imageUrl, idx: idx, size: circleSize)
                            .position(x: xOffset, y: yOffset)
                            .zIndex(Double(images.count - idx))
                    }
                }
            }
        }
    }

    private func heroCircleCell(url: String, idx: Int, size: CGFloat) -> some View {
        CachedAsyncImage(
            url: URL(string: url),
            cacheKey: "combo_hero_prod_\(comboId)_\(idx)",
            content: { image in image.resizable().scaledToFill() },
            placeholder: { Color(red: 240 / 255, green: 242 / 255, blue: 246 / 255) },
            failure: { Color(red: 240 / 255, green: 242 / 255, blue: 246 / 255) }
        )
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 4))
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
    }

    // MARK: - Header

    private func comboHeader(combo: ComboDetailGraphQL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(destination: StoreDetailView(storeId: combo.branchId)) {
                storeInfoContent(combo: combo)
            }
            .buttonStyle(.plain)

            Text(combo.name)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)

            // Combo kind badge
            comboBadge(for: combo)

            // Price row
            priceRow(combo: combo)
        }
    }

    @ViewBuilder
    private func comboBadge(for combo: ComboDetailGraphQL) -> some View {
        switch combo.comboKind {
        case .discounted:
            HStack(spacing: 6) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(combo.discountLabel)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.green))

        case .withGifts:
            HStack(spacing: 6) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(combo.giftOptions.count == 1
                     ? "1 producto de regalo"
                     : "\(combo.giftOptions.count) productos de regalo")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.purple))

        case .withFreeSlots:
            let freeCount = combo.slots.filter { $0.isFree }.count
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(freeCount == 1
                     ? "1 complemento gratis incluido"
                     : "\(freeCount) complementos gratis incluidos")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.orange))

        case .bundle:
            HStack(spacing: 6) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(gradientManager.currentAccentColor)
                Text("\(combo.slots.count) \(combo.slots.count == 1 ? "lote" : "lotes") a personalizar")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(gradientManager.currentAccentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(gradientManager.currentAccentColor.opacity(0.12)))
        }
    }

    @ViewBuilder
    private func priceRow(combo: ComboDetailGraphQL) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(viewModel.formattedCalculatedPrice)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .animation(.spring(response: 0.3), value: viewModel.calculatedPrice)

            if combo.comboKind == .discounted && combo.hasDiscount {
                Text(viewModel.formatPrice(viewModel.selectionSubtotal, currency: combo.currency))
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .strikethrough(true, color: .secondary)

                Text(combo.discountLabel)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.green))
            }
        }
    }

    private func storeInfoContent(combo: ComboDetailGraphQL) -> some View {
        HStack(spacing: 10) {
            if let logoUrl = combo.branchLogoUrl, !logoUrl.isEmpty {
                CachedAsyncImage(
                    url: URL(string: logoUrl),
                    cacheKey: "store_logo_combo_\(combo.branchId)",
                    content: { image in image.resizable().scaledToFill() },
                    placeholder: { Circle().fill(Color.gray.opacity(0.2)) },
                    failure: { Circle().fill(Color.gray.opacity(0.2)) }
                )
                .frame(width: 28, height: 28)
                .clipShape(Circle())
            }
            Text(combo.branchName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Gift Products Section

    private func giftOptionsSection(combo: ComboDetailGraphQL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.purple)
                Text("Incluye de regalo")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }

            Text("La tienda incluye estos productos gratis con tu combo")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            VStack(spacing: 10) {
                ForEach(combo.giftOptions) { gift in
                    giftOptionRow(gift: gift)
                }
            }
        }
    }

    private func giftOptionRow(gift: ComboGiftOptionGraphQL) -> some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                if !gift.productImageUrl.isEmpty {
                    CachedAsyncImage(
                        url: URL(string: gift.productImageUrl),
                        cacheKey: "combo_gift_\(gift.productId)",
                        content: { image in image.resizable().scaledToFill() },
                        placeholder: { Color.gray.opacity(0.1) },
                        failure: { Color.gray.opacity(0.1) }
                    )
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "gift.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.purple.opacity(0.5))
                        )
                }

                // Gift badge on image
                Image(systemName: "gift.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Circle().fill(Color.purple))
                    .offset(x: 4, y: -4)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(gift.productName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text("Gratis · incluido por la tienda")
                    .font(.system(size: 13))
                    .foregroundColor(.purple)
            }

            Spacer()

            // Non-interactive indicator
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.purple.opacity(0.7))
        }
        .padding(.vertical, 4)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.purple.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.purple.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Slots Section

    private func slotsSection(combo: ComboDetailGraphQL) -> some View {
        let sortedSlots = combo.slots.sorted { $0.displayOrder < $1.displayOrder }
        let sectionTitle: String = {
            switch combo.comboKind {
            case .withFreeSlots: return "Elige tus acompañantes"
            case .bundle: return "Personaliza tu combo"
            default: return "Personaliza tu combo"
            }
        }()

        return VStack(alignment: .leading, spacing: 24) {
            Text(sectionTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            ForEach(sortedSlots) { slot in
                slotView(slot: slot, combo: combo)
            }
        }
    }

    private func slotView(slot: ComboSlotGraphQL, combo: ComboDetailGraphQL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Slot header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(slot.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)

                        // Free slot badge
                        if slot.isFree {
                            Text("GRATIS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.orange))
                        } else if slot.isRequired {
                            Text("Requerido")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(gradientManager.currentAccentColor))
                        }
                    }

                    if let desc = slot.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    if slot.isFree {
                        Text("Incluido · elige \(slot.maxSelections == 1 ? "1 opción" : "hasta \(slot.maxSelections)")")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    } else {
                        Text(selectionHintText(slot: slot))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                let selected = viewModel.slotSelections[slot.id] ?? []
                if selected.count >= slot.minSelections && !selected.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(slot.isFree ? .orange : .green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(
                .spring(response: 0.3, dampingFraction: 0.7),
                value: viewModel.slotSelections[slot.id]?.count)

            VStack(spacing: 10) {
                ForEach(slot.options, id: \.productId) { option in
                    optionRow(option: option, slot: slot, combo: combo)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(slot.isFree ? Color.orange.opacity(0.05) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            slot.isFree ? Color.orange.opacity(0.2) : Color.clear,
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }

    private func optionRow(
        option: ComboOptionGraphQL, slot: ComboSlotGraphQL, combo: ComboDetailGraphQL
    ) -> some View {
        let isSelected = viewModel.isOptionSelected(slotId: slot.id, productId: option.productId)

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.toggleOption(
                    slotId: slot.id, productId: option.productId, maxSelections: slot.maxSelections)
            }
        } label: {
            HStack(spacing: 12) {
                if !option.productImageUrl.isEmpty {
                    CachedAsyncImage(
                        url: URL(string: option.productImageUrl),
                        cacheKey: "combo_opt_\(option.productId)",
                        content: { image in image.resizable().scaledToFill() },
                        placeholder: { Color.gray.opacity(0.1) },
                        failure: { Color.gray.opacity(0.1) }
                    )
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 64, height: 64)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.productName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    if slot.isFree {
                        // Free slot: show "Gratis" regardless of priceAdjustment
                        Text("Gratis")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.orange)
                    } else if option.priceAdjustment > 0 {
                        Text("+\(viewModel.formatPrice(option.priceAdjustment, currency: combo.currency))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(gradientManager.currentAccentColor)
                    } else if option.priceAdjustment < 0 {
                        Text("\(viewModel.formatPrice(option.priceAdjustment, currency: combo.currency))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.green)
                    } else {
                        Text("Incluido")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Selection indicator
                ZStack {
                    let accentColor = slot.isFree ? Color.orange : gradientManager.currentAccentColor

                    if slot.maxSelections == 1 {
                        Circle()
                            .stroke(
                                isSelected ? accentColor : Color.gray.opacity(0.3),
                                lineWidth: 2
                            )
                            .frame(width: 22, height: 22)

                        if isSelected {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 12, height: 12)
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(
                                isSelected ? accentColor : Color.gray.opacity(0.3),
                                lineWidth: 2
                            )
                            .frame(width: 22, height: 22)

                        if isSelected {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(accentColor)
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
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

    private var addComboToCartButton: some View {
        Button {
            guard viewModel.isReadyToAdd else { return }
            guard viewModel.addCurrentComboToCart(quantity: quantity) else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showAddedToCartFeedback = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.25)) {
                    showAddedToCartFeedback = false
                }
            }
        } label: {
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
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: showAddedToCartFeedback)
        .disabled(!viewModel.isReadyToAdd || showAddedToCartFeedback)
    }

    // MARK: - Helpers

    private func formatTotalPrice() -> String {
        guard let combo = viewModel.comboDetail else {
            return "$0.00"
        }

        let totalPrice = viewModel.calculatedPrice * Double(quantity)
        return viewModel.formatPrice(totalPrice, currency: combo.currency)
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

    private func selectionHintText(slot: ComboSlotGraphQL) -> String {
        if slot.minSelections == slot.maxSelections {
            return slot.minSelections == 1 ? "Elige 1 opción" : "Elige \(slot.minSelections) opciones"
        } else if slot.minSelections == 0 {
            return "Opcional · hasta \(slot.maxSelections)"
        } else {
            return "Elige entre \(slot.minSelections) y \(slot.maxSelections)"
        }
    }
}

// MARK: - Button Style Modifiers

private struct GlassProminentButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

private struct GlassButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.bordered)
        }
    }
}

// MARK: - Combo extensions used by the view

extension ComboDetailGraphQL {
    fileprivate var discountLabel: String {
        switch discountType.uppercased() {
        case "PERCENTAGE": return "-\(Int(discountValue))%"
        case "FIXED":
            let symbol: String
            switch currency.uppercased() {
            case "USD": symbol = "$"
            case "EUR": symbol = "€"
            default: symbol = currency + " "
            }
            return "-\(String(format: "\(symbol)%.2f", discountValue))"
        default: return ""
        }
    }
}
