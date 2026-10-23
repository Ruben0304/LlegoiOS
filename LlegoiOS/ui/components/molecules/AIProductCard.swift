//
//  AIProductCard.swift
//  LlegoiOS
//
//  Componente para mostrar productos en el chat con IA
//  Diseño minimalista, moderno y elegante (estilo Apple).
//

import SwiftUI

struct AIProductCard: View {
    let product: AIChatProductEntity
    @ObservedObject private var cartManager = CartManager.shared
    @ObservedObject private var gradientManager = GradientStateManager.shared

    private var count: Int {
        cartManager.getQuantity(for: product.id)
    }

    private var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: product.price))
            ?? String(format: "%.2f", product.price)
    }

    var body: some View {
        HStack(spacing: 14) {
            productImage

            infoColumn

            Spacer(minLength: 2)

            if product.availability {
                actionControl
                    .animation(.spring(response: 0.32, dampingFraction: 0.74), value: count)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 6)
        .opacity(product.availability ? 1 : 0.72)
    }

    // MARK: - Imagen del producto

    private var productImage: some View {
        Group {
            if let url = URL(string: product.imageUrl), !product.imageUrl.isEmpty {
                CachedAsyncImage(
                    url: url,
                    displaySize: CGSize(width: 64, height: 64),
                    content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                    },
                    placeholder: {
                        ZStack {
                            Rectangle().fill(Color.primary.opacity(0.04))
                            ProgressView()
                                .tint(.secondary)
                                .scaleEffect(0.8)
                        }
                    },
                    failure: {
                        imagePlaceholderIcon
                    }
                )
            } else {
                imagePlaceholderIcon
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var imagePlaceholderIcon: some View {
        ZStack {
            Rectangle().fill(Color.primary.opacity(0.04))
            Image(systemName: "bag")
                .scaledFont(size: 22, weight: .light, relativeTo: .title2)
                .foregroundColor(.secondary.opacity(0.5))
        }
    }

    // MARK: - Información

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(product.name)
                .scaledFont(size: 15.5, weight: .semibold, relativeTo: .body)
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if let branchName = product.branchName, !branchName.isEmpty {
                HStack(spacing: 5) {
                    if let urlString = product.branchAvatarUrl, let url = URL(string: urlString) {
                        CachedAsyncImage(
                            url: url,
                            displaySize: CGSize(width: 16, height: 16),
                            content: { image in
                                image.resizable().scaledToFill()
                            },
                            placeholder: {
                                Circle().fill(Color.primary.opacity(0.08))
                            },
                            failure: {
                                Circle().fill(Color.primary.opacity(0.08))
                            }
                        )
                        .frame(width: 16, height: 16)
                        .clipShape(Circle())
                    }

                    Text(branchName)
                        .scaledFont(size: 12, relativeTo: .caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            if let reason = product.reason, !reason.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "sparkles")
                        .scaledFont(size: 9.5, weight: .semibold, relativeTo: .caption2)
                        .foregroundColor(gradientManager.currentAccentColor)
                        .padding(.top, 1)
                    Text(reason)
                        .scaledFont(size: 11.5, weight: .medium, relativeTo: .caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 1)
            }

            Spacer(minLength: 6)

            priceRow
        }
    }

    private var priceRow: some View {
        HStack(spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if product.currency == "USD" {
                    Text("$")
                        .scaledFont(size: 13, weight: .semibold, relativeTo: .footnote)
                        .foregroundColor(.secondary)
                    Text(formattedPrice)
                        .scaledFont(size: 17, weight: .bold, relativeTo: .body)
                        .foregroundColor(.primary)
                } else {
                    Text(formattedPrice)
                        .scaledFont(size: 17, weight: .bold, relativeTo: .body)
                        .foregroundColor(.primary)
                    Text(product.currency)
                        .scaledFont(size: 11, weight: .semibold, relativeTo: .caption)
                        .foregroundColor(.secondary)
                }
            }

            if !product.availability {
                Text("Agotado")
                    .scaledFont(size: 10, weight: .semibold, relativeTo: .caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.primary.opacity(0.06)))
            }
        }
    }

    // MARK: - Acción (agregar / stepper)

    @ViewBuilder private var actionControl: some View {
        if count > 0 {
            HStack(spacing: 2) {
                Button(action: decrement) {
                    Image(systemName: count > 1 ? "minus" : "trash")
                        .scaledFont(size: 12, weight: .bold, relativeTo: .caption)
                        .foregroundColor(gradientManager.currentAccentColor)
                        .frame(width: 32, height: 34)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(count > 1 ? "Quitar uno" : "Eliminar del carrito")

                Text("\(count)")
                    .scaledFont(size: 15, weight: .bold, design: .rounded, relativeTo: .subheadline)
                    .foregroundColor(.primary)
                    .frame(minWidth: 20)
                    .contentTransition(.numericText())

                Button(action: increment) {
                    Image(systemName: "plus")
                        .scaledFont(size: 12, weight: .bold, relativeTo: .caption)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(gradientManager.currentAccentColor))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Agregar uno")
            }
            .padding(.leading, 6)
            .padding(.trailing, 4)
            .padding(.vertical, 2)
            .background(
                Capsule(style: .continuous).fill(Color.primary.opacity(0.05))
            )
        } else {
            Button(action: increment) {
                Image(systemName: "plus")
                    .scaledFont(size: 17, weight: .semibold, relativeTo: .body)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(gradientManager.currentAccentColor))
                    .shadow(
                        color: gradientManager.currentAccentColor.opacity(0.35),
                        radius: 8, x: 0, y: 4
                    )
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Agregar al carrito")
        }
    }

    // MARK: - Acciones del carrito

    private func increment() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            cartManager.addToCart(productId: product.id, quantity: 1)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func decrement() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            let newQuantity = count - 1
            if newQuantity <= 0 {
                cartManager.removeFromCart(productId: product.id)
            } else {
                cartManager.updateQuantity(productId: product.id, quantity: newQuantity)
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
