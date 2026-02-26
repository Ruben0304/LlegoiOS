import Foundation
import SwiftUI
import Combine
import CoreLocation

enum CartViewState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class CartViewModel: ObservableObject {
    @Published var state: CartViewState = .idle
    @Published var cartItems: [CartItem] = []
    @Published var errorMessage: String?
    @Published var hasWatchedAds: Bool = false // Descuento por ver anuncios
    @Published var isCreatingOrder: Bool = false
    @Published var createdOrder: CreatedOrder?
    @Published var orderError: String?

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

    // Store branchId from cart products
    private var cartBranchId: String?
    private var cartProducts: [CartProductGraphQL] = []

    // MARK: - AI Suggestions
    @Published var suggestedProducts: [Product] = []
    @Published var isLoadingSuggestions: Bool = false
    @Published var suggestionsError: String?
    private let recommendationEngine = RecommendationEngine.shared
    private let aiPreferenceManager = AIPreferenceManager.shared

    // MARK: - Multi-branch detection
    var uniqueBranchIds: Set<String> {
        Set(cartProducts.map { $0.branchId })
    }

    var hasMultipleBranches: Bool {
        uniqueBranchIds.count > 1
    }

    // MARK: - Service Fee Constants
    private let standardServiceFeeRate: Double = 0.15 // 15%
    private let discountedServiceFeeRate: Double = 0.10 // 10% con descuento

    // MARK: - Computed Properties

    var totalItems: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Double {
        cartItems.reduce(0.0) { $0 + ($1.price * Double($1.quantity)) }
    }

