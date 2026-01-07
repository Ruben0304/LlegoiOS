import Foundation
import Combine

@MainActor
final class OrderDetailViewModel: ObservableObject {
    @Published var order: OrderDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository = OrderDetailRepository()
    private var newItemCounter = 1
    private let status: OrderDetailStatus

    init(status: OrderDetailStatus) {
        self.status = status
        Task {
            await load()
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        order = await repository.fetchOrder(status: status)
        isLoading = false
    }

    func incrementItem(_ item: OrderDetailItem) {
        updateItem(item) { $0.quantity += 1 }
    }

    func decrementItem(_ item: OrderDetailItem) {
        updateItem(item) { current in
            current.quantity = max(current.quantity - 1, 0)
        }
        removeEmptyItems()
    }

    func addItem() {
        guard var order else { return }
        let newItem = OrderDetailItem(
            id: "new_\(newItemCounter)",
            name: "Item adicional \(newItemCounter)",
            imageName: "cart",
            quantity: 1,
            price: 1.25,
            wasModifiedByStore: false
        )
        newItemCounter += 1
        order.items.append(newItem)
        self.order = order
    }

    func cancelOrder() {
        guard var order else { return }
        order.status = .cancelled
        order.lastStatusAt = Date()
        self.order = order
    }

    func acceptOrder() {
        guard var order else { return }
        order.status = .accepted
        order.lastStatusAt = Date()
        self.order = order
    }

    func payOrder() {
        guard var order else { return }
        order.status = .inProgress
        order.lastStatusAt = Date()
        self.order = order
    }

    func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func updateItem(_ item: OrderDetailItem, update: (inout OrderDetailItem) -> Void) {
        guard var order else { return }
        guard let index = order.items.firstIndex(where: { $0.id == item.id }) else { return }
        var updatedItem = order.items[index]
        update(&updatedItem)
        order.items[index] = updatedItem
        self.order = order
    }

    private func removeEmptyItems() {
        guard var order else { return }
        order.items.removeAll { $0.quantity == 0 }
        self.order = order
    }
}
