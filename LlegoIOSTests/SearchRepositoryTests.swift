import Apollo
import Combine
import Foundation
import XCTest
@testable import LlegoiOS

@MainActor
final class SearchRepositoryTests: XCTestCase {
    func testPausedOriginalBusinessStillAllowsAlternativesElsewhere() async throws {
        let session = SearchFixtureSession(sameBranch: false, cartBranches: ["pizza": "same-branch"], alternativePizzaName: "Pizza Margarita", pausedBranchIds: ["same-branch"])
        let model = try await search("limonada", session: session, cartManager: makeCart(["pizza"]))
        defer { model.cancelCurrentSearch() }
        XCTAssertTrue(model.cartSearchSuggestions.isEmpty)
        XCTAssertEqual(model.cartAlternativeCombinations.map(\.branchId), ["other-branch"])
    }

    func testPausedAlternativeBusinessIsNotRecommended() async throws {
        let session = SearchFixtureSession(sameBranch: false, cartBranches: ["pizza": "same-branch"], alternativePizzaName: "Pizza Margarita", pausedBranchIds: ["other-branch"])
        let model = try await search("limonada", session: session, cartManager: makeCart(["pizza"]))
        defer { model.cancelCurrentSearch() }
        XCTAssertTrue(model.cartAlternativeCombinations.isEmpty)
        XCTAssertFalse(model.cartSearchSuggestions.isEmpty)
    }

    func testCartAndQuerySuggestCompleteCombinationAtAnotherBranch() async throws {
        let session = SearchFixtureSession(sameBranch: false, cartBranches: ["pizza": "same-branch"], alternativePizzaName: "Pizza Margarita")
        let cart = makeCart(["pizza"])
        let model = try await search("limonada", session: session, cartManager: cart)
        defer { model.cancelCurrentSearch() }
        XCTAssertEqual(model.cartAlternativeCombinations.count, 1)
        let combination = try XCTUnwrap(model.cartAlternativeCombinations.first)
        XCTAssertEqual(combination.branchId, "other-branch")
        XCTAssertEqual(combination.products.map(\.name), ["Pizza Margarita", "Limonada frescura"])
        XCTAssertEqual(combination.totalPrice, 2340)
        XCTAssertEqual(model.cartSearchSuggestions.map(\.id), ["local-lemonade"])
        XCTAssertEqual(cart.localItems.map(\.productId), ["pizza"])
        cart.clearCart()
        XCTAssertTrue(model.cartAlternativeCombinations.isEmpty)
    }

    func testCartAlternativeRequiresPizzaQualifierAndBothProducts() async throws {
        let session = SearchFixtureSession(sameBranch: false, cartBranches: ["pizza": "same-branch"], alternativePizzaName: "Pizza de jamón")
        let model = try await search("limonada", session: session, cartManager: makeCart(["pizza"]))
        defer { model.cancelCurrentSearch() }
        XCTAssertTrue(model.cartAlternativeCombinations.isEmpty)
        XCTAssertFalse(model.cartSearchSuggestions.isEmpty)
    }

    func testCartAlternativesExcludeOriginalBranch() async throws {
        let session = SearchFixtureSession(cartBranches: ["pizza": "same-branch"])
        let model = try await search("limonada", session: session, cartManager: makeCart(["pizza"]))
        defer { model.cancelCurrentSearch() }
        XCTAssertTrue(model.cartAlternativeCombinations.isEmpty)
    }

    func testCartBusinessMatchesAreHighlightedWithoutReplacingGlobalResults() async throws {
        let session = SearchFixtureSession(sameBranch: false, cartBranches: ["pizza": "same-branch"])
        let cart = makeCart(["pizza"])
        let model = try await search("limonada", session: session, cartManager: cart)
        defer { model.cancelCurrentSearch() }
        XCTAssertEqual(model.cartSearchContext?.branchId, "same-branch")
        XCTAssertEqual(model.cartSearchContext?.cartProductNames, ["Pizza Margarita"])
        XCTAssertEqual(model.cartSearchSuggestions.map(\.id), ["local-lemonade"])
        XCTAssertEqual(model.products.map(\.id), ["lemonade"], "Global alternatives must remain available")
        XCTAssertEqual(cart.localItems.map(\.productId), ["pizza"], "Searching must not modify the cart")
    }

