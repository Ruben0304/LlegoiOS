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
            @Sendable func emit(_ result: Result<GraphQLResponse<Query>, Swift.Error>) async {
                await MainActor.run {
                    resultHandler(result)
                }
            }

            let requestConfiguration: RequestConfiguration =
                cachePolicy == .fetchIgnoringCacheCompletely
                ? .init(writeResultsToCache: false)
                : .init()

            do {
                switch cachePolicy {
                case .returnCacheDataElseFetch:
                    let result = try await fetch(
                        query: query,
                        cachePolicy: .cacheFirst,
                        requestConfiguration: requestConfiguration
                    )
                    await emit(.success(result))

                case .fetchIgnoringCacheData, .fetchIgnoringCacheCompletely:
                    let result = try await fetch(
                        query: query,
                        cachePolicy: .networkOnly,
                        requestConfiguration: requestConfiguration
                    )
                    await emit(.success(result))

                case .returnCacheDataDontFetch:
                    if let result = try await fetch(
                        query: query,
                        cachePolicy: .cacheOnly,
                        requestConfiguration: requestConfiguration
                    ) {
                        await emit(.success(result))
                    } else {
                        await emit(.failure(ApolloClient.Error.noResults))
                    }

                case .returnCacheDataAndFetch:
                    // Compat mode: return a single result to avoid duplicate callbacks in legacy call sites.
                    // We still prioritize hitting backend first and fallback to cache if network fails.
                    let result = try await fetch(
                        query: query,
                        cachePolicy: .networkFirst,
                        requestConfiguration: requestConfiguration
                    )
                    await emit(.success(result))
                }
            } catch {
                await emit(.failure(error))
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
