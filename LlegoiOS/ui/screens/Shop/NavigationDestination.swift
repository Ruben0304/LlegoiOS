
// MARK: - Navigation Destination
enum NavigationDestination: Identifiable, Hashable {
    case detail(Store)
    case shop(branchId: String, branchName: String, storeGradient: ExtractedGradient? = nil)
    case home

    var id: String {
        switch self {
        case .detail(let store): return "detail-\(store.id)"
        case .shop(let branchId, _, _): return "shop-\(branchId)"
        case .home: return "home"
        }
    }

    // Manual Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Manual Equatable conformance
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        lhs.id == rhs.id
    }
}
