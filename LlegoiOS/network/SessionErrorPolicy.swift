import Foundation

enum SessionErrorPolicy {
    static func isCurrent(token: String, generation: UUID, currentToken: String?, currentGeneration: UUID) -> Bool {
        token == currentToken && generation == currentGeneration
    }

    static func invalidatesSession(status: Int, data: Data) -> Bool {
        if status == 401 { return true }
        guard (200..<300).contains(status),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let errors = json["errors"] as? [[String: Any]] else { return false }
        return errors.contains { error in
            if let code = (error["extensions"] as? [String: Any])?["code"] as? String {
                return code == "UNAUTHENTICATED"
            }
            // shortcut: solo el mensaje legacy exacto conocido, retirar cuando el backend emita códigos en todos los errores.
            return error["message"] as? String == "Usuario no autenticado"
        }
    }

    static func usesToken(_ token: String, request: URLRequest) -> Bool {
        guard !token.isEmpty else { return false }
        if let body = request.httpBody,
           let json = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any],
           let variables = json["variables"] as? [String: Any],
           let jwt = variables["jwt"] {
            return jwt as? String == token
        }
        guard let authorization = request.value(forHTTPHeaderField: "Authorization") else { return false }
        return authorization.split(separator: " ").last.map(String.init) == token
    }

    static func isBackend(_ request: URLRequest, baseURL: String) -> Bool {
        guard let url = request.url, let base = URL(string: baseURL),
              let host = url.host, let baseHost = base.host else { return false }
        return url.scheme == base.scheme && host == baseHost && url.port == base.port
    }
}
