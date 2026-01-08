import SwiftUI

struct OrderListView: View {
    @StateObject private var viewModel = OrderListViewModel()
    
    var body: some View {
        ZStack {
            Color.llegoBackground.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.orders.isEmpty {
                ProgressView()
            } else if let error = viewModel.errorMessage, viewModel.orders.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Reintentar") {
                        viewModel.loadOrders()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if viewModel.orders.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bag")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No tienes pedidos aún")
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Status filter chips
                        OrderStatusFilterView(selectedStatus: $viewModel.selectedStatus) { status in
                            viewModel.filterByStatus(status)
                        }
                        .padding(.horizontal, 20)
                        
                        ForEach(viewModel.orders) { order in
                            NavigationLink(destination: OrderDetailView(orderId: order.id)) {
                                RecentOrderCard(order: order)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                viewModel.loadMoreIfNeeded(currentItem: order)
                            }
                        }
                        
                        if viewModel.isLoadingMore {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                }
                .refreshable {
                    viewModel.refresh()
                }
            }
        }
        .navigationTitle("Mis Pedidos")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if viewModel.orders.isEmpty {
                viewModel.loadOrders()
            }
        }
    }
}

// MARK: - Status Filter View

struct OrderStatusFilterView: View {
    @Binding var selectedStatus: OrderStatusEnum?
    let onSelect: (OrderStatusEnum?) -> Void
    
    private let statuses: [(OrderStatusEnum?, String)] = [
        (nil, "Todos"),
        (.pendingAcceptance, "Pendientes"),
        (.onTheWay, "En camino"),
        (.delivered, "Entregados"),
        (.cancelled, "Cancelados")
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(statuses, id: \.1) { status, label in
                    Button {
                        onSelect(status)
                    } label: {
                        Text(label)
                            .font(.subheadline)
                            .fontWeight(selectedStatus == status ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedStatus == status ? Color.llegoPrimary : Color.white
                            )
                            .foregroundColor(
                                selectedStatus == status ? .white : .primary
                            )
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: selectedStatus == status ? 0 : 1)
                            )
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        OrderListView()
    }
}
