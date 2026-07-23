import Foundation

/// Registro del Grupo A: proveedores de pago digital externos.
///
/// A diferencia del backend (donde stripe/qvapay/usdt están dormidos por
/// ahora, ver ENABLED_PAYMENT_METHOD_TYPES), acá quedan los 3 registrados
/// completos a propósito: el backend es el único interruptor. El día que se
/// habilite un método ahí, la app ya sabe presentarlo sin necesitar una
/// nueva versión — y agregar Tropipay más adelante es una clase nueva +
/// una línea acá, nada más.
@MainActor
enum DigitalPaymentProviderRegistry {
    static let providers: [String: DigitalPaymentProvider] = [
        "stripe": StripeDigitalProvider(),
        "qvapay": QvaPayDigitalProvider(),
        "usdt": TronDealerDigitalProvider(),
    ]
}
