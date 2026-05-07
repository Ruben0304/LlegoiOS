import Foundation

/// Configuración de Stripe con las API Keys
struct StripeConfig {
    /// Publishable Key de Stripe (visible en el cliente)
    /// Obtenida desde el archivo Secrets.swift (no commitado a Git)
    static let publishableKey = StripeSecrets.publishableKey

    /// ⚠️ Secret Key NO debe estar en el cliente
    /// La Secret Key debe estar SOLO en el backend
    /// El backend debe crear los Payment Intents y devolver el client_secret
    ///
    /// Para testing local, puedes descomentar la siguiente línea:
    /// static let secretKey = StripeSecrets.secretKey

    /// URL del backend que crea el PaymentIntent
    /// NOTA: Este endpoint debe crearse en el backend de Railway
    static let paymentIntentURL = "https://llegobackend-production.up.railway.app/create-payment-intent"

    /// URL scheme personalizada para retorno después de autenticación
    static let returnURL = "llegoi-os://stripe-redirect"

    /// Modo de desarrollo: usa datos mock sin llamar al backend
    /// ⚠️ ACTIVAR SOLO PARA TESTING. Desactivar cuando el backend esté listo.
    static let useMockData = false

    // MARK: - Apple Pay Configuration

    /// Apple Pay Merchant ID
    /// IMPORTANTE: Debes crear este Merchant ID en:
    /// https://developer.apple.com/account/resources/identifiers/list/merchant
    /// Formato: merchant.com.tu-empresa.tu-app
    static let applePayMerchantId = "merchant.com.llego.ios"

    /// País del comerciante (código de 2 letras ISO)
    static let merchantCountryCode = "US"

    /// Nombre que aparecerá en Apple Pay
    static let merchantDisplayName = "Llego"

    // MARK: - Payment Methods Configuration

    /// Habilitar Apple Pay
    static let enableApplePay = true

    /// Habilitar pagos a plazos (Affirm, Afterpay, Klarna, etc.)
    /// NOTA: Estos métodos se mostrarán automáticamente si:
    /// 1. Están habilitados en tu Stripe Dashboard
    /// 2. El monto y país son elegibles
    /// 3. automatic_payment_methods está habilitado
    static let enableInstallments = true
}
