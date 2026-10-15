import XCTest
@testable import LlegoiOS

@MainActor
final class SearchCombinationCartTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    private var cart: CartManager!

    override func setUp() async throws {
        suite = "SearchCombinationCartTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        cart = CartManager(userDefaults: defaults)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suite)
        cart = nil
        defaults = nil
    }

    func testAddsNormalLinesAndPersistsWholeCombination() async throws {
        let coordinator = coordinator()
        let result = try await coordinator.prepare(combination())
        guard case .added = result else { return XCTFail("Expected added") }
        XCTAssertEqual(cart.cartItemCount, 2)
        XCTAssertTrue(cart.localItems.allSatisfy { $0.comboId == nil && $0.comboGroupId == nil })
        XCTAssertEqual(cart.localItems.map(\.finalTotalPrice).reduce(0, +), 30)
        XCTAssertEqual(CartManager(userDefaults: defaults).localItems.count, 2)
    }

    func testUnavailableSecondProductDoesNotAddFirst() async {
        let coordinator = coordinator(unavailableID: "ice")
        do {
            _ = try await coordinator.prepare(combination())
            XCTFail("Unavailable product must fail")
        } catch {}
        XCTAssertTrue(cart.localItems.isEmpty)
        XCTAssertEqual(cart.cartItemCount, 0)
    }

    func testPriceChangeDoesNotAddAnyProducts() async {
        let coordinator = SearchCombinationCartCoordinator(cart: cart, canOrderFromBranch: { _ in true }) { id in
            self.detail(id, price: 12)
        }
        do {
            _ = try await coordinator.prepare(combination())
            XCTFail("Changed price must fail")
        } catch {}
        XCTAssertTrue(cart.localItems.isEmpty)
    }

    func testExistingDifferentBranchIsPreservedWithoutMixing() async {
        cart.addToCart(productId: "existing")
        let coordinator = SearchCombinationCartCoordinator(cart: cart, canOrderFromBranch: { _ in true }) { id in
            self.detail(id, branch: id == "existing" ? "other" : "branch")
        }
        do {
            _ = try await coordinator.prepare(combination())
            XCTFail("Different branch must fail")
        } catch {}
        XCTAssertEqual(cart.localItems.map(\.productId), ["existing"])
    }

    func testVariantProductsRequireConfigurationWithoutPartialAdd() async throws {
        let result = try await coordinator(withVariants: true).prepare(combination())
        guard case .requiresConfiguration(let ids) = result else { return XCTFail("Expected options") }
        XCTAssertEqual(ids, ["pizza"])
        XCTAssertTrue(cart.localItems.isEmpty)
    }

    func testConfiguredVariantsUseOrdinaryLinesAndCorrectTotal() async throws {
        let coordinator = coordinator(withVariants: true)
        let option = SelectedVariantOption(
            listId: "size", listName: "Tamaño", optionId: "large",
            optionName: "Grande", priceAdjustment: 5)
        _ = try await coordinator.add(combination(), selections: ["pizza": [option]])
        XCTAssertEqual(cart.localItems.first(where: { $0.productId == "pizza" })?.finalUnitPrice, 25)
        XCTAssertEqual(cart.localItems.first(where: { $0.productId == "pizza" })?.selectedVariants, [option])
        XCTAssertEqual(cart.cartItemCount, 2)
        XCTAssertTrue(cart.localItems.allSatisfy { $0.comboId == nil })
    }

    func testInvalidVariantDoesNotPartiallyAdd() async {
        do {
            _ = try await coordinator(withVariants: true).add(combination(), selections: [:])
            XCTFail("Missing variant must fail")
        } catch {}
        XCTAssertTrue(cart.localItems.isEmpty)
    }

    func testBatchValidationFailureLeavesExistingCartUntouched() throws {
        cart.addToCart(productId: "existing")
        XCTAssertThrowsError(try cart.addSearchCombinationProducts([
            .init(productId: "pizza", quantity: 1, selectedVariants: [], basePrice: 20, unitPrice: 20),
            .init(productId: "ice", quantity: 0, selectedVariants: [], basePrice: 10, unitPrice: 10)
        ]))
        XCTAssertEqual(cart.localItems.map(\.productId), ["existing"])
        XCTAssertEqual(CartManager(userDefaults: defaults).localItems.map(\.productId), ["existing"])
    }

    func testCartChangedDuringValidationIsCheckedBeforeCommit() async {
        cart.addToCart(productId: "existing")
        var changedCart = false
        let coordinator = SearchCombinationCartCoordinator(cart: cart, canOrderFromBranch: { _ in true }) { id in
            if id == "existing", !changedCart {
                changedCart = true
                self.cart.addToCart(productId: "other-branch-product")
            }
            return self.detail(id, branch: id == "other-branch-product" ? "other" : "branch")
        }
        do {
            _ = try await coordinator.prepare(combination())
            XCTFail("The new cart product must be validated too")
        } catch {}
        XCTAssertFalse(cart.isInCart(productId: "pizza"))
        XCTAssertFalse(cart.isInCart(productId: "ice"))
        XCTAssertTrue(cart.isInCart(productId: "other-branch-product"))
    }

    func testCatalogOnlyBranchCannotAddCombination() async {
        let coordinator = SearchCombinationCartCoordinator(cart: cart, canOrderFromBranch: { _ in false }) { id in
            self.detail(id)
        }
        do {
            _ = try await coordinator.prepare(combination())
            XCTFail("Catalog only branch must fail")
        } catch {}
        XCTAssertTrue(cart.localItems.isEmpty)
    }

    func testPausedBranchDoesNotAddAndKeepsPauseMessage() async {
        let coordinator = SearchCombinationCartCoordinator(cart: cart, canOrderFromBranch: { _ in
            throw SearchCombinationCartError.ordersPaused
        }) { id in self.detail(id) }
        do {
            _ = try await coordinator.prepare(combination())
            XCTFail("Paused branch must fail")
        } catch {
            XCTAssertEqual(error.localizedDescription, BranchOrderingMessages.notAcceptingOrdersDetail)
        }
        XCTAssertTrue(cart.localItems.isEmpty)
    }

    func testChangedVariantPriceDoesNotAddWithStaleTotal() async {
        let staleOption = SelectedVariantOption(
            listId: "size", listName: "Tamaño", optionId: "large", optionName: "Grande", priceAdjustment: 3)
        do {
            _ = try await coordinator(withVariants: true).add(combination(), selections: ["pizza": [staleOption]])
            XCTFail("Changed modifier price must fail")
        } catch {}
        XCTAssertTrue(cart.localItems.isEmpty)
    }

    private func combination() -> SearchCombination {
        SearchCombination(id: "test", branchId: "branch", branchName: "Tienda", products: [
            .init(id: "pizza", branchId: "branch", name: "Pizza de piña", price: 20, currency: "CUP", imageUrl: nil),
            .init(id: "ice", branchId: "branch", name: "Helado de chocolate", price: 10, currency: "CUP", imageUrl: nil)
        ], totalPrice: 30, currency: "CUP")
    }

    private func coordinator(unavailableID: String? = nil, withVariants: Bool = false) -> SearchCombinationCartCoordinator {
        SearchCombinationCartCoordinator(cart: cart, canOrderFromBranch: { _ in true }) { id in
            self.detail(id, available: id != unavailableID, withVariants: withVariants && id == "pizza")
        }
    }

    private func detail(
        _ id: String, branch: String = "branch", price: Double? = nil,
        available: Bool = true, withVariants: Bool = false
    ) -> ProductDetailGraphQL {
        ProductDetailGraphQL(
            id: id, branchId: branch, name: id, description: "", weight: "",
            price: price ?? (id == "pizza" ? 20 : 10), currency: "CUP",
            convertedPrice: nil, convertedCurrency: nil, exchangeRate: nil,
            imageUrl: "", availability: available, categoryId: nil, createdAt: "",
            businessName: "Tienda", businessLogoUrl: nil, shopRating: nil,
            variantListIds: withVariants ? ["size"] : [],
            variantLists: withVariants ? [VariantList(
                id: "size", name: "Tamaño", description: nil,
                options: [.init(id: "large", name: "Grande", priceAdjustment: 5)])] : [])
    }
}
