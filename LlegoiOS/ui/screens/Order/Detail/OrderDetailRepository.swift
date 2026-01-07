import Foundation

final class OrderDetailRepository {
    func fetchOrder(status: OrderDetailStatus) async -> OrderDetail {
        let now = Date()
        let placedAt = Calendar.current.date(byAdding: .minute, value: -45, to: now) ?? now
        let statusAt = Calendar.current.date(byAdding: .minute, value: -8, to: now) ?? now

        let items = [
            OrderDetailItem(id: "1", name: "Sandwich de pollo", imageName: "takeoutbag.and.cup.and.straw", quantity: 1, price: 5.50, wasModifiedByStore: false),
            OrderDetailItem(id: "2", name: "Jugo natural", imageName: "cup.and.saucer.fill", quantity: 2, price: 2.25, wasModifiedByStore: true),
            OrderDetailItem(id: "3", name: "Papas fritas", imageName: "leaf", quantity: 1, price: 1.80, wasModifiedByStore: false)
        ]

        let discounts = [
            OrderDetailDiscount(id: "d1", title: "Descuento Premium", amount: 1.50, type: .premium),
            OrderDetailDiscount(id: "d2", title: "Descuento por nivel", amount: 0.75, type: .level)
        ]

        let comments = [
            OrderDetailComment(
                id: "c1",
                author: .business,
                message: "El jugo natural paso a ser de 300ml por disponibilidad.",
                timestamp: Calendar.current.date(byAdding: .minute, value: -7, to: now) ?? now
            ),
            OrderDetailComment(
                id: "c2",
                author: .customer,
                message: "Ok, mantengan el jugo pero con hielo, por favor.",
                timestamp: Calendar.current.date(byAdding: .minute, value: -5, to: now) ?? now
            )
        ]

        return OrderDetail(
            id: "order_123",
            businessName: "Cafe Habana",
            businessImageName: "storefront",
            items: items,
            deliveryFee: 1.20,
            discounts: discounts,
            status: status,
            estimatedTime: (status == .accepted || status == .inProgress) ? "30m" : nil,
            placedAt: placedAt,
            lastStatusAt: statusAt,
            comments: comments
        )
    }
}
