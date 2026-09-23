import Foundation
import Combine

enum OrderListFilter: String, CaseIterable, Identifiable {
    case all
    case actionRequired
    case active
    case delivered
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todos"
        case .actionRequired: return "Requieren acción"
        case .active: return "Activos"
        case .delivered: return "Entregados"
        case .cancelled: return "Cancelados"
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .actionRequired: return "exclamationmark.circle.fill"
        case .active: return "clock.fill"
        case .delivered: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    /// Filtro que entiende el backend (un único estado). Los grupos se filtran en cliente.
    var backendStatus: OrderStatusEnum? {
        switch self {
        case .delivered: return .delivered
        case .cancelled: return .cancelled
        case .all, .actionRequired, .active: return nil
        }
    }

    var needsClientFiltering: Bool {
        self == .actionRequired || self == .active
    }

    func matches(_ order: RecentOrder) -> Bool {
        switch self {
        case .all, .delivered, .cancelled: return true
        case .actionRequired: return order.displayStatus.requiresCustomerAction
        case .active: return order.displayStatus.isActive
        }
    }
}

@MainActor
final class OrderListViewModel: ObservableObject {
    @Published var orders: [RecentOrder] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var selectedFilter: OrderListFilter = .all

    private let repository = OrderListRepository()
    private var hasMore = false
    private var currentOffset = 0
    private let pageSize = 20
    /// Evita que la respuesta de un filtro anterior pise la del filtro actual.
    private var requestGeneration = 0

    // MARK: - Load Orders

    func loadOrders() {
        requestGeneration += 1
        let generation = requestGeneration
        let filter = selectedFilter

        isLoading = true
        isLoadingMore = false
        errorMessage = nil
        currentOffset = 0

        repository.fetchOrders(
            status: filter.backendStatus,
            limit: pageSize,
            offset: 0
        ) { [weak self] result in
            Task { @MainActor in
                guard let self = self, generation == self.requestGeneration else { return }
                self.isLoading = false

                switch result {
                case .success(let data):
                    self.orders = data.orders.filter(filter.matches)
                    self.hasMore = data.hasMore
                    self.currentOffset = data.orders.count
                    self.fillPageIfNeeded(lastPageMatches: self.orders.count)

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Load More (Pagination)

    func loadMoreIfNeeded(currentItem: RecentOrder?) {
        guard let currentItem = currentItem else { return }

        let thresholdIndex = orders.index(orders.endIndex, offsetBy: -min(3, orders.count))
        if let itemIndex = orders.firstIndex(where: { $0.id == currentItem.id }),
           itemIndex >= thresholdIndex,
           hasMore,
           !isLoadingMore {
            loadMore()
        }
    }

    private func loadMore() {
        guard hasMore, !isLoadingMore else { return }

        let generation = requestGeneration
        let filter = selectedFilter
        isLoadingMore = true

        repository.fetchOrders(
            status: filter.backendStatus,
            limit: pageSize,
            offset: currentOffset
        ) { [weak self] result in
            Task { @MainActor in
                guard let self = self, generation == self.requestGeneration else { return }
                self.isLoadingMore = false

                switch result {
                case .success(let data):
                    let matching = data.orders.filter(filter.matches)
                    self.orders.append(contentsOf: matching)
                    self.hasMore = data.hasMore
                    self.currentOffset += data.orders.count
                    self.fillPageIfNeeded(lastPageMatches: matching.count)

                case .failure(let error):
                    print("❌ Error loading more orders: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Con filtros de cliente una página del backend puede traer pocos o ningún pedido
    /// que encaje. Sin esto la lista se quedaba corta y el scroll no pedía más.
    private func fillPageIfNeeded(lastPageMatches: Int) {
        guard selectedFilter.needsClientFiltering, hasMore else { return }
        if orders.count < pageSize || lastPageMatches == 0 {
            loadMore()
        }
    }

    // MARK: - Filter

    func select(_ filter: OrderListFilter) {
        guard filter != selectedFilter else { return }
        selectedFilter = filter
        loadOrders()
    }

    // MARK: - Refresh

    func refresh() {
        loadOrders()
    }
}
