import Apollo
import Foundation

enum ApolloCompatCachePolicy {
    case returnCacheDataElseFetch
    case fetchIgnoringCacheData
    case fetchIgnoringCacheCompletely
    case returnCacheDataDontFetch
    case returnCacheDataAndFetch
}

extension ApolloClient {
    @discardableResult
    func fetchCompat<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: ApolloCompatCachePolicy = .returnCacheDataElseFetch,
        resultHandler: @escaping @Sendable (Result<GraphQLResponse<Query>, Swift.Error>) -> Void
    ) -> Task<Void, Never> where Query.ResponseFormat == SingleResponseFormat {
        Task {
            do {
                _ = cachePolicy
                let result = try await fetch(query: query, requestConfiguration: .init())
                await MainActor.run {
                    resultHandler(.success(result))
                }
            } catch {
                await MainActor.run {
                    resultHandler(.failure(error))
                }
            }
        }
    }

    @discardableResult
    func performCompat<Mutation: GraphQLMutation>(
        mutation: Mutation,
        resultHandler: @escaping @Sendable (Result<GraphQLResponse<Mutation>, Swift.Error>) -> Void
    ) -> Task<Void, Never> where Mutation.ResponseFormat == SingleResponseFormat {
        Task {
            do {
                let result = try await perform(mutation: mutation, requestConfiguration: .init())
                await MainActor.run {
                    resultHandler(.success(result))
                }
            } catch {
                await MainActor.run {
                    resultHandler(.failure(error))
                }
            }
        }
    }
}
