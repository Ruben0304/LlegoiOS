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
                        phone: data.user.phone,
                        role: data.user.role,
                        appleUserId: nil
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
                phone: phone.map { .some($0) } ?? .none,
                role: .some("customer")
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
                        phone: data.user.phone,
                        role: data.user.role,
                        appleUserId: nil
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
                        phone: data.user.phone,
                        role: data.user.role,
                        appleUserId: nil
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
                        phone: data.user.phone,
                        role: data.user.role,
                        appleUserId: nil
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
}
