import SwiftUI

struct OrderListView: View {
    @StateObject private var viewModel = OrderListViewModel()
    @StateObject private var gradientManager = GradientStateManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOrderId: String = ""

    var body: some View {
        ZStack {
            // Fondo gradiente sutil
            orderGradientBackground
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: gradientManager.currentCategoryIndex)

            // Con un filtro activo la carga y el vacío se muestran bajo los chips,
            // para que el cliente pueda cambiar de filtro sin quedarse atascado.
            if viewModel.isLoading && viewModel.orders.isEmpty && viewModel.selectedFilter == .all {
                loadingView
            } else if let error = viewModel.errorMessage, viewModel.orders.isEmpty {
                errorView(message: error)
            } else if viewModel.orders.isEmpty && viewModel.selectedFilter == .all {
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
        .fullScreenCover(isPresented: Binding(
            get: { !selectedOrderId.isEmpty },
            set: { if !$0 { selectedOrderId = "" } }
        )) {
            NavigationStack {
                OrderDetailView(orderId: selectedOrderId) {
                    // Recargar la lista cuando se cierra el detalle
                    viewModel.refresh()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        CloseButton {
                            selectedOrderId = ""
                        }
                    }
                }
            }
        }
    }

    // MARK: - Order Gradient Background
    private var orderGradientBackground: some View {
        let palette = gradientManager.getCurrentGradientPalette()

        return ZStack {
            // Base color - muy suave
            palette.veryLight
                .opacity(0.3)

            // Gradiente sutil
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.light.opacity(0.12), location: 0.0),
                    .init(color: palette.veryLight.opacity(0.25), location: 0.4),
                    .init(color: Color.feedBackground(colorScheme).opacity(0.98), location: 1.0)
                ]),
                center: UnitPoint(x: 0.85, y: 0.15),
                startRadius: 10,
                endRadius: 600
            )
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(gradientManager.currentAccentColor)

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
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))

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
                .frame(height: 48)
                .frame(maxWidth: 200)
            }
            .modifier(GlassProminentButtonModifier())
            .tint(gradientManager.currentAccentColor)
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(gradientManager.currentAccentColor.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: "bag.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(gradientManager.currentAccentColor)
            }

            VStack(spacing: 8) {
                Text("Sin pedidos aún")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                Text("Tus pedidos aparecerán aquí una vez que realices tu primera compra")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // La lista se abre desde varias pantallas (home, feed, carrito, perfil):
            // volver atrás deja al cliente donde estaba comprando.
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "storefront")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Empezar a comprar")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .frame(height: 48)
                .frame(maxWidth: 220)
            }
            .modifier(GlassProminentButtonModifier())
            .tint(gradientManager.currentAccentColor)
        }
        .padding()
    }

    // MARK: - Order List Content

    private var orderListContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                OrderStatusFilterView(selectedFilter: viewModel.selectedFilter) { filter in
                    viewModel.select(filter)
                }
                .padding(.horizontal, -20)
                .padding(.top, 8)

                if viewModel.isLoading && viewModel.orders.isEmpty {
                    ProgressView()
                        .tint(gradientManager.currentAccentColor)
                        .padding(.top, 40)
                } else if viewModel.orders.isEmpty {
                    filteredEmptyView
                } else {
                    VStack(spacing: 14) {
                        ForEach(viewModel.orders) { order in
                            Button {
                                selectedOrderId = order.id
                            } label: {
                                RecentOrderCard(order: order)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                viewModel.loadMoreIfNeeded(currentItem: order)
                            }
                        }
                    }
                }

                // Loading more indicator
                if viewModel.isLoadingMore {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(gradientManager.currentAccentColor)

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

    private var filteredEmptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: viewModel.selectedFilter.icon)
                .font(.system(size: 34, weight: .medium))
                .foregroundColor(gradientManager.currentAccentColor.opacity(0.7))
            Text(filteredEmptyMessage)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 48)
        .padding(.horizontal, 24)
    }

    private var filteredEmptyMessage: String {
        switch viewModel.selectedFilter {
        case .actionRequired: return "Nada pendiente por tu parte. ¡Todo en orden!"
        case .active: return "No tienes pedidos en curso."
        case .delivered: return "Aún no tienes pedidos entregados."
        case .cancelled: return "No tienes pedidos cancelados."
        case .all: return "Sin pedidos aún."
        }
    }
}

// MARK: - Status Filter View

struct OrderStatusFilterView: View {
    let selectedFilter: OrderListFilter
    let onSelect: (OrderListFilter) -> Void
    @StateObject private var gradientManager = GradientStateManager.shared

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(OrderListFilter.allCases) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }

    private func filterChip(_ filter: OrderListFilter) -> some View {
        let isSelected = selectedFilter == filter
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onSelect(filter)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark" : filter.icon)
                    .fontWeight(.semibold)
                    .font(.system(size: 14))
                Text(filter.title)
                    .fontWeight(.semibold)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
        }
        .modifier(GlassProminentButtonModifier())
        .buttonBorderShape(.capsule)
        .clipShape(Capsule())
        .compositingGroup()
        .tint(isSelected ? gradientManager.currentAccentColor : Color.gray)
        .overlay {
            if isSelected {
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.2)
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct GlassProminentButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    NavigationStack {
        OrderListView()
    }
}
