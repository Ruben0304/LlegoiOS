import Foundation
import SwiftUI
import AuthenticationServices
import Combine

enum ProfileViewState: Equatable {
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
    @Published var isRefreshingProfile: Bool = false
    @Published var isUploadingAvatar: Bool = false
    
    // Recent orders
    @Published var recentOrders: [RecentOrder] = []
    @Published var isLoadingOrders: Bool = false

    // Login form state
    @Published var email: String = ""
    @Published var password: String = ""

    // Register form state
    @Published var registerName: String = ""
    @Published var registerEmail: String = ""
    @Published var registerPassword: String = ""
    @Published var registerPhone: String = ""

    private let repository = ProfileRepository()
    private let orderRepository = OrderListRepository()
    private let authManager = AuthManager.shared

    init() {
        // Nota: No llamar checkAuthenticationStatus() aquí para evitar
        // "Publishing changes from within view updates" cuando el ViewModel
        // se crea durante el body de una vista.
        // Usar checkAuthenticationStatus() en onAppear de la vista.
    }

    // MARK: - Public Methods

    /// Verificar estado de autenticación
    func checkAuthenticationStatus() {
        if authManager.isAuthenticated, let user = authManager.currentUser {
            currentUser = user
            updateCachedUserInfo(user)
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
            updateCachedUserInfo(session.user)

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
            updateCachedUserInfo(session.user)

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

    /// Login con Apple
    func signInWithApple(result: Result<ASAuthorization, Error>) async {
        state = .loading
        errorMessage = nil

        do {
            switch result {
            case .success(let authorization):
                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    guard let tokenData = appleIDCredential.identityToken,
                          let identityToken = String(data: tokenData, encoding: .utf8) else {
                        errorMessage = "No se pudo obtener el token de Apple"
                        state = .unauthenticated
                        print("⚠️ Apple Sign In: identityToken nil o inválido")
                        return
                    }

                    let authorizationCode = appleIDCredential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
                    let nonce: String?
                    if let state = appleIDCredential.state, !state.isEmpty {
                        nonce = state
                    } else {
                        nonce = nil
                    }

                    print("🍎 Recibido AppleIDCredential. email: \(appleIDCredential.email ?? "no proporcionado"), tieneAuthCode: \(authorizationCode != nil)")

                    let session = try await repository.loginWithApple(
                        identityToken: identityToken,
                        authorizationCode: authorizationCode,
                        nonce: nonce
                    )

                    authManager.saveSession(session)
                    currentUser = session.user
                    state = .authenticated
                    updateCachedUserInfo(session.user)

                    print("✅ Apple Sign In exitoso: \(session.user.email)")
                } else {
                    errorMessage = "Credencial de Apple inválida"
                    state = .unauthenticated
                    print("⚠️ Apple Sign In: credencial no es ASAuthorizationAppleIDCredential")
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

    /// Login con Google
    func signInWithGoogle(idToken: String, authorizationCode: String?, email: String?) async {
        state = .loading
        errorMessage = nil

        guard !idToken.isEmpty else {
            errorMessage = "No se pudo obtener el token de Google"
            state = .unauthenticated
            print("⚠️ Google Sign In: idToken vacío")
            return
        }

        do {
            print("🔍 Iniciando login con Google. email: \(email ?? "desconocido") authCode: \(authorizationCode != nil)")
            let session = try await repository.loginWithGoogle(
                idToken: idToken,
                authorizationCode: authorizationCode,
                nonce: nil
            )

            authManager.saveSession(session)
            currentUser = session.user
            state = .authenticated
            updateCachedUserInfo(session.user)

            print("✅ Google Sign In exitoso: \(session.user.email)")
        } catch {
            errorMessage = "Error al iniciar sesión con Google: \(error.localizedDescription)"
            state = .unauthenticated
            print("❌ Error en Google Sign In: \(error)")
        }
    }

    /// Cerrar sesión
    func signOut() {
        authManager.signOut()
        currentUser = nil
        state = .unauthenticated
        ProfileLocalCache.clear()
        print("✅ Sesión cerrada")
    }

    func refreshProfile() async {
        guard !isRefreshingProfile else { return }
        guard let token = authManager.getAccessToken() else {
            state = .unauthenticated
            return
        }

        isRefreshingProfile = true
        defer { isRefreshingProfile = false }

        do {
            let user = try await repository.fetchCurrentUser(jwt: token)
            authManager.applyCurrentUser(user)
            currentUser = user
            updateCachedUserInfo(user)
            state = .authenticated
            
            // Load recent orders after profile refresh
            await loadRecentOrders()
        } catch {
            if shouldInvalidateSession(for: error) {
                authManager.signOut()
                currentUser = nil
                state = .unauthenticated
                ProfileLocalCache.clear()
                return
            }
            state = .authenticated
        }
    }
    
    // MARK: - Orders
    
    /// Load recent orders from backend
    func loadRecentOrders() async {
        guard authManager.isAuthenticated else { return }
        
        isLoadingOrders = true
        
        await withCheckedContinuation { continuation in
            orderRepository.fetchOrders(limit: 3, offset: 0) { [weak self] result in
                Task { @MainActor in
                    guard let self = self else {
                        continuation.resume()
                        return
                    }
                    
                    self.isLoadingOrders = false
                    
                    switch result {
                    case .success(let orderResult):
                        self.recentOrders = orderResult.orders
                        print("✅ Loaded \(orderResult.orders.count) recent orders")
                        
                    case .failure(let error):
                        print("❌ Error loading recent orders: \(error.localizedDescription)")
                        // Keep empty array on error, don't show error to user
                    }
                    
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Validation

    var isLoginButtonEnabled: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var isRegisterButtonEnabled: Bool {
        !registerName.isEmpty && !registerEmail.isEmpty && !registerPassword.isEmpty
    }

    private func updateCachedUserInfo(_ user: User) {
        ProfileLocalCache.update { snapshot in
            snapshot.fullName = user.fullName
            snapshot.email = user.email
        }
    }

    private func shouldInvalidateSession(for error: Error) -> Bool {
        let message = (error as NSError).localizedDescription.lowercased()
        return message.contains("token")
            || message.contains("jwt")
            || message.contains("unauthorized")
            || message.contains("no autorizado")
    }
    
    // MARK: - Avatar Upload
    
    /// Upload avatar image
    func uploadAvatar(image: UIImage) async {
        guard !isUploadingAvatar else { return }
        
        isUploadingAvatar = true
        errorMessage = nil
        
        do {
            let response = try await AvatarService.shared.uploadAvatar(image: image)
            
            // Update current user with new avatar
            if let user = currentUser {
                let updatedUser = User(
                    id: user.id,
                    email: user.email,
                    fullName: user.fullName,
                    phone: user.phone,
                    role: user.role,
                    appleUserId: user.appleUserId,
                    avatar: response.avatar,
                    avatarUrl: response.avatarUrl
                )
                
                currentUser = updatedUser
                authManager.applyCurrentUser(updatedUser)
                updateCachedUserInfo(updatedUser)
                
                print("✅ Avatar uploaded successfully")
            }
            
            // Refresh profile to get complete data
            await refreshProfile()
            
        } catch {
            errorMessage = "Error al subir avatar: \(error.localizedDescription)"
            print("❌ Error uploading avatar: \(error)")
        }
        
        isUploadingAvatar = false
    }
}
