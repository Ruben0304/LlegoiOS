import Foundation
import SwiftUI
import Combine

// MARK: - View State
enum StoreDetailState {
    case idle
    case loading
    case success(BranchDetailGraphQL)
    case error(String)
}

// MARK: - StoreDetailViewModel
@MainActor
class StoreDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var state: StoreDetailState = .idle
    @Published var branchDetail: BranchDetailGraphQL?
    @Published var businessDetail: BusinessDetailGraphQL?
    @Published var siblingBranches: [BranchGraphQL] = []
    @Published var branchProducts: [StoreProductGraphQL] = []
    @Published var branchCombos: [ComboDetailGraphQL] = []
    @Published var branchShowcases: [ShowcaseGraphQL] = []
    @Published var isLoadingSiblings: Bool = false
    @Published var isLoadingProducts: Bool = false
    @Published var isLoadingCombos: Bool = false
    @Published var isLoadingShowcases: Bool = false

    // MARK: - Computed Properties
    var isLoading: Bool {
        if case .loading = state {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = state {
            return message
        }
        return nil
    }

    var socialMedia: [String: String]? {
        businessDetail?.socialMedia
    }

    var hasCoordinates: Bool {
        guard let coords = branchDetail?.coordinates else { return false }
        return coords.latitude != 0.0 && coords.longitude != 0.0
    }

    // MARK: - Dependencies
    private let repository = StoreDetailRepository()
    private let comboRepository = ComboDetailRepository()

    // Default images - Empty strings to trigger AsyncImage failure -> shows generic assets
    private let defaultLogoUrl = ""
    private let defaultBannerUrl = ""

    // MARK: - Public Methods
    func loadBranchDetail(id: String) {
        state = .loading

        repository.fetchBranchDetail(id: id) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let detail):
                    self.branchDetail = detail
                    self.state = .success(detail)
                    print("✅ StoreDetailViewModel: Loaded details for branch \(id)")

                    // Load related data
                    self.loadBusinessDetail(businessId: detail.businessId)
                    self.loadSiblingBranches(businessId: detail.businessId, currentBranchId: id)
                    self.loadBranchProducts(branchId: id)
                    self.loadBranchCombos(branchId: id)
                    self.loadBranchShowcases(branchId: id)

                case .failure(let error):
                    let message = "Error al cargar detalles: \(error.localizedDescription)"
                    print("❌ StoreDetailViewModel FAILURE: \(message)")
                    // Solo actualiza el estado de error si no tenemos datos previos
                    if self.branchDetail == nil {
                        self.state = .error(message)
                    }
                }
            }
        }
    }

    func loadBusinessDetail(businessId: String) {
        repository.fetchBusinessDetail(id: businessId) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let business):
                    self.businessDetail = business
                    print("✅ StoreDetailViewModel: Loaded business details")

                case .failure(let error):
                    print("⚠️ StoreDetailViewModel: Failed to load business details: \(error.localizedDescription)")
                    // Don't fail the whole view if business details fail
                }
            }
        }
    }

    func loadSiblingBranches(businessId: String, currentBranchId: String) {
        isLoadingSiblings = true

        repository.fetchSiblingBranches(businessId: businessId) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoadingSiblings = false

                switch result {
                case .success(let branches):
                    // Filter out current branch
                    self.siblingBranches = branches.filter { $0.id != currentBranchId }
                    print("✅ StoreDetailViewModel: Loaded \(self.siblingBranches.count) sibling branches")

                case .failure(let error):
                    print("⚠️ StoreDetailViewModel: Failed to load sibling branches: \(error.localizedDescription)")
                    // Don't fail the whole view if sibling branches fail
                    self.siblingBranches = []
                }
            }
        }
    }

    func loadBranchProducts(branchId: String, limit: Int = 10) {
        isLoadingProducts = true

        repository.fetchBranchProducts(branchId: branchId, limit: limit) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoadingProducts = false

                switch result {
                case .success(let products):
                    self.branchProducts = products
                    print("✅ StoreDetailViewModel: Loaded \(products.count) products for branch")

                case .failure(let error):
                    print("⚠️ StoreDetailViewModel: Failed to load branch products: \(error.localizedDescription)")
                    // Don't fail the whole view if products fail
                    self.branchProducts = []
                }
            }
        }
    }

    func loadBranchCombos(branchId: String) {
        isLoadingCombos = true

        comboRepository.fetchCombosByBranch(branchId: branchId) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoadingCombos = false

                switch result {
                case .success(let combos):
                    self.branchCombos = combos
                    print("✅ StoreDetailViewModel: Loaded \(combos.count) combos for branch")

                case .failure(let error):
                    print("⚠️ StoreDetailViewModel: Failed to load combos: \(error.localizedDescription)")
                    self.branchCombos = []
                }
            }
        }
    }

    func loadBranchShowcases(branchId: String) {
        isLoadingShowcases = true

        repository.fetchShowcases(branchId: branchId) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoadingShowcases = false

                switch result {
                case .success(let showcases):
                    self.branchShowcases = showcases
                    print("✅ StoreDetailViewModel: Loaded \(showcases.count) showcases for branch")
                case .failure(let error):
                    print("⚠️ StoreDetailViewModel: Failed to load showcases: \(error.localizedDescription)")
                    self.branchShowcases = []
                }
            }
        }
    }

    // MARK: - Branch Likes
    func toggleLike(branchId: String) {
        BranchLikesManager.shared.toggleLike(branchId: branchId)
    }

    func isLiked(branchId: String) -> Bool {
        return BranchLikesManager.shared.isLiked(branchId: branchId)
    }

    // MARK: - Helper Methods
    func calculateETA(deliveryRadius: Double?) -> Int {
        // Estimación simple: 5 minutos por km + 10 minutos base
        guard let radius = deliveryRadius else { return 20 }
        return Int(radius * 5 + 10)
    }

    func getLogoUrl() -> String {
        branchDetail?.avatarUrl ?? defaultLogoUrl
    }

    func getBannerUrl() -> String {
        branchDetail?.coverUrl ?? defaultBannerUrl
    }

    func getSocialMediaUrl(for platform: String) -> String? {
        guard let socialMedia = businessDetail?.socialMedia,
              let urlString = socialMedia[platform] else {
            return nil
        }
        return urlString
    }
}