    func testCartSuggestionsExcludeProductsAlreadyInCart() async throws {
        let session = SearchFixtureSession(cartBranches: ["pizza": "same-branch", "local-lemonade": "same-branch"])
        let model = try await search("limonada", session: session, cartManager: makeCart(["pizza", "local-lemonade"]))
        defer { model.cancelCurrentSearch() }
        XCTAssertTrue(model.cartSearchSuggestions.isEmpty)
        XCTAssertFalse(model.products.isEmpty)
    }

    func testMixedBranchCartDoesNotClaimOneSharedBusiness() async throws {
        let session = SearchFixtureSession(cartBranches: ["pizza": "same-branch", "foreign": "other-branch"])
        let model = try await search("limonada", session: session, cartManager: makeCart(["pizza", "foreign"]))
        defer { model.cancelCurrentSearch() }
        XCTAssertNil(model.cartSearchContext)
        XCTAssertTrue(model.cartSearchSuggestions.isEmpty)
        XCTAssertFalse(model.products.isEmpty)
    }

    func testCartChangesInvalidateHighlightedResults() async throws {
        let session = SearchFixtureSession(cartBranches: ["pizza": "same-branch", "foreign": "other-branch"])
        let cart = makeCart(["pizza"])
        let model = try await search("limonada", session: session, cartManager: cart)
        defer { model.cancelCurrentSearch() }
        XCTAssertEqual(model.cartSearchSuggestions.map(\.id), ["local-lemonade"])
        cart.addToCart(productId: "foreign")
        await waitForCartSuggestions(model)
        XCTAssertNil(model.cartSearchContext)
        XCTAssertTrue(model.cartSearchSuggestions.isEmpty)
        XCTAssertFalse(model.products.isEmpty)
        cart.clearCart()
        XCTAssertNil(model.cartSearchContext)
        XCTAssertTrue(model.cartSearchSuggestions.isEmpty)
    }

    func testEmptyCartDoesNotMakeRecommendationRequests() async throws {
        let session = SearchFixtureSession(cartBranches: [:])
        let model = try await search("limonada", session: session, cartManager: makeCart([]))
        defer { model.cancelCurrentSearch() }
        let operations = await session.requestOperations
        XCTAssertFalse(operations.contains("GetProductsByIds"))
        XCTAssertTrue(model.cartSearchSuggestions.isEmpty)
    }

    func testRecommendationFailureDoesNotBreakNormalSearch() async throws {
        let session = SearchFixtureSession(cartBranches: ["pizza": "same-branch"], cartLookupFails: true)
        let model = try await search("limonada", session: session, cartManager: makeCart(["pizza"]))
        defer { model.cancelCurrentSearch() }
        XCTAssertTrue(model.cartSearchSuggestions.isEmpty)
        XCTAssertEqual(model.products.map(\.name), ["Limonada frescura"])
        guard case .success = model.state else { return XCTFail("Normal search must succeed") }
    }

    func testCatalogOnlyBusinessIsNotHighlightedForPurchases() async throws {
        let session = SearchFixtureSession(cartBranches: ["pizza": "same-branch"], cartCatalogOnly: true)
        let result = try await repository(session: session).searchCartSuggestions(query: "limonada", cartProductIds: ["pizza"])
        XCTAssertNil(result)
    }

    func testShowcaseFromAnotherBranchPreventsSharedBusinessClaim() async throws {
        let session = SearchFixtureSession(cartBranches: ["pizza": "same-branch"])
        let result = try await repository(session: session).searchCartSuggestions(
            query: "limonada", cartProductIds: ["pizza"], showcaseBranchIds: ["other-branch"])
        XCTAssertNil(result)
    }

    private func makeCart(_ ids: [String]) -> CartManager {
        let suite = "SearchCartContextTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        let cart = CartManager(userDefaults: defaults)
        for id in ids { cart.addToCart(productId: id) }
        return cart
    }

