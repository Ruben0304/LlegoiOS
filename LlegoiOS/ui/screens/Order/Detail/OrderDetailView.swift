import SwiftUI

struct OrderDetailView: View {
    @StateObject private var viewModel: OrderDetailViewModel
    @StateObject private var gradientManager = GradientStateManager.shared
    @State private var showCancelAlert = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    var onDismiss: (() -> Void)?

    init(orderId: String, onDismiss: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: OrderDetailViewModel(orderId: orderId))
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            // Fondo gradiente sutil similar a ProductFeedView
            orderGradientBackground
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: gradientManager.currentCategoryIndex)

            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(gradientManager.currentAccentColor)
                        .scaleEffect(1.2)
                        .padding(.top, 100)
                } else if let order = viewModel.order {
                    VStack(spacing: 16) {
                        headerSection(order)
                        itemsSection(order)
                        if !order.comments.isEmpty {
                            commentsSection(order)
                        }
                        pricingSection(order)
                        paymentSection(order)
                        if !order.timeline.isEmpty {
                            timelineSection(order)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button("Reintentar") { viewModel.load() }
                            .frame(height: 48)
                            .frame(maxWidth: 200)
                            .modifier(GlassProminentButtonModifier())
                            .tint(gradientManager.currentAccentColor)
                    }
                    .padding(.top, 100)
                }
            }
            .refreshable { viewModel.refresh() }

            // Bottom action buttons
            if let order = viewModel.order {
                VStack {
                    Spacer()
                    bottomActions(order)
                }
            }
        }
        .navigationTitle("Pedido #\(viewModel.order?.orderNumber.suffix(6) ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cancelar Pedido", isPresented: $showCancelAlert) {
            Button("No", role: .cancel) {}
            Button("Sí, cancelar", role: .destructive) {
                viewModel.cancelOrder {
                    onDismiss?()
                    dismiss()
                }
            }
        } message: {
            Text("¿Estás seguro de que deseas cancelar este pedido?")
        }
        .alert("Pago", isPresented: $viewModel.showPaymentAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.paymentAlertMessage ?? "Error al procesar el pago.")
        }
        .sheet(isPresented: $viewModel.showTronDealerSheet) {
            if let paymentInfo = viewModel.tronDealerPaymentInfo {
                TronDealerPaymentView(
                    address: paymentInfo.address,
                    amount: paymentInfo.expectedAmount,
                    orderId: paymentInfo.orderId,
                    isPolling: viewModel.isPollingTronDealer,
                    onDismiss: {
                        viewModel.stopTronDealerPolling()
                        viewModel.showTronDealerSheet = false
                    }
                )
            }
        }
        .background(
            StripePaymentSheetPresenter(
                isPresented: $viewModel.showStripePaymentSheet,
                paymentSheet: viewModel.paymentSheet,
                onCompletion: viewModel.handleStripePaymentResult
            )
        )
    }

    // MARK: - Order Gradient Background
    private var orderGradientBackground: some View {
        let palette = gradientManager.getCurrentGradientPalette()

        return ZStack {
            // Base color - muy suave
            palette.veryLight
                .opacity(0.3)

            // Gradiente sutil
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.light.opacity(0.12), location: 0.0),
                    .init(color: palette.veryLight.opacity(0.25), location: 0.4),
                    .init(color: Color.feedBackground(colorScheme).opacity(0.98), location: 1.0),
                ]),
                center: UnitPoint(x: 0.85, y: 0.15),
                startRadius: 10,
                endRadius: 600
            )
        }
    }

    // MARK: - Header Section

    private func headerSection(_ order: OrderDetail) -> some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    // Store image
                    CachedAsyncImage(
                        url: ImageURLResolver.resolve(order.branchImageUrl),
                        cacheKey: order.branchId + "_branch"
                    ) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            gradientManager.currentAccentColor.opacity(0.1)
                            Image(systemName: "storefront")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(gradientManager.currentAccentColor)
                        }
                    } failure: {
                        ZStack {
                            gradientManager.currentAccentColor.opacity(0.1)
                            Image(systemName: "storefront")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(gradientManager.currentAccentColor)
                        }
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(order.branchName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                        Text(order.orderNumber)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                    statusBadge(order.status)
                }

                Divider()

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Text(order.formattedTotal)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                    }

                    Spacer()

                    if let eta = order.estimatedMinutesRemaining {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Tiempo estimado")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 14))
                                Text("\(eta) min")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(gradientManager.currentAccentColor)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Items Section

    private func itemsSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Items")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                if order.isEditable {
                    Text("• Editable")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(gradientManager.currentAccentColor)
                }
                Spacer()
            }
            .padding(.horizontal, 2)

            card {
                VStack(spacing: 0) {
                    ForEach(Array(order.items.enumerated()), id: \.element.id) { index, item in
                        itemRow(item)
                        if index != order.items.count - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }
        }
    }

    private func itemRow(_ item: OrderDetailItem) -> some View {
        HStack(spacing: 12) {
            CachedAsyncImage(
                url: ImageURLResolver.resolve(item.imageUrl),
                cacheKey: "order_detail_item_\(item.productId)"
            ) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    Color.gray.opacity(0.1)
                    Image(systemName: "photo")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            } failure: {
                ZStack {
                    Color.gray.opacity(0.1)
                    Image(systemName: "photo")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                    if item.wasModifiedByStore {
                        Text("Modificado")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(gradientManager.currentAccentColor.opacity(0.15))
                            .foregroundColor(gradientManager.currentAccentColor)
                            .clipShape(Capsule())
                    }
                }
                Text("x\(item.quantity)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(item.formattedLineTotal)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
        }
        .padding(.vertical, 12)
    }

    // MARK: - Pricing Section

    private func pricingSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resumen")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .padding(.horizontal, 2)

            card {
                VStack(spacing: 12) {
                    priceRow(title: "Subtotal", value: order.formattedSubtotal)
                    priceRow(title: "Envío", value: order.formattedDeliveryFee)

                    ForEach(order.discounts) { discount in
                        priceRow(
                            title: discount.title, value: discount.formattedAmount,
                            valueColor: gradientManager.currentAccentColor)
                    }

                    Divider()
                    priceRow(title: "Total", value: order.formattedTotal, isEmphasis: true)
                }
            }
        }
    }

    // MARK: - Payment Section

    private func paymentSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pago")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .padding(.horizontal, 2)

            card {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(
                            systemName: paymentIconName(
                                for: viewModel.paymentMethod, fallback: order.paymentMethod)
                        )
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(gradientManager.currentAccentColor)
                        .frame(width: 44, height: 44)
                        .background(gradientManager.currentAccentColor.opacity(0.12))
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(paymentMethodLabel(order))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                            HStack(spacing: 6) {
                                Text(paymentStatusText(order.paymentStatus))
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                if viewModel.isPollingQvaPay {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(gradientManager.currentAccentColor)
                                    Text("Verificando...")
                                        .font(.system(size: 12))
                                        .foregroundColor(gradientManager.currentAccentColor)
                                }
                            }
                        }

                        Spacer()
                        paymentStatusBadge(order.paymentStatus)
                    }

                    if viewModel.isLoadingPaymentMethod {
                        ProgressView()
                            .tint(gradientManager.currentAccentColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if viewModel.paymentMethod == nil {
                        Text("Método de pago no disponible.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if viewModel.canInitiatePayment(for: order) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(gradientManager.currentAccentColor)
                            Text(
                                "Debes completar el pago para que el negocio continúe con tu pedido."
                            )
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(gradientManager.currentAccentColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private func priceRow(
        title: String, value: String, valueColor: Color? = nil, isEmphasis: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .font(
                    .system(size: isEmphasis ? 15 : 14, weight: isEmphasis ? .semibold : .regular)
                )
                .foregroundColor(isEmphasis ? Color.adaptiveOnSurface(colorScheme) : .secondary)
            Spacer()
            Text(value)
                .font(.system(size: isEmphasis ? 18 : 15, weight: isEmphasis ? .bold : .semibold))
                .foregroundColor(valueColor ?? Color.adaptiveOnSurface(colorScheme))
        }
    }

    // MARK: - Timeline Section

    private func timelineSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .padding(.horizontal, 2)

            card {
                VStack(spacing: 0) {
                    ForEach(Array(order.timeline.enumerated()), id: \.element.id) { index, event in
                        HStack(alignment: .top, spacing: 14) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(event.status.color)
                                    .frame(width: 14, height: 14)
                                if index < order.timeline.count - 1 {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.25))
                                        .frame(width: 2)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 14)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.message)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                                Text(event.formattedDate)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.bottom, index < order.timeline.count - 1 ? 18 : 0)

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Comments Section

    private func commentsSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comentarios")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .padding(.horizontal, 2)

            card {
                VStack(spacing: 12) {
                    ForEach(order.comments) { comment in
                        commentBubble(comment)
                    }
                }
            }
        }
    }

    private func commentBubble(_ comment: OrderDetailComment) -> some View {
        HStack {
            if comment.author == .business { Spacer(minLength: 40) }

            VStack(alignment: comment.author == .customer ? .leading : .trailing, spacing: 4) {
                Text(comment.message)
                    .font(.system(size: 14))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                Text(comment.formattedTime)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        comment.author == .customer
                            ? Color.gray.opacity(colorScheme == .dark ? 0.2 : 0.1)
                            : gradientManager.currentAccentColor.opacity(0.15))
            )

            if comment.author == .customer { Spacer(minLength: 40) }
        }
    }

    // MARK: - Bottom Actions

    private func bottomActions(_ order: OrderDetail) -> some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.2))
            HStack(spacing: 10) {
                let shouldShowPay = viewModel.canInitiatePayment(for: order)
                let shouldShowAccept = OrderPermissionPolicy.canAcceptModifications(
                    status: order.status)

                if order.canCancel {
                    Button {
                        showCancelAlert = true
                    } label: {
                        Text("Cancelar")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .modifier(GlassProminentButtonModifier())
                    .tint(.red)
                }

                if shouldShowAccept {
                    Button {
                        viewModel.acceptModifications {
                            onDismiss?()
                            dismiss()
                        }
                    } label: {
                        Text("Aceptar cambios")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .modifier(GlassProminentButtonModifier())
                    .tint(gradientManager.currentAccentColor)
                }

                if shouldShowPay {
                    Button {
                        viewModel.initiatePayment()
                    } label: {
                        HStack(spacing: 10) {
                            if viewModel.isInitiatingPayment {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(
                                    systemName: paymentIconName(
                                        for: viewModel.paymentMethod, fallback: order.paymentMethod)
                                )
                                .font(.system(size: 16, weight: .semibold))
                            }
                            Text("Pagar \(order.formattedTotal)")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                    }
                    .modifier(GlassProminentButtonModifier())
                    .tint(gradientManager.currentAccentColor)
                    .disabled(viewModel.isInitiatingPayment || viewModel.isProcessing)
                }

                if OrderPermissionPolicy.canShowTracking(status: order.status) {
                    NavigationLink(destination: OrderTrackingView(orderId: order.id)) {
                        Text("Ver tracking")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .modifier(GlassProminentButtonModifier())
                    .tint(gradientManager.currentAccentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Helpers

    private func paymentMethodLabel(_ order: OrderDetail) -> String {
        if let method = viewModel.paymentMethod {
            return method.name
        }
        return order.paymentMethod.uppercased()
    }

    private func paymentStatusText(_ status: PaymentStatusEnum) -> String {
        switch status {
        case .pending:
            return "Pago pendiente"
        case .validated:
            return "Pago validado"
        case .completed:
            return "Pagado"
        case .failed:
            return "Pago fallido"
        }
    }

    private func paymentStatusBadge(_ status: PaymentStatusEnum) -> some View {
        let (text, color): (String, Color) = {
            switch status {
            case .pending:
                return ("Pendiente", .orange)
            case .validated:
                return ("Validado", gradientManager.currentAccentColor)
            case .completed:
                return ("Pagado", .green)
            case .failed:
                return ("Fallido", .red)
            }
        }()

        return Text(text)
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    private func paymentIconName(for method: PaymentMethodModel?, fallback: String) -> String {
        if let method = method {
            switch method.method.lowercased() {
            case "wallet":
                return "wallet.pass.fill"
            case "stripe", "card":
                return "creditcard.fill"
            case "cash":
                return "banknote.fill"
            case "qvapay":
                return "dollarsign.circle.fill"
            case "usdt":
                return "bitcoinsign.circle.fill"
            default:
                if method.code.lowercased().contains("qvapay") {
                    return "dollarsign.circle.fill"
                }
                if method.code.lowercased().contains("usdt") || method.code.lowercased().contains("trondealer") {
                    return "bitcoinsign.circle.fill"
                }
                break
            }
        }

        let normalized = fallback.lowercased()
        if normalized.contains("wallet") {
            return "wallet.pass.fill"
        }
        if normalized.contains("stripe") {
            return "creditcard.fill"
        }
        if normalized.contains("qvapay") {
            return "dollarsign.circle.fill"
        }
        if normalized.contains("usdt") || normalized.contains("trondealer") {
            return "bitcoinsign.circle.fill"
        }

        return "creditcard.fill"
    }

    private func statusBadge(_ status: OrderStatusEnum) -> some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 11, weight: .bold))
            Text(status.displayName)
                .font(.system(size: 12, weight: .bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(status.color.opacity(0.15))
        .foregroundColor(status.color)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground(colorScheme))
                    .shadow(
                        color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 10, x: 0,
                        y: 4)
            )
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
    NavigationStack {
        OrderDetailView(orderId: "test-order-id")
    }
}
