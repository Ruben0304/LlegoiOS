import Foundation

enum AuthenticatedURLSession {
    static func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let session = await MainActor.run {
            (AuthManager.shared.getAccessToken(), AuthManager.shared.sessionGeneration)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse {
            await inspect(request: request, token: session.0, generation: session.1,
                          status: response.statusCode, data: data)
        }
        return (data, response)
    }

    static func inspect(request: URLRequest, token: String?, generation: UUID, status: Int, data: Data) async {
        if let token, SessionErrorPolicy.isBackend(request, baseURL: ApolloClientManager.baseURL),
           SessionErrorPolicy.usesToken(token, request: request),
           SessionErrorPolicy.invalidatesSession(status: status, data: data) {
            await MainActor.run {
                guard SessionErrorPolicy.isCurrent(token: token, generation: generation,
                    currentToken: AuthManager.shared.getAccessToken(),
                    currentGeneration: AuthManager.shared.sessionGeneration) else { return }
                AuthManager.shared.signOut()
                OrderManager.shared.stopOrder()
                ProfileLocalCache.clear()
                FavoritesManager.shared.clearFavorites()
                CartManager.shared.clearCart()
                UserLocationManager.shared.clearLocation()
                ApolloClientManager.shared.clearDataCache()
            }
        }
    }
}