    private func waitForCartSuggestions(_ model: SearchViewModel) async {
        let ready = expectation(description: "Cart suggestions finished")
        let subscription = model.$isLoadingCartSuggestions.filter { !$0 }.prefix(1).sink { _ in ready.fulfill() }
        defer { subscription.cancel() }
        await fulfillment(of: [ready], timeout: 5)
    }

    func testPizzaAndBatidoRunsThroughViewModelAsTwoProducts() async throws {
        let session = SearchFixtureSession(secondTerm: "batido", secondName: "Batido de fresa")
        let model = try await search("pizza y batido", session: session)
        defer { model.cancelCurrentSearch() }
        XCTAssertTrue(model.isShowingCombinationResults)
        XCTAssertEqual(model.combinationIntentResults.map(\.intent), ["pizza", "batido"])
        XCTAssertEqual(model.searchCombinations.first?.products.map(\.name), ["Pizza Margarita", "Batido de fresa"])
        let queries = await session.requestVariables.compactMap { $0["query"] }
        XCTAssertTrue(queries.contains("pizza"))
        XCTAssertTrue(queries.contains("batido"))
    }

    func testDescribedBatidoInOtherStoreIsShownSeparately() async throws {
        let session = SearchFixtureSession(
            secondTerm: "batido", secondName: "Ensure Nutrition Shake Fresa",
            secondDescription: "Batido nutricional sabor fresa", sameBranch: false)
        let model = try await search("pizza y batido", session: session)
        defer { model.cancelCurrentSearch() }
        XCTAssertTrue(model.searchCombinations.isEmpty)
        XCTAssertEqual(model.combinationIntentResults.count, 2)
        XCTAssertEqual(model.combinationIntentResults.last?.products.first?.name, "Ensure Nutrition Shake Fresa")
    }

    func testNonFoodProductsDoNotRequireKnownProductNames() async throws {
        let session = SearchFixtureSession(
            secondTerm: "champú", secondName: "Champú de coco", firstName: "Perfume Rosa")
        let model = try await search("perfume y champú", session: session)
        defer { model.cancelCurrentSearch() }
        XCTAssertEqual(model.searchCombinations.first?.products.map(\.name), ["Perfume Rosa", "Champú de coco"])
    }

    func testCatalogProductWithIngredientConjunctionKeepsNormalSearch() async throws {
        let session = SearchFixtureSession(firstName: "Pizza de jamón y queso")
        let model = try await search("pizza de jamón y queso", session: session)
        defer { model.cancelCurrentSearch() }
        XCTAssertFalse(model.isShowingCombinationResults)
        XCTAssertEqual(model.products.first?.name, "Pizza de jamón y queso")
    }

    private func search(
        _ query: String, session: SearchFixtureSession, cartManager: CartManager? = nil
    ) async throws -> SearchViewModel {
        let model = SearchViewModel(searchRepository: repository(session: session), cartManager: cartManager ?? .shared)
        let completed = expectation(description: "Search finished: \(query)")
        let subscription = model.$state.sink { state in
            switch state {
            case .success, .empty, .error: completed.fulfill()
            default: break
            }
        }
        defer { subscription.cancel() }
        model.search(query: query)
        await fulfillment(of: [completed], timeout: 5)
        await waitForCartSuggestions(model)
        if case .error(let message) = model.state { XCTFail(message) }
        return model
    }

    func testMargaritaAndLemonadeSearchDoesNotInheritHomeCategory() async throws {
        let previousType = BranchTypeManager.shared.selectedType
        BranchTypeManager.shared.selectedType = .restaurante
        defer { BranchTypeManager.shared.selectedType = previousType }
        let session = SearchFixtureSession()
        let repository = repository(session: session)

        let pizza = try await repository.searchCombinationCandidates(query: "pizza margarita")
        let lemonade = try await repository.searchCombinationCandidates(query: "limonada")
        let combinations = SearchCombinationMatcher.build(
            intents: ["pizza margarita", "limonada"],
            candidatesByIntent: [pizza.candidates, lemonade.candidates])

        XCTAssertEqual(combinations.count, 1)
        XCTAssertEqual(combinations.first?.products.map(\.name), ["Pizza Margarita", "Limonada frescura"])
        XCTAssertEqual(combinations.first?.totalPrice, 2340)
        let requests = await session.requestVariables
        XCTAssertEqual(requests.count, 2)
        for variables in requests {
            XCTAssertNil(variables["branchTipo"], "Global combination search must not inherit Home's filter")
            XCTAssertNil(variables["jwt"], "Match the global SearchBoth delivery-radius behavior")
        }
    }

