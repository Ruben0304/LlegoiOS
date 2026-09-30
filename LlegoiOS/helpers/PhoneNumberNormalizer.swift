import Foundation

/// Normaliza teléfonos al formato internacional "+<dígitos>" (sin espacios ni guiones).
/// Si el número no trae código de país se asume Cuba (+53); si ya lo trae, se respeta.
///
/// La app de negocios arma `wa.me/<dígitos>` y `tel:<teléfono>` con el teléfono del cliente,
/// así que sin código de país WhatsApp abriría un número de otro país.
enum PhoneNumberNormalizer {
    enum ValidationError: LocalizedError, Equatable {
        case invalidCharacters
        case invalidCubanNumber
        case invalidInternationalNumber

        var errorDescription: String? {
            switch self {
            case .invalidCharacters:
                return "El teléfono solo puede tener números, espacios, guiones, paréntesis y + al inicio"
            case .invalidCubanNumber:
                return "Los números de Cuba tienen 8 dígitos (ej. 5XXX XXXX o +53 5XXX XXXX)"
            case .invalidInternationalNumber:
                return "Número no válido. Si no es de Cuba, escríbelo con + y el código de país"
            }
        }
    }

    static let cubaCountryCode = "53"
    private static let cubaNationalLength = 8
    private static let separators: Set<Character> = [" ", "-", "(", ")", "."]

    /// - Returns: `""` si la entrada está vacía (borrar el teléfono); si no, el número normalizado
    ///   (`"+53XXXXXXXX"` para Cuba o `"+<código><número>"` para otros países).
    static func normalize(_ input: String) -> Result<String, ValidationError> {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .success("") }

        var body = Substring(trimmed)
        var hasCountryCode = false
        if body.first == "+" {
            hasCountryCode = true
            body = body.dropFirst()
        }

        guard body.allSatisfy({ isASCIIDigit($0) || separators.contains($0) }) else {
            return .failure(.invalidCharacters)
        }
        var digits = String(body.filter(isASCIIDigit))

        // "00" es el prefijo internacional al marcar desde Cuba: "0053..." equivale a "+53..."
        if !hasCountryCode, digits.hasPrefix("00") {
            hasCountryCode = true
            digits.removeFirst(2)
        }

        if hasCountryCode {
            if digits.hasPrefix(cubaCountryCode) {
                guard digits.count == cubaCountryCode.count + cubaNationalLength else {
                    return .failure(.invalidCubanNumber)
                }
                return .success("+" + digits)
            }
            // E.164: el código de país nunca empieza por 0 y el total es de 8 a 15 dígitos
            guard digits.first != "0", (8...15).contains(digits.count) else {
                return .failure(.invalidInternationalNumber)
            }
            return .success("+" + digits)
        }

        // Sin código de país: número cubano
        if digits.count == cubaNationalLength + 1, digits.hasPrefix("0") {
            // Prefijo de larga distancia nacional (ej. "078XXXXXX")
            digits.removeFirst()
        }
        if digits.count == cubaNationalLength {
            return .success("+" + cubaCountryCode + digits)
        }
        if digits.count == cubaCountryCode.count + cubaNationalLength, digits.hasPrefix(cubaCountryCode) {
            return .success("+" + digits)
        }
        return .failure(digits.count < cubaNationalLength ? .invalidCubanNumber : .invalidInternationalNumber)
    }

    /// Variante tolerante para flujos donde el teléfono es opcional y no se muestra error (registro):
    /// si no se puede normalizar devuelve el texto recortado tal cual, para no bloquear al usuario.
    static func normalizedOrOriginal(_ input: String) -> String {
        switch normalize(input) {
        case .success(let phone):
            return phone
        case .failure:
            return input.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static func isASCIIDigit(_ character: Character) -> Bool {
        character.isASCII && character.isNumber
    }
}
