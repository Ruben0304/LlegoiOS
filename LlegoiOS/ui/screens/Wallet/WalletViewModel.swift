import Foundation
import SwiftUI
import Combine
import PassKit
import StripePaymentSheet

enum WalletCurrency: String, CaseIterable, Identifiable {
    case usd
    case cup

    var id: String { rawValue }

    var currencyCode: String {
        switch self {
        case .usd:
            return "USD"
        case .cup:
            return "CUP"
        }
    }

    var symbol: String {
        switch self {
        case .usd, .cup:
            return "$"
        }
    }
}

@MainActor
class WalletViewModel: NSObject, ObservableObject {
    static let shared = WalletViewModel()

    @Published var balance: Double = 0.0
    @Published var cupBalance: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var isLoadingTransactions: Bool = false
    @Published var showRechargeSheet: Bool = false
    @Published var showForeignRechargeSheet: Bool = false
    @Published var showRefundSheet: Bool = false
    @Published var rechargeAmount: String = ""
    @Published var foreignRechargeURL: String = ""
    @Published var isGeneratingForeignURL: Bool = false
    @Published var showSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    @Published var showTransferSheet: Bool = false
    @Published var transferUsername: String = ""
    @Published var transferAmount: String = ""
    @Published var searchResults: [SearchUserResult] = []
    @Published var isSearching: Bool = false
    @Published var selectedUser: SearchUserResult?
    @Published var transactions: [WalletTransaction] = []
    @Published var walletStatus: String = "active"
    @Published var currentUserId: String = ""

    // Stripe
    @Published var paymentSheet: PaymentSheet?
    @Published var showStripePaymentSheet: Bool = false

    private let repository = WalletRepository()
    private let profileRepository = ProfileRepository()
    private let authManager = AuthManager.shared
    private var searchTask: Task<Void, Never>?