    private func repository(session: SearchFixtureSession) -> SearchRepository {
        let store = ApolloStore(cache: InMemoryNormalizedCache())
        let transport = RequestChainNetworkTransport(
            urlSession: session, interceptorProvider: DefaultInterceptorProvider.shared,
            store: store, endpointURL: URL(string: "https://search-fixture.invalid/graphql")!)
        return SearchRepository(apolloClient: ApolloClient(networkTransport: transport, store: store))
    }
}

/// Exercises serialization, Apollo parsing, repository mapping and matching,
/// without making network requests or depending on production catalog changes.
private actor SearchFixtureSession: ApolloURLSession {
    private(set) var requestVariables: [[String: String]] = []
    private(set) var requestOperations: [String] = []
    let secondTerm: String
    let secondName: String
    let secondDescription: String
    let firstName: String
    let sameBranch: Bool
    let cartBranches: [String: String]?
    let cartLookupFails: Bool
    let cartCatalogOnly: Bool
    let alternativePizzaName: String?
    let pausedBranchIds: Set<String>

    init(
        secondTerm: String = "limonada", secondName: String = "Limonada frescura",
        secondDescription: String = "Limonada natural", firstName: String = "Pizza Margarita",
        sameBranch: Bool = true, cartBranches: [String: String]? = nil,
        cartLookupFails: Bool = false, cartCatalogOnly: Bool = false,
        alternativePizzaName: String? = nil, pausedBranchIds: Set<String> = []
    ) {
        self.secondTerm = secondTerm
        self.secondName = secondName
        self.secondDescription = secondDescription
        self.firstName = firstName
        self.sameBranch = sameBranch
        self.cartBranches = cartBranches
        self.cartLookupFails = cartLookupFails
        self.cartCatalogOnly = cartCatalogOnly
        self.alternativePizzaName = alternativePizzaName
        self.pausedBranchIds = pausedBranchIds
    }

    func chunks(for request: URLRequest) async throws -> (any AsyncChunkSequence, URLResponse) {
        let payload = try XCTUnwrap(request.httpBody)
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: payload) as? [String: Any])
        let variables = try XCTUnwrap(body["variables"] as? [String: Any])
        requestVariables.append(variables.mapValues { String(describing: $0) })
        let operation = body["operationName"] as? String ?? ""
        requestOperations.append(operation)
        let query = variables["query"] as? String ?? ""
        if let cartBranches, operation == "GetProductsByIds" {
            if cartLookupFails {
                return try response(for: request, result: ["errors": [["message": "Cart lookup failed"]]])
            }
            let ids = variables["ids"] as? [String] ?? []
            let products = ids.compactMap { id -> [String: Any]? in
                guard let branchId = cartBranches[id] else { return nil }
                return cartProduct(id: id, branchId: branchId,
                                   name: id == "pizza" ? firstName : "Limonada frescura")
            }
            return try response(for: request, result: ["data": ["productsByIds": products]])
        }
        if cartBranches != nil, operation == "GetBranchProductsForAI" {
            let products = [
                cartProduct(id: "pizza", branchId: "same-branch", name: firstName),
                cartProduct(id: "local-lemonade", branchId: "same-branch", name: "Limonada frescura"),
                cartProduct(id: "unavailable-lemonade", branchId: "same-branch", name: "Limonada fría", available: false),
                cartProduct(id: "other-lemonade", branchId: "other-branch", name: "Limonada de otro local")
            ]
            return try response(for: request, result: ["data": ["productsFromSameBranch": products]])
        }
        if cartBranches != nil, operation == "GetBranchDetail" {
            return try response(for: request, result: ["data": ["branch": branchFixture(id: variables["id"] as? String ?? "same-branch")]])
        }
        if operation == "GetBranchDetail" {
            return try response(for: request, result: ["data": ["branch": NSNull()]])
        }
        let isPizza = !query.localizedCaseInsensitiveContains(secondTerm)
        let product: [String: Any] = [
            "__typename": "ScoredProductType", "id": isPizza ? "pizza" : "lemonade",
            "branchId": (isPizza && alternativePizzaName == nil) || sameBranch ? "same-branch" : "other-branch",
            "name": isPizza ? (alternativePizzaName ?? firstName) : secondName,
            "description": isPizza ? "Pizza con tomate, queso y albahaca" : secondDescription,
            "weight": "", "price": isPizza ? 1640.0 : 700.0, "currency": "CUP",
            "imageUrlBaja": "", "availability": true, "createdAt": "2026-01-01T00:00:00Z",
            "distanceKm": NSNull(), "score": 0.175, "categoryId": NSNull(), "category": NSNull(),
            "business": ["__typename": "BusinessType", "id": "business", "name": "Restaurante",
                         "avatarUrl": NSNull(), "avatarUrlBaja": NSNull(), "avatarUrlAlta": NSNull()]
        ]
        // The production regression returned an empty connection when this
        // unrelated Home filter was supplied, even for these available items.
        let filtered = variables["branchTipo"] != nil
        let edges: [[String: Any]] = filtered ? [] : [[
            "__typename": "ProductEdge", "cursor": "last", "node": product
        ]]
        let result: [String: Any] = ["data": ["searchProducts": [
            "__typename": "ProductConnection", "edges": edges,
            "pageInfo": ["__typename": "PageInfo", "hasNextPage": false,
                         "hasPreviousPage": false, "startCursor": NSNull(),
                         "endCursor": NSNull(), "totalCount": edges.count]
        ], "searchBranches": ["__typename": "BranchConnection", "edges": []]]]
        return try response(for: request, result: result)
    }

    private func cartProduct(id: String, branchId: String, name: String, available: Bool = true) -> [String: Any] {
        ["__typename": "ProductType", "id": id, "branchId": branchId, "name": name,
         "description": name, "weight": "", "price": 700.0, "currency": "CUP",
         "convertedPrice": NSNull(), "convertedCurrency": NSNull(), "exchangeRate": NSNull(),
         "imageUrlMuyBaja": "", "imageUrlBaja": "", "availability": available,
         "business": ["__typename": "BusinessType", "name": "Restaurante"]]
    }

    private func branchFixture(id: String) -> [String: Any] {
        ["__typename": "BranchType", "id": id, "businessId": "business", "name": "Restaurante",
         "acceptsQvapay": false, "acceptsZelle": false, "qvapayUsername": NSNull(), "zelleEmail": NSNull(),
         "address": "Calle 1", "coordinates": ["__typename": "CoordinatesType", "type": "Point", "coordinates": [-82.0, 23.0]],
         "phone": "", "status": "ACTIVE", "avatarUrl": NSNull(), "avatarUrlBaja": NSNull(), "avatarUrlAlta": NSNull(),
         "coverUrl": NSNull(), "coverUrlBaja": NSNull(), "coverUrlAlta": NSNull(), "deliveryRadius": 5.0,
         "acceptedCurrency": "CUP", "exchangeRate": 1,
         "schedule": ["__typename": "BranchScheduleType", "days": [], "temporaryStatus": NSNull()],
         "catalogOnly": cartCatalogOnly, "acceptingOrders": !pausedBranchIds.contains(id),
         "createdAt": "2026-01-01T00:00:00Z", "showcases": []]
    }

    private func response(for request: URLRequest, result: [String: Any]) throws -> (any AsyncChunkSequence, URLResponse) {
        let data = try JSONSerialization.data(withJSONObject: result)
        let response = try XCTUnwrap(HTTPURLResponse(
            url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]))
        return (SearchFixtureChunks(data: data), response)
    }
}

private struct SearchFixtureChunks: AsyncChunkSequence {
    let data: Data

    func makeAsyncIterator() -> AsyncStream<Data>.Iterator {
        AsyncStream<Data> { continuation in
            continuation.yield(data)
            continuation.finish()
        }.makeAsyncIterator()
    }
}
