import Combine
import CoreLocation
import Foundation
import SwiftUI

enum CartViewState {
    case idle
    case loading
    case success
    case error(String)
}

enum DeliveryFeePaymentMode: String, CaseIterable {
    case sameCurrency
    case cashCUP
}

@MainActor
class CartViewModel: ObservableObject {
    @Published var state: CartViewState = .idle
    @Published var cartItems: [CartItem] = []
    @Published var errorMessage: String?
    @Published var hasWatchedAds: Bool = false  // Descuento por ver anuncios
    @Published var isCreatingOrder: Bool = false
    @Published var createdOrder: CreatedOrder?
    @Published var orderError: String?

    // Moneda seleccionada en el toolbar (sincronizada desde CartView)
    @Published var selectedCurrency: String = "CUP"

    // Payment Methods
    @Published var paymentMethods: [PaymentMethodModel] = []
    @Published var isLoadingPaymentMethods: Bool = false

    // Payment Attempt
    @Published var currentPaymentAttempt: PaymentAttemptModel?
    @Published var isInitiatingPayment: Bool = false

    // Shortcut polling
    @Published var isPollingShortcut: Bool = false
    @Published var shortcutPollingError: String?
    private var pollingTask: Task<Void, Never>?

    // Delivery Fee Estimation
    @Published var deliveryFeeEstimate: DeliveryFeeEstimate?
    @Published var isLoadingDeliveryFee: Bool = false
    @Published var deliveryFeeError: String?
    @Published var deliveryFeePaymentMode: DeliveryFeePaymentMode = .sameCurrency

    private let repository = CartRepository()
    private let cartManager = CartManager.shared
    private let createOrderRepository = CreateOrderRepository()
    private let paymentRepository = PaymentRepository()
    private let paymentMethodManager = PaymentMethodManager.shared
    private let walletRepository = WalletRepository()
    private let authManager = AuthManager.shared

    // Default Address
    @Published var defaultAddress: SavedAddress?
    @Published var selectedAddress: SavedAddress?
    @Published var fulfillmentMode: FulfillmentMode = .delivery
    @Published var selectedPickup: PickupSelection?
    @Published var isValidatingCheckout: Bool = false
    @Published var checkoutValidation: CheckoutValidationResultUI?
    @Published var checkoutIssues: [CheckoutIssueCode] = []

    // Store branchId from cart products
    private var cartBranchId: String?
    private var cartProducts: [CartProductGraphQL] = []
    @Published private(set) var branchAcceptedCurrency: String?
    @Published private(set) var cashKycMerchantId: String?
    @Published private(set) var cashKycBranchId: String?
    @Published private(set) var branchOpenStatus: BranchOpenStatus?
    @Published private(set) var branchSchedule: BranchSchedule?

    // Scheduled order
    @Published var scheduledFor: Date?

    // MARK: - AI Suggestions
    @Published var suggestedProducts: [Product] = []
    @Published var isLoadingSuggestions: Bool = false
    @Published var suggestionsError: String?
    private let recommendationsManager = CartRecommendationsManager.shared
    private let recommendationEngine = RecommendationEngine.shared
    private let aiPreferenceManager = AIPreferenceManager.shared
    private let pickupSelectionManager = PickupSelectionManager.shared
    private let checkoutFeatureFlags = CheckoutFeatureFlagManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Multi-branch detection
    var uniqueBranchIds: Set<String> {
        Set(cartItems.compactMap { $0.branchId })
    }

    var hasMultipleBranches: Bool {
        uniqueBranchIds.count > 1
    }

    var hasShowcaseItems: Bool {
        cartItems.contains(where: { $0.itemType == .showcase })
    }

    var isPickupAvailableForCurrentCart: Bool {
        !hasMultipleBranches && !hasShowcaseItems
    }

    var requiresDeliveryAddress: Bool {
        fulfillmentMode == .delivery
    }

    // MARK: - Service Fee Rate (fetched from backend, fallback 10%)
    @Published var serviceFeeRate: Double = 0.10

    init() {
        bindGlobalRecommendations()
    }

    // MARK: - Computed Properties

    var totalItems: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Double {
        cartItems.reduce(0.0) { partial, item in
            partial + item.itemTotal(for: selectedCurrency)
        }
    }

    var deliveryFee: Double {
        if cartItems.isEmpty { return 0.0 }
        return deliveryFeeEstimate?.deliveryFee ?? 0.0
    }

    /// Monto de envío incluido en el pago in-app según preferencia del usuario.
    /// - `sameCurrency`: se incluye convertido a la moneda seleccionada.
    /// - `cashCUP`: no se incluye en el pago in-app.
    var payableDeliveryFee: Double {
        guard !cartItems.isEmpty else { return 0.0 }
        guard fulfillmentMode == .delivery else { return 0.0 }
        guard let estimate = deliveryFeeEstimate else {
            return deliveryFeePaymentMode == .sameCurrency ? deliveryFee : 0.0
        }

        switch deliveryFeePaymentMode {
        case .sameCurrency:
            return convertAmount(
                estimate.deliveryFee,
                from: estimate.currency,
                to: selectedCurrency
            )
        case .cashCUP:
            return 0.0
        }
    }

    /// Moneda del envío estimado
    var deliveryFeeCurrency: String? {
        deliveryFeeEstimate?.currency
    }

    /// Distancia estimada en km
    var deliveryDistanceKm: Double? {
        deliveryFeeEstimate?.distanceKm
    }

    /// Nombre de la zona de envío
    var deliveryZoneName: String? {
        deliveryFeeEstimate?.zoneName
    }

    /// Tasa de servicio actual (obtenida del backend)
    var currentServiceFeeRate: Double {
        serviceFeeRate
    }

    /// Porcentaje de servicio formateado
    var serviceFeePercentage: Int {
        Int(currentServiceFeeRate * 100)
    }

    /// Cargo de servicio calculado sobre el subtotal
    var serviceFee: Double {
        subtotal * currentServiceFeeRate
    }

    /// Ahorro por ver anuncios (sin efecto mientras el backend maneja la tasa)
    var adSavings: Double { 0 }

    var total: Double {
        subtotal + payableDeliveryFee + serviceFee
    }

    var formattedSubtotal: String {
        formatPrice(subtotal, currency: selectedCurrency)
    }