    // MARK: - Apple Pay
    private let merchantID = "merchant.com.llego.ios"
    private let supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .amex, .discover]
    private var paymentCompletionHandler: ((Bool, String?) -> Void)?
    private var pendingRechargeAmount: Double = 0.0
    private var pendingRechargeCurrency: WalletCurrency = .usd

    private override init() {
        super.init()
    }

    // MARK: - Apple Pay Diagnostics
    func getApplePayDiagnostics() -> String {
        var diagnostics = "🔍 Diagnóstico de Apple Pay:\n\n"
        
        // 1. Verificar disponibilidad básica
        let canMakePayments = PKPaymentAuthorizationController.canMakePayments()
        diagnostics += "1. Dispositivo soporta Apple Pay: \(canMakePayments ? "✅ Sí" : "❌ No")\n"
        
        // 2. Verificar tarjetas configuradas
        let canMakePaymentsWithCards = PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks)
        diagnostics += "2. Tarjetas configuradas: \(canMakePaymentsWithCards ? "✅ Sí" : "❌ No")\n"
        
        // 3. Merchant ID
        diagnostics += "3. Merchant ID: \(merchantID)\n"
        
        // 4. Redes soportadas
        diagnostics += "4. Redes soportadas: \(supportedNetworks.map { $0.rawValue }.joined(separator: ", "))\n"
        
        // 5. Recomendaciones
        diagnostics += "\n💡 Recomendaciones:\n"
        if !canMakePayments {
            diagnostics += "- Este dispositivo no soporta Apple Pay\n"
        } else if !canMakePaymentsWithCards {
            diagnostics += "- Abre la app Wallet y agrega una tarjeta\n"
            diagnostics += "- Puedes usar tarjetas de prueba: 4111 1111 1111 1111\n"
        } else {
            diagnostics += "- Todo está configurado correctamente ✅\n"
        }
        
        return diagnostics
    }

    // MARK: - Load Balance Only (for Home)
    func loadBalance() {
        Task {
            guard let jwt = await authManager.getAccessToken() else {
                print("⚠️ No JWT token available")
                return
            }

            isLoading = true

            do {
                let walletBalance = try await repository.fetchWalletBalance(jwt: jwt)
                await MainActor.run {
                    self.balance = walletBalance.usd
                    self.cupBalance = walletBalance.local
                    self.walletStatus = walletBalance.status
                    self.isLoading = false
                }
            } catch {
                print("❌ Error loading wallet balance: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Load Full Wallet Details (for WalletView)
    func loadWalletDetails() {
        Task {
            guard let jwt = await authManager.getAccessToken() else {
                print("⚠️ No JWT token available")
                return
            }

            // Get current user ID
            if let userId = authManager.userId {
                self.currentUserId = userId
            }

            isLoadingTransactions = true

            do {
                let details = try await repository.fetchWalletDetails(jwt: jwt, limit: 50, skip: 0)
                await MainActor.run {
                    self.balance = details.balance.usd
                    self.cupBalance = details.balance.local
                    self.walletStatus = details.balance.status
                    self.transactions = details.transactions
                    self.isLoadingTransactions = false
                }
            } catch {
                print("❌ Error loading wallet details: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoadingTransactions = false
                }
            }
        }
    }

    func balance(for currency: WalletCurrency) -> Double {
        switch currency {
        case .usd:
            return balance
        case .cup:
            return cupBalance
        }
    }

    // MARK: - Manual Recharge (for testing)
    func processManualRecharge(for currency: WalletCurrency) {
        guard let amount = Double(rechargeAmount), amount > 0 else {
            return
        }

        Task {
            guard let jwt = await authManager.getAccessToken() else {
                print("⚠️ No JWT token available")
                return
            }

            isLoading = true

            do {
                let currencyCode = currency == .usd ? "usd" : "local"
                let _ = try await repository.depositMoney(
                    jwt: jwt,
                    amount: amount,
                    currency: currencyCode,
                    source: "manual_testing",
                    description: "Recarga manual de prueba"
                )

                // Reload wallet balance
                try await Task.sleep(nanoseconds: 500_000_000)
                let walletBalance = try await repository.fetchWalletBalance(jwt: jwt)

                await MainActor.run {
                    self.balance = walletBalance.usd
                    self.cupBalance = walletBalance.local
                    self.isLoading = false
                    self.showRechargeSheet = false
                    self.rechargeAmount = ""

                    let formattedAmount = String(format: "%.2f", amount)
                    self.successMessage = "¡Recarga manual exitosa! Se agregaron \(currency.symbol)\(formattedAmount) \(currency.currencyCode)"
                    self.showSuccessMessage = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showSuccessMessage = false
                    }
                }
            } catch {
                print("❌ Error en recarga manual: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                    self.successMessage = "Error: \(error.localizedDescription)"
                    self.showSuccessMessage = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showSuccessMessage = false
                    }
                }
            }
        }
    }

    // MARK: - Apple Pay Recharge
    func processApplePayRecharge(for currency: WalletCurrency) {
        guard let amount = Double(rechargeAmount), amount > 0 else {
            return
        }

        // Verificar disponibilidad básica
        guard PKPaymentAuthorizationController.canMakePayments() else {
            successMessage = "Apple Pay no está disponible en este dispositivo"
            showSuccessMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showSuccessMessage = false
            }
            return
        }

        // Verificar si hay tarjetas configuradas
        let canMakePaymentsWithCards = PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks)
        if !canMakePaymentsWithCards {
            successMessage = "Por favor, agrega una tarjeta a Apple Wallet primero"
            showSuccessMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showSuccessMessage = false
            }
            return
        }

        pendingRechargeAmount = amount
        pendingRechargeCurrency = currency

        let request = createPaymentRequest(amount: amount, currency: currency)
        
        // Validar el request antes de presentar
        guard request.paymentSummaryItems.count > 0 else {
            successMessage = "Error al crear la solicitud de pago"
            showSuccessMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showSuccessMessage = false
            }
            return
        }

        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self

        controller.present { presented in
            if !presented {
                print("❌ Apple Pay no se pudo presentar")
                print("Merchant ID: \(self.merchantID)")
                print("Currency: \(currency.currencyCode)")
                print("Amount: \(amount)")
                
                self.successMessage = "No se pudo presentar Apple Pay. Verifica tu configuración."
                self.showSuccessMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showSuccessMessage = false
                }
            } else {
                print("✅ Apple Pay presentado correctamente")
            }
        }
    }

    private func createPaymentRequest(amount: Double, currency: WalletCurrency) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantID
        request.merchantCapabilities = .capability3DS
        request.countryCode = "US"
        request.currencyCode = currency.currencyCode
        request.supportedNetworks = supportedNetworks

        let rechargeItem = PKPaymentSummaryItem(
            label: "Recarga Wallet \(currency.currencyCode)",
            amount: NSDecimalNumber(value: amount),
            type: .final
        )

        let total = PKPaymentSummaryItem(
            label: "Llego",
            amount: NSDecimalNumber(value: amount),
            type: .final
        )

        request.paymentSummaryItems = [rechargeItem, total]
        
        // Opcional pero recomendado
        request.requiredBillingContactFields = [.emailAddress, .name]
        
        print("📱 Payment Request creado:")
        print("  - Merchant ID: \(merchantID)")
        print("  - Currency: \(currency.currencyCode)")
        print("  - Amount: \(amount)")
        print("  - Items: \(request.paymentSummaryItems.count)")

        return request
    }

    // MARK: - Stripe Recharge
    func processStripeRecharge(for currency: WalletCurrency) {
        guard let amount = Double(rechargeAmount), amount > 0 else {
            return
        }

        isLoading = true
        
        Task {
            do {
                // 1. Crear Payment Intent en el backend
                let paymentIntentClientSecret = try await createPaymentIntent(
                    amount: amount,
                    currency: currency
                )
                
                // 2. Configurar Stripe Payment Sheet
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Llego"
                configuration.allowsDelayedPaymentMethods = true
                
                // Configurar Apple Pay si está disponible
                if PKPaymentAuthorizationController.canMakePayments() {
                    configuration.applePay = .init(
                        merchantId: "merchant.com.llego.ios",
                        merchantCountryCode: "US"
                    )
                }
                
                // 3. Crear el Payment Sheet y cerrar el sheet de recarga
                await MainActor.run {
                    self.paymentSheet = PaymentSheet(
                        paymentIntentClientSecret: paymentIntentClientSecret,
                        configuration: configuration
                    )
                    self.isLoading = false
                    
                    // Cerrar el sheet de recarga primero
                    self.showRechargeSheet = false
                    
                    // Mostrar el Payment Sheet después de un delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showStripePaymentSheet = true
                    }
                }
                
            } catch {
                print("❌ Error creando Payment Intent: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                    self.successMessage = "Error: \(error.localizedDescription)"
                    self.showSuccessMessage = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showSuccessMessage = false
                    }
                }
            }
        }
    }
    
    // MARK: - Create Payment Intent
    private func createPaymentIntent(amount: Double, currency: WalletCurrency) async throws -> String {
        // Validar que no se intente usar Stripe con CUP
        guard currency == .usd else {
            throw NSError(
                domain: "WalletViewModel",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Stripe solo soporta pagos en USD. Para CUP usa transferencia bancaria."]
            )
        }
        
        guard let jwt = await authManager.getAccessToken() else {
            throw NSError(domain: "WalletViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "No JWT token"])
        }
        
        // Convertir a centavos (Stripe usa centavos)
        let amountInCents = Int(amount * 100)
        let currencyCode = "usd" // Siempre USD para Stripe
        
        // URL de tu backend
        let url = URL(string: "https://llegobackend-production.up.railway.app/stripe/create-payment-intent")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "amount": amountInCents,
            "currency": currencyCode,
            "description": "Recarga Wallet \(currency.currencyCode)"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "WalletViewModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "Error del servidor"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // El backend puede devolver client_secret (snake_case) o clientSecret (camelCase)
        let clientSecret = (json?["clientSecret"] as? String) ?? (json?["client_secret"] as? String)
        
        guard let clientSecret = clientSecret else {
            // Debug: imprimir la respuesta completa para ver qué está devolviendo el backend
            if let jsonData = try? JSONSerialization.data(withJSONObject: json ?? [:], options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("❌ Respuesta del backend: \(jsonString)")
            }
            throw NSError(domain: "WalletViewModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "No se recibió client secret"])
        }
        
        return clientSecret
    }
    
    // MARK: - Handle Stripe Payment Result
    func handleStripePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            print("✅ Pago completado con Stripe")
            
            Task {
                guard let jwt = await authManager.getAccessToken() else { return }
                
                do {
                    // Registrar la recarga en el backend
                    let amount = Double(rechargeAmount) ?? 0
                    let currencyCode = pendingRechargeCurrency == .usd ? "usd" : "local"
                    
                    let _ = try await repository.depositMoney(
                        jwt: jwt,
                        amount: amount,
                        currency: currencyCode,
                        source: "stripe",
                        description: "Recarga via Stripe"
                    )
                    
                    // Recargar balance
                    try await Task.sleep(nanoseconds: 500_000_000)
                    let walletBalance = try await repository.fetchWalletBalance(jwt: jwt)
                    
                    await MainActor.run {
                        self.balance = walletBalance.usd
                        self.cupBalance = walletBalance.local
                        self.showRechargeSheet = false
                        self.rechargeAmount = ""
                        
                        let formattedAmount = String(format: "%.2f", amount)
                        self.successMessage = "¡Recarga exitosa! \(pendingRechargeCurrency.symbol)\(formattedAmount) \(pendingRechargeCurrency.currencyCode)"
                        self.showSuccessMessage = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.showSuccessMessage = false
                        }
                    }
                } catch {
                    print("❌ Error registrando recarga: \(error.localizedDescription)")
                    await MainActor.run {
                        self.successMessage = "Pago exitoso pero error al actualizar balance"
                        self.showSuccessMessage = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.showSuccessMessage = false
                        }
                    }
                }
            }
            
        case .canceled:
            print("⚠️ Pago cancelado por el usuario")
            successMessage = "Pago cancelado"
            showSuccessMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showSuccessMessage = false
            }
            
        case .failed(let error):
            print("❌ Error en el pago: \(error.localizedDescription)")
            successMessage = "Error: \(error.localizedDescription)"
            showSuccessMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showSuccessMessage = false
            }
        }
    }

    // MARK: - Transfer Money
    func performTransfer(for currency: WalletCurrency) {
        let trimmedUsername = transferUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedAmount = sanitizeAmount(transferAmount)
        guard
            !trimmedUsername.isEmpty,
            let amountValue = Double(sanitizedAmount),
            amountValue > 0
        else {
            return
        }

        Task {
            guard let jwt = await authManager.getAccessToken() else {
                print("⚠️ No JWT token available")
                return
            }

            isLoading = true

            do {
                let currencyCode = currency == .usd ? "usd" : "local"
                
                // Determinar si es username, email o ID
                let isEmail = trimmedUsername.contains("@")
                let toOwnerUsername = isEmail ? nil : trimmedUsername
                let toOwnerEmail = isEmail ? trimmedUsername : nil
                
                let _ = try await repository.transferMoney(
                    jwt: jwt,
                    toOwnerUsername: toOwnerUsername,
                    toOwnerEmail: toOwnerEmail,
                    toOwnerId: nil,
                    toOwnerType: "user",
                    amount: amountValue,
                    currency: currencyCode,
                    description: "Transferencia entre usuarios"
                )

                // Reload wallet balance
                try await Task.sleep(nanoseconds: 500_000_000)
                let walletBalance = try await repository.fetchWalletBalance(jwt: jwt)

                await MainActor.run {
                    self.balance = walletBalance.usd
                    self.cupBalance = walletBalance.local
                    self.isLoading = false
                    self.showTransferSheet = false
                    self.transferUsername = ""
                    self.transferAmount = ""
                    self.searchResults = []
                    self.selectedUser = nil

                    let formattedAmount = String(format: "%.2f", amountValue)
                    self.successMessage = "Transferencia exitosa: \(currency.symbol)\(formattedAmount) \(currency.currencyCode) a \(trimmedUsername)"
                    self.showSuccessMessage = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showSuccessMessage = false
                    }
                }
            } catch {
                print("❌ Error en transferencia: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                    self.successMessage = "Error: \(error.localizedDescription)"
                    self.showSuccessMessage = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showSuccessMessage = false
                    }
                }
            }
        }
    }
    
    // MARK: - Search Users
    func searchUsers(query: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clear results if query is too short
        guard trimmedQuery.count >= 2 else {
            searchResults = []
            return
        }
        
        // Debounce search
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
            
            guard !Task.isCancelled else { return }
            
            await performSearch(query: trimmedQuery)
        }
    }
    
    private func performSearch(query: String) async {
        guard let jwt = await authManager.getAccessToken() else {
            print("⚠️ No JWT token available")
            return
        }
        
        isSearching = true
        
        do {
            let results = try await profileRepository.searchUsers(jwt: jwt, query: query)
            
            await MainActor.run {
                // Limit to 3 results
                self.searchResults = Array(results.prefix(3))
                self.isSearching = false
            }
        } catch {
            print("❌ Error searching users: \(error.localizedDescription)")
            await MainActor.run {
                self.searchResults = []
                self.isSearching = false
            }
        }
    }
    
    func selectUser(_ user: SearchUserResult) {
        selectedUser = user
        transferUsername = user.username
        searchResults = []
    }

    // MARK: - Helpers
    func prepareCupTransfer(amountText: String) {
        rechargeAmount = sanitizeAmount(amountText)
    }

    var cupTransferAmountDisplay: String {
        let sanitized = sanitizeAmount(rechargeAmount)
        return sanitized
    }

    func completeCupTransferRecharge(amountString: String) {
        let sanitizedAmount = sanitizeAmount(amountString)
        guard let amount = Double(sanitizedAmount), amount > 0 else {
            return
        }

        Task {
            guard let jwt = await authManager.getAccessToken() else {
                print("⚠️ No JWT token available")
                return
            }

            do {
                let _ = try await repository.depositMoney(
                    jwt: jwt,
                    amount: amount,
                    currency: "local",
                    source: "bank_transfer",
                    description: "Transferencia bancaria CUP"
                )

                // Reload wallet balance
                try await Task.sleep(nanoseconds: 500_000_000)
                let walletBalance = try await repository.fetchWalletBalance(jwt: jwt)

                await MainActor.run {
                    self.cupBalance = walletBalance.local
                    self.rechargeAmount = ""

                    let formattedAmount = String(format: "%.2f", amount)
                    self.successMessage = "¡Transferencia CUP exitosa! Se agregaron $\(formattedAmount) CUP"
                    self.showSuccessMessage = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showSuccessMessage = false
                    }
                }
            } catch {
                print("❌ Error en transferencia CUP: \(error.localizedDescription)")
                await MainActor.run {
                    self.successMessage = "Error: \(error.localizedDescription)"
                    self.showSuccessMessage = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showSuccessMessage = false
                    }
                }
            }
        }
    }

    private func sanitizeAmount(_ text: String) -> String {
        let allowed = CharacterSet(charactersIn: "0123456789.,")
        let filteredScalars = text.unicodeScalars.filter { allowed.contains($0) }
        var sanitized = String(String.UnicodeScalarView(filteredScalars))
        sanitized = sanitized.replacingOccurrences(of: ",", with: ".")
        return sanitized
    }

    func generateForeignRechargeURL() {
        Task {
            guard let jwt = await authManager.getAccessToken() else {
                print("⚠️ No JWT token available")
                successMessage = "Error: No hay sesión activa"
                showSuccessMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showSuccessMessage = false
                }
                return
            }
            
            isGeneratingForeignURL = true
            
            do {
                // Llamar al backend para generar el link de Stripe
                let url = URL(string: "https://llegobackend-production.up.railway.app/stripe/create-recharge-link")!
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
                
                let body: [String: Any] = [
                    "currency": "usd",
                    "description": "Recarga internacional para Llego Wallet"
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw NSError(domain: "WalletViewModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "Error del servidor"])
                }
                
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let paymentLink = json?["payment_link"] as? String else {
                    throw NSError(domain: "WalletViewModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "No se recibió el link de pago"])
                }
                
                await MainActor.run {
                    self.foreignRechargeURL = paymentLink
                    self.isGeneratingForeignURL = false
                    self.showForeignRechargeSheet = true
                    print("✅ Link de recarga generado: \(paymentLink)")
                }
                
            } catch {
                print("❌ Error generando link de recarga: \(error.localizedDescription)")
                await MainActor.run {
                    self.isGeneratingForeignURL = false
                    self.successMessage = "Error al generar el link: \(error.localizedDescription)"
                    self.showSuccessMessage = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showSuccessMessage = false
                    }
                }
            }
        }
    }

    func copyURLToClipboard() {
        UIPasteboard.general.string = foreignRechargeURL
    }

    func presentTransferSheet() {
        transferUsername = ""
        transferAmount = ""
        searchResults = []
        selectedUser = nil
        showTransferSheet = true
    }

    func sanitizeTransferAmount() {
        let sanitized = sanitizeAmount(transferAmount)
        if sanitized != transferAmount {
            transferAmount = sanitized
        }
    }

    var isTransferFormValid: Bool {
        let trimmedUsername = transferUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let amountValue = Double(sanitizeAmount(transferAmount)) ?? 0
        return !trimmedUsername.isEmpty && amountValue > 0
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate
extension WalletViewModel: PKPaymentAuthorizationControllerDelegate {

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        print("✅ Payment authorized")
        print("📦 Payment token: \(payment.token)")
        print("📧 Billing contact: \(payment.billingContact?.emailAddress ?? "N/A")")

        Task {
            guard let jwt = await authManager.getAccessToken() else {
                print("❌ No JWT token available")
                await MainActor.run {
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                }
                return
            }

            do {
                let currencyCode = self.pendingRechargeCurrency == .usd ? "usd" : "local"
                print("💰 Procesando recarga: \(self.pendingRechargeAmount) \(currencyCode)")
                
                let _ = try await self.repository.depositMoney(
                    jwt: jwt,
                    amount: self.pendingRechargeAmount,
                    currency: currencyCode,
                    source: "apple_pay",
                    description: "Recarga via Apple Pay"
                )

                print("✅ Recarga procesada exitosamente")

                // Reload wallet balance
                try await Task.sleep(nanoseconds: 500_000_000)
                let walletBalance = try await self.repository.fetchWalletBalance(jwt: jwt)

                await MainActor.run {
                    self.balance = walletBalance.usd
                    self.cupBalance = walletBalance.local
                    self.showRechargeSheet = false
                    self.rechargeAmount = ""

                    let formattedAmount = String(format: "%.2f", self.pendingRechargeAmount)
                    self.successMessage = "¡Recarga Apple Pay exitosa! \(self.pendingRechargeCurrency.symbol)\(formattedAmount) \(self.pendingRechargeCurrency.currencyCode)"
                    self.showSuccessMessage = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showSuccessMessage = false
                    }

                    completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                }
            } catch {
                print("❌ Error procesando Apple Pay: \(error.localizedDescription)")
                await MainActor.run {
                    self.successMessage = "Error: \(error.localizedDescription)"
                    self.showSuccessMessage = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showSuccessMessage = false
                    }

                    completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                }
            }
        }
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        print("🏁 Apple Pay controller dismissed")
        controller.dismiss {
            print("✅ Dismiss completed")
        }
    }
}
