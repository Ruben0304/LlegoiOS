import SwiftUI

struct OrderDetailView: View {
    @StateObject private var viewModel: OrderDetailViewModel

    init(status: OrderDetailStatus = .modifiedByStore) {
        _viewModel = StateObject(wrappedValue: OrderDetailViewModel(status: status))
    }

    var body: some View {
        NavigationStack {
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
                            commentsSection(order)
                            pricingSection(order)
                            statusSection(order)
                            timingSection(order)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                    }
                }
            }
            .navigationTitle("Pedido")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let order = viewModel.order {
                    if order.status == .pendingAcceptance {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                viewModel.cancelOrder()
                            }) {
                                Text("Cancelar")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    }

                    if order.status == .modifiedByStore {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                viewModel.cancelOrder()
                            }) {
                                Text("Cancelar")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }

                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                viewModel.acceptOrder()
                            }) {
                                Text("Aceptar")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                    }

                    if order.status == .accepted, let estimatedTime = order.estimatedTime {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {}) {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock")
                                    Text("~\(estimatedTime)")
                                }
                            
                            }
                            
                        }

                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                viewModel.payOrder()
                            }) {
                                Text("Pagar")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.llegoPrimary)
                        }
                    }

                    if order.status == .inProgress, let estimatedTime = order.estimatedTime {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {}) {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock")
                                    Text("~\(estimatedTime)")
                                }
                            
                            }
                            
                        }
                    }
                }
            }
        }
    }

    private func headerSection(_ order: OrderDetail) -> some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    HStack(spacing: 12) {
                        Image(systemName: order.businessImageName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.04))
                            )

                        VStack(alignment: .leading, spacing: 4) {
                        Text(order.businessName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.llegoPrimary)

                        Text("Pedido #\(order.id)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                        }
                    }

                    Spacer()

                    statusBadge(order.status)
                }

                Text("Total: \(viewModel.formatCurrency(order.total))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.llegoPrimary)
            }
        }
    }

    private func timingSection(_ order: OrderDetail) -> some View {
        card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Creado")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)

                    Text(viewModel.formatTime(order.placedAt))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.llegoPrimary)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ultimo estado")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)

                    Text(viewModel.formatTime(order.lastStatusAt))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.llegoPrimary)
                }

                Spacer()
            }
        }
    }

    private func itemsSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Items")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.llegoPrimary)

                if order.isEditable {
                    Text("Editable")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                }

                Spacer()
            }

            card {
                VStack(spacing: 0) {
                    ForEach(Array(order.items.enumerated()), id: \.element.id) { index, item in
                        itemRow(item, editable: order.isEditable)

                        if index != order.items.count - 1 {
                            Divider()
                                .padding(.leading, 12)
                        }
                    }

                }
            }
        }
    }

    private func pricingSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resumen")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.llegoPrimary)

            card {
                VStack(spacing: 10) {
                    priceRow(title: "Subtotal", value: viewModel.formatCurrency(order.subtotal))
                    priceRow(title: "Envio", value: viewModel.formatCurrency(order.deliveryFee))

                    ForEach(order.discounts) { discount in
                        let formatted = "-\(viewModel.formatCurrency(discount.amount))"
                        priceRow(title: discount.title, value: formatted, valueColor: .green)
                    }

                    Divider()

                    priceRow(title: "Total", value: viewModel.formatCurrency(order.total), isEmphasis: true)
                }
            }
        }
    }

    private func statusSection(_ order: OrderDetail) -> some View {
        card {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(order.status.accentColor)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text(order.status.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.llegoPrimary)

                    Text(statusSubtitle(order.status))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()
            }
        }
    }

    private func commentsSection(_ order: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Comentarios")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.llegoPrimary)

            if order.comments.isEmpty {
                card {
                    Text("Sin comentarios")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            } else {
                card {
                    VStack(spacing: 10) {
                        ForEach(order.comments) { comment in
                            commentBubble(comment)
                        }
                    }
                }
            }
        }
    }

    private func itemRow(_ item: OrderDetailItem, editable: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.imageName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.gray)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.04))
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.llegoPrimary)

                    if item.wasModifiedByStore {
                        Text("Modificado")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.12))
                            )
                    }
                }

                Text("Cantidad: \(item.quantity)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(viewModel.formatCurrency(item.lineTotal))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.llegoPrimary)

                if editable && item.wasModifiedByStore {
                    HStack(spacing: 8) {
                        Button(action: {
                            viewModel.decrementItem(item)
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 12, weight: .semibold))
                        }

                        Text("\(item.quantity)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.llegoPrimary)
                            .frame(minWidth: 20)

                        Button(action: {
                            viewModel.incrementItem(item)
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .foregroundColor(.llegoPrimary)
                }
            }
        }
        .padding(.vertical, 12)
    }

    private func priceRow(title: String, value: String, valueColor: Color = .llegoPrimary, isEmphasis: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.system(size: isEmphasis ? 15 : 14, weight: isEmphasis ? .semibold : .medium))
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.system(size: isEmphasis ? 16 : 14, weight: isEmphasis ? .semibold : .medium))
                .foregroundColor(valueColor)
        }
    }

    private func statusBadge(_ status: OrderDetailStatus) -> some View {
        Text(status.displayName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(status.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(status.accentColor.opacity(0.12))
            )
    }

    private func statusSubtitle(_ status: OrderDetailStatus) -> String {
        switch status {
        case .pendingAcceptance:
            return "Esperando confirmacion del negocio"
        case .modifiedByStore:
            return "Puedes ajustar los items antes de confirmar"
        case .inProgress:
            return "El pedido esta en camino"
        case .cancelled:
            return "El pedido fue cancelado"
        case .accepted:
            return "Aceptado por la tienda, pendiente de pago"
        }
    }

    private func commentBubble(_ comment: OrderDetailComment) -> some View {
        HStack {
            if comment.author == .business { Spacer(minLength: 0) }

            VStack(alignment: .leading, spacing: 6) {
                Text(comment.message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.llegoPrimary)

                Text(viewModel.formatTime(comment.timestamp))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(comment.author == .customer ? Color.black.opacity(0.04) : Color.blue.opacity(0.12))
            )

            if comment.author == .customer { Spacer(minLength: 0) }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }
}
