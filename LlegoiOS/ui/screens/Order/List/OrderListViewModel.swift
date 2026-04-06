import Foundation
import Combine

@MainActor
final class OrderListViewModel: ObservableObject {
    @Published var orders: [RecentOrder] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var selectedStatus: OrderStatusEnum?
    
    private let repository = OrderListRepository()
    private var totalCount = 0
    private var hasMore = false
    private var currentOffset = 0
    private let pageSize = 20
    private let actionRequiredStatuses: Set<OrderStatusEnum> = [
        .pendingAcceptance,
        .modifiedByStore,
        .rejectedByStore,
        .awaitingDeliveryAcceptance,
        .pendingPayment,
        .paymentInProgress,
    ]
    
    // MARK: - Load Orders
    
    func loadOrders() {
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        
        repository.fetchOrders(
            status: backendStatusForSelectedFilter(),
            limit: pageSize,
            offset: 0
        ) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let data):
                    self.orders = self.applyFilter(data.orders)
                    self.totalCount = data.totalCount
                    self.hasMore = data.hasMore
                    self.currentOffset = data.orders.count
                    
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
        
        isLoadingMore = true
        
        repository.fetchOrders(
            status: backendStatusForSelectedFilter(),
            limit: pageSize,
            offset: currentOffset
        ) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoadingMore = false
                
                switch result {
                case .success(let data):
                    self.orders.append(contentsOf: self.applyFilter(data.orders))
                    self.hasMore = data.hasMore
                    self.currentOffset += data.orders.count
                    
                case .failure(let error):
                    print("❌ Error loading more orders: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Filter by Status
    
    func filterByStatus(_ status: OrderStatusEnum?) {
        selectedStatus = status
        loadOrders()
    }
    
    // MARK: - Refresh
    
    func refresh() {
        loadOrders()
    }

    private func backendStatusForSelectedFilter() -> OrderStatusEnum? {
        // "Pendientes" en UI incluye estados que requieren acción del cliente.
        if selectedStatus == .pendingAcceptance {
            return nil
        }
        return selectedStatus
    }

    private func applyFilter(_ incoming: [RecentOrder]) -> [RecentOrder] {
        guard selectedStatus == .pendingAcceptance else {
            return incoming
        }
        return incoming.filter { actionRequiredStatuses.contains($0.status.normalizedForContract) }
    }
}
