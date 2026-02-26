import SwiftUI

struct ComboDetailView: View {
    let comboId: String

    @StateObject private var viewModel = ComboDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showCart = false
    @State private var addedToCartPulse = false
    @State private var contentOffset: CGFloat = 60

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

                // Bottom action bar (shown when data is loaded)
                if viewModel.comboDetail != nil {
                    bottomBar
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
                            .foregroundColor(.llegoPrimary)
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
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
                .tint(.llegoPrimary)
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
            .buttonStyle(.glass)
            .tint(.llegoPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Main Content

    private func comboContent(combo: ComboDetailGraphQL) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image
                heroImage(combo: combo)

                // Content card
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    comboHeader(combo: combo)

                    Divider()

                    // Description
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

                    // Slots
                    slotsSection(combo: combo)
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

                // Bottom padding to clear the action bar
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
                            ProgressView().tint(.llegoPrimary)
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

    /// Floating circular images over a gradient background for the hero area
    private func comboHeroFallback(combo: ComboDetailGraphQL) -> some View {
        let images = Array(combo.representativeProducts.prefix(3))
        return GeometryReader { geo in
            ZStack {
                // Soft gradient background
                LinearGradient(
                    colors: [
                        Color.llegoAccent.opacity(0.22),
                        Color.llegoPrimary.opacity(0.12)
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
            placeholder: { Color(red: 240/255, green: 242/255, blue: 246/255) },
            failure: { Color(red: 240/255, green: 242/255, blue: 246/255) }
        )
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 4))
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
    }

    // MARK: - Header

    private func comboHeader(combo: ComboDetailGraphQL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Store info
            HStack(spacing: 8) {
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
            }

            // Combo name
            Text(combo.name)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)

            // Slots badge
            HStack(spacing: 6) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.llegoAccent)
                Text("\(combo.slots.count) \(combo.slots.count == 1 ? "lote" : "lotes") a personalizar")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.llegoAccent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.llegoAccent.opacity(0.12)))

            // Price row
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(viewModel.formattedCalculatedPrice)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .animation(.spring(response: 0.3), value: viewModel.calculatedPrice)

                if combo.hasDiscount {
                    Text(combo.formattedBasePrice)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .strikethrough(true, color: .secondary)

                    if !combo.discountLabel.isEmpty {
                        Text(combo.discountLabel)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.green))
                    }
                }
            }
        }
    }

    // MARK: - Slots Section

    private func slotsSection(combo: ComboDetailGraphQL) -> some View {
        let sortedSlots = combo.slots.sorted { $0.displayOrder < $1.displayOrder }
        return VStack(alignment: .leading, spacing: 24) {
            Text("Personaliza tu combo")
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

                        if slot.isRequired {
                            Text("Requerido")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.llegoPrimary))
                        }
                    }

                    if let desc = slot.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Text(selectionHintText(slot: slot))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Checkmark when slot is satisfied
                let selected = viewModel.slotSelections[slot.id] ?? []
                if selected.count >= slot.minSelections {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.slotSelections[slot.id]?.count)

            // Options list
            VStack(spacing: 10) {
                ForEach(slot.options, id: \.productId) { option in
                    optionRow(option: option, slot: slot, combo: combo)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }

    private func optionRow(option: ComboOptionGraphQL, slot: ComboSlotGraphQL, combo: ComboDetailGraphQL) -> some View {
        let isSelected = viewModel.isOptionSelected(slotId: slot.id, productId: option.productId)

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.toggleOption(slotId: slot.id, productId: option.productId, maxSelections: slot.maxSelections)
            }
        } label: {
            HStack(spacing: 12) {
                // Product image
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

                // Name + price
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.productName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    if option.priceAdjustment > 0 {
                        Text("+\(viewModel.formatPrice(option.priceAdjustment, currency: combo.currency))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.llegoPrimary)
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
                    if slot.maxSelections == 1 {
                        // Radio button style
                        Circle()
                            .stroke(isSelected ? Color.llegoPrimary : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 22, height: 22)

                        if isSelected {
                            Circle()
                                .fill(Color.llegoPrimary)
                                .frame(width: 12, height: 12)
                        }
                    } else {
                        // Checkbox style
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(isSelected ? Color.llegoPrimary : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 22, height: 22)

                        if isSelected {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.llegoPrimary)
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

    // MARK: - Bottom Action Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text(viewModel.formattedCalculatedPrice)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .animation(.spring(response: 0.3), value: viewModel.calculatedPrice)
                }

                Spacer()

                Button {
                    guard viewModel.isReadyToAdd else { return }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        addedToCartPulse = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { addedToCartPulse = false }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: addedToCartPulse ? "checkmark.circle.fill" : "cart.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text(addedToCartPulse ? "Agregado" : "Agregar combo")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .fill(viewModel.isReadyToAdd ? Color.llegoPrimary : Color.gray.opacity(0.4))
                    )
                }
                .disabled(!viewModel.isReadyToAdd)
                .animation(.spring(response: 0.25), value: viewModel.isReadyToAdd)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Helpers

    private func selectionHintText(slot: ComboSlotGraphQL) -> String {
        if slot.minSelections == slot.maxSelections {
            if slot.minSelections == 1 {
                return "Elige 1 opción"
            } else {
                return "Elige \(slot.minSelections) opciones"
            }
        } else if slot.minSelections == 0 {
            return "Opcional · hasta \(slot.maxSelections)"
        } else {
            return "Elige entre \(slot.minSelections) y \(slot.maxSelections)"
        }
    }
}

// MARK: - Combo extensions used by the view

private extension ComboDetailGraphQL {
    var hasDiscount: Bool { savings > 0 }

    var formattedBasePrice: String {
        let symbol: String
        switch currency.uppercased() {
        case "USD": symbol = "$"
        case "EUR": symbol = "€"
        case "CUP": symbol = "CUP "
        default: symbol = currency + " "
        }
        return String(format: "\(symbol)%.2f", basePrice)
    }

    var discountLabel: String {
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
