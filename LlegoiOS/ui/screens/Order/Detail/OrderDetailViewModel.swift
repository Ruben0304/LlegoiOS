import Foundation
import Combine

@MainActor
final class OrderDetailViewModel: ObservableObject {
    @Published var order: OrderDetail?
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var newComment: String = ""

    private let repository = OrderDetailRepository()
    private let orderId: String

    init(orderId: String) {
        self.orderId = orderId
        load()
    }

    // MARK: - Load Order
    
    func load() {
        isLoading = true
        errorMessage = nil
        
        repository.fetchOrder(id: orderId) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let detail):
                    self.order = detail
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Refresh
    
    func refresh() {
        load()
    }

    // MARK: - Accept Modifications
    
    func acceptModifications() {
        guard let order = order, order.status == .modifiedByStore else { return }
        
        isProcessing = true
        errorMessage = nil
        
        repository.acceptModifications(orderId: orderId) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isProcessing = false
                
                switch result {
                case .success(let updatedOrder):
                    self.order = updatedOrder
                    self.successMessage = "Modificaciones aceptadas"
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Cancel Order
    
    func cancelOrder(reason: String? = nil) {
        guard let order = order, order.canCancel else { return }
        
        isProcessing = true
        errorMessage = nil
        
        repository.cancelOrder(orderId: orderId, reason: reason) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isProcessing = false
                
                switch result {
                case .success(let updatedOrder):
                    self.order = updatedOrder
                    self.successMessage = "Pedido cancelado"
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Add Comment
    
    func sendComment() {
        let message = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        isProcessing = true
        
        repository.addComment(orderId: orderId, message: message) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isProcessing = false
                
                switch result {
                case .success:
                    self.newComment = ""
                    self.load() // Reload to get updated comments
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Formatting Helpers
    
    func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, HH:mm"
        formatter.locale = Locale(identifier: "es")
        return formatter.string(from: date)
    }
    
    // MARK: - Computed Properties
    
    var canAcceptModifications: Bool {
        order?.status == .modifiedByStore
    }
    
    var canCancelOrder: Bool {
        order?.canCancel ?? false
    }
    
    var showDeliveryPerson: Bool {
        guard let status = order?.status else { return false }
        return status == .onTheWay || status == .readyForPickup
    }
    
    var showTimeline: Bool {
        !(order?.timeline.isEmpty ?? true)
    }
}
