import Combine
import MapKit
import SwiftUI

struct OrderDetailView: View {
    @StateObject private var viewModel: OrderDetailViewModel
    @StateObject private var gradientManager = GradientStateManager.shared
    @ObservedObject private var cartManager = CartManager.shared
    @State private var showCancelOptions = false
    @State private var showReplaceCartAlert = false
    @State private var showCartEditor = false
    @State private var showTracking = false
    @State private var showAcceptChangesConfirmation = false
    @State private var toastMessage: String?
    @Environment(\.colorScheme) private var colorScheme
    /// Avisa a quien presenta el detalle (p. ej. la lista) de que el pedido cambió.
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
                if let order = viewModel.order {
                    // Primero lo que requiere atención (estado, código, pago pendiente),
                    // después el detalle informativo.
                    VStack(spacing: 16) {
                        statusHeroCard(order)
                        if let deliveryCode = order.deliveryVerificationCode, !deliveryCode.isEmpty {
                            deliveryCodeCard(deliveryCode)
                        }
                        if isPaymentPriority(order) {
                            paymentSection(order)
                        }
                        if viewModel.canRate {
                            ratingSection(order)
                        }
                        itemsSection(order)
                        fulfillmentSection(order)
                        pricingSection(order)
                        if !isPaymentPriority(order) {
                            paymentSection(order)
                        }
                        refundSection(order)
                        if !viewModel.canRate {
                            ratingSection(order)
                        }
                        if !order.comments.isEmpty {
                            commentsSection(order)
                        }
                        if !order.timeline.isEmpty {
                            timelineSection(order)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                } else if viewModel.isLoading {
                    ProgressView()
                        .tint(gradientManager.currentAccentColor)
                        .scaleEffect(1.2)
                        .padding(.top, 100)
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
        }
        .navigationTitle("Pedido #\(viewModel.order?.orderNumber.suffix(6) ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let order = viewModel.order {
                orderDetailToolbarItems(order)
            }
        }
        .overlay(alignment: .top) {
            if let toastMessage {
                successToast(toastMessage)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: viewModel.successMessage) { _, message in
            guard let message else { return }
            viewModel.successMessage = nil
            showToast(message)
        }
        .onAppear { viewModel.startLiveUpdates() }
        .onDisappear { viewModel.stopLiveUpdates() }
        .navigationDestination(isPresented: $showTracking) {
            if let order = viewModel.order {
                OrderTrackingView(orderId: order.id)
            }
        }
        .confirmationDialog(
            "Cancelar pedido",
            isPresented: $showCancelOptions,
            titleVisibility: .visible
        ) {
            Button("Llevarme al carrito con estos productos") {
                handleCancelAndGoToCart()
            }
            Button("Solo cancelar", role: .destructive) {
                viewModel.cancelOrder {
                    onDismiss?()
                }
            }
            Button("No cancelar", role: .cancel) {}
        } message: {
            Text("¿Quieres ir al carrito con los productos de este pedido? Útil si quieres agregarle algo o hacer un pequeño cambio manteniendo los demás productos.")
        }
        .confirmationDialog(
            "Aceptar cambios",
            isPresented: $showAcceptChangesConfirmation,
            titleVisibility: .visible
        ) {
            Button("Aceptar y reenviar a la tienda") {
                viewModel.acceptModifications {
                    onDismiss?()
                }
            }
            Button("Revisar de nuevo", role: .cancel) {}
        } message: {
            if let order = viewModel.order {
                Text("Tu pedido volverá a la tienda con los cambios. Nuevo total: \(order.formattedTotal).")
            }
        }
        .alert("Reemplazar carrito", isPresented: $showReplaceCartAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Continuar", role: .destructive) {
                openCartEditor()
            }
        } message: {
            Text("Los productos del carrito actual se reemplazarán por los de este pedido.")
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showPaymentAlert) {
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
        .sheet(isPresented: $viewModel.showRefundSheet) {
            refundReasonSheet
        }
        .sheet(isPresented: $viewModel.showTransferSheet) {
            if let order = viewModel.order {
                OrderTransferPaymentSheet(
                    order: order,
                    paymentAttemptId: viewModel.activePaymentAttemptId ?? "",
                    isConfirming: viewModel.isConfirmingTransfer,
                    onConfirm: { proofImageData in
                        viewModel.confirmTransferPaymentSent(proofImageData: proofImageData)
                    },
                    onDismiss: {
                        viewModel.showTransferSheet = false
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showCartEditor) {
            NavigationStack {
                CartView()
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

    // MARK: - Status Hero

    /// Tarjeta principal: qué pasa con el pedido, qué viene después y, si le toca
    /// al cliente, qué tiene que hacer.
    private func statusHeroCard(_ order: OrderDetail) -> some View {
        let status = order.displayStatus
        let modifiedCount = order.items.filter(\.wasModifiedByStore).count

        return card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    storeImage(order)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(order.branchName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                            .lineLimit(1)
                        Text("#\(order.orderNumber.suffix(6)) · \(order.formattedTotal)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 8)
                    OrderStatusBadge(status: status)
                }

                Divider()

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: status.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(status.color)
                        .frame(width: 44, height: 44)
                        .background(status.color.opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(status.headline(isPickup: order.isPickup))
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                        Text(status.nextStep(isPickup: order.isPickup))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)

                if status == .modifiedByStore, modifiedCount > 0 {
                    heroNote(
                        icon: "square.and.pencil",
                        text: "La tienda modificó \(modifiedCount) producto\(modifiedCount == 1 ? "" : "s"). Los verás marcados abajo en naranja.",
                        color: .orange)
                }

                if let reason = order.statusReason {
                    heroNote(icon: "text.quote", text: reason, color: status.color)
                }

                if let scheduledFor = order.scheduledFor, status.isActive {
                    heroNote(
                        icon: "calendar.clock",
                        text: "Programado para \(OrderTimeFormatting.scheduled(scheduledFor))",
                        color: gradientManager.currentAccentColor)
                }

                if status.stepIndex(isPickup: order.isPickup) != nil {
                    OrderStatusStepper(status: status, isPickup: order.isPickup)
                        .padding(.top, 2)
                }

                if let etaText = etaText(order) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 13))
                        Text(etaText)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(gradientManager.currentAccentColor)
                }

                if OrderPermissionPolicy.shouldShowDeadline(status: order.status),
                    let deadlineAt = order.deadlineAt
                {
                    OrderDeadlineNotice(status: status, deadline: deadlineAt)
                }

                // Cuando el cliente tiene que decidir, cancelar es una salida legítima
                // y debe estar a mano (en el resto de casos vive en el menú ···).
                if status.requiresCustomerAction && order.canCancel {
                    Button(role: .destructive) {
                        showCancelOptions = true
                    } label: {
                        Text("Cancelar pedido")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .padding(.top, 2)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    status.requiresCustomerAction ? status.color.opacity(0.5) : Color.clear,
                    lineWidth: 1.5)
        )
    }

    private func heroNote(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme).opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func etaText(_ order: OrderDetail) -> String? {
        switch order.displayStatus {
        case .accepted, .preparing:
            if order.isPickup, let ready = order.estimatedReadyAt {
                return "Listo aprox. a las \(OrderTimeFormatting.time(ready))"
            }
            return order.estimatedMinutes.map { "Tiempo de preparación: ~\($0) min" }
        case .onTheWay:
            return order.estimatedMinutesRemaining.map { "Llega en ~\($0) min" }
        default:
            return nil
        }
    }

    private func storeImage(_ order: OrderDetail) -> some View {
        CachedAsyncImage(
            url: ImageURLResolver.resolve(order.branchImageUrl),
            cacheKey: order.branchId + "_branch"
        ) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            storeImagePlaceholder
        } failure: {
            storeImagePlaceholder
        }
    }

    private var storeImagePlaceholder: some View {
        ZStack {
            gradientManager.currentAccentColor.opacity(0.1)
            Image(systemName: "storefront")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(gradientManager.currentAccentColor)
        }
    }

    private func isPaymentPriority(_ order: OrderDetail) -> Bool {
        order.displayStatus == .pendingPayment || order.displayStatus == .paymentInProgress
    }

    // MARK: - Toast

    private func successToast(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.green)
            Text(message)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.cardBackground(colorScheme))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 24)
        .onTapGesture { withAnimation { toastMessage = nil } }
        .accessibilityAddTraits(.isStaticText)
    }

    private func showToast(_ message: String) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIAccessibility.post(notification: .announcement, argument: message)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            toastMessage = message
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if toastMessage == message {
                withAnimation { toastMessage = nil }
            }
        }
    }

    // MARK: - Items Section

    private func itemsSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Productos")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                Spacer()
                if order.isEditable {
                    Button("Modificar productos") {
                        handleOpenInCartTap()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(gradientManager.currentAccentColor)
                }
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

    private func handleOpenInCartTap() {
        let hasExistingCart = !cartManager.localItems.isEmpty || !cartManager.localShowcaseItems.isEmpty
        if hasExistingCart {
            showReplaceCartAlert = true
        } else {
            openCartEditor()
        }
    }

    private func handleCancelAndGoToCart() {
        guard let order = viewModel.order else { return }
        loadCart(with: order)
        viewModel.cancelOrder {
            onDismiss?()
        }
        showCartEditor = true
    }

    /// Editar (pedido modificado/rechazado) o volver a pedir (pedido terminado):
    /// ambos llevan los productos del pedido al carrito.
    private func openCartEditor() {
        guard let order = viewModel.order, order.isEditable || order.displayStatus.isFinal else {
            return
        }
        loadCart(with: order)
        showCartEditor = true
    }

    private func loadCart(with order: OrderDetail) {
        let cartItems = order.items.map { item in
            CartItemLocal(
                productId: item.productId,
                quantity: item.quantity,
                basePrice: item.price,
                finalUnitPrice: item.price
            )
        }
        cartManager.replaceCart(items: cartItems)
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
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
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
        .padding(.horizontal, item.wasModifiedByStore ? 8 : 0)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(item.wasModifiedByStore ? Color.orange.opacity(0.08) : Color.clear)
        )
        .accessibilityElement(children: .combine)
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
                    priceRow(
                        title: order.isPickup ? "Recogida" : "Envío",
                        value: order.isPickup ? order.formattedZeroAmount : order.formattedDeliveryFee
                    )
                    if order.serviceCharge > 0 {
                        priceRow(title: "Cargo de servicio", value: order.formattedServiceCharge)
                    }

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

    private func fulfillmentSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(order.isPickup ? "Recogida" : "Entrega")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .padding(.horizontal, 2)

            card {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: order.isPickup ? "bag.fill" : "shippingbox.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(gradientManager.currentAccentColor)
                            .frame(width: 44, height: 44)
                            .background(gradientManager.currentAccentColor.opacity(0.12))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(order.isPickup ? "Recogida en tienda" : "Envío a domicilio")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                            if order.isPickup {
                                Text(order.pickupAddress?.displayText ?? order.branchAddress ?? order.branchName)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            } else {
                                Text(order.deliveryAddress?.fullAddress ?? "Dirección de entrega")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }

                    if order.isPickup {
                        Divider()

                        HStack(spacing: 12) {
                            if let coordinate = order.branchCoordinates {
                                Button {
                                    openInMaps(coordinate: coordinate, name: order.branchName)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 14))
                                        Text("Ver en mapa")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(gradientManager.currentAccentColor.opacity(0.12))
                                    .foregroundColor(gradientManager.currentAccentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }

                            if let phone = order.branchPhone, !phone.isEmpty {
                                Button {
                                    callPhone(phone)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: 14))
                                        Text("Llamar")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(gradientManager.currentAccentColor.opacity(0.12))
                                    .foregroundColor(gradientManager.currentAccentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    } else {
                        if let address = order.deliveryAddress {
                            if let reference = address.reference, !reference.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    Text(reference)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                            if let instructions = address.deliveryInstructions, !instructions.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "text.bubble.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    Text(instructions)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func openInMaps(coordinate: CLLocationCoordinate2D, name: String) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault
        ])
    }

    private func callPhone(_ phone: String) {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
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
                    } else if viewModel.paymentMethod == nil,
                        OrderPermissionPolicy.isAwaitingCustomerPayment(
                            status: order.status, paymentStatus: order.paymentStatus),
                        !viewModel.canInitiatePayment(for: order)
                    {
                        // Solo importa si falta pagar: sin método no se puede mostrar el botón.
                        paymentNote(
                            icon: "exclamationmark.triangle.fill",
                            text: "No pudimos cargar el método de pago. Desliza hacia abajo para reintentar.",
                            color: .orange)
                    }

                    if viewModel.transferPaymentConfirmed {
                        paymentNote(
                            icon: "clock.badge.checkmark",
                            text: "Tu pago fue enviado. La tienda lo está verificando; no tienes que pagar de nuevo.",
                            color: .blue)
                    } else if order.paymentStatus == .validated {
                        paymentNote(
                            icon: "checkmark.circle.fill",
                            text: "Pago validado. La tienda confirmará tu pedido en breve.",
                            color: .green)
                    } else if order.paymentStatus == .failed,
                        viewModel.canInitiatePayment(for: order)
                    {
                        paymentNote(
                            icon: "xmark.octagon.fill",
                            text: "El último intento de pago falló. Puedes intentarlo de nuevo.",
                            color: .red)
                    }
                }
            }
        }
    }

    private func paymentNote(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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

    // MARK: - Refund Section

    @ViewBuilder
    private func refundSection(_ order: OrderDetail) -> some View {
        if let refund = viewModel.refundInfo {
            VStack(alignment: .leading, spacing: 12) {
                Text("Reembolso")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                    .padding(.horizontal, 2)

                card {
                    switch refund.state {
                    case .eligible:
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(gradientManager.currentAccentColor)
                                    .frame(width: 44, height: 44)
                                    .background(gradientManager.currentAccentColor.opacity(0.12))
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("¿Algún problema con tu pedido?")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                                    Text("Puedes solicitar el reembolso de este pago.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                Spacer(minLength: 0)
                            }
                            Button {
                                viewModel.refundReason = ""
                                viewModel.showRefundSheet = true
                            } label: {
                                Text("Solicitar reembolso")
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                            }
                            .modifier(GlassProminentButtonModifier())
                            .tint(gradientManager.currentAccentColor)
                            .disabled(viewModel.isSubmittingRefund)
                        }
                    case .requested:
                        refundStatusRow(
                            icon: "clock.fill", color: .orange,
                            text: "Reembolso solicitado. El negocio lo está revisando.")
                    case .processing:
                        refundStatusRow(
                            icon: "clock.arrow.circlepath", color: .orange,
                            text: "Tu reembolso está en proceso.")
                    case .refunded:
                        refundStatusRow(
                            icon: "checkmark.seal.fill", color: .green,
                            text: refund.formattedRefundAmount.map { "Reembolsado: \($0)" }
                                ?? "Tu pago fue reembolsado.")
                    }
                }
            }
        }
    }

    private func refundStatusRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Rating Section

    @ViewBuilder
    private func ratingSection(_ order: OrderDetail) -> some View {
        if order.status == .delivered {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tu calificación")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                    .padding(.horizontal, 2)

                card {
                    if let rating = order.rating {
                        VStack(alignment: .leading, spacing: 8) {
                            starsRow(current: rating, interactive: false)
                            if let comment = order.ratingComment, !comment.isEmpty {
                                Text(comment)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            Text("¡Gracias por tu calificación!")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("¿Cómo estuvo tu pedido?")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                            starsRow(current: viewModel.ratingDraft, interactive: true)
                            TextField("Comentario (opcional)", text: $viewModel.ratingCommentDraft)
                                .font(.system(size: 14))
                                .textFieldStyle(.roundedBorder)
                            Button {
                                viewModel.submitRating()
                            } label: {
                                HStack {
                                    if viewModel.isSubmittingRating {
                                        ProgressView().tint(.white)
                                    }
                                    Text(viewModel.isSubmittingRating ? "Enviando..." : "Enviar calificación")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                            }
                            .modifier(GlassProminentButtonModifier())
                            .tint(gradientManager.currentAccentColor)
                            .disabled(viewModel.ratingDraft == 0 || viewModel.isSubmittingRating)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func starsRow(current: Int, interactive: Bool) -> some View {
        let stars = HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { index in
                let star = Image(systemName: index <= current ? "star.fill" : "star")
                    .font(.system(size: 26))
                    .foregroundColor(index <= current ? .yellow : Color.gray.opacity(0.4))
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())

                if interactive {
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        viewModel.ratingDraft = index
                    } label: {
                        star
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(index) estrella\(index == 1 ? "" : "s")")
                    .accessibilityAddTraits(index == current ? .isSelected : [])
                } else {
                    star
                }
            }
        }

        if interactive {
            stars
        } else {
            stars
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Calificación: \(current) de 5 estrellas")
        }
    }

    // MARK: - Refund Reason Sheet

    private var refundReasonSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Cuéntanos el motivo del reembolso")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    if viewModel.refundReason.isEmpty {
                        Text("Ej. El pedido llegó incompleto…")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                    }
                    TextEditor(text: $viewModel.refundReason)
                        .font(.system(size: 14))
                        .padding(8)
                        .frame(height: 120)
                }
                .frame(height: 120)

                Button {
                    viewModel.submitRefund()
                } label: {
                    HStack {
                        if viewModel.isSubmittingRefund { ProgressView().tint(.white) }
                        Text(viewModel.isSubmittingRefund ? "Enviando..." : "Enviar solicitud")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .modifier(GlassProminentButtonModifier())
                .tint(gradientManager.currentAccentColor)
                .disabled(
                    viewModel.refundReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || viewModel.isSubmittingRefund)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Solicitar reembolso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { viewModel.showRefundSheet = false }
                }
            }
        }
    }

    // MARK: - History Section

    private func timelineSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historial")
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

    // MARK: - Toolbar

    /// Una sola acción principal según el estado; lo secundario (cancelar, llamar)
    /// vive en el menú ··· para no competir con ella.
    private enum PrimaryAction {
        case pay, acceptChanges, editAndResend, track, reorder
    }

    private func primaryAction(for order: OrderDetail) -> PrimaryAction? {
        if viewModel.canInitiatePayment(for: order) { return .pay }
        if OrderPermissionPolicy.canAcceptModifications(status: order.status) { return .acceptChanges }
        if order.displayStatus == .rejectedByStore && order.isEditable { return .editAndResend }
        if OrderPermissionPolicy.canShowTracking(status: order.status) && !order.isPickup { return .track }
        if order.displayStatus.isFinal && !order.items.isEmpty { return .reorder }
        return nil
    }

    @ToolbarContentBuilder
    private func orderDetailToolbarItems(_ order: OrderDetail) -> some ToolbarContent {
        let hasPhone = !(order.branchPhone ?? "").isEmpty
        if order.canCancel || hasPhone {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if let phone = order.branchPhone, hasPhone {
                        Button {
                            callPhone(phone)
                        } label: {
                            Label("Llamar a la tienda", systemImage: "phone")
                        }
                    }
                    if order.canCancel {
                        Button(role: .destructive) {
                            showCancelOptions = true
                        } label: {
                            Label("Cancelar pedido", systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Más opciones")
            }
        }

        if primaryAction(for: order) != nil {
            ToolbarItem(placement: .bottomBar) {
                primaryActionButton(order)
            }
        }
    }

    @ViewBuilder
    private func primaryActionButton(_ order: OrderDetail) -> some View {
        if let action = primaryAction(for: order) {
            let isBusy = action == .pay ? viewModel.isInitiatingPayment : viewModel.isProcessing

            Button {
                switch action {
                case .pay: viewModel.initiatePayment()
                case .acceptChanges: showAcceptChangesConfirmation = true
                case .editAndResend, .reorder: handleOpenInCartTap()
                case .track: showTracking = true
                }
            } label: {
                HStack(spacing: 10) {
                    if isBusy {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: primaryActionIcon(action, order: order))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(primaryActionTitle(action, order: order))
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(minWidth: 220)
                .frame(height: 52)
            }
            .modifier(GlassProminentButtonModifier())
            .tint(gradientManager.currentAccentColor)
            .disabled(viewModel.isInitiatingPayment || viewModel.isProcessing)
        }
    }

    private func primaryActionTitle(_ action: PrimaryAction, order: OrderDetail) -> String {
        switch action {
        case .pay: return "Pagar \(order.formattedTotal)"
        case .acceptChanges: return "Aceptar cambios"
        case .editAndResend: return "Editar y reenviar"
        case .track: return "Seguir pedido"
        case .reorder: return "Volver a pedir"
        }
    }

    private func primaryActionIcon(_ action: PrimaryAction, order: OrderDetail) -> String {
        switch action {
        case .pay: return paymentIconName(for: viewModel.paymentMethod, fallback: order.paymentMethod)
        case .acceptChanges: return "checkmark.circle.fill"
        case .editAndResend: return "square.and.pencil"
        case .track: return "location.fill"
        case .reorder: return "arrow.clockwise"
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
        case .cancelled:
            return "Pago cancelado"
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
            case .cancelled:
                return ("Cancelado", .gray)
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
            case "transfer", "transfermovil":
                return "building.columns.fill"
            case "qvapay":
                return "dollarsign.circle.fill"
            case "usdt":
                return "bitcoinsign.circle.fill"
            default:
                if method.code.lowercased().contains("qvapay") {
                    return "dollarsign.circle.fill"
                }
                if method.code.lowercased().contains("usdt")
                    || method.code.lowercased().contains("trondealer")
                {
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
        if normalized.contains("transfer") {
            return "building.columns.fill"
        }

        return "creditcard.fill"
    }

    // MARK: - Delivery Verification Code Card

    @State private var codeCopied = false

    private func deliveryCodeCard(_ code: String) -> some View {
        Button {
            UIPasteboard.general.string = code
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                codeCopied = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { codeCopied = false }
            }
        } label: {
            VStack(spacing: 0) {
                // Top strip — label row
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Código de verificación de entrega")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.3)
                    Spacer()
                    Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                        .contentTransition(.symbolEffect(.replace))
                }
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color(red: 1, green: 0.75, blue: 0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 10)

                Divider()
                    .overlay(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.4), Color.yellow.opacity(0.3), Color.orange.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                // Code row
                HStack(alignment: .center) {
                    Text(code)
                        .font(.system(size: 38, weight: .black, design: .monospaced))
                        .kerning(6)
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                    Spacer()

                    Text(codeCopied ? "Copiado" : "Toca para\ncopiar")
                        .font(.system(size: 11, weight: .medium))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.secondary)
                        .opacity(0.7)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)

                // Bottom warning
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                        .padding(.top, 1)
                    Text("Comparte este código **solo cuando tengas el pedido en tus manos**. Dárselo antes equivale a confirmar la entrega sin haberla recibido.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.cardBackground(colorScheme))
                    .shadow(color: Color.orange.opacity(colorScheme == .dark ? 0.25 : 0.15), radius: 14, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.9),
                                Color(red: 1, green: 0.75, blue: 0.2).opacity(0.6),
                                Color.orange.opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
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
