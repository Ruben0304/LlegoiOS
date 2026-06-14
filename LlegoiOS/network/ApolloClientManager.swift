import Foundation
import Apollo
import ApolloSQLite

final class ApolloClientManager: @unchecked Sendable {
    nonisolated(unsafe) static let shared = ApolloClientManager()

    private(set) lazy var apollo: ApolloClient = {
        let url = URL(string: "https://llegobackend-production.up.railway.app/graphql")!
        let store = ApolloStore(cache: cache)
        return ApolloClient(url: url, store: store)
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
