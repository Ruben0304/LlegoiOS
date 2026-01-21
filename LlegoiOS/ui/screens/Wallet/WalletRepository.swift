import Foundation
import Apollo

// MARK: - Wallet Balance Model
struct WalletBalance {
    let local: Double
    let usd: Double
    let status: String
}

// MARK: - Wallet Transaction Model
struct WalletTransaction {
    let id: String
    let fromOwnerId: String?
    let fromOwnerType: String?
    let toOwnerId: String?
    let toOwnerType: String?
    let amount: Double
    let currency: String
    let type: String
    let status: String
    let description: String?
    let createdAt: String
    let completedAt: String?
}

// MARK: - Wallet Details Model
struct WalletDetails {
    let balance: WalletBalance
    let transactions: [WalletTransaction]
}

class WalletRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // MARK: - Fetch Wallet Balance (para Home)
    func fetchWalletBalance(jwt: String) async throws -> WalletBalance {
        return try await withCheckedThrowingContinuation { continuation in
            let query = LlegoAPI.MyWalletBalanceQuery(jwt: jwt)

            apolloClient.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (wallet balance):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error desconocido"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.me else {
                        print("⚠️ Wallet balance devolvió nil")
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

                    print("✅ Balance obtenido: USD \(balance.usd), Local \(balance.local)")
                    continuation.resume(returning: balance)

                case .failure(let error):
                    print("❌ Error en wallet balance: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Fetch Wallet Details (para WalletView)
    func fetchWalletDetails(jwt: String, limit: Int = 50, skip: Int = 0, currency: String? = nil) async throws -> WalletDetails {
        return try await withCheckedThrowingContinuation { continuation in
            let query = LlegoAPI.MyWalletDetailsQuery(
                jwt: jwt,
                limit: .some(Int32(limit)),
                skip: .some(Int32(skip)),
                currency: currency.map { .some($0) } ?? .none
            )

            apolloClient.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (wallet details):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error desconocido"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data else {
                        print("⚠️ Wallet details devolvió nil")
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                        ))
                        return
                    }

                    guard let meData = data.me else {
                        print("⚠️ Me data es nil en wallet details")
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -3,
                            userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"]
                        ))
                        return
                    }

                    let balance = WalletBalance(
                        local: meData.wallet.local,
                        usd: meData.wallet.usd,
                        status: meData.walletStatus
                    )

                    let transactions = data.myWalletTransactions.map { tx in
                        WalletTransaction(
                            id: tx.id,
                            fromOwnerId: tx.fromOwnerId,
                            fromOwnerType: tx.fromOwnerType,
                            toOwnerId: tx.toOwnerId,
                            toOwnerType: tx.toOwnerType,
                            amount: tx.amount,
                            currency: tx.currency,
                            type: tx.type,
                            status: tx.status,
                            description: tx.description,
                            createdAt: tx.createdAt,
                            completedAt: tx.completedAt
                        )
                    }

                    let walletDetails = WalletDetails(
                        balance: balance,
                        transactions: transactions
                    )

                    print("✅ Wallet details obtenidos: \(transactions.count) transacciones")
                    continuation.resume(returning: walletDetails)

                case .failure(let error):
                    print("❌ Error en wallet details: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Deposit Money
    func depositMoney(jwt: String, amount: Double, currency: String, source: String, description: String?) async throws -> WalletTransaction {
        return try await withCheckedThrowingContinuation { continuation in
            let input = LlegoAPI.DepositInput(
                amount: amount,
                currency: currency,
                source: source,
                description: description.map { .some($0) } ?? .none
            )
            let mutation = LlegoAPI.DepositMoneyMutation(jwt: jwt, input: input)

            apolloClient.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (deposit money):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error al depositar"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.depositMoney else {
                        print("⚠️ Deposit money devolvió nil")
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                        ))
                        return
                    }

                    let transaction = WalletTransaction(
                        id: data.id,
                        fromOwnerId: data.fromOwnerId,
                        fromOwnerType: data.fromOwnerType,
                        toOwnerId: data.toOwnerId,
                        toOwnerType: data.toOwnerType,
                        amount: data.amount,
                        currency: data.currency,
                        type: data.type,
                        status: data.status,
                        description: data.description,
                        createdAt: data.createdAt,
                        completedAt: data.completedAt
                    )

                    print("✅ Depósito exitoso: \(amount) \(currency)")
                    continuation.resume(returning: transaction)

                case .failure(let error):
                    print("❌ Error en deposit money: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Transfer Money
    func transferMoney(jwt: String, toOwnerUsername: String?, toOwnerEmail: String?, toOwnerId: String?, toOwnerType: String, amount: Double, currency: String, description: String?) async throws -> WalletTransaction {
        return try await withCheckedThrowingContinuation { continuation in
            let input = LlegoAPI.TransferInput(
                toOwnerId: toOwnerId.map { .some($0) } ?? .none,
                toOwnerEmail: toOwnerEmail.map { .some($0) } ?? .none,
                toOwnerUsername: toOwnerUsername.map { .some($0) } ?? .none,
                toOwnerType: toOwnerType,
                amount: amount,
                currency: currency,
                description: description.map { .some($0) } ?? .none
            )
            let mutation = LlegoAPI.TransferMoneyMutation(jwt: jwt, input: input)

            apolloClient.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (transfer money):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error al transferir"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.transferMoney else {
                        print("⚠️ Transfer money devolvió nil")
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No se recibió respuesta del servidor"]
                        ))
                        return
                    }

                    let transaction = WalletTransaction(
                        id: data.id,
                        fromOwnerId: data.fromOwnerId,
                        fromOwnerType: data.fromOwnerType,
                        toOwnerId: data.toOwnerId,
                        toOwnerType: data.toOwnerType,
                        amount: data.amount,
                        currency: data.currency,
                        type: data.type,
                        status: data.status,
                        description: data.description,
                        createdAt: data.createdAt,
                        completedAt: data.completedAt
                    )

                    print("✅ Transferencia exitosa: \(amount) \(currency) a \(toOwnerUsername ?? toOwnerEmail ?? toOwnerId ?? "unknown")")
                    continuation.resume(returning: transaction)

                case .failure(let error):
                    print("❌ Error en transfer money: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
