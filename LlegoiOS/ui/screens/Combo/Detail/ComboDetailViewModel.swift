import Combine
import Foundation
import SwiftUI

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
    @Published var selectedModifiers: [String: Set<String>] = [:]  // key: productId

    // MARK: - Private
    private var loadedComboId: String?
    private let repository = ComboDetailRepository()
    private let cartManager = CartManager.shared

    // MARK: - Computed Properties

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    var errorMessage: String? {
        if case .error(let msg) = state { return msg }
        return nil
    }

    /// Subtotal from user-selected options in paid slots only (free slots are excluded)
    var selectionSubtotal: Double {
        guard let combo = comboDetail else { return 0 }
        var total = 0.0

        for slot in combo.slots {
            guard !slot.isFree else { continue }   // free slots don't add to price
            let selected = slotSelections[slot.id] ?? []
            for option in slot.options where selected.contains(option.productId) {
                total += option.effectivePrice

                let mods = selectedModifiers[option.productId] ?? []
                total += option.availableModifiers
                    .filter { mods.contains($0.name) }
                    .reduce(0.0) { $0 + $1.priceAdjustment }
            }
        }

        return total
    }

    /// Final price after applying the combo discount to the paid subtotal
    var calculatedPrice: Double {
        let subtotal = selectionSubtotal
        return max(0, subtotal - comboDiscountAmount(for: subtotal))
    }

    var calculatedDiscountAmount: Double {
        comboDiscountAmount(for: selectionSubtotal)
    }

    /// True if all required paid slots have enough selections.
    /// Gift-only combos (no selectable required slots) are always ready.
    var isReadyToAdd: Bool {
        guard let combo = comboDetail else { return false }
        let requiredSlots = combo.slots.filter { $0.isRequired }
        if requiredSlots.isEmpty { return true }
        for slot in requiredSlots {
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

    @discardableResult
    func addCurrentComboToCart(quantity: Int = 1) -> Bool {
        guard quantity > 0 else { return false }
        guard isReadyToAdd, let combo = comboDetail else { return false }

        let comboGroupId = "combo::\(combo.id)::\(UUID().uuidString)"

        // Collect all components: user-selected slot options + gift products
        let sortedSlots = combo.slots.sorted { $0.displayOrder < $1.displayOrder }
        var allComponents: [(
            productId: String,
            slotId: String,
            slotName: String,
            unitRawFinalPrice: Double,
            componentOrder: Int,
            modifierNames: [String],
            isFree: Bool
        )] = []

        var order = 0
        for slot in sortedSlots {
            let selectedIds = Array(slotSelections[slot.id] ?? []).sorted()
            for selectedId in selectedIds {
                guard let option = slot.options.first(where: { $0.productId == selectedId }) else {
                    continue
                }

                let selectedModifierNames = selectedModifiers[option.productId] ?? []
                let modifierAdjustment = option.availableModifiers
                    .filter { selectedModifierNames.contains($0.name) }
                    .reduce(0.0) { $0 + $1.priceAdjustment }

                let rawPrice = slot.isFree ? 0.0 : (option.effectivePrice + modifierAdjustment)

                allComponents.append((
                    productId: option.productId,
                    slotId: slot.id,
                    slotName: slot.name,
                    unitRawFinalPrice: rawPrice,
                    componentOrder: order,
                    modifierNames: selectedModifierNames.sorted(),
                    isFree: slot.isFree
                ))
                order += 1
            }
        }

        // Gift products are always free and added automatically
        for gift in combo.giftOptions {
            allComponents.append((
                productId: gift.productId,
                slotId: "gift",
                slotName: "Regalo",
                unitRawFinalPrice: 0.0,
                componentOrder: order,
                modifierNames: [],
                isFree: true
            ))
            order += 1
        }

        guard !allComponents.isEmpty else { return false }

        // Distribute the discount proportionally across paid components
        let paidComponents = allComponents.filter { !$0.isFree }
        let targetPaidCents = cents(from: calculatedPrice)
        let totalRaw = paidComponents.reduce(0.0) { $0 + max(0.01, $1.unitRawFinalPrice) }

        // Map productId → allocated cents for paid components
        var paidAllocations: [String: Int] = [:]
        var assigned = 0
        for (index, component) in paidComponents.enumerated() {
            if index == paidComponents.count - 1 {
                paidAllocations["\(component.componentOrder)_\(component.productId)"] = max(0, targetPaidCents - assigned)
                continue
            }
            let ratio = max(0.01, component.unitRawFinalPrice) / totalRaw
            let centsValue = Int((Double(targetPaidCents) * ratio).rounded())
            paidAllocations["\(component.componentOrder)_\(component.productId)"] = centsValue
            assigned += centsValue
        }

        for component in allComponents {
            let finalCents = component.isFree
                ? 0
                : (paidAllocations["\(component.componentOrder)_\(component.productId)"] ?? 0)
            let lineCartItemId = "combo-item::\(comboGroupId)::\(component.componentOrder)::\(component.productId)"
            cartManager.addToCart(
                productId: component.productId,
                quantity: quantity,
                selectedVariants: [],
                cartItemId: lineCartItemId,
                comboGroupId: comboGroupId,
                comboId: combo.id,
                comboName: combo.name,
                comboComponentSlotId: component.slotId,
                comboComponentSlotName: component.slotName,
                comboComponentOrder: component.componentOrder,
                comboModifierNames: component.modifierNames,
                basePrice: component.unitRawFinalPrice,
                finalUnitPrice: Double(finalCents) / 100.0
            )
        }
        return true
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

    private func cents(from value: Double) -> Int {
        Int((value * 100.0).rounded())
    }

    private func comboDiscountAmount(for subtotal: Double) -> Double {
        guard let combo = comboDetail, subtotal > 0 else { return 0 }

        switch combo.discountType.uppercased() {
        case "PERCENTAGE":
            return subtotal * (combo.discountValue / 100.0)
        case "FIXED":
            return min(subtotal, combo.discountValue)
        default:
            return 0
        }
    }
}
