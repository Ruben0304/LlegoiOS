import XCTest
@testable import LlegoiOS

@MainActor
final class BranchTypeManagerTests: XCTestCase {

    var manager: BranchTypeManager!

    override func setUp() async throws {
        manager = BranchTypeManager()
    }

    // MARK: - Estado inicial

    func test_defaultSelectedType_isRestaurante() {
        XCTAssertEqual(manager.selectedType, .restaurante)
    }

    // MARK: - setTypeFromCategoryIndex (mapeo de índice de HomeView)

    func test_index0_mapsToRestaurante() {
        manager.setTypeFromCategoryIndex(0)
        XCTAssertEqual(manager.selectedType, .restaurante)
    }

    func test_index1_mapsToTienda() {
        manager.setTypeFromCategoryIndex(1)
        XCTAssertEqual(manager.selectedType, .tienda)
    }

    func test_index2_mapsToDulceria() {
        manager.setTypeFromCategoryIndex(2)
        XCTAssertEqual(manager.selectedType, .dulceria)
    }

    func test_index3_mapsToPerfumeria() {
        manager.setTypeFromCategoryIndex(3)
        XCTAssertEqual(manager.selectedType, .perfumeria)
    }

    func test_outOfBoundsPositiveIndex_defaultsToRestaurante() {
        manager.setTypeFromCategoryIndex(99)
        XCTAssertEqual(manager.selectedType, .restaurante)
    }

    func test_negativeIndex_defaultsToRestaurante() {
        manager.setTypeFromCategoryIndex(-1)
        XCTAssertEqual(manager.selectedType, .restaurante)
    }

    func test_allValidIndexes_coverAllBranchTypes() {
        let expectedMapping: [(Int, BranchType)] = [
            (0, .restaurante),
            (1, .tienda),
            (2, .dulceria),
            (3, .perfumeria)
        ]

        for (index, expectedType) in expectedMapping {
            manager.setTypeFromCategoryIndex(index)
            XCTAssertEqual(manager.selectedType, expectedType, "El índice \(index) debería dar .\(expectedType)")
        }
    }

    // MARK: - setType directo

    func test_setType_changesSelectedType() {
        manager.setType(.tienda)
        XCTAssertEqual(manager.selectedType, .tienda)
    }

    func test_setType_canChangeBackToRestaurante() {
        manager.setType(.perfumeria)
        manager.setType(.restaurante)
        XCTAssertEqual(manager.selectedType, .restaurante)
    }

    // MARK: - graphQLValue (valor que se envía al backend)

    func test_graphQLValue_isAlwaysLowercase() {
        for type_ in [BranchType.restaurante, .tienda, .dulceria, .perfumeria] {
            manager.setType(type_)
            XCTAssertEqual(
                manager.graphQLValue,
                manager.graphQLValue.lowercased(),
                "El valor GraphQL de .\(type_) debe ser minúscula"
            )
        }
    }

    func test_graphQLValue_matchesExpectedStrings() {
        let expectedValues: [(BranchType, String)] = [
            (.restaurante, "restaurante"),
            (.tienda, "tienda"),
            (.dulceria, "dulceria"),
            (.perfumeria, "perfumeria")
        ]

        for (type_, expected) in expectedValues {
            manager.setType(type_)
            XCTAssertEqual(manager.graphQLValue, expected)
        }
    }

    func test_graphQLValue_matchesSelectedTypeRawValue() {
        for type_ in [BranchType.restaurante, .tienda, .dulceria, .perfumeria] {
            manager.setType(type_)
            XCTAssertEqual(manager.graphQLValue, type_.rawValue)
        }
    }
}
