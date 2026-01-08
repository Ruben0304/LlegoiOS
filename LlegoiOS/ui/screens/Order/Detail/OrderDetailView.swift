import SwiftUI

struct OrderDetailView: View {
    @StateObject private var viewModel: OrderDetailViewModel
    @State private var showCancelAlert = false

    init(orderId: String) {
        _viewModel = StateObject(wrappedValue: OrderDetailViewModel(orderId: orderId))
    }

    var body: some View {
        ZStack {
            Color.llegoBackground.ignoresSafeArea()

            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if let order = viewModel.order {
                    VStack(spacing: 18) {
                        headerSection(order)
                        itemsSection(order)
                        if !order.comments.isEmpty {
                            commentsSection(order)
                        }
                        pricingSection(order)
                        deliverySection(order)
                        if !order.timeline.isEmpty {
                            timelineSection(order)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                        Button("Reintentar") { viewModel.load() }
                            .buttonStyle(.bordered)
                    }
                    .padding(.top, 40)
                }
            }
            .refreshable { viewModel.refresh() }
            
            // Bottom action buttons
            if let order = viewModel.order {
                VStack {
                    Spacer()
                    bottomActions(order)
                }
            }
        }
        .navigationTitle("Pedido #\(viewModel.order?.orderNumber.suffix(6) ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cancelar Pedido", isPresented: $showCancelAlert) {
            Button("No", role: .cancel) { }
            Button("Sí, cancelar", role: .destructive) { viewModel.cancelOrder() }
        } message: {
            Text("¿Estás seguro de que deseas cancelar este pedido?")
        }
    }


    // MARK: - Header Section
    
    private func headerSection(_ order: OrderDetail) -> some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    // Store image
                    AsyncImage(url: URL(string: order.branchImageUrl ?? "")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "storefront")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 48, height: 48)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(order.branchName)
                            .font(.headline)
                        Text(order.orderNumber)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                    statusBadge(order.status)
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(order.formattedTotal)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    if let eta = order.estimatedMinutesRemaining {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Tiempo estimado")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(eta) min")
                                .font(.headline)
                                .foregroundColor(.llegoPrimary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Items Section
    
    private func itemsSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Items")
                    .font(.headline)
                if order.isEditable {
                    Text("• Editable")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                Spacer()
            }

            card {
                VStack(spacing: 0) {
                    ForEach(Array(order.items.enumerated()), id: \.element.id) { index, item in
                        itemRow(item)
                        if index != order.items.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
        }
    }

    private func itemRow(_ item: OrderDetailItem) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if item.wasModifiedByStore {
                        Text("Modificado")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                Text("x\(item.quantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(item.formattedLineTotal)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 10)
    }


    // MARK: - Pricing Section
    
    private func pricingSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resumen")
                .font(.headline)

            card {
                VStack(spacing: 10) {
                    priceRow(title: "Subtotal", value: order.formattedSubtotal)
                    priceRow(title: "Envío", value: order.formattedDeliveryFee)

                    ForEach(order.discounts) { discount in
                        priceRow(title: discount.title, value: discount.formattedAmount, valueColor: .green)
                    }

                    Divider()
                    priceRow(title: "Total", value: order.formattedTotal, isEmphasis: true)
                }
            }
        }
    }

    private func priceRow(title: String, value: String, valueColor: Color = .primary, isEmphasis: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(isEmphasis ? .subheadline : .caption)
                .fontWeight(isEmphasis ? .semibold : .regular)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(isEmphasis ? .headline : .subheadline)
                .fontWeight(isEmphasis ? .bold : .medium)
                .foregroundColor(valueColor)
        }
    }

    // MARK: - Delivery Section
    
    private func deliverySection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Entrega")
                .font(.headline)

            card {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.llegoPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(order.deliveryAddress.street)
                                .font(.subheadline)
                            if let city = order.deliveryAddress.city {
                                Text(city)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if let deliveryPerson = order.deliveryPerson {
                        Divider()
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: deliveryPerson.profileImageUrl ?? "")) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(deliveryPerson.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.yellow)
                                    Text(deliveryPerson.formattedRating)
                                        .font(.caption)
                                    Text("• \(deliveryPerson.vehicleType)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Button {
                                if let url = URL(string: "tel:\(deliveryPerson.phone)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.llegoPrimary)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
        }
    }


    // MARK: - Timeline Section
    
    private func timelineSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Timeline")
                .font(.headline)

            card {
                VStack(spacing: 0) {
                    ForEach(Array(order.timeline.enumerated()), id: \.element.id) { index, event in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(event.status.color)
                                    .frame(width: 12, height: 12)
                                if index < order.timeline.count - 1 {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 2)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 12)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.message)
                                    .font(.subheadline)
                                Text(event.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.bottom, index < order.timeline.count - 1 ? 16 : 0)

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Comments Section
    
    private func commentsSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Comentarios")
                .font(.headline)

            card {
                VStack(spacing: 10) {
                    ForEach(order.comments) { comment in
                        commentBubble(comment)
                    }
                }
            }
        }
    }

    private func commentBubble(_ comment: OrderDetailComment) -> some View {
        HStack {
            if comment.author == .business { Spacer(minLength: 40) }

            VStack(alignment: comment.author == .customer ? .leading : .trailing, spacing: 4) {
                Text(comment.message)
                    .font(.subheadline)
                Text(comment.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(comment.author == .customer ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
            )

            if comment.author == .customer { Spacer(minLength: 40) }
        }
    }

    // MARK: - Bottom Actions
    
    private func bottomActions(_ order: OrderDetail) -> some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                if order.canCancel {
                    Button {
                        showCancelAlert = true
                    } label: {
                        Text("Cancelar")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                    }
                }

                if order.status == .modifiedByStore {
                    Button {
                        viewModel.acceptModifications()
                    } label: {
                        Text("Aceptar cambios")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.llegoPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }

                if order.status == .onTheWay || order.status == .preparing {
                    NavigationLink(destination: OrderTrackingView(orderId: order.id)) {
                        Text("Ver tracking")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.llegoPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }

    // MARK: - Helpers
    
    private func statusBadge(_ status: OrderStatusEnum) -> some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(status.color.opacity(0.15))
        .foregroundColor(status.color)
        .cornerRadius(12)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        OrderDetailView(orderId: "test-order-id")
    }
}
