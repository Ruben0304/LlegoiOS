import Foundation
import SwiftUI
import Combine
import Apollo

@MainActor
class TutorialsViewModel: ObservableObject {
    @Published var tutorials: [Tutorial] = []
    @Published var selectedTutorial: Tutorial?
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    init() {
        loadTutorials()
    }

    func loadTutorials() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {
            let result = await fetchActiveTutorials()

            isLoading = false

            switch result {
            case .success(let tutorials):
                self.tutorials = tutorials
            case .failure(let error):
                self.tutorials = []
                self.errorMessage = "Error al cargar tutoriales: \(error.localizedDescription)"
            }
        }
    }

    func selectTutorial(_ tutorial: Tutorial) {
        selectedTutorial = tutorial
        isPlaying = true
    }

    func closeTutorial() {
        selectedTutorial = nil
        isPlaying = false
    }

    // MARK: - Private

    private func fetchActiveTutorials() async -> Result<[Tutorial], Error> {
        await withCheckedContinuation { continuation in
            let query = LlegoAPI.GetActiveTutorialsQuery()

            ApolloClientManager.shared.apollo.fetchCompat(query: query, cachePolicy: .fetchIgnoringCacheCompletely) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data {
                        let tutorials = data.activeTutorials
                            .filter { $0.appTarget.rawValue == "CUSTOMER" }
                            .sorted(by: { $0.order < $1.order })
                            .map { tutorialData -> Tutorial in
                                let minutes = tutorialData.duration / 60
                                let seconds = tutorialData.duration % 60
                                let formattedDuration = String(format: "%d:%02d", minutes, seconds)

                                return Tutorial(
                                    id: tutorialData.id,
                                    title: tutorialData.title,
                                    description: tutorialData.description,
                                    duration: formattedDuration,
                                    thumbnailUrl: tutorialData.thumbnailUrlSigned ?? tutorialData.thumbnailUrl ?? "",
                                    videoUrl: tutorialData.videoUrlSigned,
                                    category: tutorialData.tags.first
                                )
                            }

                        continuation.resume(returning: .success(tutorials))
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
