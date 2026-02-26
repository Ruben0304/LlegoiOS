import Foundation
import SwiftUI
import Combine

// MARK: - View State

enum ComboDetailState {
    case idle
    case loading
    case success(ComboDetailGraphQL)
    case error(String)
}

// MARK: - Selection Model

/// Tracks the user's selection for a single slot
struct SlotSelection: Identifiable {
    let slotId: String
    var selectedProductIds: Set<String>

    var id: String { slotId }
}

// MARK: - ComboDetailViewModel

@MainActor
class ComboDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var state: ComboDetailState = .idle
    @Published var comboDetail: ComboDetailGraphQL?
    /// Key: slotId, Value: selected productIds (may be multiple if maxSelections > 1)
    @Published var slotSelections: [String: Set<String>] = [:]
    @Published var selectedModifiers: [String: Set<String>] = [:] // key: productId

    // MARK: - Private
    private var loadedComboId: String?
    private let repository = ComboDetailRepository()

    // MARK: - Computed Properties

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    var errorMessage: String? {
        if case .error(let msg) = state { return msg }
        return nil
    }

    /// Total price based on current selections
    var calculatedPrice: Double {
        guard let combo = comboDetail else { return 0 }
        var total = combo.finalPrice // Start from discounted base price

        // Add price adjustments for non-default selections
        for slot in combo.slots {
            let selected = slotSelections[slot.id] ?? []
            for option in slot.options {
                if selected.contains(option.productId) && !option.isDefault {
                    total += option.priceAdjustment
                }
                // Add modifier adjustments
                let mods = selectedModifiers[option.productId] ?? []
                for modifier in option.availableModifiers where mods.contains(modifier.name) {
                    total += modifier.priceAdjustment
                }
            }
        }
        return total
    }

    /// True if all required slots have at least one selection
    var isReadyToAdd: Bool {
        guard let combo = comboDetail else { return false }
        for slot in combo.slots where slot.isRequired {
            let selected = slotSelections[slot.id] ?? []
            if selected.count < slot.minSelections { return false }
        }
        return true
    }

    var formattedCalculatedPrice: String {
        guard let combo = comboDetail else { return "" }
        return formatPrice(calculatedPrice, currency: combo.currency)
    }

    // MARK: - Public Methods

    func loadComboDetail(id: String, forceRefresh: Bool = false) {
        guard forceRefresh || loadedComboId != id else { return }
        loadedComboId = id
        slotSelections = [:]
        state = .loading

        repository.fetchComboDetail(id: id) { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success(let detail):
                    self.comboDetail = detail
                    self.state = .success(detail)
                    self.applyDefaultSelections(for: detail)
                    print("✅ ComboDetailViewModel: Loaded combo \(id)")
                case .failure(let error):
                    self.state = .error("Error al cargar el combo: \(error.localizedDescription)")
                    self.loadedComboId = nil
                    print("❌ ComboDetailViewModel: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Toggle a product selection within a slot
    func toggleOption(slotId: String, productId: String, maxSelections: Int) {
        var current = slotSelections[slotId] ?? []
        if current.contains(productId) {
            current.remove(productId)
        } else {
            if maxSelections == 1 {
                current = [productId]
            } else if current.count < maxSelections {
                current.insert(productId)
            }
        }
        slotSelections[slotId] = current
    }

    func isOptionSelected(slotId: String, productId: String) -> Bool {
        slotSelections[slotId]?.contains(productId) ?? false
    }

    // MARK: - Private Methods

    private func applyDefaultSelections(for combo: ComboDetailGraphQL) {
        var selections: [String: Set<String>] = [:]
        for slot in combo.slots {
            let defaults = slot.options.filter { $0.isDefault }.map { $0.productId }
            if !defaults.isEmpty {
                selections[slot.id] = Set(defaults)
            }
        }
        slotSelections = selections
    }

    func formatPrice(_ value: Double, currency: String) -> String {
        let symbol: String
        switch currency.uppercased() {
        case "USD": symbol = "$"
        case "EUR": symbol = "€"
        case "CUP": symbol = "CUP "
        default: symbol = currency + " "
        }
        return String(format: "\(symbol)%.2f", value)
    }
}
