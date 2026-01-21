import Foundation
import Apollo

class HomeRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // MARK: - Fetch Wallet Balance (solo balance para el toolbar)
    func fetchWalletBalance(jwt: String) async throws -> WalletBalance {
        return try await withCheckedThrowingContinuation { continuation in
            let query = LlegoAPI.MyWalletBalanceQuery(jwt: jwt)

            apolloClient.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (home wallet balance):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error desconocido"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.me else {
                        print("⚠️ Home wallet balance devolvió nil")
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                        ))
                        return
                    }

                    let balance = WalletBalance(
                        local: data.wallet.local,
                        usd: data.wallet.usd,
                        status: data.walletStatus
                    )

                    print("✅ Home balance obtenido: USD \(balance.usd), Local \(balance.local)")
                    continuation.resume(returning: balance)

                case .failure(let error):
                    print("❌ Error en home wallet balance: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
