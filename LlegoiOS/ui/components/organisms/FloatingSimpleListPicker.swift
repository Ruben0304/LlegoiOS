//
//  FloatingSimpleListPicker.swift
//  LlegoiOS
//
//  Picker flotante simple para listas (monedas, métodos de pago, etc.)
//

import SwiftUI

struct FloatingSimpleListPicker<Item: Identifiable & Equatable>: View {
    let title: String
    let items: [Item]
    let itemLabel: (Item) -> String
    let itemIcon: (Item) -> AnyView
    @Binding var selectedValue: String?
    @Binding var isVisible: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Título
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isVisible = false
                    }
                }) {
                    Text("Cancelar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.llegoPrimary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()
                .padding(.horizontal, 16)

            // Lista de items
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        Button(action: {
                            selectedValue = itemLabel(item)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isVisible = false
                            }
                        }) {
                            HStack(spacing: 16) {
                                itemIcon(item)

                                Text(itemLabel(item))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.llegoSurface.opacity(0.5))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .frame(maxHeight: 400)
        }
        .background(Color.clear)
        .cornerRadius(16)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 16)
    }
}
