import Foundation
import Apollo
import ApolloAPI

struct AuthorizationInterceptor: HTTPInterceptor {
    func intercept(
        request: URLRequest,
        next: NextHTTPInterceptorFunction
    ) async throws -> HTTPResponse {
        var request = request
        let session = await MainActor.run {
            (AuthManager.shared.getAuthorizationHeader(), AuthManager.shared.getAccessToken(),
             AuthManager.shared.sessionGeneration)
        }
        if let authorization = session.0 {
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
        }
        let authenticatedRequest = request
        let response = try await next(authenticatedRequest)
        await AuthenticatedURLSession.inspect(
            request: authenticatedRequest, token: session.1, generation: session.2,
            status: response.response.statusCode, data: Data())
        return await response.mapChunks { response, data in
            await AuthenticatedURLSession.inspect(
                request: authenticatedRequest, token: session.1, generation: session.2, status: response.statusCode, data: data)
            return data
        }
    }
}


struct LlegoInterceptorProvider: InterceptorProvider {
    func graphQLInterceptors<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> [any GraphQLInterceptor] {
        DefaultInterceptorProvider.shared.graphQLInterceptors(for: operation)
    }

    func cacheInterceptor<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> any CacheInterceptor {
        DefaultInterceptorProvider.shared.cacheInterceptor(for: operation)
    }

    func httpInterceptors<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> [any HTTPInterceptor] {
        DefaultInterceptorProvider.shared.httpInterceptors(for: operation) + [AuthorizationInterceptor()]
    }

    func responseParser<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> any ResponseParsingInterceptor {
        DefaultInterceptorProvider.shared.responseParser(for: operation)
    }
}
