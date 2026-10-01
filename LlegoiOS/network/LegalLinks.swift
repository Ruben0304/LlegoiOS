import Foundation

/// URLs públicas de los textos legales.
///
/// La web es la fuente única de la política de privacidad y los términos.
/// `llego.app` todavía no resuelve (los universal links son fase 2), así que
/// se enlaza al dominio real de la web. Para cambiar de dominio basta con
/// tocar `baseURL`.
enum LegalLinks {
    static let baseURL = "https://llegoweb-production.up.railway.app"
    static let termsURL = "\(baseURL)/terminos"
    static let privacyURL = "\(baseURL)/privacidad"
}
