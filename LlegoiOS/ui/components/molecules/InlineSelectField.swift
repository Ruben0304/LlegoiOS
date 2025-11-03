//
//  InlineSelectField.swift
//  LlegoiOS
//
//  Campo de selección inline elegante y minimalista
//  Se integra naturalmente con el texto sin romper el flujo visual
//

import SwiftUI

/// Campo de selección que se integra inline con el texto de forma elegante
struct InlineSelectField: View {
    let type: SearchPillType
    @Binding var selectedValue: String?
    @Binding var isExpanded: Bool

    var body: some View {
        Group {
            if selectedValue == nil {
                // Estado vacío - texto elegante que invita a escoger
                emptyInlineView
            } else {
                // Estado con valor seleccionado
                filledInlineView
            }
        }
    }

    // MARK: - Empty Inline View
    private var emptyInlineView: some View {
        Text("escoger")
            .font(.custom("SF Pro Display", size: 28))
            .fontWeight(.light)
            .italic()
            .foregroundColor(.llegoSecondary)
            .underline(color: .llegoSecondary)
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isExpanded = true
                }
            }
    }

    // MARK: - Filled Inline View
    private var filledInlineView: some View {
        HStack(spacing: 4) {
            Text(selectedValue ?? "")
                .font(.custom("SF Pro Display", size: 28))
                .fontWeight(.semibold)
                .foregroundColor(.llegoPrimary)

            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    selectedValue = nil
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isExpanded = true
            }
        }
    }

}

// MARK: - Preview
#Preview("Inline Select") {
    ZStack {
        Color.llegoBackground.ignoresSafeArea()

        VStack(spacing: 30) {
            HStack(spacing: 8) {
                Text("Quiero ordenar")
                    .font(.system(size: 28, weight: .medium))

                InlineSelectField(
                    type: .products,
                    selectedValue: .constant(nil),
                    isExpanded: .constant(false)
                )
            }
        }
    }
}
