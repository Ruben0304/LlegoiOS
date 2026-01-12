import Foundation
import SwiftUI
import Combine
// MARK: - User Model
struct User: Codable, Sendable {
    let id: String
    let email: String
    let fullName: String
    let phone: String?
    let role: String
    let appleUserId: String?

    enum CodingKeys: String, CodingKey {
        case id, email, fullName, phone, role, appleUserId
    }
}

// MARK: - Auth Session
struct AuthSession: Codable, Sendable {
    let user: User
    let accessToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case user, accessToken, tokenType
    }
}

// MARK: - Persisted Auth Session (no token)
struct PersistedAuthSession: Codable, Sendable {
    let user: User
    let tokenType: String?
}

// MARK: - AuthManager
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: User?
    @Published var accessToken: String?
    @Published var tokenType: String?
    @Published var userId: String?
    @Published var isAuthenticated: Bool = false

    private let sessionKey = "llego_auth_session"
    private let tokenKey = "llego_auth_token"
    private let userIdKey = "llego_auth_user_id"
    private let keychainService = Bundle.main.bundleIdentifier ?? "com.llego.auth"

    private init() {
        loadSession()
    }

    // MARK: - Public Methods

    /// Guardar sesión de autenticación
    func saveSession(_ session: AuthSession) {
        do {
            let encoder = JSONEncoder()
            let persisted = PersistedAuthSession(user: session.user, tokenType: session.tokenType)
            let data = try encoder.encode(persisted)
            UserDefaults.standard.set(data, forKey: sessionKey)
            UserDefaults.standard.set(session.user.id, forKey: userIdKey)
            let normalizedToken = normalizeAccessToken(session.accessToken, tokenType: session.tokenType)
            KeychainHelper.save(
                normalizedToken,
                service: keychainService,
                account: tokenKey
            )

            currentUser = session.user
            accessToken = normalizedToken
            tokenType = session.tokenType
            userId = session.user.id
            isAuthenticated = true

            print("✅ Sesión guardada: \(session.user.email)")
        } catch {
            print("❌ Error guardando sesión: \(error.localizedDescription)")
        }
    }

    /// Cerrar sesión
    func signOut() {
        currentUser = nil
        accessToken = nil
        tokenType = nil
        userId = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: sessionKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        KeychainHelper.delete(service: keychainService, account: tokenKey)
        print("✅ Sesión cerrada exitosamente")
    }

    /// Obtener token de autorización
    func getAuthorizationHeader() -> String? {
        guard let token = getAccessToken() else { return nil }
        let prefix = tokenType?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedPrefix = (prefix?.isEmpty == false) ? prefix! : "Bearer"
        return "\(resolvedPrefix) \(token)"
    }

    func getAccessToken() -> String? {
        if let token = accessToken {
            let normalized = normalizeAccessToken(token, tokenType: tokenType)
            // Solo actualizar si el valor cambió para evitar "Publishing changes from within view updates"
            if normalized != token {
                accessToken = normalized
            }
            return normalized
        }
        if let token = KeychainHelper.read(service: keychainService, account: tokenKey) {
            let normalized = normalizeAccessToken(token, tokenType: tokenType)
            if normalized != token {
                KeychainHelper.save(normalized, service: keychainService, account: tokenKey)
            }
            // Solo actualizar si el valor cambió
            if accessToken != normalized {
                accessToken = normalized
            }
            return normalized
        }
        return nil
    }

    func getRawAccessToken() -> String? {
        return getAccessToken()
    }

    func applyCurrentUser(_ user: User) {
        currentUser = user
        userId = user.id
        isAuthenticated = getAccessToken() != nil
        persistUser(user, tokenType: tokenType)
    }

    // MARK: - Private Methods

    /// Cargar sesión desde UserDefaults
    private func loadSession() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: sessionKey),
           let session = try? decoder.decode(PersistedAuthSession.self, from: data) {
            currentUser = session.user
            tokenType = session.tokenType
            userId = session.user.id
            accessToken = getAccessToken()
            isAuthenticated = accessToken != nil
            print("✅ Sesión cargada: \(session.user.email)")
            return
        }

        if let data = UserDefaults.standard.data(forKey: sessionKey),
           let legacySession = try? decoder.decode(AuthSession.self, from: data) {
            currentUser = legacySession.user
            userId = legacySession.user.id
            tokenType = legacySession.tokenType
            let normalizedToken = normalizeAccessToken(legacySession.accessToken, tokenType: tokenType)
            accessToken = normalizedToken
            isAuthenticated = !normalizedToken.isEmpty
            KeychainHelper.save(
                normalizedToken,
                service: keychainService,
                account: tokenKey
            )
            persistUser(legacySession.user, tokenType: legacySession.tokenType)
            print("✅ Sesión migrada: \(legacySession.user.email)")
            return
        }

        if let legacyToken = UserDefaults.standard.string(forKey: tokenKey) {
            let normalized = normalizeAccessToken(legacyToken, tokenType: tokenType)
            KeychainHelper.save(normalized, service: keychainService, account: tokenKey)
            UserDefaults.standard.removeObject(forKey: tokenKey)
        }

        accessToken = getAccessToken()
        userId = UserDefaults.standard.string(forKey: userIdKey)
        isAuthenticated = accessToken != nil
        print("⚠️ No hay sesión guardada")
    }

    /// Actualizar user_id desde las extensions de GraphQL
    func updateUserId(_ newUserId: String) {
        let trimmed = newUserId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != userId else { return }
        userId = trimmed
        UserDefaults.standard.set(trimmed, forKey: userIdKey)
    }

    private func persistUser(_ user: User, tokenType: String?) {
        do {
            let encoder = JSONEncoder()
            let persisted = PersistedAuthSession(user: user, tokenType: tokenType)
            let data = try encoder.encode(persisted)
            UserDefaults.standard.set(data, forKey: sessionKey)
        } catch {
            print("❌ Error guardando sesión local: \(error.localizedDescription)")
        }
    }

    private func normalizeAccessToken(_ token: String, tokenType: String?) -> String {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return token }
        if let prefix = tokenType?.trimmingCharacters(in: .whitespacesAndNewlines),
           !prefix.isEmpty {
            let lowerPrefix = prefix.lowercased() + " "
            if trimmed.lowercased().hasPrefix(lowerPrefix) {
                return String(trimmed.dropFirst(lowerPrefix.count))
            }
        }
        if trimmed.lowercased().hasPrefix("bearer ") {
            return String(trimmed.dropFirst("bearer ".count))
        }
        return trimmed
    }
}
