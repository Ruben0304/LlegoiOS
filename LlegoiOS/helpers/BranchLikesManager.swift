import Foundation
import Combine
import Apollo

@MainActor
class BranchLikesManager: ObservableObject {
    static let shared = BranchLikesManager()

    @Published private(set) var localLikes: [BranchLikeLocal] = []
    @Published private(set) var likedBranchCount: Int = 0

    private let userDefaults = UserDefaults.standard
    private let likesKey = "llego_branch_likes"
    private let apolloClient = ApolloClientManager.shared.apollo

    private init() {
        loadLikes()
        updateLikeCount()
    }

    // MARK: - Public Methods

    func addLike(branchId: String) {
        var likes = localLikes

        guard !likes.contains(where: { $0.branchId == branchId }) else {
            return
        }

        likes.append(BranchLikeLocal(branchId: branchId))
        saveLikes(likes)
        print("❤️ Added like for branch ID: '\(branchId)'")

        // Llamar a la mutation en el backend
        sendLikeBranchMutation(branchId: branchId)
    }

    func removeLike(branchId: String) {
        var likes = localLikes
        likes.removeAll { $0.branchId == branchId }
        saveLikes(likes)
        print("🗑️ Removed like for branch ID: '\(branchId)'")

        // Llamar a la mutation en el backend
        sendUnlikeBranchMutation(branchId: branchId)
    }

    func toggleLike(branchId: String) {
        if isLiked(branchId: branchId) {
            removeLike(branchId: branchId)
        } else {
            addLike(branchId: branchId)
        }
    }

    func isLiked(branchId: String) -> Bool {
        localLikes.contains(where: { $0.branchId == branchId })
    }

    func clearLikes() {
        userDefaults.removeObject(forKey: likesKey)
        localLikes = []
        updateLikeCount()
        print("🧹 Branch likes cleared")
    }

    // MARK: - Private Methods

    private func saveLikes(_ likes: [BranchLikeLocal]) {
        let encoded = likes.map { $0.branchId }
        userDefaults.set(encoded, forKey: likesKey)
        localLikes = likes
        updateLikeCount()
    }

    private func loadLikes() {
        let ids = userDefaults.stringArray(forKey: likesKey) ?? []
        localLikes = ids.map { BranchLikeLocal(branchId: $0) }
    }

    private func updateLikeCount() {
        likedBranchCount = localLikes.count
    }

    /// Enviar mutation likeBranch al backend (sin bloquear la UI)
    private func sendLikeBranchMutation(branchId: String) {
        Task {
            do {
                // Obtener JWT si está disponible
                let jwt = await AuthManager.shared.getAccessToken()

                // Llamar a la mutation de manera asíncrona
                _ = try await apolloClient.perform(mutation: LlegoAPI.LikeBranchMutation(
                    branchId: branchId,
                    jwt: jwt.map { .some($0) } ?? .none
                ))

                print("📊 Branch like sent to backend: \(branchId)")
            } catch {
                // Silenciosamente fallar - el like local ya está guardado
                print("⚠️ Failed to send branch like to backend: \(error.localizedDescription)")
            }
        }
    }

    /// Enviar mutation unlikeBranch al backend (sin bloquear la UI)
    private func sendUnlikeBranchMutation(branchId: String) {
        Task {
            do {
                // Obtener JWT si está disponible
                let jwt = await AuthManager.shared.getAccessToken()

                // Llamar a la mutation de manera asíncrona
                _ = try await apolloClient.perform(mutation: LlegoAPI.UnlikeBranchMutation(
                    branchId: branchId,
                    jwt: jwt.map { .some($0) } ?? .none
                ))

                print("📊 Branch unlike sent to backend: \(branchId)")
            } catch {
                // Silenciosamente fallar - el unlike local ya está guardado
                print("⚠️ Failed to send branch unlike to backend: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Local Model
struct BranchLikeLocal: Identifiable, Codable {
    let id = UUID()
    let branchId: String
}
