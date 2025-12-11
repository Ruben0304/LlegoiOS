
// MARK: - Navigation Destination
enum NavigationDestination: Identifiable {
    case detail(Store)
    case home
    
    var id: String {
        switch self {
        case .detail(let store): return "detail-\(store.id)"
        case .home: return "home"
        }
    }
}
