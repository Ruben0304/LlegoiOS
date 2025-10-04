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
}
