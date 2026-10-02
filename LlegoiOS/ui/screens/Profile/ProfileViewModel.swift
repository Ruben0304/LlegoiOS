import AuthenticationServices
import Combine
import Foundation
import SwiftUI

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
    @Published var isUpdatingUsername: Bool = false
    @Published var showEditUsernameSheet: Bool = false
    @Published var editingUsername: String = ""
    @Published var isUpdatingPhone: Bool = false
    @Published var showEditPhoneSheet: Bool = false
    @Published var editingPhone: String = ""

    // Eliminación de cuenta: programada con 30 días de gracia, igual que en el resto de apps
    @Published var showDeleteAccountConfirmation: Bool = false
    /// Solicitando la eliminación programada.
    @Published var isDeletingAccount: Bool = false
    /// Cancelando una eliminación programada.
    @Published var isCancellingAccountDeletion: Bool = false
    @Published var deleteAccountError: String?
    /// Se muestra tras programar la eliminación, antes de cerrar la sesión.
    @Published var showAccountDeletionScheduledAlert: Bool = false
    @Published var accountDeletionScheduledMessage: String = ""

    /// Fecha en que se eliminará la cuenta, si hay una eliminación programada.
    var scheduledDeletionAt: Date? { currentUser?.scheduledDeletionAt }

    // Recent orders
    @Published var recentOrders: [RecentOrder] = []
    @Published var isLoadingOrders: Bool = false
    @Published var completedOrdersCount: Int?

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
            completedOrdersCount = resolveCompletedOrdersCount(
                remoteCount: user.completedOrdersCount,
                fallbackDeliveredCount: nil
            )
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

        // Opcional en el registro: se normaliza (+53) si se puede, sin bloquear si no
        let phone = PhoneNumberNormalizer.normalizedOrOriginal(registerPhone)

        do {
            // Llamar al repository
            let session = try await repository.register(
                name: registerName,
                email: registerEmail,
                password: registerPassword,
                phone: phone.isEmpty ? nil : phone
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
                if let appleIDCredential = authorization.credential
                    as? ASAuthorizationAppleIDCredential
                {
                    guard let tokenData = appleIDCredential.identityToken,
                        let identityToken = String(data: tokenData, encoding: .utf8)
                    else {
                        errorMessage = "No se pudo obtener el token de Apple"
                        state = .unauthenticated
                        print("⚠️ Apple Sign In: identityToken nil o inválido")
                        return
                    }

                    let authorizationCode = appleIDCredential.authorizationCode.flatMap {
                        String(data: $0, encoding: .utf8)
                    }
                    let nonce: String?
                    if let state = appleIDCredential.state, !state.isEmpty {
                        nonce = state
                    } else {
                        nonce = nil
                    }

                    print(
                        "🍎 Recibido AppleIDCredential. email: \(appleIDCredential.email ?? "no proporcionado"), tieneAuthCode: \(authorizationCode != nil)"
                    )

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
            print(
                "🔍 Iniciando login con Google. email: \(email ?? "desconocido") authCode: \(authorizationCode != nil)"
            )
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
        completedOrdersCount = nil
        recentOrders = []
        state = .unauthenticated
        ProfileLocalCache.clear()
        print("✅ Sesión cerrada")
    }

    /// Programa la eliminación de la cuenta (30 días de gracia; se puede cancelar).
    /// No borra nada al instante: avisa de la fecha y, al cerrar el aviso, cierra la sesión.
    func requestAccountDeletion() async {
        guard !isDeletingAccount else { return }
        guard let token = authManager.getAccessToken() else {
            signOut()
            return
        }

        isDeletingAccount = true
        deleteAccountError = nil
        defer { isDeletingAccount = false }

        do {
            let scheduledAt = try await repository.requestAccountDeletion(jwt: token)
            if let user = currentUser {
                let updated = user.withScheduledDeletion(scheduledAt)
                currentUser = updated
                authManager.applyCurrentUser(updated)
            }

            if let scheduledAt {
                accountDeletionScheduledMessage =
                    "Tu cuenta se eliminará definitivamente el \(scheduledAt.longDateInHavana). "
                    + "Si inicias sesión antes de esa fecha podrás cancelar la eliminación."
            } else {
                accountDeletionScheduledMessage =
                    "Tu cuenta se eliminará definitivamente en 30 días. "
                    + "Si inicias sesión antes de ese plazo podrás cancelar la eliminación."
            }
            showAccountDeletionScheduledAlert = true
        } catch {
            deleteAccountError = error.localizedDescription
            print("❌ Error al programar la eliminación de la cuenta: \(error.localizedDescription)")
        }
    }

    /// Cierra la sesión local una vez que el usuario vio la fecha de eliminación.
    func finishAccountDeletionRequest() {
        showAccountDeletionScheduledAlert = false
        signOut()
    }

    /// Cancela la eliminación programada: la cuenta sigue como siempre.
    func cancelAccountDeletion() async {
        guard !isCancellingAccountDeletion else { return }
        guard let token = authManager.getAccessToken() else {
            signOut()
            return
        }

        isCancellingAccountDeletion = true
        deleteAccountError = nil
        defer { isCancellingAccountDeletion = false }

        do {
            let scheduledAt = try await repository.cancelAccountDeletion(jwt: token)
            if let user = currentUser {
                let updated = user.withScheduledDeletion(scheduledAt)
                currentUser = updated
                authManager.applyCurrentUser(updated)
            }
        } catch {
            deleteAccountError = error.localizedDescription
            print("❌ Error al cancelar la eliminación de la cuenta: \(error.localizedDescription)")
        }
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
            await loadCompletedOrdersCount()
        } catch {
            if shouldInvalidateSession(for: error) {
                authManager.signOut()
                currentUser = nil
                completedOrdersCount = nil
                recentOrders = []
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

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
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

    /// Load completed (delivered) orders count.
    /// Current source: filtered myOrders(status: DELIVERED).totalCount.
    /// Future source: backend-provided user.completedOrdersCount, with local fallback.
    func loadCompletedOrdersCount() async {
        guard authManager.isAuthenticated else { return }

        // Prefer backend-provided value when available.
        if let remoteCount = currentUser?.completedOrdersCount {
            completedOrdersCount = resolveCompletedOrdersCount(
                remoteCount: remoteCount,
                fallbackDeliveredCount: nil
            )
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            orderRepository.fetchDeliveredOrdersCount { [weak self] result in
                Task { @MainActor in
                    defer { continuation.resume() }
                    guard let self = self else { return }

                    switch result {
                    case .success(let deliveredCount):
                        self.completedOrdersCount = self.resolveCompletedOrdersCount(
                            remoteCount: self.currentUser?.completedOrdersCount,
                            fallbackDeliveredCount: deliveredCount
                        )
                    case .failure(let error):
                        print(
                            "❌ Error loading completed orders count: \(error.localizedDescription)")
                        self.completedOrdersCount = self.resolveCompletedOrdersCount(
                            remoteCount: self.currentUser?.completedOrdersCount,
                            fallbackDeliveredCount: nil
                        )
                    }
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

    private func resolveCompletedOrdersCount(
        remoteCount: Int?,
        fallbackDeliveredCount: Int?
    ) -> Int? {
        if let remoteCount {
            return max(remoteCount, 0)
        }
        if let fallbackDeliveredCount {
            return max(fallbackDeliveredCount, 0)
        }
        return nil
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
                    username: user.username,
                    phone: user.phone,
                    role: user.role,
                    appleUserId: user.appleUserId,
                    avatar: response.avatar,
                    avatarUrl: response.avatarUrl,
                    savedAddresses: user.savedAddresses,
                    defaultAddressId: user.defaultAddressId,
                    scheduledDeletionAt: user.scheduledDeletionAt
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

    // MARK: - Update Username

    /// Update username
    func updateUsername(newUsername: String) async {
        guard !isUpdatingUsername else { return }
        guard !newUsername.isEmpty else {
            errorMessage = "El username no puede estar vacío"
            return
        }

        isUpdatingUsername = true
        errorMessage = nil

        do {
            guard let jwt = authManager.getAccessToken() else {
                errorMessage = "No hay sesión activa"
                isUpdatingUsername = false
                return
            }

            let updatedUser = try await repository.updateUser(
                jwt: jwt,
                name: nil,
                username: newUsername,
                phone: nil
            )

            // Update current user with new username
            if let user = currentUser {
                let newUser = User(
                    id: user.id,
                    email: user.email,
                    fullName: user.fullName,
                    username: updatedUser.username,
                    phone: user.phone,
                    role: user.role,
                    appleUserId: user.appleUserId,
                    avatar: user.avatar,
                    avatarUrl: user.avatarUrl,
                    savedAddresses: user.savedAddresses,
                    defaultAddressId: user.defaultAddressId,
                    scheduledDeletionAt: user.scheduledDeletionAt
                )

                currentUser = newUser
                authManager.applyCurrentUser(newUser)
                updateCachedUserInfo(newUser)

                print("✅ Username actualizado a: \(updatedUser.username)")
            }

            showEditUsernameSheet = false
            editingUsername = ""

        } catch {
            errorMessage = "Error al actualizar username: \(error.localizedDescription)"
            print("❌ Error updating username: \(error)")
        }

        isUpdatingUsername = false
    }

    // MARK: - Update Phone

    /// Actualiza el teléfono del usuario. Se guarda normalizado con código de país (+53 si no lo trae)
    /// para que la app de negocios pueda llamar/abrir WhatsApp desde el detalle del pedido.
    /// Cadena vacía lo borra: se envía "" explícito porque el backend trata `phone: null` como
    /// "no cambiar" y respondería "No hay campos para actualizar".
    func updatePhone(newPhone: String) async {
        guard !isUpdatingPhone else { return }

        let normalizedPhone: String
        switch PhoneNumberNormalizer.normalize(newPhone) {
        case .success(let phone):
            normalizedPhone = phone
        case .failure(let validationError):
            errorMessage = validationError.localizedDescription
            return
        }

        // Sin cambios: no llamar al backend (y evita el error "No hay campos para actualizar").
        // Un teléfono antiguo sin +53 sí cambia al normalizarlo, así que se guarda corregido.
        if normalizedPhone == (currentUser?.phone ?? "") {
            errorMessage = nil
            showEditPhoneSheet = false
            editingPhone = ""
            return
        }

        isUpdatingPhone = true
        errorMessage = nil

        do {
            guard let jwt = authManager.getAccessToken() else {
                errorMessage = "No hay sesión activa"
                isUpdatingPhone = false
                return
            }

            let updatedUser = try await repository.updateUser(
                jwt: jwt,
                name: nil,
                username: nil,
                phone: normalizedPhone
            )

            if let user = currentUser {
                let newUser = User(
                    id: user.id,
                    email: user.email,
                    fullName: user.fullName,
                    username: user.username,
                    phone: updatedUser.phone,
                    role: user.role,
                    appleUserId: user.appleUserId,
                    avatar: user.avatar,
                    avatarUrl: user.avatarUrl,
                    savedAddresses: user.savedAddresses,
                    defaultAddressId: user.defaultAddressId,
                    scheduledDeletionAt: user.scheduledDeletionAt
                )

                currentUser = newUser
                authManager.applyCurrentUser(newUser)
                updateCachedUserInfo(newUser)

                print("✅ Teléfono actualizado a: \(updatedUser.phone ?? "(vacío)")")
            }

            showEditPhoneSheet = false
            editingPhone = ""

        } catch {
            errorMessage = "Error al actualizar teléfono: \(error.localizedDescription)"
            print("❌ Error updating phone: \(error)")
        }

        isUpdatingPhone = false
    }
}
