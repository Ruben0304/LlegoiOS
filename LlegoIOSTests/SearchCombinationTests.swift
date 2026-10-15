import XCTest
@testable import LlegoiOS

final class SearchCombinationTests: XCTestCase {
    func testParsesTwoClearProductPhrasesAroundY() {
        XCTAssertEqual(
            SearchCombinationParser.parse("pizza de piña y helado de chocolate"),
            .combination(["pizza de piña", "helado de chocolate"])
        )
    }

    func testParserTentativelySplitsConjunctionsIncludingIngredients() {
        XCTAssertEqual(
            SearchCombinationParser.parse("pizza de jamón y queso"),
            .combination(["pizza de jamón", "queso"])
        )
        XCTAssertEqual(SearchCombinationParser.parse("pizza y batido"), .combination(["pizza", "batido"]))
        XCTAssertEqual(SearchCombinationParser.parse("crepe y smoothie"), .combination(["crepe", "smoothie"]))
        XCTAssertEqual(SearchCombinationParser.parse("perfume y champú"), .combination(["perfume", "champú"]))
    }

    func testParsesArticlesAndMixedSeparators() {
        XCTAssertEqual(
            SearchCombinationParser.parse("quiero una pizza de piña y un helado de chocolate"),
            .combination(["quiero una pizza de piña", "un helado de chocolate"]))
        XCTAssertEqual(SearchCombinationParser.parse("pizza, helado y jugo"),
                       .combination(["pizza", "helado", "jugo"]))
    }

    func testSegmentsRetainWhichConjunctionsCanBeResolvedAsProductNames() {
        XCTAssertEqual(
            SearchCombinationParser.segments("pizza de jamón y queso y helado de chocolate"),
            [
                SearchCombinationSegment(text: "pizza de jamón", canMergeWithPrevious: false),
                SearchCombinationSegment(text: "queso", canMergeWithPrevious: true),
                SearchCombinationSegment(text: "helado de chocolate", canMergeWithPrevious: true)
            ]
        )
    }

    func testCommaAndPlusAreExplicitSeparators() {
        XCTAssertEqual(
            SearchCombinationParser.segments("pizza, y queso").map(\.canMergeWithPrevious),
            [false, false])
        XCTAssertEqual(SearchCombinationParser.parse("pizza, helado"), .combination(["pizza", "helado"]))
        XCTAssertEqual(SearchCombinationParser.parse("pizza + helado"), .combination(["pizza", "helado"]))
        XCTAssertEqual(SearchCombinationParser.parse("pizza; helado"), .combination(["pizza", "helado"]))
        XCTAssertEqual(
            SearchCombinationParser.segments("pizza, queso + batido; smoothie").map(\.canMergeWithPrevious),
            [false, false, false, false]
        )
    }

    func testExplicitQuantityRequestsConfiguration() {
        XCTAssertEqual(SearchCombinationParser.parse("2 pizzas y 1 helado"), .quantityNeedsConfiguration)
        XCTAssertEqual(SearchCombinationParser.parse("2x pizzas + 1 helado"), .quantityNeedsConfiguration)
        XCTAssertEqual(SearchCombinationParser.parse("pizza x2 y helado"), .quantityNeedsConfiguration)
        XCTAssertEqual(SearchCombinationParser.parse("quiero 2 pizzas y un helado"), .quantityNeedsConfiguration)
        XCTAssertEqual(SearchCombinationParser.parse("quiero dos pizzas y un helado"), .quantityNeedsConfiguration)
        XCTAssertEqual(SearchCombinationParser.parse("dame 3 crepes"), .quantityNeedsConfiguration)
        XCTAssertEqual(SearchCombinationParser.parse("7up"), .single)
        XCTAssertEqual(SearchCombinationParser.parse("pizza 4 quesos"), .single)
    }

    func testCombinationIntentCountIsBounded() {
        XCTAssertEqual(
            SearchCombinationParser.parse("pizza y helado y sushi y jugo y pasta"),
            .tooManyIntents
        )
    }

    func testCombinationRequiresActualSameBranchDistinctAvailableProductsAndSameCurrency() {
        let pizza = candidate(id: "pizza", branch: "branch-a", name: "Pizza de piña", price: 12)
        let iceCream = candidate(id: "ice", branch: "branch-a", name: "Helado de chocolate", price: 5)
        let otherBranchIceCream = candidate(id: "ice-b", branch: "branch-b", name: "Helado de chocolate", price: 4)
        let unavailable = candidate(id: "ice-off", branch: "branch-a", name: "Helado de chocolate", price: 3, available: false)

        let combos = SearchCombinationMatcher.build(
            intents: ["pizza de piña", "helado de chocolate"],
            candidatesByIntent: [[pizza], [iceCream, otherBranchIceCream, unavailable]]
        )

        XCTAssertEqual(combos.count, 1)
        XCTAssertEqual(combos[0].branchId, "branch-a")
        XCTAssertEqual(combos[0].totalPrice, 17)
        XCTAssertEqual(combos[0].products.map(\.id), ["pizza", "ice"])
        XCTAssertEqual(combos[0].products.map(\.quantity), [1, 1])
    }

