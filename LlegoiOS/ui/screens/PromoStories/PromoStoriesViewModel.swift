import Foundation
import SwiftUI
import Combine
import Apollo

@MainActor
final class PromoStoriesViewModel: ObservableObject {
    @Published var videos: [PromotionalVideo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func load() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {
            let result = await fetchActivePromotionalVideos()

            isLoading = false

            switch result {
            case .success(let videos):
                self.videos = videos
            case .failure(let error):
                self.videos = []
                self.errorMessage = "Error al cargar promociones: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Private

    private func fetchActivePromotionalVideos() async -> Result<[PromotionalVideo], Error> {
        await withCheckedContinuation { continuation in
            let query = LlegoAPI.GetActivePromotionalVideosQuery()

            ApolloClientManager.shared.apollo.fetchCompat(
                query: query,
                cachePolicy: .fetchIgnoringCacheCompletely
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data {
                        let videos = data.activePromotionalVideos
                            .filter { $0.appTarget.rawValue == "CUSTOMER" }
                            .sorted(by: { $0.order < $1.order })
                            .map { item -> PromotionalVideo in
                                PromotionalVideo(
                                    id: item.id,
                                    title: item.title,
                                    description: item.description,
                                    duration: item.duration,
                                    videoUrl: item.videoUrlSigned,
                                    thumbnailUrl: item.thumbnailUrlSigned ?? item.thumbnailUrl,
                                    branchName: item.branchName,
                                    branchAvatarUrl: item.branchAvatarUrl
                                )
                            }

                        continuation.resume(returning: .success(videos))
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(returning: .failure(NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.map { $0.localizedDescription }.joined(separator: ", ")]
                        )))
                    } else {
                        continuation.resume(returning: .failure(NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "No data returned"]
                        )))
                    }

                case .failure(let error):
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
}
