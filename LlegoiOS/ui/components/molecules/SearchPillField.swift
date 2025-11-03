//
//  SearchPillField.swift
//  LlegoiOS
//
//  Campo interactivo en forma de cápsula que se expande a barra de búsqueda
//  Diseño minimalista y elegante con glass effect
//

import SwiftUI

enum SearchPillType {
    case products
    case stores

    var placeholder: String {
        switch self {
        case .products: return "¿qué buscas?"
        case .stores: return "¿de dónde?"
        }
    }

    var icon: String {
        switch self {
        case .products: return "bag"
        case .stores: return "storefront"
        }
    }
}

/// Campo de búsqueda en forma de cápsula que se expande al tocar
struct SearchPillField: View {
    let type: SearchPillType
    @Binding var selectedValue: String?
    @Binding var isExpanded: Bool

    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool

    var onSearch: ((String) -> Void)?

    var body: some View {
        if !isExpanded && selectedValue == nil {
            // Estado colapsado - Pill vacío
            emptyPillView
        } else if !isExpanded && selectedValue != nil {
            // Estado con valor seleccionado
            filledPillView
        } else {
            // Estado expandido - Search bar
            expandedSearchView
        }
    }

    // MARK: - Empty Pill
    private var emptyPillView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray.opacity(0.5))

            Text(type.placeholder)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.llegoSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                )
        )
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isExpanded = true
            }
            // Delay para focus después de la animación
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
    }

    // MARK: - Filled Pill
    private var filledPillView: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.llegoPrimary)

            Text(selectedValue ?? "")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.onBackgroundColor)
                .lineLimit(1)

            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    selectedValue = nil
                    searchText = ""
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.llegoAccent.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.llegoAccent.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isExpanded = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
    }

    // MARK: - Expanded Search View
    private var expandedSearchView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Magnifying glass icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)

                // Text field
                TextField(type.placeholder, text: $searchText)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.onBackgroundColor)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }

                // Clear button
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

                // Cancel button
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
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
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            )
        }
    }

    private func performSearch() {
        onSearch?(searchText)
        // Simular selección
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            selectedValue = searchText.isEmpty ? nil : searchText
            isExpanded = false
            isSearchFocused = false
        }
    }
}

// MARK: - Preview
#Preview("Empty Pill") {
    ZStack {
        Color.llegoBackground.ignoresSafeArea()

        VStack(spacing: 30) {
            SearchPillField(
                type: .products,
                selectedValue: .constant(nil),
                isExpanded: .constant(false)
            )

            SearchPillField(
                type: .stores,
                selectedValue: .constant(nil),
                isExpanded: .constant(false)
            )
        }
        .padding()
    }
}

#Preview("Filled Pill") {
    ZStack {
        Color.llegoBackground.ignoresSafeArea()

        VStack(spacing: 30) {
            SearchPillField(
                type: .products,
                selectedValue: .constant("Frutas frescas"),
                isExpanded: .constant(false)
            )

            SearchPillField(
                type: .stores,
                selectedValue: .constant("La Bodeguita del Medio"),
                isExpanded: .constant(false)
            )
        }
        .padding()
    }
}

#Preview("Expanded Search") {
    struct ExpandedSearchPreview: View {
        @State private var selectedValue: String? = nil
        @State private var isExpanded: Bool = true

        var body: some View {
            ZStack {
                Color.llegoBackground.ignoresSafeArea()

                VStack(spacing: 30) {
                    SearchPillField(
                        type: .products,
                        selectedValue: $selectedValue,
                        isExpanded: $isExpanded
                    )

                    Spacer()
                }
                .padding()
            }
        }
    }

    return ExpandedSearchPreview()
}

#Preview("Interactive Demo") {
    struct InteractiveDemoPreview: View {
        @State private var productValue: String? = nil
        @State private var storeValue: String? = nil
        @State private var productExpanded: Bool = false
        @State private var storeExpanded: Bool = false

        var body: some View {
            ZStack {
                Color.llegoBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    Text("Búsqueda Conversacional")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.onBackgroundColor)

                    HStack(spacing: 12) {
                        Text("Quiero ordenar")
                            .font(.system(size: 18, weight: .regular))

                        SearchPillField(
                            type: .products,
                            selectedValue: $productValue,
                            isExpanded: $productExpanded
                        )
                    }

                    HStack(spacing: 12) {
                        Text("del vendedor")
                            .font(.system(size: 18, weight: .regular))

                        SearchPillField(
                            type: .stores,
                            selectedValue: $storeValue,
                            isExpanded: $storeExpanded
                        )
                    }

                    Spacer()
                }
                .padding(24)
            }
        }
    }

    return InteractiveDemoPreview()
}