    func testRejectsDifferentCurrenciesAndUnrelatedVectorHit() {
        let pizza = candidate(id: "pizza", branch: "branch", name: "Pizza de piña", price: 12, currency: "USD")
        let iceCream = candidate(id: "ice", branch: "branch", name: "Helado de chocolate", price: 5, currency: "EUR")
        let unrelated = candidate(id: "soup", branch: "branch", name: "Sopa del día", price: 4)

        XCTAssertTrue(SearchCombinationMatcher.build(
            intents: ["pizza de piña", "helado de chocolate"],
            candidatesByIntent: [[pizza], [iceCream]]
        ).isEmpty)
        XCTAssertTrue(SearchCombinationMatcher.matchingCandidates(
            intent: "helado de chocolate", candidates: [unrelated]
        ).isEmpty)
    }

    func testRequiresFlavorQualifiersAndNormalizesCommonPlurals() {
        let hamPizza = candidate(
            id: "ham-pizza",
            branch: "branch",
            name: "Pizza de jamón",
            price: 10,
            description: "Jamones curados"
        )
        let pineapplePizza = candidate(
            id: "pineapple-pizza",
            branch: "branch",
            name: "Pizza",
            price: 11,
            description: "Pizza con piñas frescas"
        )

        XCTAssertTrue(SearchCombinationMatcher.matchingCandidates(
            intent: "quiero una pizza de piña", candidates: [hamPizza]
        ).isEmpty)
        XCTAssertEqual(
            SearchCombinationMatcher.matchingCandidates(
                intent: "quiero una pizza de piñas", candidates: [pineapplePizza]
            ).map(\.id),
            ["pineapple-pizza"]
        )
    }

    func testSingleTermCanMatchExactDescriptionTokenButNotSimilarWord() {
        let ensure = candidate(
            id: "ensure",
            branch: "branch",
            name: "Ensure Original Nutrition Shake Fresa",
            price: 8,
            description: "Batido nutricional sabor fresa"
        )
        let similarDescription = candidate(
            id: "similar",
            branch: "branch",
            name: "Bebida de fruta",
            price: 6,
            description: "Batida de fresa"
        )

        XCTAssertEqual(
            SearchCombinationMatcher.matchingCandidates(intent: "batido", candidates: [ensure]).map(\.id),
            ["ensure"]
        )
        XCTAssertTrue(SearchCombinationMatcher.matchingCandidates(
            intent: "batido", candidates: [similarDescription]
        ).isEmpty)
    }

    func testResolverMergesIngredientConjunctionWhenCatalogNameProvesFullProduct() {
        let segments = SearchCombinationParser.segments("pizza de jamón y queso")
        let pizza = candidate(id: "pizza", branch: "branch", name: "Pizza de jamón y queso", price: 12)
        let resolved = SearchCombinationIntentResolver.resolve(
            segments: segments,
            candidatesBySegment: [[pizza], []],
            catalogCandidates: [pizza]
        )

        XCTAssertEqual(resolved.map(\.intent), ["pizza de jamón y queso"])
        XCTAssertEqual(resolved[0].products.map(\.id), ["pizza"])
    }

    func testResolverDoesNotMergeDifferentProductsFromDescriptionEvidence() {
        let segments = SearchCombinationParser.segments("pizza y batido")
        let pizza = candidate(
            id: "pizza", branch: "branch", name: "Pizza Margarita", price: 12,
            description: "Incluye batido de fresa"
        )
        let shake = candidate(id: "shake", branch: "branch", name: "Batido de fresa", price: 5)
        let resolved = SearchCombinationIntentResolver.resolve(
            segments: segments,
            candidatesBySegment: [[pizza], [shake]],
            catalogCandidates: [pizza, shake]
        )

        XCTAssertEqual(resolved.map(\.intent), ["pizza", "batido"])
        XCTAssertEqual(resolved.map { $0.products.map(\.id) }, [["pizza"], ["shake"]])
    }

