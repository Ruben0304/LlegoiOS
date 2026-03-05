import Foundation
import Apollo
import ApolloAPI

struct AuthorizationInterceptor: HTTPInterceptor {
    func intercept(
        request: URLRequest,
        next: NextHTTPInterceptorFunction
    ) async throws -> HTTPResponse {
        var request = request
        let authorization = await MainActor.run {
            AuthManager.shared.getAuthorizationHeader()
        }
        if let authorization {
            request.addValue(authorization, forHTTPHeaderField: "Authorization")
        }
        return try await next(request)
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
        [AuthorizationInterceptor()] + DefaultInterceptorProvider.shared.httpInterceptors(for: operation)
    }

    func responseParser<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> any ResponseParsingInterceptor {
        DefaultInterceptorProvider.shared.responseParser(for: operation)
    }
}
