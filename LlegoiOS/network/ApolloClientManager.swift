import Foundation
import Apollo
import ApolloSQLite


final class ApolloClientManager: @unchecked Sendable {
    nonisolated(unsafe) static let shared = ApolloClientManager()
    
    static let baseURL = "https://llegobackend-production.up.railway.app"

    private(set) lazy var apollo: ApolloClient = {
        return ApolloClient(networkTransport: networkTransport, store: store)
    }()

    private lazy var store: ApolloStore = {
        ApolloStore(cache: cache)
    }()

    private lazy var networkTransport: NetworkTransport = {
        let url = URL(string: "\(Self.baseURL)/graphql")!
        let interceptorProvider = LlegoInterceptorProvider()
        return RequestChainNetworkTransport(
            urlSession: URLSession.shared,
            interceptorProvider: interceptorProvider,
            store: store,
            endpointURL: url
        )
    }()

    private lazy var cache: SQLiteNormalizedCache = {
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        ).first!
        let documentsURL = URL(fileURLWithPath: documentsPath)
        let sqliteFileURL = documentsURL.appendingPathComponent("llego_apollo_cache.sqlite")

        do {
            let sqliteCache = try SQLiteNormalizedCache(fileURL: sqliteFileURL)
            return sqliteCache
        } catch {
            fatalError("Failed to create SQLite cache: \(error)")
        }
    }()

    private init() {}
}
