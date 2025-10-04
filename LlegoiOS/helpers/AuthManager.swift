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

// MARK: - AuthManager
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: User?
    @Published var accessToken: String?
    @Published var isAuthenticated: Bool = false

    private let sessionKey = "llego_auth_session"

    private init() {
        loadSession()
    }

    // MARK: - Public Methods

    /// Guardar sesión de autenticación
    func saveSession(_ session: AuthSession) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(session)
            UserDefaults.standard.set(data, forKey: sessionKey)

            currentUser = session.user
            accessToken = session.accessToken
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
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: sessionKey)
        print("✅ Sesión cerrada exitosamente")
    }

    /// Obtener token de autorización
    func getAuthorizationHeader() -> String? {
        guard let token = accessToken else { return nil }
        return "Bearer \(token)"
    }

    // MARK: - Private Methods

    /// Cargar sesión desde UserDefaults
    private func loadSession() {
        guard let data = UserDefaults.standard.data(forKey: sessionKey) else {
            print("⚠️ No hay sesión guardada")
            return
        }

        do {
            let decoder = JSONDecoder()
            let session = try decoder.decode(AuthSession.self, from: data)
            currentUser = session.user
            accessToken = session.accessToken
            isAuthenticated = true
            print("✅ Sesión cargada: \(session.user.email)")
        } catch {
            print("❌ Error cargando sesión: \(error.localizedDescription)")
            UserDefaults.standard.removeObject(forKey: sessionKey)
        }
    }
}