    var deliveryFee: Double {
        if cartItems.isEmpty { return 0.0 }
        return deliveryFeeEstimate?.deliveryFee ?? 0.0
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

    /// Tasa de servicio actual (15% normal, 10% con descuento)
    var currentServiceFeeRate: Double {
        hasWatchedAds ? discountedServiceFeeRate : standardServiceFeeRate
    }

    /// Porcentaje de servicio formateado
    var serviceFeePercentage: Int {
        Int(currentServiceFeeRate * 100)
    }

    /// Cargo de servicio calculado sobre el subtotal
    var serviceFee: Double {
        subtotal * currentServiceFeeRate
    }

    /// Ahorro por ver anuncios
    var adSavings: Double {
        hasWatchedAds ? subtotal * (standardServiceFeeRate - discountedServiceFeeRate) : 0
    }

    var total: Double {
        subtotal + deliveryFee + serviceFee
    }

    var formattedSubtotal: String {
        formatPrice(subtotal)
    }

    var formattedDeliveryFee: String {
        if isLoadingDeliveryFee {
            return "Calculando..."
        }
        if deliveryFeeError != nil && deliveryFeeEstimate == nil {
            return "--"
        }
        if let estimate = deliveryFeeEstimate {
            return formatPriceWithCurrency(estimate.deliveryFee, currency: estimate.currency)
        }
        return formatPriceWithCurrency(deliveryFee, currency: "CUP")
    }

    /// Descripción del envío (distancia + zona)
    var deliveryFeeDescription: String {
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
        formatPrice(serviceFee)
    }

    var formattedAdSavings: String {
        formatPrice(adSavings)
    }

    var formattedTotal: String {
        formatPrice(total)
    }

    /// Total si viera los anuncios (para mostrar incentivo)
    var totalWithDiscount: Double {
        subtotal + deliveryFee + (subtotal * discountedServiceFeeRate)
    }

    var formattedTotalWithDiscount: String {
        formatPrice(totalWithDiscount)
    }

    /// Ahorro potencial si ve los anuncios
    var potentialSavings: Double {
        subtotal * (standardServiceFeeRate - discountedServiceFeeRate)
    }

    var formattedPotentialSavings: String {
        formatPrice(potentialSavings)
    }

    /// Activar descuento por ver anuncios
    func activateAdDiscount() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            hasWatchedAds = true
        }
    }

    // MARK: - Actions

    /// Cargar productos del carrito (desde local + GraphQL)
    func loadCart() {
        state = .loading
        errorMessage = nil

        repository.fetchCartProducts { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let cartProducts):
                    // Store cart products for order creation
                    self.cartProducts = cartProducts

                    // Get branchId from first product (assuming all products are from same branch)
                    self.cartBranchId = cartProducts.first?.branchId

                    // Mapear a UI models
                    self.cartItems = cartProducts.map { product in
                        CartItem(
                            id: product.id,
                            name: product.name,
                            shop: product.businessName,
                            weight: product.weight,
                            price: product.price,
                            imageUrl: product.image,
                            quantity: product.quantity,
                            availability: product.availability
                        )
                    }

                    print("✅ Loaded \(self.cartItems.count) items in cart")
                    if let branchId = self.cartBranchId {
                        print("📍 Branch ID: \(branchId)")
                        // Estimar envío usando el branchId del primer producto
                        self.fetchDeliveryFeeEstimate(branchId: branchId)
                    }

                    // Check for default saved address
                    if let user = self.authManager.currentUser, let defaultId = user.defaultAddressId, let addresses = user.savedAddresses {
                        if let defaultAddr = addresses.first(where: { $0.id == defaultId }) {
                            self.defaultAddress = defaultAddr
                            self.selectedAddress = defaultAddr
                        }
                    }

                    self.state = .success

                    // Load payment methods after cart is loaded
                    self.loadPaymentMethods()

                    // Load AI suggestions if Apple Intelligence is available
                    self.loadAISuggestions()

                case .failure(let error):
                    self.errorMessage = "Error al cargar el carrito: \(error.localizedDescription)"
                    self.state = .error(self.errorMessage!)
                    print("❌ Error loading cart: \(error)")
                }
            }
        }
    }

    // MARK: - AI Suggestions

    /// Obtener sugerencias de productos usando la estrategia seleccionada por el usuario
    func loadAISuggestions() {
        // Verificar que hay productos en el carrito
        guard !cartProducts.isEmpty else {
            print("⚠️ No hay productos en el carrito para sugerencias")
            return
        }

        isLoadingSuggestions = true
        suggestionsError = nil

        let selectedEngine = aiPreferenceManager.selectedEngine
        print("🎯 [CartViewModel] Engine seleccionado: \(selectedEngine.displayName)")

        switch selectedEngine {
        case .appleIntelligence:
            loadSuggestionsFromAppleIntelligence()
        case .llegoCloud:
            loadSuggestionsFromLlegoCloud()
        }
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

        let productIds = cartProducts.map { $0.id }
        let productNames = cartProducts.map { $0.name }

        print("🌐 [CartViewModel] ========================================")
        print("🌐 [CartViewModel] Obteniendo recomendaciones desde Llego Cloud")
        print("🌐 [CartViewModel] Cantidad de productos: \(productIds.count)")
        print("🌐 [CartViewModel] Product IDs: \(productIds)")
        print("🌐 [CartViewModel] Product Names: \(productNames)")

        // Detectar si hay múltiples branches
        if hasMultipleBranches {
            print("⚠️ [CartViewModel] ADVERTENCIA: Carrito con múltiples branches: \(uniqueBranchIds)")
            print("⚠️ [CartViewModel] Esto puede afectar las recomendaciones")
        } else if let branchId = cartBranchId {
            print("✅ [CartViewModel] Branch único: \(branchId)")
        }

        print("🌐 [CartViewModel] ========================================")

        repository.fetchCloudRecommendations(productIds: productIds, limit: 6) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let recommendations):
                    print("🌐 [CartViewModel] Backend retornó \(recommendations.count) recomendaciones")

                    // Filtrar productos que ya están en el carrito
                    let cartProductIds = Set(self.cartProducts.map { $0.id })
                    self.suggestedProducts = recommendations.filter { !cartProductIds.contains($0.id) }

                    self.isLoadingSuggestions = false

                    if self.suggestedProducts.isEmpty {
                        print("⚠️ [CartViewModel] No hay recomendaciones después de filtrar")
                        self.suggestionsError = "No hay recomendaciones disponibles para estos productos"
                    } else {
                        print("✅ [CartViewModel] Loaded \(self.suggestedProducts.count) cloud recommendations")
                    }

                case .failure(let error):
                    self.isLoadingSuggestions = false
                    self.suggestionsError = "No se pudieron cargar recomendaciones de la nube"
                    print("❌ [CartViewModel] Error loading cloud recommendations: \(error.localizedDescription)")
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
            let cartProductIds = Set(cartProducts.map { $0.id })
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
                let methods = try await paymentMethodManager.fetchPaymentMethods(branchId: cartBranchId)
                await MainActor.run {
                    self.paymentMethods = methods
                        .filter { $0.isActive }
                        .sorted { $0.displayOrder < $1.displayOrder }
                    self.isLoadingPaymentMethods = false
                    print("✅ Loaded \(self.paymentMethods.count) payment methods for branch \(self.cartBranchId ?? "all")")
                }
            } catch {
                await MainActor.run {
                    self.isLoadingPaymentMethods = false
                    print("❌ Error loading payment methods: \(error.localizedDescription)")
                }
            }
        }
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
        comments: String? = nil,
        completion: @escaping @Sendable (Result<(CreatedOrder, InitiatePaymentResultModel), Error>) -> Void
    ) {
        guard let branchId = cartBranchId else {
            let error = NSError(domain: "CartViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo determinar la tienda"])
            completion(.failure(error))
            return
        }

        guard !cartItems.isEmpty else {
            let error = NSError(domain: "CartViewModel", code: -2, userInfo: [NSLocalizedDescriptionKey: "El carrito está vacío"])
            completion(.failure(error))
            return
        }

        // Get user location for delivery address
        let locationManager = UserLocationManager.shared
        guard let userLocation = locationManager.userLocation else {
            let error = NSError(domain: "CartViewModel", code: -3, userInfo: [NSLocalizedDescriptionKey: "Por favor selecciona una ubicación de entrega"])
            completion(.failure(error))
            return
        }

        isCreatingOrder = true
        orderError = nil

        // Build items array
        let items = cartItems.map { item in
            (productId: item.id, quantity: item.quantity)
        }

        // Build delivery address
        let deliveryAddress: DeliveryAddressInput
        if let selected = selectedAddress {
            deliveryAddress = DeliveryAddressInput(
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
        } else {
            deliveryAddress = DeliveryAddressInput(
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

        print("🛒 Creating order with new payment flow...")
        print("   Branch: \(branchId)")
        print("   Items: \(items.count)")
        print("   Payment Method: \(paymentMethodId)")
        print("   Address: \(locationManager.userAddress)")

        // Step 1: Create Order (without payment)
        createOrderRepository.createOrder(
            branchId: branchId,
            items: items,
            deliveryAddress: deliveryAddress,
            paymentMethod: "pending", // Temporary, will be updated by payment
            paymentIntentId: nil,
            comments: comments
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
        sendsSmsNotification: Bool = false
    ) async throws -> InitiatePaymentResultModel {
        guard let jwt = await authManager.getAccessToken() else {
            throw NSError(domain: "CartViewModel", code: -4, userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa"])
        }

        await MainActor.run {
            self.isInitiatingPayment = true
        }

        do {
            let result = try await paymentRepository.initiatePayment(
                orderId: orderId,
                paymentMethodId: paymentMethodId,
                jwt: jwt,
                includeDeliveryFee: true,
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
                let error = NSError(domain: "CartViewModel", code: -5, userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa"])
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
                    if status == "confirmed" || status == "completed" || status == "customer_confirmed" {
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
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 segundos
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
                let error = NSError(domain: "CartViewModel", code: -5, userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa"])
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
            let error = NSError(domain: "CartViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo determinar la tienda"])
            completion(.failure(error))
            return
        }

        guard !cartItems.isEmpty else {
            let error = NSError(domain: "CartViewModel", code: -2, userInfo: [NSLocalizedDescriptionKey: "El carrito está vacío"])
            completion(.failure(error))
            return
        }

        // Get user location for delivery address
        let locationManager = UserLocationManager.shared
        guard let userLocation = locationManager.userLocation else {
            let error = NSError(domain: "CartViewModel", code: -3, userInfo: [NSLocalizedDescriptionKey: "Por favor selecciona una ubicación de entrega"])
            completion(.failure(error))
            return
        }

        isCreatingOrder = true
        orderError = nil

        // Build items array
        let items = cartItems.map { item in
            (productId: item.id, quantity: item.quantity)
        }

        // Build delivery address
        let deliveryAddress: DeliveryAddressInput
        if let selected = selectedAddress {
            deliveryAddress = DeliveryAddressInput(
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
        } else {
            deliveryAddress = DeliveryAddressInput(
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

        print("🛒 Creating order...")
        print("   Branch: \(branchId)")
        print("   Items: \(items.count)")
        print("   Payment: \(paymentMethod)")
        print("   Address: \(locationManager.userAddress)")

        createOrderRepository.createOrder(
            branchId: branchId,
            items: items,
            deliveryAddress: deliveryAddress,
            paymentMethod: paymentMethod,
            paymentIntentId: paymentIntentId,
            comments: comments
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
    func incrementQuantity(productId: String) {
        if let item = cartItems.first(where: { $0.id == productId }) {
            cartManager.updateQuantity(productId: productId, quantity: item.quantity + 1)
            loadCart()
        }
    }

    /// Decrementar cantidad de un producto
    func decrementQuantity(productId: String) {
        if let item = cartItems.first(where: { $0.id == productId }) {
            let newQuantity = item.quantity - 1
            if newQuantity <= 0 {
                removeFromCart(productId: productId)
            } else {
                cartManager.updateQuantity(productId: productId, quantity: newQuantity)
                loadCart()
            }
        }
    }

    /// Remover producto del carrito
    func removeFromCart(productId: String) {
        cartManager.removeFromCart(productId: productId)
        loadCart()
    }

    /// Limpiar todo el carrito
    func clearCart() {
        cartManager.clearCart()
        cartItems = []
        state = .success
    }

    // MARK: - Helpers

    private func formatPrice(_ price: Double) -> String {
        return String(format: "$%.2f", price)
    }

    private func formatPriceWithCurrency(_ price: Double, currency: String) -> String {
        return String(format: "%.2f %@", price, currency)
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
    let name: String
    let shop: String
    let weight: String
    let price: Double
    let imageUrl: String
    var quantity: Int
    let availability: Bool

    var formattedPrice: String {
        String(format: "$%.2f", price)
    }

    var itemTotal: Double {
        price * Double(quantity)
    }

    var formattedItemTotal: String {
        String(format: "$%.2f", itemTotal)
    }
}
