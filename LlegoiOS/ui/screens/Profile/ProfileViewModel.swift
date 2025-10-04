import Foundation
import SwiftUI
import AuthenticationServices
import Combine

enum ProfileViewState {
    case idle
    case loading
    case authenticated
    case unauthenticated
    case error(String)
}

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var state: ProfileViewState = .idle
    @Published var currentUser: User?
    @Published var errorMessage: String?

    // Login form state
    @Published var email: String = ""
    @Published var password: String = ""

    // Register form state
    @Published var registerName: String = ""
    @Published var registerEmail: String = ""
    @Published var registerPassword: String = ""
    @Published var registerPhone: String = ""

    private let repository = ProfileRepository()
    private let authManager = AuthManager.shared

    init() {
        checkAuthenticationStatus()
    }

    // MARK: - Public Methods

    /// Verificar estado de autenticación
    func checkAuthenticationStatus() {
        if authManager.isAuthenticated, let user = authManager.currentUser {
            currentUser = user
            state = .authenticated
        } else {
            state = .unauthenticated
        }
    }

    /// Login con email y password
    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Por favor, completa todos los campos"
            return
        }

        state = .loading
        errorMessage = nil

        do {
            // Llamar al repository
            let session = try await repository.login(email: email, password: password)

            // Guardar sesión en AuthManager
            authManager.saveSession(session)

            // Actualizar estado
            currentUser = session.user
            state = .authenticated

            // Limpiar campos
            email = ""
            password = ""

            print("✅ Login exitoso: \(session.user.email)")

        } catch {
            errorMessage = "Error al iniciar sesión: \(error.localizedDescription)"
            state = .unauthenticated
            print("❌ Error en login: \(error)")
        }
    }

    /// Registro de usuario
    func register() async {
        guard !registerName.isEmpty, !registerEmail.isEmpty, !registerPassword.isEmpty else {
            errorMessage = "Por favor, completa todos los campos obligatorios"
            return
        }

        state = .loading
        errorMessage = nil

        do {
            // Llamar al repository
            let session = try await repository.register(
                name: registerName,
                email: registerEmail,
                password: registerPassword,
                phone: registerPhone.isEmpty ? nil : registerPhone
            )

            // Guardar sesión en AuthManager
            authManager.saveSession(session)

            // Actualizar estado
            currentUser = session.user
            state = .authenticated

            // Limpiar campos
            registerName = ""
            registerEmail = ""
            registerPassword = ""
            registerPhone = ""

            print("✅ Registro exitoso: \(session.user.email)")

        } catch {
            errorMessage = "Error al registrarse: \(error.localizedDescription)"
            state = .unauthenticated
            print("❌ Error en registro: \(error)")
        }
    }

    /// Login con Apple (por implementar con backend)
    func signInWithApple(result: Result<ASAuthorization, Error>) async {
        state = .loading
        errorMessage = nil

        do {
            switch result {
            case .success(let authorization):
                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    // TODO: Implementar login con Apple en el backend
                    // Por ahora, mostrar mensaje
                    errorMessage = "Login con Apple estará disponible próximamente"
                    state = .unauthenticated
                    print("⚠️ Apple Sign In no implementado en backend aún")
                }

            case .failure(let error):
                throw error
            }

        } catch {
            errorMessage = "Error al iniciar sesión con Apple: \(error.localizedDescription)"
            state = .unauthenticated
            print("❌ Error en Apple Sign In: \(error)")
        }
    }

    /// Cerrar sesión
    func signOut() {
        authManager.signOut()
        currentUser = nil
        state = .unauthenticated
        print("✅ Sesión cerrada")
    }

    // MARK: - Validation

    var isLoginButtonEnabled: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var isRegisterButtonEnabled: Bool {
        !registerName.isEmpty && !registerEmail.isEmpty && !registerPassword.isEmpty
    }
}