    var formattedDeliveryFee: String {
        if fulfillmentMode == .pickup {
            return "Gratis"
        }
        if isLoadingDeliveryFee {
            return "Calculando..."
        }
        if deliveryFeeError != nil && deliveryFeeEstimate == nil {
            return "--"
        }
        if let estimate = deliveryFeeEstimate {
            switch deliveryFeePaymentMode {
            case .sameCurrency:
                let converted = convertAmount(
                    estimate.deliveryFee,
                    from: estimate.currency,
                    to: selectedCurrency
                )
                return formatPriceWithCurrency(converted, currency: selectedCurrency.uppercased())
            case .cashCUP:
                let cupAmount = convertAmount(
                    estimate.deliveryFee,
                    from: estimate.currency,
                    to: "CUP"
                )
                return formatPriceWithCurrency(cupAmount, currency: "CUP")
            }
        }
        return formatPriceWithCurrency(deliveryFee, currency: selectedCurrency.uppercased())
    }

    /// Descripción del envío (distancia + zona)
    var deliveryFeeDescription: String {
        if fulfillmentMode == .pickup {
            return "Recogida en tienda"
        }
        if isLoadingDeliveryFee {
            return "Estimando envío..."
        }
        if let error = deliveryFeeError, deliveryFeeEstimate == nil {
            return error
        }
        guard let estimate = deliveryFeeEstimate else {
            return "Entrega"
        }
        let distanceText = String(format: "%.1f km", estimate.distanceKm)
        if let zone = estimate.zoneName, !zone.isEmpty {
            return "\(distanceText) · \(zone)"
        }
        return distanceText
    }

    var formattedServiceFee: String {
        formatPrice(serviceFee, currency: selectedCurrency)
    }

    var formattedAdSavings: String {
        formatPrice(adSavings, currency: selectedCurrency)
    }

    var formattedTotal: String {
        formatPrice(total, currency: selectedCurrency)
    }

    /// Total si viera los anuncios (igual al total normal ya que la tasa viene del backend)
    var totalWithDiscount: Double { total }

    var formattedTotalWithDiscount: String {
        formattedTotal
    }

    /// Ahorro potencial si ve los anuncios
    var potentialSavings: Double { 0 }

    var formattedPotentialSavings: String {
        formatPrice(potentialSavings, currency: selectedCurrency)
    }

