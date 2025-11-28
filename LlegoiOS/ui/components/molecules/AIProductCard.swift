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

    private var formattedPrice: String {
        let currencySymbol = product.currency == "USD" ? "$" : product.currency
        return String(format: "%@%.2f", currencySymbol, product.price)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Imagen del producto
            CachedAsyncImage(
                url: URL(string: product.image),
                content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipped()
                },
                placeholder: {
                    ZStack {
                        Color(red: 240/255, green: 242/255, blue: 246/255)
                        ProgressView()
                            .tint(.llegoPrimary)
                    }
                }
            )
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Información del producto
            VStack(alignment: .leading, spacing: 6) {
                Text(product.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(product.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                HStack {
                    Text(formattedPrice)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.llegoPrimary)
                    
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
