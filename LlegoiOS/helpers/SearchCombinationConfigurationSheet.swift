import SwiftUI

/// Configuration stays within the combination: no component is added on its own.
struct SearchCombinationConfigurationSheet: View {
    let combination: SearchCombination
    let onAdded: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var details: [ProductDetailGraphQL] = []
    @State private var choices: [String: [String: Int]] = [:]
    @State private var isLoading = true
    @State private var isAdding = false
    @State private var errorMessage: String?
    @State private var addTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Form {
                if isLoading {
                    ProgressView("Cargando opciones…")
                } else if details.isEmpty {
                    Text(errorMessage ?? "No se pudieron cargar las opciones.")
                    Button("Reintentar") { Task { await loadOptions() } }
                } else {
                    Section {
                        Text("Elige las opciones antes de añadir todos los productos juntos.")
                        Text(combination.branchName).font(.headline)
                    }
                    ForEach(details) { product in
                        Section(product.name) {
                            let quantity = combination.products.first(where: { $0.id == product.id })?.quantity ?? 1
                            Text("\(quantity) × \(formatted(product.price))")
                                .foregroundStyle(.secondary)
                            ForEach(product.variantLists ?? []) { list in
                                Picker(list.name, selection: selectionBinding(product: product, list: list)) {
                                    Text("Seleccionar").tag(-1)
                                    ForEach(Array(list.options.enumerated()), id: \.offset) { index, option in
                                        Text(optionLabel(option)).tag(index)
                                    }
                                }
                            }
                        }
                    }
                    Section {
                        HStack {
                            Text("Total de productos")
                            Spacer()
                            Text(formatted(totalPrice)).bold()
                        }
                        Text("El envío y los cargos se calculan en el carrito.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button {
                            addTask = Task { await addCombination() }
                        } label: {
                            HStack {
                                if isAdding { ProgressView() }
                                Text("Añadir combinación al carrito")
                            }
                        }
                        .disabled(!hasAllSelections || isAdding)
                    }
                }
            }
            .disabled(isAdding)
            .navigationTitle("Tu combinación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }.disabled(isAdding)
                }
            }
            .task { await loadOptions() }
            .onDisappear { addTask?.cancel() }
            .interactiveDismissDisabled(isAdding)
            .alert("No se pudo añadir", isPresented: Binding(
                get: { errorMessage != nil && !details.isEmpty },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Aceptar", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private var hasAllSelections: Bool {
        !details.isEmpty && details.allSatisfy { product in
            (product.variantLists ?? []).allSatisfy { list in
                guard let index = choices[product.id]?[list.id] else { return false }
                return list.options.indices.contains(index)
            }
        }
    }

    private var selectedOptions: [String: [SelectedVariantOption]] {
        Dictionary(uniqueKeysWithValues: details.map { product in
            let selected = (product.variantLists ?? []).compactMap { list -> SelectedVariantOption? in
                guard let index = choices[product.id]?[list.id], list.options.indices.contains(index) else { return nil }
                let option = list.options[index]
                return SelectedVariantOption(
                    listId: list.id, listName: list.name, optionId: option.id,
                    optionName: option.name, priceAdjustment: option.priceAdjustment)
            }
            return (product.id, selected)
        })
    }

    private var totalPrice: Double {
        let selections = selectedOptions
        return details.reduce(0) { total, product in
            let quantity = combination.products.first(where: { $0.id == product.id })?.quantity ?? 1
            let price = computeFinalUnitPrice(base: Decimal(product.price), selected: selections[product.id] ?? [])
            return total + NSDecimalNumber(decimal: price).doubleValue * Double(quantity)
        }
    }

    private func selectionBinding(product: ProductDetailGraphQL, list: VariantList) -> Binding<Int> {
        Binding(
            get: { choices[product.id]?[list.id] ?? -1 },
            set: { choices[product.id, default: [:]][list.id] = $0 })
    }

    private func formatted(_ price: Double) -> String {
        price.formatted(.currency(code: combination.currency))
    }

    private func optionLabel(_ option: VariantOption) -> String {
        guard option.priceAdjustment != 0 else { return option.name }
        let price = NSDecimalNumber(decimal: option.priceAdjustment).doubleValue
        return "\(option.name) (\(price > 0 ? "+" : "")\(formatted(price)))"
    }

    private func loadOptions() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let loaded = try await SearchCombinationCartCoordinator.shared.configurationDetails(for: combination)
            try Task.checkCancellation()
            details = loaded
            choices = [:]
        } catch is CancellationError {
        } catch { errorMessage = error.localizedDescription }
    }

    private func addCombination() async {
        guard hasAllSelections, !isAdding else { return }
        isAdding = true
        defer { isAdding = false }
        do {
            let result = try await SearchCombinationCartCoordinator.shared.add(combination, selections: selectedOptions)
            if case .added = result {
                dismiss()
                onAdded()
            }
        } catch is CancellationError {
        } catch { errorMessage = error.localizedDescription }
    }
}
