import Foundation
import Apollo


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

    private lazy var cache: any NormalizedCache = {
        return InMemoryNormalizedCache()
    }()

    /// Clears only the GraphQL data cache (normalized store), preserving image caches.
    func clearDataCache() {
        Task {
            do {
                try await apollo.store.clearCache()
                print("✅ Apollo data cache cleared")
            } catch {
                print("❌ Failed to clear Apollo cache: \(error.localizedDescription)")
            }
        }
    }

    private init() {}
}
