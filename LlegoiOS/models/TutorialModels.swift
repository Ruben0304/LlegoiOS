import Foundation

// MARK: - Tutorial Model
struct Tutorial: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let duration: String // e.g., "5:32"
    let thumbnailUrl: String
    let videoUrl: String
    let category: String? // e.g., "Cómo usar la app", "Tips de compra"

    init(id: String, title: String, description: String, duration: String, thumbnailUrl: String, videoUrl: String, category: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.duration = duration
        self.thumbnailUrl = thumbnailUrl
        self.videoUrl = videoUrl
        self.category = category
    }
}
