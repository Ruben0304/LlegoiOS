import Foundation

/// Promotional video shown in the Instagram-stories style player.
struct PromotionalVideo: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let duration: Int  // seconds (0 if unknown)
    let videoUrl: String  // presigned streaming URL
    let thumbnailUrl: String?
    let branchName: String?
    let branchAvatarUrl: String?
}
