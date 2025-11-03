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

    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool

    var onSearch: ((String) -> Void)?

    var body: some View {
        if !isExpanded && selectedValue == nil {
            // Estado vacío - texto elegante que invita a escoger
            emptyInlineView
        } else if !isExpanded && selectedValue != nil {
            // Estado con valor seleccionado
            filledInlineView
        } else {
            // Estado expandido - Search bar flotante
            expandedSearchView
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
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    isExpanded = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isSearchFocused = true
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
                    searchText = ""
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                isExpanded = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isSearchFocused = true
            }
        }
    }

    // MARK: - Expanded Search View
    private var expandedSearchView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)

                TextField(type.placeholder, text: $searchText)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.primary.opacity(0.85))
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                        isExpanded = false
                        searchText = ""
                        isSearchFocused = false
                    }
                }) {
                    Text("Cancelar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.llegoPrimary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.llegoSurface)
                    .shadow(color: .black.opacity(0.1), radius: 16, y: 6)
            )
        }
    }

    private func performSearch() {
        onSearch?(searchText)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            selectedValue = searchText.isEmpty ? nil : searchText
            isExpanded = false
            isSearchFocused = false
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
