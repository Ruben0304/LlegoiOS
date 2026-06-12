import XCTest
@testable import LlegoiOS

// Tests de lógica pura de modelos del carrito (sin I/O, sin red)

final class CartItemLocalTests: XCTestCase {

    // MARK: - buildCartItemId: sin variantes

    func test_noVariants_idEqualsProductId() {
        let id = CartItemLocal.buildCartItemId(productId: "p1", selectedVariants: [])
        XCTAssertEqual(id, "p1")
    }

    // MARK: - buildCartItemId: con variantes

    func test_withVariant_idIsDifferentFromProductId() {
        let variant = SelectedVariantOption(listId: "size", listName: "Tamaño", optionId: "l", optionName: "Grande", priceAdjustment: 0)
        let id = CartItemLocal.buildCartItemId(productId: "p1", selectedVariants: [variant])

        XCTAssertNotEqual(id, "p1")
        XCTAssertTrue(id.hasPrefix("p1::"))
    }

    func test_differentVariantOptions_generateDifferentIds() {
        let small = SelectedVariantOption(listId: "size", listName: "Tamaño", optionId: "s", optionName: "Pequeño", priceAdjustment: 0)
        let large = SelectedVariantOption(listId: "size", listName: "Tamaño", optionId: "l", optionName: "Grande", priceAdjustment: 10)

        let idSmall = CartItemLocal.buildCartItemId(productId: "p1", selectedVariants: [small])
        let idLarge = CartItemLocal.buildCartItemId(productId: "p1", selectedVariants: [large])

        XCTAssertNotEqual(idSmall, idLarge)
    }

    func test_differentProducts_generateDifferentIds() {
        let variant = SelectedVariantOption(listId: "size", listName: "Tamaño", optionId: "l", optionName: "Grande", priceAdjustment: 0)

        let id1 = CartItemLocal.buildCartItemId(productId: "p1", selectedVariants: [variant])
        let id2 = CartItemLocal.buildCartItemId(productId: "p2", selectedVariants: [variant])

        XCTAssertNotEqual(id1, id2)
    }

    func test_sameVariantsDifferentOrder_generateSameId() {
        // El orden en que el usuario selecciona variantes no debe cambiar la línea del carrito
        let v1 = SelectedVariantOption(listId: "size", listName: "Tamaño", optionId: "l", optionName: "Grande", priceAdjustment: 0)
        let v2 = SelectedVariantOption(listId: "color", listName: "Color", optionId: "r", optionName: "Rojo", priceAdjustment: 0)

        let id1 = CartItemLocal.buildCartItemId(productId: "p1", selectedVariants: [v1, v2])
        let id2 = CartItemLocal.buildCartItemId(productId: "p1", selectedVariants: [v2, v1])

        XCTAssertEqual(id1, id2)
    }

    func test_variantWithoutOptionId_usesOptionName() {
        // Cuando no hay optionId, la clave de la variante se basa en el optionName
        let withId = SelectedVariantOption(listId: "size", listName: "Tamaño", optionId: "l", optionName: "Grande", priceAdjustment: 0)
        let withoutId = SelectedVariantOption(listId: "size", listName: "Tamaño", optionId: nil, optionName: "Grande", priceAdjustment: 0)

        let idWith = CartItemLocal.buildCartItemId(productId: "p1", selectedVariants: [withId])
        let idWithout = CartItemLocal.buildCartItemId(productId: "p1", selectedVariants: [withoutId])

        // Con optionId="l" y optionName="Grande" → clave es "l"
        // Sin optionId → clave es "Grande"
        // Son distintos porque la clave cambia
        XCTAssertNotEqual(idWith, idWithout)
    }

    // MARK: - Precio total al construir el modelo

    func test_init_withBasePrice_calculatesTotalFromBase() {
        let item = CartItemLocal(productId: "p1", quantity: 3, basePrice: 10.0)
        XCTAssertEqual(item.finalTotalPrice, 30.0)
    }

    func test_init_withFinalUnitPrice_usesFinalNotBase() {
        // Si hay finalUnitPrice, ese es el que se usa para el total (no basePrice)
        let item = CartItemLocal(productId: "p1", quantity: 2, basePrice: 10.0, finalUnitPrice: 12.0)
        XCTAssertEqual(item.finalTotalPrice, 24.0)
    }

    func test_init_noPriceGiven_totalIsZero() {
        let item = CartItemLocal(productId: "p1", quantity: 5)
        XCTAssertEqual(item.finalTotalPrice, 0.0)
    }

    func test_init_quantity1_totalEqualsUnitPrice() {
        let item = CartItemLocal(productId: "p1", quantity: 1, finalUnitPrice: 99.99)
        XCTAssertEqual(item.finalTotalPrice, 99.99, accuracy: 0.001)
    }
}

// MARK: - ShowcaseCartItemLocal

final class ShowcaseCartItemLocalTests: XCTestCase {

    // MARK: - buildCartItemId: determinismo

    func test_sameInput_generatesSameId() {
        let id1 = ShowcaseCartItemLocal.buildCartItemId(showcaseId: "s1", requestDescription: "pizza grande")
        let id2 = ShowcaseCartItemLocal.buildCartItemId(showcaseId: "s1", requestDescription: "pizza grande")
        XCTAssertEqual(id1, id2)
    }

    func test_differentShowcaseIds_generateDifferentIds() {
        let id1 = ShowcaseCartItemLocal.buildCartItemId(showcaseId: "s1", requestDescription: "pizza")
        let id2 = ShowcaseCartItemLocal.buildCartItemId(showcaseId: "s2", requestDescription: "pizza")
        XCTAssertNotEqual(id1, id2)
    }

    func test_differentDescriptions_generateDifferentIds() {
        let id1 = ShowcaseCartItemLocal.buildCartItemId(showcaseId: "s1", requestDescription: "pizza grande")
        let id2 = ShowcaseCartItemLocal.buildCartItemId(showcaseId: "s1", requestDescription: "pizza pequeña")
        XCTAssertNotEqual(id1, id2)
    }

    // MARK: - Normalización de texto

    func test_descriptionIsCaseInsensitive() {
        // "Pizza Grande" y "pizza grande" deben ser el mismo item
        let id1 = ShowcaseCartItemLocal.buildCartItemId(showcaseId: "s1", requestDescription: "Pizza Grande")
        let id2 = ShowcaseCartItemLocal.buildCartItemId(showcaseId: "s1", requestDescription: "pizza grande")
        XCTAssertEqual(id1, id2)
    }

    func test_leadingTrailingWhitespace_isTrimmed() {
        let id1 = ShowcaseCartItemLocal.buildCartItemId(showcaseId: "s1", requestDescription: "  pizza grande  ")
        let id2 = ShowcaseCartItemLocal.buildCartItemId(showcaseId: "s1", requestDescription: "pizza grande")
        XCTAssertEqual(id1, id2)
    }

    func test_multipleInternalSpaces_areNormalized() {
        // "pizza  grande" (doble espacio) == "pizza grande"
        let id1 = ShowcaseCartItemLocal.buildCartItemId(showcaseId: "s1", requestDescription: "pizza  grande")
        let id2 = ShowcaseCartItemLocal.buildCartItemId(showcaseId: "s1", requestDescription: "pizza grande")
        XCTAssertEqual(id1, id2)
    }

    func test_idContainsShowcaseId() {
        let id = ShowcaseCartItemLocal.buildCartItemId(showcaseId: "showcase-abc", requestDescription: "algo")
        XCTAssertTrue(id.contains("showcase-abc"))
    }
}