    /// Activar descuento por ver anuncios
    func activateAdDiscount() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            hasWatchedAds = true
        }
    }

    // MARK: - Service Fee

    /// Obtener la tasa de cargo de servicio desde el backend
    func fetchServiceFeeRate() {
        repository.fetchServiceFeeRate { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                if case .success(let rate) = result {
                    self.serviceFeeRate = rate
                }
            }
        }
    }

    // MARK: - Actions

    /// Cargar productos del carrito (desde local + GraphQL)
    func loadCart() {
        state = .loading
        errorMessage = nil
        fetchServiceFeeRate()

        repository.fetchCartProducts { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let cartProducts):
                    // Store cart products for order creation
                    self.cartProducts = cartProducts

                    // Mapear a UI models
                    let productItems = cartProducts.map { product in
                        CartItem(
                            id: product.id,
                            itemType: .product,
                            productId: product.productId,
                            showcaseId: nil,
                            showcaseRequestDescription: nil,
                            comboGroupId: product.comboGroupId,
                            comboId: product.comboId,
                            comboName: product.comboName,
                            comboComponentSlotId: product.comboComponentSlotId,
                            comboComponentSlotName: product.comboComponentSlotName,
                            comboComponentOrder: product.comboComponentOrder,
                            comboModifierNames: product.comboModifierNames,
                            name: product.name,
                            shop: product.businessName,
                            weight: product.weight,
                            basePrice: product.basePrice,
                            finalUnitPrice: product.finalUnitPrice,
                            finalTotalPrice: product.finalTotalPrice,
                            currency: product.currency,
                            convertedPrice: product.convertedPrice,
                            convertedCurrency: product.convertedCurrency,
                            exchangeRate: product.exchangeRate,
                            imageUrl: product.image,
                            quantity: product.quantity,
                            branchId: product.branchId,
                            availability: product.availability,
                            selectedVariants: product.selectedVariants
                        )
                    }

                    let showcaseItems = self.cartManager.localShowcaseItems.map { showcase in
                        CartItem(
                            id: showcase.cartItemId,
                            itemType: .showcase,
                            productId: "",
                            showcaseId: showcase.showcaseId,
                            showcaseRequestDescription: showcase.requestDescription,
                            comboGroupId: nil,
                            comboId: nil,
                            comboName: nil,
                            comboComponentSlotId: nil,
                            comboComponentSlotName: nil,
                            comboComponentOrder: nil,
                            comboModifierNames: [],
                            name: showcase.title,
                            shop: showcase.branchName,
                            weight: "Pedido manual",
                            basePrice: 0,
                            finalUnitPrice: 0,
                            finalTotalPrice: 0,
                            currency: "BOTH",
                            convertedPrice: nil,
                            convertedCurrency: nil,
                            exchangeRate: nil,
                            imageUrl: showcase.imageUrl,
                            quantity: showcase.quantity,
                            branchId: showcase.branchId,
                            availability: true,
                            selectedVariants: []
                        )
                    }

                    self.cartItems = productItems + showcaseItems
                    self.cartBranchId = self.cartItems.first?.branchId
                    self.selectedPickup = self.pickupSelectionManager.loadSelection(
                        for: self.authManager.currentUser?.id
                    )

                    print("✅ Loaded \(self.cartItems.count) items in cart")
                    if let branchId = self.cartBranchId {
                        print("📍 Branch ID: \(branchId)")
                        self.fetchBranchAcceptedCurrency(branchId: branchId)
                        self.fetchCashKycMerchantContext(branchId: branchId)
                        self.fetchBranchScheduleStatus(branchId: branchId)
                        // Estimar envío usando el branchId del primer producto
                        self.fetchDeliveryFeeEstimate(branchId: branchId)
                        if self.selectedPickup == nil || self.selectedPickup?.branchId != branchId {
                            self.selectedPickup = PickupSelection(
                                branchId: branchId,
                                branchName: self.cartItems.first?.shop ?? "Tienda",
                                address: nil,
                                latitude: nil,
                                longitude: nil,
                                scheduleJson: nil,
                                selectedWindowId: nil
                            )
                            self.persistPickupSelection()
                        }
                    } else {
                        self.cashKycMerchantId = nil
                        self.cashKycBranchId = nil
                    }

                    if !self.isStorePickupEnabled || !self.isPickupAvailableForCurrentCart {
                        self.fulfillmentMode = .delivery
                    }

                    // Check for default saved address
                    if let user = self.authManager.currentUser,
                        let defaultId = user.defaultAddressId, let addresses = user.savedAddresses
                    {
                        if let defaultAddr = addresses.first(where: { $0.id == defaultId }) {
                            self.defaultAddress = defaultAddr
                            self.selectedAddress = defaultAddr
                        }
                    }

                    self.state = .success

                    // Load payment methods after cart is loaded
                    self.loadPaymentMethods()

                    // Refrescar estado de sugerencias globales
                    self.loadAISuggestions()

                case .failure(let error):
                    self.errorMessage = "Error al cargar el carrito: \(error.localizedDescription)"
                    self.state = .error(self.errorMessage!)
                    print("❌ Error loading cart: \(error)")
                }
            }
        }
    }

    // MARK: - Optimistic Add from Recommendations

    /// Adds a product to cartItems immediately without waiting for a backend reload.
    /// Calls CartManager to persist the mutation in the background.
    func optimisticallyAdd(product: Product) {
        // Convert Product.price (String) to Double
        let priceValue: Double
        let clean = product.price
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        priceValue = Double(clean) ?? 0.0

        // Check if item already exists in cart and increment instead
        if let index = cartItems.firstIndex(where: { $0.id == product.id }) {
            cartItems[index].quantity += 1
        } else {
            let newItem = CartItem(
                id: product.id,
                itemType: .product,
                productId: product.id,
                showcaseId: nil,
                showcaseRequestDescription: nil,
                comboGroupId: nil,
                comboId: nil,
                comboName: nil,
                comboComponentSlotId: nil,
                comboComponentSlotName: nil,
                comboComponentOrder: nil,
                comboModifierNames: [],
                name: product.name,
                shop: product.shop,
                weight: product.weight,
                basePrice: priceValue,
                finalUnitPrice: priceValue,
                finalTotalPrice: priceValue,
                currency: "CUP",
                convertedPrice: nil,
                convertedCurrency: nil,
                exchangeRate: nil,
                imageUrl: product.imageUrl,
                quantity: 1,
                branchId: nil,
                availability: true,
                selectedVariants: []
            )
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                cartItems.append(newItem)
            }
        }

        // Persist via CartManager (fires backend mutation in background)
        CartManager.shared.addToCart(productId: product.id, quantity: 1)
    }

    // MARK: - AI Suggestions

    /// Obtener sugerencias de productos usando la estrategia seleccionada por el usuario
    func loadAISuggestions() {
        // Pasar el productId del primer producto del carrito para que el flujo de Apple Intelligence
        // pueda llamar productsFromSameBranch con ese productId
        if let firstProductId = cartProducts.first?.productId {
            recommendationsManager.updateFirstProductId(firstProductId)
        }
        // El manager global maneja el estado reactivamente via Combine bindings
        recommendationsManager.refreshNow()
    }

    private func bindGlobalRecommendations() {
        recommendationsManager.$suggestedProducts
            .receive(on: RunLoop.main)
            .sink { [weak self] products in
                self?.suggestedProducts = products
            }
            .store(in: &cancellables)

        recommendationsManager.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                self?.isLoadingSuggestions = isLoading
            }
            .store(in: &cancellables)

        recommendationsManager.$errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                self?.suggestionsError = message
            }
            .store(in: &cancellables)
    }

    /// Cargar sugerencias usando Apple Intelligence (local)
    private func loadSuggestionsFromAppleIntelligence() {
        // Verificar disponibilidad de Apple Intelligence
        guard recommendationEngine.isAvailable() else {
            let status = recommendationEngine.getAvailabilityStatus()
            print("⚠️ \(status.message)")
            suggestionsError = status.message
            isLoadingSuggestions = false
            return
        }

        // Verificar que hay un branchId
        guard let branchId = cartBranchId else {
            print("⚠️ No hay branchId para sugerencias")
            isLoadingSuggestions = false
            return
        }

        // Obtener todos los productos del branch
        repository.fetchAllBranchProducts(branchId: branchId) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let branchProducts):
                    // Enviar a Apple Intelligence local
                    await self.getSuggestionsFromAppleIntelligence(
                        cartProducts: self.cartProducts,
                        branchProducts: branchProducts
                    )

                case .failure(let error):
                    self.isLoadingSuggestions = false
                    self.suggestionsError = "No se pudieron cargar productos"
                    print("❌ Error fetching branch products: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Cargar sugerencias usando la API de Llego Cloud
    private func loadSuggestionsFromLlegoCloud() {
        // Verificar que hay productos válidos
        guard !cartProducts.isEmpty else {
            print("⚠️ [CartViewModel] No hay productos en el carrito")
            isLoadingSuggestions = false
            return
        }

        let productIds = cartProducts.map { $0.productId }
        let productNames = cartProducts.map { $0.name }

        print("🌐 [CartViewModel] ========================================")
        print("🌐 [CartViewModel] Obteniendo recomendaciones desde Llego Cloud")
        print("🌐 [CartViewModel] Cantidad de productos: \(productIds.count)")
        print("🌐 [CartViewModel] Product IDs: \(productIds)")
        print("🌐 [CartViewModel] Product Names: \(productNames)")

        // Detectar si hay múltiples branches
        if hasMultipleBranches {
            print(
                "⚠️ [CartViewModel] ADVERTENCIA: Carrito con múltiples branches: \(uniqueBranchIds)")
            print("⚠️ [CartViewModel] Esto puede afectar las recomendaciones")
        } else if let branchId = cartBranchId {
            print("✅ [CartViewModel] Branch único: \(branchId)")
        }

        print("🌐 [CartViewModel] ========================================")

        repository.fetchCloudRecommendations(productIds: productIds, limit: 6) {
            [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let recommendations):
                    print(
                        "🌐 [CartViewModel] Backend retornó \(recommendations.count) recomendaciones"
                    )

                    // Filtrar productos que ya están en el carrito
                    let cartProductIds = Set(self.cartProducts.map { $0.productId })
                    self.suggestedProducts = recommendations.filter {
                        !cartProductIds.contains($0.id)
                    }

                    self.isLoadingSuggestions = false

                    if self.suggestedProducts.isEmpty {
                        print("⚠️ [CartViewModel] No hay recomendaciones después de filtrar")
                        self.suggestionsError =
                            "No hay recomendaciones disponibles para estos productos"
                    } else {
                        print(
                            "✅ [CartViewModel] Loaded \(self.suggestedProducts.count) cloud recommendations"
                        )
                    }

                case .failure(let error):
                    self.isLoadingSuggestions = false
                    self.suggestionsError = "No se pudieron cargar recomendaciones de la nube"
                    print(
                        "❌ [CartViewModel] Error loading cloud recommendations: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    /// Enviar productos a Apple Intelligence local para obtener sugerencias
    private func getSuggestionsFromAppleIntelligence(
        cartProducts: [CartProductGraphQL],
        branchProducts: [ProductGraphQL]
    ) async {
        do {
            // Preparar nombres de productos del carrito
            let cartItemNames = cartProducts.map { $0.name }

            // Preparar catálogo con ID y nombre
            let catalog = branchProducts.map { (id: $0.id, name: $0.name) }

            // Obtener recomendaciones del engine
            let recommendedIds = try await recommendationEngine.getRecommendations(
                cartItems: cartItemNames,
                catalog: catalog
            )

            print("🤖 AI sugirió \(recommendedIds.count) productos: \(recommendedIds)")

            // Filtrar productos por IDs recomendados
            let filteredProducts = repository.filterProductsByIds(
                productIds: recommendedIds,
                allProducts: branchProducts
            )

            // Filtrar productos que ya están en el carrito
            let cartProductIds = Set(cartProducts.map { $0.productId })
            suggestedProducts = filteredProducts.filter { !cartProductIds.contains($0.id) }

            isLoadingSuggestions = false
            print("✅ Loaded \(suggestedProducts.count) suggested products")

        } catch {
            isLoadingSuggestions = false
            suggestionsError = "No se pudieron cargar sugerencias"
            print("❌ Error loading AI suggestions: \(error.localizedDescription)")
        }
    }

    // MARK: - Load Payment Methods

    // MARK: - Delivery Fee Estimation

    /// Obtener estimación de envío desde el backend
    func fetchDeliveryFeeEstimate(branchId: String) {
        isLoadingDeliveryFee = true
        deliveryFeeError = nil

        repository.estimateDeliveryFee(branchId: branchId) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoadingDeliveryFee = false

                switch result {
                case .success(let estimate):
                    self.deliveryFeeEstimate = estimate
                    print("✅ Delivery fee loaded: \(estimate.deliveryFee) \(estimate.currency)")

                case .failure(let error):
                    self.deliveryFeeError = "No se pudo estimar el envío"
                    print("❌ Error fetching delivery fee: \(error.localizedDescription)")
                }
            }
        }
    }

    func loadPaymentMethods() {
        // Si hay productos de múltiples branches, no cargar métodos de pago
        guard !hasMultipleBranches else {
            paymentMethods = []
            print("⚠️ Múltiples branches en carrito – métodos de pago deshabilitados")
            return
        }

        Task {
            isLoadingPaymentMethods = true

            do {
                let methods = try await paymentMethodManager.fetchPaymentMethods(
                    branchId: cartBranchId)
                await MainActor.run {
                    self.paymentMethods =
                        methods
                        .filter { $0.isActive }
                        .sorted { $0.displayOrder < $1.displayOrder }
                    self.isLoadingPaymentMethods = false
                    print(
                        "✅ Loaded \(self.paymentMethods.count) payment methods for branch \(self.cartBranchId ?? "all")"
                    )
                }
            } catch {
                await MainActor.run {
                    self.isLoadingPaymentMethods = false
                    print("❌ Error loading payment methods: \(error.localizedDescription)")
                }
            }
        }
    }

    private func fetchBranchAcceptedCurrency(branchId: String) {
        repository.fetchBranchAcceptedCurrency(branchId: branchId) { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success(let accepted):
                    self.branchAcceptedCurrency = accepted?.uppercased()
                case .failure(let error):
                    print("⚠️ Error loading branch accepted currency: \(error.localizedDescription)")
                }
            }
        }
    }

    private func fetchCashKycMerchantContext(branchId: String) {
        repository.fetchBranchBusinessContext(branchId: branchId) { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success(let context):
                    self.cashKycMerchantId = context.businessId
                    self.cashKycBranchId = context.branchId
                case .failure(let error):
                    self.cashKycMerchantId = nil
                    self.cashKycBranchId = nil
                    print("⚠️ Error loading KYC merchant context: \(error.localizedDescription)")
                }
            }
        }
    }

    private func fetchBranchScheduleStatus(branchId: String) {
        repository.fetchBranchSchedule(branchId: branchId) { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success(let schedule):
                    self.branchSchedule = schedule
                    self.branchOpenStatus = schedule?.currentStatus()
                case .failure(let error):
                    print("⚠️ Error loading branch schedule: \(error.localizedDescription)")
                }
            }
        }
    }

    var includeDeliveryFeeInAppPayment: Bool {
        fulfillmentMode == .delivery && deliveryFeePaymentMode == .sameCurrency
    }

    var shouldIncludeDeliveryFeeInPayment: Bool {
        includeDeliveryFeeInAppPayment
    }

    var isStorePickupEnabled: Bool {
        checkoutFeatureFlags.isPickupEnabled(for: cartBranchId)
    }

    // MARK: - Filter Payment Methods

    func paymentMethodsByCurrency(_ currency: String) -> [PaymentMethodModel] {
        paymentMethods.filter { $0.currency.uppercased() == currency.uppercased() }
    }

    // MARK: - Create Order with New Payment Flow

    /// Crear pedido y luego iniciar el pago
    func createOrderAndInitiatePayment(
        paymentMethodId: String,
        sendsSmsNotification: Bool = false,
        includeDeliveryFee: Bool = true,
        comments: String? = nil,
        completion:
            @escaping @Sendable (Result<(CreatedOrder, InitiatePaymentResultModel), Error>) -> Void
    ) {
        guard let branchId = cartBranchId else {
            let error = NSError(
                domain: "CartViewModel", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No se pudo determinar la tienda"])
            completion(.failure(error))
            return
        }

        guard !cartItems.isEmpty else {
            let error = NSError(
                domain: "CartViewModel", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "El carrito está vacío"])
            completion(.failure(error))
            return
        }

        isCreatingOrder = true
        orderError = nil

        let items = buildOrderRequestItems()
        guard !items.isEmpty else {
            let error = NSError(
                domain: "CartViewModel",
                code: -8,
                userInfo: [NSLocalizedDescriptionKey: "No hay ítems válidos para crear el pedido"]
            )
            completion(.failure(error))
            return
        }

        guard let fulfillment = buildFulfillmentInput(branchId: branchId) else {
            let error = NSError(
                domain: "CartViewModel",
                code: -9,
                userInfo: [NSLocalizedDescriptionKey: "La recogida seleccionada no es válida"]
            )
            completion(.failure(error))
            return
        }

        let deliveryAddress: DeliveryAddressInput?
        switch fulfillment.type {
        case .delivery:
            guard let address = buildDeliveryAddress() else {
                let error = NSError(
                    domain: "CartViewModel", code: -3,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Por favor selecciona una ubicación de entrega"
                    ])
                completion(.failure(error))
                return
            }
            deliveryAddress = address
        case .pickup:
            deliveryAddress = nil
        }

        print("🛒 Creating order with new payment flow...")
        print("   Branch: \(branchId)")
        print("   Items: \(items.count)")
        print("   Payment Method: \(paymentMethodId)")
        print("   Fulfillment: \(fulfillment.type.rawValue)")

        // Step 1: Create Order (without payment)
        createOrderRepository.createOrder(
            branchId: branchId,
            items: items,
            fulfillment: fulfillment,
            deliveryAddress: deliveryAddress,
            paymentMethod: "pending",  // Temporary, will be updated by payment
            paymentIntentId: nil,
            comments: comments,
            scheduledFor: scheduledFor
        ) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let order):
                    print("✅ Order created: \(order.orderNumber)")
                    self.createdOrder = order

                    // Step 2: Initiate Payment
                    do {
                        let paymentResult = try await self.initiatePaymentForOrder(
                            orderId: order.id,
                            paymentMethodId: paymentMethodId,
                            includeDeliveryFee: includeDeliveryFee,
                            sendsSmsNotification: sendsSmsNotification
                        )

                        await MainActor.run {
                            self.isCreatingOrder = false
                            print("✅ Payment initiated: \(paymentResult.paymentAttempt.id)")
                            completion(.success((order, paymentResult)))
                        }
                    } catch {
                        await MainActor.run {
                            self.isCreatingOrder = false
                            self.orderError = error.localizedDescription
                            print("❌ Error initiating payment: \(error.localizedDescription)")
                            completion(.failure(error))
                        }
                    }

                case .failure(let error):
                    print("❌ Error creating order: \(error.localizedDescription)")
                    await MainActor.run {
                        self.isCreatingOrder = false
                        self.orderError = error.localizedDescription
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // MARK: - Initiate Payment

    private func initiatePaymentForOrder(
        orderId: String,
        paymentMethodId: String,
        includeDeliveryFee: Bool = true,
        sendsSmsNotification: Bool = false
    ) async throws -> InitiatePaymentResultModel {
        guard let jwt = await authManager.getAccessToken() else {
            throw NSError(
                domain: "CartViewModel", code: -4,
                userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa"])
        }

        await MainActor.run {
            self.isInitiatingPayment = true
        }

        do {
            let result = try await paymentRepository.initiatePayment(
                orderId: orderId,
                paymentMethodId: paymentMethodId,
                jwt: jwt,
                includeDeliveryFee: includeDeliveryFee,
                sendsSmsNotification: sendsSmsNotification
            )

            await MainActor.run {
                self.currentPaymentAttempt = result.paymentAttempt
                self.isInitiatingPayment = false
            }

            return result
        } catch {
            await MainActor.run {
                self.isInitiatingPayment = false
            }
            throw error
        }
    }

    // MARK: - Confirm Transfer By Shortcut (con polling)

    /// Llama a confirmTransferByShortcut una vez. El polling lo gestiona startShortcutPolling.
    func confirmTransferByShortcut(
        paymentAttemptId: String,
        transferId: String? = nil,
        completion: @escaping @Sendable (Result<PaymentAttemptModel, Error>) -> Void
    ) {
        Task {
            guard let jwt = await authManager.getAccessToken() else {
                let error = NSError(
                    domain: "CartViewModel", code: -5,
                    userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa"])
                completion(.failure(error))
                return
            }

            do {
                let attempt = try await paymentRepository.confirmTransferByShortcut(
                    paymentAttemptId: paymentAttemptId,
                    jwt: jwt,
                    transferId: transferId
                )
                await MainActor.run {
                    self.currentPaymentAttempt = attempt
                }
                completion(.success(attempt))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Inicia polling cada 5 segundos llamando a confirmTransferByShortcut.
    /// Detiene al recibir status "confirmed" o "completed", o cuando se cancela.
    func startShortcutPolling(
        paymentAttemptId: String,
        onSuccess: @escaping @Sendable (PaymentAttemptModel) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) {
        stopShortcutPolling()
        isPollingShortcut = true
        shortcutPollingError = nil

        pollingTask = Task {
            while !Task.isCancelled {
                guard let jwt = await authManager.getAccessToken() else { break }
                do {
                    let attempt = try await paymentRepository.confirmTransferByShortcut(
                        paymentAttemptId: paymentAttemptId,
                        jwt: jwt,
                        transferId: nil
                    )
                    await MainActor.run {
                        self.currentPaymentAttempt = attempt
                    }
                    let status = attempt.status.lowercased()
                    if status == "confirmed" || status == "completed"
                        || status == "customer_confirmed"
                    {
                        await MainActor.run {
                            self.isPollingShortcut = false
                        }
                        onSuccess(attempt)
                        return
                    }
                } catch {
                    // El backend aún no encontró la transferencia — seguimos intentando
                    print("⏳ Shortcut poll: \(error.localizedDescription)")
                }
                try? await Task.sleep(nanoseconds: 5_000_000_000)  // 5 segundos
            }
            await MainActor.run {
                self.isPollingShortcut = false
            }
        }
    }

    func stopShortcutPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        isPollingShortcut = false
    }

    // MARK: - Confirm Payment Sent (for manual methods)

    func confirmPaymentSent(
        paymentAttemptId: String,
        proofUrl: String,
        completion: @escaping @Sendable (Result<PaymentAttemptModel, Error>) -> Void
    ) {
        Task {
            guard let jwt = await authManager.getAccessToken() else {
                let error = NSError(
                    domain: "CartViewModel", code: -5,
                    userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa"])
                completion(.failure(error))
                return
            }

            do {
                let paymentAttempt = try await paymentRepository.confirmPaymentSent(
                    paymentAttemptId: paymentAttemptId,
                    proofUrl: proofUrl,
                    jwt: jwt
                )

                await MainActor.run {
                    self.currentPaymentAttempt = paymentAttempt
                }

                completion(.success(paymentAttempt))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Legacy Create Order (for backward compatibility)

    /// Crear pedido real en el backend (método legacy)
    func createOrder(
        paymentMethod: String,
        paymentIntentId: String? = nil,
        comments: String? = nil,
        completion: @escaping @Sendable (Result<CreatedOrder, Error>) -> Void
    ) {
        guard let branchId = cartBranchId else {
            let error = NSError(
                domain: "CartViewModel", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No se pudo determinar la tienda"])
            completion(.failure(error))
            return
        }

        guard !cartItems.isEmpty else {
            let error = NSError(
                domain: "CartViewModel", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "El carrito está vacío"])
            completion(.failure(error))
            return
        }

        isCreatingOrder = true
        orderError = nil

        let items = buildOrderRequestItems()
        guard !items.isEmpty else {
            let error = NSError(
                domain: "CartViewModel",
                code: -8,
                userInfo: [NSLocalizedDescriptionKey: "No hay ítems válidos para crear el pedido"]
            )
            completion(.failure(error))
            return
        }

        guard let fulfillment = buildFulfillmentInput(branchId: branchId) else {
            let error = NSError(
                domain: "CartViewModel",
                code: -9,
                userInfo: [NSLocalizedDescriptionKey: "La recogida seleccionada no es válida"]
            )
            completion(.failure(error))
            return
        }

        let deliveryAddress: DeliveryAddressInput?
        switch fulfillment.type {
        case .delivery:
            guard let address = buildDeliveryAddress() else {
                let error = NSError(
                    domain: "CartViewModel", code: -3,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Por favor selecciona una ubicación de entrega"
                    ])
                completion(.failure(error))
                return
            }
            deliveryAddress = address
        case .pickup:
            deliveryAddress = nil
        }

        print("🛒 Creating order...")
        print("   Branch: \(branchId)")
        print("   Items: \(items.count)")
        print("   Payment: \(paymentMethod)")
        print("   Fulfillment: \(fulfillment.type.rawValue)")

        createOrderRepository.createOrder(
            branchId: branchId,
            items: items,
            fulfillment: fulfillment,
            deliveryAddress: deliveryAddress,
            paymentMethod: paymentMethod,
            paymentIntentId: paymentIntentId,
            comments: comments,
            scheduledFor: scheduledFor
        ) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isCreatingOrder = false

                switch result {
                case .success(let order):
                    print("✅ Order created successfully: \(order.orderNumber)")
                    self.createdOrder = order
                    completion(.success(order))

                case .failure(let error):
                    print("❌ Error creating order: \(error.localizedDescription)")
                    self.orderError = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }

    /// Incrementar cantidad de un producto
    func incrementQuantity(cartItemId: String) {
        if let item = cartItems.first(where: { $0.id == cartItemId }) {
            if let comboGroupId = item.comboGroupId {
                let currentComboQty =
                    cartItems.first(where: { $0.comboGroupId == comboGroupId })?
                    .quantity ?? 0
                cartManager.updateComboQuantity(
                    comboGroupId: comboGroupId, quantity: currentComboQty + 1)
                loadCart()
                return
            }
            cartManager.updateQuantity(cartItemId: cartItemId, quantity: item.quantity + 1)
            loadCart()
        }
    }

    /// Decrementar cantidad de un producto
    func decrementQuantity(cartItemId: String) {
        if let item = cartItems.first(where: { $0.id == cartItemId }) {
            if let comboGroupId = item.comboGroupId {
                let currentComboQty =
                    cartItems.first(where: { $0.comboGroupId == comboGroupId })?
                    .quantity ?? 0
                let newQty = currentComboQty - 1
                if newQty <= 0 {
                    cartManager.removeComboFromCart(comboGroupId: comboGroupId)
                } else {
                    cartManager.updateComboQuantity(comboGroupId: comboGroupId, quantity: newQty)
                }
                loadCart()
                return
            }
            let newQuantity = item.quantity - 1
            if newQuantity <= 0 {
                removeFromCart(cartItemId: cartItemId)
            } else {
                cartManager.updateQuantity(cartItemId: cartItemId, quantity: newQuantity)
                loadCart()
            }
        }
    }

    /// Remover producto del carrito
    func removeFromCart(cartItemId: String) {
        if let comboGroupId = cartItems.first(where: { $0.id == cartItemId })?.comboGroupId {
            cartManager.removeComboFromCart(comboGroupId: comboGroupId)
            loadCart()
            return
        }
        cartManager.removeFromCart(cartItemId: cartItemId)
        loadCart()
    }

    /// Limpiar todo el carrito
    func clearCart() {
        cartManager.clearCart()
        cartItems = []
        state = .success
        fulfillmentMode = .delivery
    }

    // MARK: - Helpers

    func setFulfillmentMode(_ mode: FulfillmentMode) {
        if mode == .pickup && (!isStorePickupEnabled || !isPickupAvailableForCurrentCart) {
            fulfillmentMode = .delivery
            return
        }
        fulfillmentMode = mode
    }

    func setPickupSelection(_ selection: PickupSelection?) {
        selectedPickup = selection
        persistPickupSelection()
    }

    private func persistPickupSelection() {
        pickupSelectionManager.saveSelection(selectedPickup, for: authManager.currentUser?.id)
    }

    private func buildDeliveryAddress() -> DeliveryAddressInput? {
        if let selected = selectedAddress {
            return DeliveryAddressInput(
                street: selected.street,
                city: selected.city,
                reference: selected.reference,
                latitude: selected.latitude,
                longitude: selected.longitude,
                addressType: selected.addressType,
                buildingName: selected.buildingName,
                floor: selected.floor,
                apartment: selected.apartment,
                deliveryInstructions: selected.deliveryInstructions
            )
        }

        let locationManager = UserLocationManager.shared
        guard let userLocation = locationManager.userLocation else {
            return nil
        }

        return DeliveryAddressInput(
            street: locationManager.userAddress,
            city: nil,
            reference: nil,
            latitude: userLocation.latitude,
            longitude: userLocation.longitude,
            addressType: nil,
            buildingName: nil,
            floor: nil,
            apartment: nil,
            deliveryInstructions: nil
        )
    }

    private func buildFulfillmentInput(branchId: String) -> FulfillmentPayloadInput? {
        switch fulfillmentMode {
        case .delivery:
            return .delivery
        case .pickup:
            guard isStorePickupEnabled, isPickupAvailableForCurrentCart else {
                return nil
            }
            guard let pickup = selectedPickup, pickup.branchId == branchId else {
                return nil
            }
            return FulfillmentPayloadInput(
                type: .pickup,
                pickupBranchId: pickup.branchId,
                pickupWindowId: pickup.selectedWindowId
            )
        }
    }

    private func aggregatedOrderItems() -> [(productId: String, quantity: Int)] {
        let grouped = Dictionary(
            grouping: cartItems.filter { $0.itemType == .product && $0.comboGroupId == nil },
            by: \.productId
        )
        return grouped.map { productId, items in
            let qty = items.reduce(0) { partial, item in
                partial + item.quantity
            }
            return (productId: productId, quantity: qty)
        }
    }

    private func buildOrderRequestItems() -> [OrderRequestItem] {
        let productItems = aggregatedOrderItems().map { item in
            OrderRequestItem(
                itemType: .product,
                quantity: item.quantity,
                productId: item.productId,
                comboId: nil,
                comboSelections: nil,
                showcaseId: nil,
                description: nil
            )
        }

        let comboItems = buildComboOrderRequestItems()

        let showcaseItems =
            cartItems
            .filter { $0.itemType == .showcase }
            .compactMap { item -> OrderRequestItem? in
                guard
                    let showcaseId = item.showcaseId,
                    let description = item.showcaseRequestDescription?.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                    !description.isEmpty
                else {
                    return nil
                }

                return OrderRequestItem(
                    itemType: .showcase,
                    quantity: item.quantity,
                    productId: nil,
                    comboId: nil,
                    comboSelections: nil,
                    showcaseId: showcaseId,
                    description: description
                )
            }

        return productItems + comboItems + showcaseItems
    }

    private func buildComboOrderRequestItems() -> [OrderRequestItem] {
        let comboGroups = Dictionary(
            grouping: cartItems.filter { $0.itemType == .product && $0.comboGroupId != nil },
            by: \.comboGroupId
        )

        return comboGroups.compactMap { _, groupedItems -> OrderRequestItem? in
            let sortedItems = groupedItems.sorted {
                ($0.comboComponentOrder ?? .max) < ($1.comboComponentOrder ?? .max)
            }
            guard let firstItem = sortedItems.first, let comboId = firstItem.comboId else {
                return nil
            }

            let slotMap = Dictionary(
                grouping: sortedItems.compactMap { item -> (slotId: String, item: CartItem)? in
                    guard let slotId = item.comboComponentSlotId else { return nil }
                    return (slotId: slotId, item: item)
                },
                by: \.slotId
            )

            let comboSelections = slotMap.compactMap {
                slotId, values -> (order: Int, selection: OrderRequestComboSlotSelection)? in
                let slotItems = values.map(\.item).sorted {
                    ($0.comboComponentOrder ?? .max) < ($1.comboComponentOrder ?? .max)
                }
                guard let firstSlotItem = slotItems.first else { return nil }

                let selection = OrderRequestComboSlotSelection(
                    slotId: slotId,
                    slotName: firstSlotItem.comboComponentSlotName ?? "",
                    selectedOptions: slotItems.map { slotItem in
                        OrderRequestComboSelectedOption(
                            productId: slotItem.productId,
                            quantity: 1,
                            modifiers: slotItem.comboModifierNames.map {
                                OrderRequestComboModifier(name: $0)
                            }
                        )
                    }
                )
                return (firstSlotItem.comboComponentOrder ?? .max, selection)
            }
            .sorted { $0.order < $1.order }
            .map(\.selection)

            return OrderRequestItem(
                itemType: .combo,
                quantity: firstItem.quantity,
                productId: nil,
                comboId: comboId,
                comboSelections: comboSelections,
                showcaseId: nil,
                description: nil
            )
        }
    }

    func formatPrice(_ price: Double) -> String {
        return String(format: "$%.2f", price)
    }

    func formatPrice(_ price: Double, currency: String) -> String {
        return String(format: "%.2f %@", price, currency.uppercased())
    }

    private func formatPriceWithCurrency(_ price: Double, currency: String) -> String {
        return String(format: "%.2f %@", price, currency)
    }

    private func convertAmount(
        _ amount: Double, from sourceCurrency: String, to targetCurrency: String
    )
        -> Double
    {
        let from = sourceCurrency.uppercased()
        let to = targetCurrency.uppercased()
        if from == to { return amount }

        guard let rate = cartItems.compactMap(\.exchangeRate).first(where: { $0 > 0 }) else {
            return amount
        }

        if from == "USD" && to == "CUP" {
            return amount * Double(rate)
        }

        if from == "CUP" && to == "USD" {
            return amount / Double(rate)
        }

        return amount
    }

    // MARK: - Wallet Balance Check

    /// Verifica si el usuario tiene saldo suficiente en wallet para cubrir el total.
    /// - Parameters:
    ///   - method: El método de pago wallet seleccionado.
    ///   - requiredAmount: Monto a comparar (total del carrito).
    ///   - selectedCurrency: Moneda activa en el selector del carrito.
    /// - Returns: Tupla con si tiene saldo y el balance actual.
    func checkWalletBalance(
        for method: PaymentMethodModel,
        requiredAmount: Double,
        selectedCurrency: String
    ) async throws -> (hasSufficientBalance: Bool, available: Double) {
        guard let jwt = await authManager.getAccessToken() else {
            throw NSError(
                domain: "CartViewModel",
                code: -6,
                userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa"]
            )
        }
        let balance = try await walletRepository.fetchWalletBalance(jwt: jwt)
        let available = selectedCurrency.uppercased() == "USD" ? balance.usd : balance.local
        return (available >= requiredAmount, available)
    }
}

// MARK: - UI Model

struct CartItem: Identifiable, Hashable {
    let id: String
    let itemType: CartOrderItemType
    let productId: String
    let showcaseId: String?
    let showcaseRequestDescription: String?
    let comboGroupId: String?
    let comboId: String?
    let comboName: String?
    let comboComponentSlotId: String?
    let comboComponentSlotName: String?
    let comboComponentOrder: Int?
    let comboModifierNames: [String]
    let name: String
    let shop: String
    let weight: String
    let basePrice: Double
    let finalUnitPrice: Double
    let finalTotalPrice: Double
    var currency: String
    let convertedPrice: Double?
    let convertedCurrency: String?
    let exchangeRate: Int?
    let imageUrl: String
    var quantity: Int
    let branchId: String?
    let availability: Bool
    let selectedVariants: [SelectedVariantOption]

    var formattedPrice: String {
        "\(currencySymbol) \(String(format: "%.2f", finalUnitPrice))"
    }

    /// Precio unitario convertido a la moneda seleccionada
    func unitPrice(for selectedCurrency: String) -> Double {
        let selected = selectedCurrency.uppercased()
        let original = canonicalCurrencyForDisplay

        // Misma moneda o no soporta la seleccionada → precio original
        if selected == original || !supportsCurrency(selected) {
            return finalUnitPrice
        }

        if let convertedCurrency,
            convertedCurrency.uppercased() == selected,
            let convertedPrice
        {
            if basePrice > 0 {
                // Preserva ajustes de variantes aplicando el mismo factor sobre el precio convertido base.
                let variantFactor = finalUnitPrice / basePrice
                return convertedPrice * variantFactor
            }
            return convertedPrice
        }

        guard let rate = exchangeRate, rate > 0 else {
            return finalUnitPrice
        }

        if original == "USD" && selected == "CUP" {
            return finalUnitPrice * Double(rate)
        } else if original == "CUP" && selected == "USD" {
            return finalUnitPrice / Double(rate)
        }

        return finalUnitPrice
    }

    func formattedPrice(for selectedCurrency: String) -> String {
        "\(currencySymbol(for: selectedCurrency)) \(String(format: "%.2f", unitPrice(for: selectedCurrency)))"
    }

    var formattedBasePrice: String {
        String(format: "$%.2f", basePrice)
    }

    func baseUnitPrice(for selectedCurrency: String) -> Double {
        let selected = selectedCurrency.uppercased()
        let original = canonicalCurrencyForDisplay

        if selected == original || !supportsCurrency(selected) {
            return basePrice
        }

        guard let rate = exchangeRate, rate > 0 else {
            return basePrice
        }

        if original == "USD" && selected == "CUP" {
            return basePrice * Double(rate)
        } else if original == "CUP" && selected == "USD" {
            return basePrice / Double(rate)
        }

        return basePrice
    }

    var itemTotal: Double {
        finalTotalPrice
    }

    /// Total del item convertido a la moneda seleccionada
    func itemTotal(for selectedCurrency: String) -> Double {
        unitPrice(for: selectedCurrency) * Double(quantity)
    }

    var formattedItemTotal: String {
        "\(currencySymbol) \(String(format: "%.2f", itemTotal))"
    }

    func formattedItemTotal(for selectedCurrency: String) -> String {
        "\(currencySymbol(for: selectedCurrency)) \(String(format: "%.2f", itemTotal(for: selectedCurrency)))"
    }

    var isShowcase: Bool {
        itemType == .showcase
    }

    var isComboComponent: Bool {
        comboGroupId != nil
    }

    var supportsCUP: Bool {
        supportedCurrencyCodes.contains("CUP")
    }

    var supportsUSD: Bool {
        supportedCurrencyCodes.contains("USD")
    }

    var acceptsBothCurrencies: Bool {
        supportsCUP && supportsUSD
    }

    func supportsCurrency(_ code: String) -> Bool {
        supportedCurrencyCodes.contains(code.uppercased())
    }

    var currencyInfoText: String? {
        if acceptsBothCurrencies {
            return nil
        }
        if supportsUSD {
            return "Este producto solo se paga en USD"
        }
        if supportsCUP {
            return "Este producto solo se paga en CUP"
        }
        return "Moneda disponible: \(currency.uppercased())"
    }

    /// Info text que solo aparece cuando la moneda seleccionada no es soportada
    func currencyInfoText(for selectedCurrency: String) -> String? {
        let selected = selectedCurrency.uppercased()
        // Si soporta la moneda seleccionada, no mostrar nada
        if supportsCurrency(selected) { return nil }
        // No soporta la seleccionada → mostrar en qué moneda se cobra
        return "Solo disponible en \(currency.uppercased())"
    }

    private var currencySymbol: String {
        switch canonicalCurrencyForDisplay {
        case "USD":
            return "USD"
        case "CUP":
            return "CUP"
        default:
            return currency.uppercased()
        }
    }

    private func currencySymbol(for selectedCurrency: String) -> String {
        if supportsUSD && !supportsCUP { return "USD" }
        if supportsCUP && !supportsUSD { return "CUP" }
        // BOTH: usar la moneda seleccionada en el toolbar
        let code = selectedCurrency.uppercased()
        if code == "USD" || code == "CUP" { return code }
        return currency.uppercased()
    }

    private var canonicalCurrencyForDisplay: String {
        if supportsUSD && !supportsCUP {
            return "USD"
        }
        if supportsCUP && !supportsUSD {
            return "CUP"
        }
        return currency.uppercased()
    }

    private var supportedCurrencyCodes: Set<String> {
        // Si hay convertedPrice y convertedCurrency, el branch acepta ambas monedas
        if convertedPrice != nil && convertedCurrency != nil {
            return ["CUP", "USD"]
        }

        let uppercase = currency.uppercased()
        if uppercase.contains("BOTH") {
            return ["CUP", "USD"]
        }

        var codes = Set<String>()
        if uppercase.contains("CUP") {
            codes.insert("CUP")
        }
        if uppercase.contains("USD") {
            codes.insert("USD")
        }
        return codes
    }
}

enum CartOrderItemType: String, Codable, Hashable {
    case product = "PRODUCT"
    case combo = "COMBO"
    case showcase = "SHOWCASE"
}
