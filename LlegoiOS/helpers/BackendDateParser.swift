import Foundation

/// Parsea el scalar `DateTime` del backend (`isoformat` de Python).
///
/// Puede venir con zona (`Z` u offset `±hh:mm`) o naive, sin zona: en ese caso el
/// backend guarda UTC, así que se interpreta como UTC. La fracción de segundo puede
/// tener 3 o 6 dígitos (milisegundos o microsegundos).
enum BackendDateParser {
    static func parse(_ raw: String?) -> Date? {
        guard let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty
        else { return nil }

        // Con zona horaria.
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) { return date }
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: value) { return date }

        // Naive (UTC): con 6, 3 o sin decimales.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        for format in [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss",
        ] {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }
}

extension Date {
    /// Fecha larga en español y hora de Cuba, p. ej. "1 de noviembre de 2026".
    var longDateInHavana: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_CU")
        formatter.timeZone = BranchHours.timeZone
        formatter.dateFormat = "d 'de' MMMM 'de' yyyy"
        return formatter.string(from: self)
    }
}
