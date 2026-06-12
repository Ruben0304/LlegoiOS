import XCTest
@testable import LlegoiOS

@MainActor
final class CartManagerTests: XCTestCase {

    var cart: CartManager!
    var testDefaults: UserDefaults!
    var suiteName: String!

    override func setUp() async throws {
        suiteName = "CartManagerTests_\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        cart = CartManager(userDefaults: testDefaults)
    }

    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: suiteName)
        cart = nil
        testDefaults = nil
        suiteName = nil
    }

    // MARK: - Agregar productos

    func test_addProduct_appearsInCart() {
        cart.addToCart(productId: "p1")
        XCTAssertTrue(cart.isInCart(productId: "p1"))
    }

    func test_addProduct_defaultQuantityIsOne() {
        cart.addToCart(productId: "p1")
        XCTAssertEqual(cart.getQuantity(for: "p1"), 1)
    }

    func test_addSameProductTwice_incrementsQuantity_notDuplicates() {
        cart.addToCart(productId: "p1")
        cart.addToCart(productId: "p1")

        XCTAssertEqual(cart.localItems.count, 1, "El mismo producto no debe crear dos líneas")
        XCTAssertEqual(cart.getQuantity(for: "p1"), 2)
    }

    func test_addDifferentProducts_createsSeparateLines() {
        cart.addToCart(productId: "p1")
        cart.addToCart(productId: "p2")

        XCTAssertEqual(cart.localItems.count, 2)
        XCTAssertTrue(cart.isInCart(productId: "p1"))
        XCTAssertTrue(cart.isInCart(productId: "p2"))
    }

    func test_addProductWithExplicitQuantity() {
        cart.addToCart(productId: "p1", quantity: 5)
        XCTAssertEqual(cart.getQuantity(for: "p1"), 5)
    }

    // MARK: - Variantes

    func test_sameProductDifferentVariants_createsTwoLines() {
        let small = SelectedVariantOption(listId: "size", listName: "Tamaño", optionId: "s", optionName: "Pequeño", priceAdjustment: 0)
        let large = SelectedVariantOption(listId: "size", listName: "Tamaño", optionId: "l", optionName: "Grande", priceAdjustment: 10)

        cart.addToCart(productId: "p1", selectedVariants: [small])
        cart.addToCart(productId: "p1", selectedVariants: [large])

        XCTAssertEqual(cart.localItems.count, 2, "Variantes distintas son líneas distintas")
    }

    func test_sameProductSameVariant_incrementsQuantity() {
        let variant = SelectedVariantOption(listId: "size", listName: "Tamaño", optionId: "l", optionName: "Grande", priceAdjustment: 10)

        cart.addToCart(productId: "p1", selectedVariants: [variant])
        cart.addToCart(productId: "p1", selectedVariants: [variant])

        XCTAssertEqual(cart.localItems.count, 1)
        XCTAssertEqual(cart.getQuantity(for: "p1"), 2)
    }

    func test_getQuantityForProduct_sumsAllVariantLines() {
        let small = SelectedVariantOption(listId: "size", listName: "Tamaño", optionId: "s", optionName: "Pequeño", priceAdjustment: 0)
        let large = SelectedVariantOption(listId: "size", listName: "Tamaño", optionId: "l", optionName: "Grande", priceAdjustment: 10)

        cart.addToCart(productId: "p1", quantity: 2, selectedVariants: [small])
        cart.addToCart(productId: "p1", quantity: 1, selectedVariants: [large])

        // getQuantity suma todas las líneas del productId, sin importar variante
        XCTAssertEqual(cart.getQuantity(for: "p1"), 3)
    }

    // MARK: - Precios

    func test_addProductWithBasePrice_calculatesTotalCorrectly() {
        cart.addToCart(productId: "p1", quantity: 3, basePrice: 10.0)

        let item = cart.localItems.first!
        XCTAssertEqual(item.finalTotalPrice, 30.0)
    }

    func test_finalUnitPriceTakesPriorityOverBasePrice() {
        cart.addToCart(productId: "p1", quantity: 2, basePrice: 10.0, finalUnitPrice: 12.0)

        let item = cart.localItems.first!
        XCTAssertEqual(item.finalTotalPrice, 24.0, "Cuando hay finalUnitPrice, NO debe usar basePrice para el total")
    }

    func test_updateQuantity_recalculatesTotalPrice() {
        cart.addToCart(productId: "p1", quantity: 1, finalUnitPrice: 15.0)
        cart.updateQuantity(productId: "p1", quantity: 4)

        let item = cart.localItems.first!
        XCTAssertEqual(item.finalTotalPrice, 60.0)
    }

    func test_addProductNoPrice_totalIsZero() {
        cart.addToCart(productId: "p1", quantity: 3)

        let item = cart.localItems.first!
        XCTAssertEqual(item.finalTotalPrice, 0.0)
    }

    // MARK: - Actualizar cantidad

    func test_updateQuantity_changesAmount() {
        cart.addToCart(productId: "p1", quantity: 1)
        cart.updateQuantity(productId: "p1", quantity: 5)

        XCTAssertEqual(cart.getQuantity(for: "p1"), 5)
    }

    func test_updateQuantityToZero_removesItem() {
        cart.addToCart(productId: "p1")
        cart.updateQuantity(productId: "p1", quantity: 0)

        XCTAssertFalse(cart.isInCart(productId: "p1"))
        XCTAssertTrue(cart.localItems.isEmpty)
    }

    func test_updateQuantityToNegative_removesItem() {
        cart.addToCart(productId: "p1")
        cart.updateQuantity(productId: "p1", quantity: -1)

        XCTAssertFalse(cart.isInCart(productId: "p1"))
    }

    func test_updateQuantityByCartItemId_changesCorrectLine() {
        let small = SelectedVariantOption(listId: "size", listName: "Tamaño", optionId: "s", optionName: "Pequeño", priceAdjustment: 0)
        let large = SelectedVariantOption(listId: "size", listName: "Tamaño", optionId: "l", optionName: "Grande", priceAdjustment: 10)

        cart.addToCart(productId: "p1", quantity: 1, selectedVariants: [small])
        cart.addToCart(productId: "p1", quantity: 1, selectedVariants: [large])

        let smallLine = cart.localItems.first { $0.selectedVariants.contains(where: { $0.optionId == "s" }) }!
        cart.updateQuantity(cartItemId: smallLine.cartItemId, quantity: 4)

        XCTAssertEqual(cart.localItems.first { $0.cartItemId == smallLine.cartItemId }?.quantity, 4)
        XCTAssertEqual(cart.localItems.first { $0.selectedVariants.contains(where: { $0.optionId == "l" }) }?.quantity, 1, "La otra línea no debería cambiar")
    }

    // MARK: - Eliminar productos

    func test_removeFromCart_productDisappears() {
        cart.addToCart(productId: "p1")
        cart.removeFromCart(productId: "p1")

        XCTAssertFalse(cart.isInCart(productId: "p1"))
    }

    func test_removeOneProduct_otherProductsRemain() {
        cart.addToCart(productId: "p1")
        cart.addToCart(productId: "p2")
        cart.removeFromCart(productId: "p1")

        XCTAssertFalse(cart.isInCart(productId: "p1"))
        XCTAssertTrue(cart.isInCart(productId: "p2"))
    }

    // MARK: - Conteo de items

    func test_cartItemCount_startsAtZero() {
        XCTAssertEqual(cart.cartItemCount, 0)
    }

    func test_cartItemCount_sumsQuantitiesAcrossAllProducts() {
        cart.addToCart(productId: "p1", quantity: 3)
        cart.addToCart(productId: "p2", quantity: 2)

        XCTAssertEqual(cart.cartItemCount, 5)
    }

    func test_cartItemCount_decreasesOnRemove() {
        cart.addToCart(productId: "p1", quantity: 3)
        cart.removeFromCart(productId: "p1")

        XCTAssertEqual(cart.cartItemCount, 0)
    }

    // MARK: - Limpiar carrito

    func test_clearCart_emptiesAllProductLines() {
        cart.addToCart(productId: "p1", quantity: 2)
        cart.addToCart(productId: "p2", quantity: 1)
        cart.clearCart()

        XCTAssertTrue(cart.localItems.isEmpty)
        XCTAssertEqual(cart.cartItemCount, 0)
    }

    func test_clearCart_alsoEmptiesShowcaseItems() {
        cart.addShowcaseToCart(showcaseId: "s1", branchId: "b1", branchName: "Tienda", title: "Item", imageUrl: "", requestDescription: "Quiero algo")
        cart.clearCart()

        XCTAssertTrue(cart.localShowcaseItems.isEmpty)
    }

    func test_afterClearCart_canAddItemsAgain() {
        cart.addToCart(productId: "p1")
        cart.clearCart()
        cart.addToCart(productId: "p2")

        XCTAssertFalse(cart.isInCart(productId: "p1"))
        XCTAssertTrue(cart.isInCart(productId: "p2"))
    }

    // MARK: - Combos

    func test_addCombo_createsOneLinePerComponent() {
        cart.addComboToCart(
            comboId: "c1",
            comboName: "Combo Especial",
            components: [
                (productId: "p1", slotId: "s1", slotName: "Principal", unitBasePrice: 10, unitFinalPrice: 10, componentOrder: 0, modifierNames: []),
                (productId: "p2", slotId: "s2", slotName: "Bebida", unitBasePrice: 5, unitFinalPrice: 5, componentOrder: 1, modifierNames: [])
            ]
        )

        XCTAssertEqual(cart.localItems.count, 2)
    }

    func test_addComboComponents_allShareTheSameGroupId() {
        cart.addComboToCart(
            comboId: "c1",
            comboName: "Combo",
            components: [
                (productId: "p1", slotId: "s1", slotName: "Principal", unitBasePrice: 10, unitFinalPrice: 10, componentOrder: 0, modifierNames: []),
                (productId: "p2", slotId: "s2", slotName: "Bebida", unitBasePrice: 5, unitFinalPrice: 5, componentOrder: 1, modifierNames: [])
            ]
        )

        let groupIds = Set(cart.localItems.compactMap { $0.comboGroupId })
        XCTAssertEqual(groupIds.count, 1, "Todos los componentes del combo deben tener el mismo groupId")
    }

    func test_addSameComboTwice_createsTwoSeparateGroups() {
        let components: [(productId: String, slotId: String, slotName: String, unitBasePrice: Double, unitFinalPrice: Double, componentOrder: Int, modifierNames: [String])] = [
            (productId: "p1", slotId: "s1", slotName: "Principal", unitBasePrice: 10, unitFinalPrice: 10, componentOrder: 0, modifierNames: [])
        ]

        cart.addComboToCart(comboId: "c1", comboName: "Combo", components: components)
        cart.addComboToCart(comboId: "c1", comboName: "Combo", components: components)

        let groupIds = Set(cart.localItems.compactMap { $0.comboGroupId })
        XCTAssertEqual(groupIds.count, 2, "Cada llamada a addComboToCart crea un grupo independiente")
        XCTAssertEqual(cart.localItems.count, 2)
    }

    func test_removeCombo_removesAllItsComponents() {
        cart.addComboToCart(
            comboId: "c1",
            comboName: "Combo",
            components: [
                (productId: "p1", slotId: "s1", slotName: "Principal", unitBasePrice: 10, unitFinalPrice: 10, componentOrder: 0, modifierNames: []),
                (productId: "p2", slotId: "s2", slotName: "Bebida", unitBasePrice: 5, unitFinalPrice: 5, componentOrder: 1, modifierNames: [])
            ]
        )

        let groupId = cart.localItems.first!.comboGroupId!
        cart.removeComboFromCart(comboGroupId: groupId)

        XCTAssertTrue(cart.localItems.isEmpty)
    }

    func test_removeCombo_doesNotAffectOtherProducts() {
        cart.addToCart(productId: "standalone")
        cart.addComboToCart(
            comboId: "c1",
            comboName: "Combo",
            components: [
                (productId: "p1", slotId: "s1", slotName: "Principal", unitBasePrice: 10, unitFinalPrice: 10, componentOrder: 0, modifierNames: [])
            ]
        )

        let groupId = cart.localItems.first { $0.comboGroupId != nil }!.comboGroupId!
        cart.removeComboFromCart(comboGroupId: groupId)

        XCTAssertTrue(cart.isInCart(productId: "standalone"))
    }

    func test_updateComboQuantity_updatesAllComponents() {
        cart.addComboToCart(
            comboId: "c1",
            comboName: "Combo",
            components: [
                (productId: "p1", slotId: "s1", slotName: "Principal", unitBasePrice: 10, unitFinalPrice: 10, componentOrder: 0, modifierNames: []),
                (productId: "p2", slotId: "s2", slotName: "Bebida", unitBasePrice: 5, unitFinalPrice: 5, componentOrder: 1, modifierNames: [])
            ],
            quantity: 1
        )

        let groupId = cart.localItems.first!.comboGroupId!
        cart.updateComboQuantity(comboGroupId: groupId, quantity: 3)

        let groupItems = cart.localItems.filter { $0.comboGroupId == groupId }
        XCTAssertTrue(groupItems.allSatisfy { $0.quantity == 3 }, "Todos los componentes deben actualizarse a la misma cantidad")
    }

    func test_updateComboQuantityToZero_removesAllComponents() {
        cart.addComboToCart(
            comboId: "c1",
            comboName: "Combo",
            components: [
                (productId: "p1", slotId: "s1", slotName: "Principal", unitBasePrice: 10, unitFinalPrice: 10, componentOrder: 0, modifierNames: [])
            ]
        )

        let groupId = cart.localItems.first!.comboGroupId!
        cart.updateComboQuantity(comboGroupId: groupId, quantity: 0)

        XCTAssertTrue(cart.localItems.isEmpty)
    }

    // MARK: - Showcase items

    func test_addShowcaseItem_appearsInCart() {
        cart.addShowcaseToCart(showcaseId: "s1", branchId: "b1", branchName: "Tienda", title: "Item especial", imageUrl: "", requestDescription: "Quiero una pizza napolitana")

        XCTAssertEqual(cart.localShowcaseItems.count, 1)
    }

    func test_addShowcaseWithEmptyDescription_doesNothing() {
        cart.addShowcaseToCart(showcaseId: "s1", branchId: "b1", branchName: "Tienda", title: "Item", imageUrl: "", requestDescription: "")

        XCTAssertTrue(cart.localShowcaseItems.isEmpty)
    }

    func test_addShowcaseWithOnlyWhitespace_doesNothing() {
        cart.addShowcaseToCart(showcaseId: "s1", branchId: "b1", branchName: "Tienda", title: "Item", imageUrl: "", requestDescription: "   ")

        XCTAssertTrue(cart.localShowcaseItems.isEmpty)
    }

    func test_addSameShowcaseTwice_incrementsQuantity() {
        cart.addShowcaseToCart(showcaseId: "s1", branchId: "b1", branchName: "Tienda", title: "Item", imageUrl: "", requestDescription: "Quiero pizza")
        cart.addShowcaseToCart(showcaseId: "s1", branchId: "b1", branchName: "Tienda", title: "Item", imageUrl: "", requestDescription: "Quiero pizza")

        XCTAssertEqual(cart.localShowcaseItems.count, 1)
        XCTAssertEqual(cart.localShowcaseItems.first?.quantity, 2)
    }

    func test_showcaseCount_includedInTotalCartItemCount() {
        cart.addToCart(productId: "p1", quantity: 2)
        cart.addShowcaseToCart(showcaseId: "s1", branchId: "b1", branchName: "Tienda", title: "Item", imageUrl: "", requestDescription: "Algo especial")

        XCTAssertEqual(cart.cartItemCount, 3)
    }

    // MARK: - Persistencia

    func test_cartPersistsAcrossNewInstances() {
        cart.addToCart(productId: "p1", quantity: 3)

        let newCart = CartManager(userDefaults: testDefaults)
        XCTAssertEqual(newCart.getQuantity(for: "p1"), 3)
    }

    func test_clearCartIsAlsoPersisted() {
        cart.addToCart(productId: "p1")
        cart.clearCart()

        let newCart = CartManager(userDefaults: testDefaults)
        XCTAssertFalse(newCart.isInCart(productId: "p1"))
    }
}
