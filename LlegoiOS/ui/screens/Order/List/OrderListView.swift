import SwiftUI

struct OrderListView: View {
    @StateObject private var viewModel = OrderListViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background
            Color.llegoBackground.ignoresSafeArea()

            if viewModel.isLoading && viewModel.orders.isEmpty {
                loadingView
            } else if let error = viewModel.errorMessage, viewModel.orders.isEmpty {
                errorView(message: error)
            } else if viewModel.orders.isEmpty {
                emptyStateView
            } else {
                orderListContent
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

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.llegoPrimary)

            Text("Cargando pedidos...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 8) {
                Text("Algo salió mal")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(message)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                viewModel.loadOrders()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Reintentar")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(height: 48)
                .frame(maxWidth: 200)
            }
            .buttonStyle(.glassProminent)
            .tint(.llegoPrimary)
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.llegoPrimary.opacity(0.15), Color.llegoAccent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "bag.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.llegoPrimary, Color.llegoAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Sin pedidos aún")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Tus pedidos aparecerán aquí una vez que realices tu primera compra")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                // Navigate to store list or home
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "storefront")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Explorar tiendas")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(height: 48)
                .frame(maxWidth: 220)
            }
            .buttonStyle(.glassProminent)
            .tint(.llegoPrimary)
        }
        .padding()
    }

    // MARK: - Order List Content

    private var orderListContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Status filter chips
                OrderStatusFilterView(selectedStatus: $viewModel.selectedStatus) { status in
                    viewModel.filterByStatus(status)
                }
                .padding(.top, 8)

                // Orders list
                VStack(spacing: 14) {
                    ForEach(viewModel.orders) { order in
                        NavigationLink(destination: OrderDetailView(orderId: order.id)) {
                            RecentOrderCard(order: order)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            viewModel.loadMoreIfNeeded(currentItem: order)
                        }
                    }
                }

                // Loading more indicator
                if viewModel.isLoadingMore {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.llegoPrimary)

                        Text("Cargando más...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .refreshable {
            viewModel.refresh()
        }
    }
}

// MARK: - Status Filter View

struct OrderStatusFilterView: View {
    @Binding var selectedStatus: OrderStatusEnum?
    let onSelect: (OrderStatusEnum?) -> Void
    @Environment(\.colorScheme) private var colorScheme

    private let statuses: [(OrderStatusEnum?, String, String)] = [
        (nil, "Todos", "square.grid.2x2"),
        (.pendingAcceptance, "Pendientes", "clock.fill"),
        (.onTheWay, "En camino", "car.fill"),
        (.delivered, "Entregados", "checkmark.circle.fill"),
        (.cancelled, "Cancelados", "xmark.circle.fill")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(statuses, id: \.1) { status, label, icon in
                    filterChip(status: status, label: label, icon: icon)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func filterChip(status: OrderStatusEnum?, label: String, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onSelect(status)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(label)
                    .font(.system(size: 14, weight: selectedStatus == status ? .bold : .semibold, design: .rounded))
            }
            .foregroundColor(selectedStatus == status ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Group {
                    if selectedStatus == status {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.llegoPrimary, Color.llegoPrimary.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.llegoPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }
                }
            )
        }
    }
}

#Preview {
    NavigationStack {
        OrderListView()
    }
}
