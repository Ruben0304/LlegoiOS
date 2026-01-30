//
//  AIProductCard.swift
//  LlegoiOS
//
//  Componente para mostrar productos en el chat con IA
//

import SwiftUI

struct AIProductCard: View {
    let product: AIChatProductEntity
    @ObservedObject private var cartManager = CartManager.shared

    private var count: Int {
        cartManager.getQuantity(for: product.id)
    }

    private var currencySymbol: String {
        product.currency == "USD" ? "$" : product.currency
    }

    private var priceValue: String {
        String(format: "%.2f", product.price)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Product Image - Circular with ProgressView accent
            if let url = URL(string: product.imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Circle()
                                .fill(Color.llegoBackground)
                            ProgressView()
                                .tint(.llegoAccent)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        ZStack {
                            Circle()
                                .fill(Color.llegoBackground)
                            Image(systemName: "photo")
                                .font(.system(size: 28))
                                .foregroundColor(.llegoPrimary)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                .overlay(
                    Circle()
                        .stroke(Color.llegoAccent.opacity(0.3), lineWidth: 2)
                )
            } else {
                ZStack {
                    Circle()
                        .fill(Color.llegoBackground)
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundColor(.llegoPrimary)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                .overlay(
                    Circle()
                        .stroke(Color.llegoAccent.opacity(0.3), lineWidth: 2)
                )
            }

            // Información del producto
            VStack(alignment: .leading, spacing: 6) {
                // Product name as main title
                Text(product.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Branch name with avatar
                if let branchName = product.branchName {
                    HStack(spacing: 6) {
                        // Branch avatar - pequeño y circular
                        if let branchAvatarUrl = product.branchAvatarUrl, let url = URL(string: branchAvatarUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 16, height: 16)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 16, height: 16)
                                        .clipShape(Circle())
                                case .failure:
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 16, height: 16)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }

                        Text(branchName)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                if let reason = product.reason, !reason.isEmpty {
                    Text(reason)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.llegoPrimary)
                        .lineLimit(4)
                }

                Spacer()

                HStack {
                    HStack(spacing: 4) {
                        Text(currencySymbol)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.llegoPrimary.opacity(0.8))

                        Text(priceValue)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.llegoPrimary)
                    }

                    Spacer()

                    if product.availability {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Disponible")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        }
                    } else {
                        Text("No disponible")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }

            // Controles de cantidad
            if product.availability {
                if count > 0 {
                    // Mostrar controles +/- cuando hay items
                    HStack(spacing: 6) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                let newQuantity = count - 1
                                if newQuantity <= 0 {
                                    cartManager.removeFromCart(productId: product.id)
                                } else {
                                    cartManager.updateQuantity(productId: product.id, quantity: newQuantity)
                                }
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.llegoPrimary)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(Color.llegoBackground)
                                )
                        }

                        Text("\(count)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.llegoPrimary)
                            .frame(width: 24)

                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                cartManager.addToCart(productId: product.id, quantity: 1)
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(Color.llegoPrimary)
                                )
                        }
                    }
                } else {
                    // Mostrar botón de agregar cuando count == 0
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            cartManager.addToCart(productId: product.id, quantity: 1)
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        Image(systemName: "cart.fill.badge.plus")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.llegoPrimary)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
    }
}
