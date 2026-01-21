import Foundation
import Apollo

class ProfileRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // MARK: - Login con Email/Password
    func login(email: String, password: String) async throws -> AuthSession {
        return try await withCheckedThrowingContinuation { continuation in
            let input = LlegoAPI.LoginInput(email: email, password: password)
            let mutation = LlegoAPI.LoginMutation(input: input)

            apolloClient.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors:")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error desconocido"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.login else {
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                        ))
                        return
                    }

                    // Mapear datos GraphQL a AuthSession
                    let user = User(
                        id: data.user.id,
                        email: data.user.email,
                        fullName: data.user.name,
                        username: "", // El backend genera username automáticamente
                        phone: data.user.phone,
                        role: data.user.role,
                        appleUserId: nil,
                        avatar: nil,
                        avatarUrl: nil
                    )

                    let session = AuthSession(
                        user: user,
                        accessToken: data.accessToken,
                        tokenType: data.tokenType
                    )

                    print("✅ Login exitoso: \(user.email)")
                    continuation.resume(returning: session)

                case .failure(let error):
                    print("❌ Error en login: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Registro de Usuario
    func register(name: String, email: String, password: String, phone: String?) async throws -> AuthSession {
        return try await withCheckedThrowingContinuation { continuation in
            let input = LlegoAPI.RegisterInput(
                name: name,
                email: email,
                password: password,
                phone: phone.map { .some($0) } ?? .none
            )
            let mutation = LlegoAPI.RegisterMutation(input: input)

            apolloClient.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors:")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error desconocido"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.register else {
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                        ))
                        return
                    }

                    // Mapear datos GraphQL a AuthSession
                    let user = User(
                        id: data.user.id,
                        email: data.user.email,
                        fullName: data.user.name,
                        username: "", // El backend genera username automáticamente
                        phone: data.user.phone,
                        role: data.user.role,
                        appleUserId: nil,
                        avatar: nil,
                        avatarUrl: nil
                    )

                    let session = AuthSession(
                        user: user,
                        accessToken: data.accessToken,
                        tokenType: data.tokenType
                    )

                    print("✅ Registro exitoso: \(user.email)")
                    continuation.resume(returning: session)

                case .failure(let error):
                    print("❌ Error en registro: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Login con Google
    func loginWithGoogle(idToken: String, authorizationCode: String?, nonce: String?) async throws -> AuthSession {
        return try await withCheckedThrowingContinuation { continuation in
            let input = LlegoAPI.SocialLoginInput(
                idToken: idToken,
                authorizationCode: authorizationCode.map { .some($0) } ?? .none,
                nonce: nonce.map { .some($0) } ?? .none
            )
            let mutation = LlegoAPI.LoginWithGoogleMutation(input: input)

            apolloClient.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (Google login):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error desconocido"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.loginWithGoogle else {
                        print("⚠️ loginWithGoogle devolvió nil")
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                        ))
                        return
                    }

                    let user = User(
                        id: data.user.id,
                        email: data.user.email,
                        fullName: data.user.name,
                        username: "", // El backend genera username automáticamente
                        phone: data.user.phone,
                        role: data.user.role,
                        appleUserId: nil,
                        avatar: nil,
                        avatarUrl: nil
                    )

                    let session = AuthSession(
                        user: user,
                        accessToken: data.accessToken,
                        tokenType: data.tokenType
                    )

                    print("✅ Login con Google exitoso: \(user.email)")
                    continuation.resume(returning: session)

                case .failure(let error):
                    print("❌ Error en login con Google: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Login con Apple
    func loginWithApple(identityToken: String, authorizationCode: String?, nonce: String?) async throws -> AuthSession {
        return try await withCheckedThrowingContinuation { continuation in
            let input = LlegoAPI.AppleLoginInput(
                identityToken: identityToken,
                authorizationCode: authorizationCode.map { .some($0) } ?? .none,
                nonce: nonce.map { .some($0) } ?? .none
            )
            let mutation = LlegoAPI.LoginWithAppleMutation(input: input)

            apolloClient.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (Apple login):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error desconocido"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.loginWithApple else {
                        print("⚠️ loginWithApple devolvió nil")
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                        ))
                        return
                    }

                    let user = User(
                        id: data.user.id,
                        email: data.user.email,
                        fullName: data.user.name,
                        username: "", // El backend genera username automáticamente
                        phone: data.user.phone,
                        role: data.user.role,
                        appleUserId: nil,
                        avatar: nil,
                        avatarUrl: nil
                    )

                    let session = AuthSession(
                        user: user,
                        accessToken: data.accessToken,
                        tokenType: data.tokenType
                    )

                    print("✅ Login con Apple exitoso: \(user.email)")
                    continuation.resume(returning: session)

                case .failure(let error):
                    print("❌ Error en login con Apple: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Usuario Actual (Me)
    func fetchCurrentUser(jwt: String) async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            let query = LlegoAPI.MeQuery(jwt: jwt)
            apolloClient.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (me):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error desconocido"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.me else {
                        print("⚠️ Me devolvió nil (posible token inválido)")
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "Token inválido o usuario no encontrado"]
                        ))
                        return
                    }

                    let user = User(
                        id: data.id,
                        email: data.email,
                        fullName: data.name,
                        username: data.username,
                        phone: data.phone,
                        role: data.role,
                        appleUserId: data.providerUserId,
                        avatar: data.avatar,
                        avatarUrl: data.avatarUrl
                    )
                    continuation.resume(returning: user)

                case .failure(let error):
                    print("❌ Error en me: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Update User
    func updateUser(jwt: String, name: String?, username: String?, phone: String?) async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            let input = LlegoAPI.UpdateUserInput(
                name: name.map { .some($0) } ?? .none,
                username: username.map { .some($0) } ?? .none,
                phone: phone.map { .some($0) } ?? .none,
                avatar: .none
            )
            let mutation = LlegoAPI.UpdateUserMutation(input: input, jwt: jwt)

            apolloClient.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (update user):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error al actualizar usuario"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.updateUser else {
                        print("⚠️ updateUser devolvió nil")
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                        ))
                        return
                    }

                    let user = User(
                        id: data.id,
                        email: data.email,
                        fullName: data.name,
                        username: data.username,
                        phone: data.phone,
                        role: "user", // El mutation no devuelve role, usar default
                        appleUserId: nil,
                        avatar: data.avatar,
                        avatarUrl: data.avatarUrl
                    )

                    print("✅ Usuario actualizado: \(user.username)")
                    continuation.resume(returning: user)

                case .failure(let error):
                    print("❌ Error en update user: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Search Users
    func searchUsers(jwt: String, query: String) async throws -> [SearchUserResult] {
        return try await withCheckedThrowingContinuation { continuation in
            let searchQuery = LlegoAPI.SearchUsersQuery(query: query, jwt: jwt)
            
            apolloClient.fetch(query: searchQuery, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (search users):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error al buscar usuarios"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.searchUsers else {
                        print("⚠️ searchUsers devolvió nil")
                        continuation.resume(returning: [])
                        return
                    }

                    let users = data.map { user in
                        SearchUserResult(
                            id: user.id,
                            name: user.name,
                            username: user.username,
                            email: user.email,
                            avatarUrl: user.avatarUrl
                        )
                    }

                    print("✅ Usuarios encontrados: \(users.count)")
                    continuation.resume(returning: users)

                case .failure(let error):
                    print("❌ Error en search users: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Search User Result Model
struct SearchUserResult {
    let id: String
    let name: String
    let username: String
    let email: String
    let avatarUrl: String?
}