    func testResolverUsesLongestCatalogProvenSpanAndDoesNotMergeAcrossExplicitSeparators() {
        let conjunctive = SearchCombinationParser.segments("pizza jamón y queso y batido")
        let pizza = candidate(id: "pizza", branch: "branch", name: "Pizza de jamón y queso", price: 12)
        let shake = candidate(id: "shake", branch: "branch", name: "Batido de fresa", price: 5)
        let resolved = SearchCombinationIntentResolver.resolve(
            segments: conjunctive,
            candidatesBySegment: [[pizza], [], [shake]],
            catalogCandidates: [pizza, shake]
        )
        XCTAssertEqual(resolved.map(\.intent), ["pizza jamón y queso", "batido"])

        let explicit = SearchCombinationParser.segments("pizza, queso")
        let cheesePizza = candidate(id: "pizza-cheese", branch: "branch", name: "Pizza queso", price: 10)
        let explicitResult = SearchCombinationIntentResolver.resolve(
            segments: explicit,
            candidatesBySegment: [[pizza], [cheesePizza]],
            catalogCandidates: [pizza, cheesePizza]
        )
        XCTAssertEqual(explicitResult.map(\.intent), ["pizza", "queso"])
        XCTAssertEqual(explicitResult.map { $0.products.map(\.id) }, [["pizza"], ["pizza-cheese"]])
    }

    func testResolverSupportsGenericNamesWithoutProductDictionary() {
        for queryAndNames in [
            ("crepe y smoothie", ["Crepe de fresa", "Smoothie de mango"]),
            ("perfume y champú", ["Perfume floral", "Champú suave"])
        ] {
            let segments = SearchCombinationParser.segments(queryAndNames.0)
            let first = candidate(id: "first", branch: "branch", name: queryAndNames.1[0], price: 10)
            let second = candidate(id: "second", branch: "branch", name: queryAndNames.1[1], price: 8)
            let resolved = SearchCombinationIntentResolver.resolve(
                segments: segments,
                candidatesBySegment: [[first], [second]],
                catalogCandidates: [first, second]
            )
            XCTAssertEqual(resolved.map(\.products.count), [1, 1])
        }
    }

    func testResolverKeepsShortMeaningfulTermsAndIgnoresOnlyConnectorY() {
        let segments = SearchCombinationParser.segments("té y limón")
        let tea = candidate(id: "tea", branch: "branch", name: "Té y limón", price: 4)
        let resolved = SearchCombinationIntentResolver.resolve(
            segments: segments,
            candidatesBySegment: [[], []],
            catalogCandidates: [tea]
        )

        XCTAssertEqual(resolved.map(\.intent), ["té y limón"])
    }

    func testBuildsAtMostOneCombinationPerBranch() {
        let pizzaA = candidate(id: "pizza-a", branch: "branch", name: "Pizza piña", price: 10)
        let pizzaB = candidate(id: "pizza-b", branch: "branch", name: "Pizza piña especial", price: 12)
        let iceA = candidate(id: "ice-a", branch: "branch", name: "Helado chocolate", price: 4)
        let iceB = candidate(id: "ice-b", branch: "branch", name: "Helado chocolate premium", price: 6)

        let combos = SearchCombinationMatcher.build(
            intents: ["pizza piña", "helado chocolate"],
            candidatesByIntent: [[pizzaA, pizzaB], [iceA, iceB]]
        )

        XCTAssertEqual(combos.count, 1)
        XCTAssertEqual(combos[0].products.map(\.id), ["pizza-a", "ice-a"])
    }

    func testBroadIntentDoesNotConsumeOnlyMatchForSpecificIntent() {
        let pineapple = candidate(id: "pineapple", branch: "branch", name: "Pizza piña", price: 10)
        let ham = candidate(id: "ham", branch: "branch", name: "Pizza jamón", price: 12)
        let combos = SearchCombinationMatcher.build(
            intents: ["pizza", "pizza piña"], candidatesByIntent: [[pineapple, ham], [pineapple]])
        XCTAssertEqual(combos.first?.products.map(\.id), ["ham", "pineapple"])
    }

    func testCommonBranchBeyondFirstTwentyCandidatesIsFound() {
        let pizzas = (0..<25).map {
            candidate(id: "pizza-\($0)", branch: "branch-\($0)", name: "Pizza piña", price: 10)
        }
        let ice = candidate(id: "ice", branch: "branch-24", name: "Helado chocolate", price: 4)
        let combos = SearchCombinationMatcher.build(
            intents: ["pizza piña", "helado chocolate"], candidatesByIntent: [pizzas, [ice]])
        XCTAssertEqual(combos.first?.branchId, "branch-24")
    }

    private func candidate(
        id: String,
        branch: String,
        name: String,
        price: Double,
        currency: String = "USD",
        available: Bool = true,
        description: String = ""
    ) -> SearchCombinationCandidate {
        SearchCombinationCandidate(
            id: id,
            branchId: branch,
            branchName: "Sucursal",
            businessName: "Negocio",
            name: name,
            description: description,
            price: price,
            currency: currency,
            imageUrl: nil,
            availability: available
        )
    }
}
