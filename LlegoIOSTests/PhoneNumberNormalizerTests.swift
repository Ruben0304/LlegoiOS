import XCTest
@testable import LlegoiOS

final class PhoneNumberNormalizerTests: XCTestCase {

    private func normalized(_ input: String) -> String? {
        try? PhoneNumberNormalizer.normalize(input).get()
    }

    private func error(_ input: String) -> PhoneNumberNormalizer.ValidationError? {
        if case .failure(let error) = PhoneNumberNormalizer.normalize(input) { return error }
        return nil
    }

    // MARK: - Vacío (borrar teléfono)

    func test_empty_returnsEmpty() {
        XCTAssertEqual(normalized(""), "")
        XCTAssertEqual(normalized("   "), "")
    }

    // MARK: - Cuba sin código de país → se agrega +53

    func test_eightDigits_addsCubaCode() {
        XCTAssertEqual(normalized("55555555"), "+5355555555")
        XCTAssertEqual(normalized("5555 5555"), "+5355555555")
        XCTAssertEqual(normalized("5555-5555"), "+5355555555")
        XCTAssertEqual(normalized(" 78 123456 "), "+5378123456")
    }

    func test_nationalTrunkPrefix_isDropped() {
        XCTAssertEqual(normalized("078123456"), "+5378123456")
    }

    func test_cubaCodeWithoutPlus_addsPlus() {
        XCTAssertEqual(normalized("5355555555"), "+5355555555")
        XCTAssertEqual(normalized("53 5555 5555"), "+5355555555")
    }

    // MARK: - Con código de país → se respeta

    func test_cubaCodeWithPlus_isKept() {
        XCTAssertEqual(normalized("+5355555555"), "+5355555555")
        XCTAssertEqual(normalized("+53 5555 5555"), "+5355555555")
        XCTAssertEqual(normalized("+ 53 (5555) 5555"), "+5355555555")
    }

    func test_internationalPrefix00_isConvertedToPlus() {
        XCTAssertEqual(normalized("0053 5555 5555"), "+5355555555")
        XCTAssertEqual(normalized("001 305 555 1234"), "+13055551234")
    }

    func test_foreignNumberWithPlus_isKept() {
        XCTAssertEqual(normalized("+1 (305) 555-1234"), "+13055551234")
        XCTAssertEqual(normalized("+34 612 345 678"), "+34612345678")
    }

    func test_alreadyNormalized_isIdempotent() {
        for phone in ["+5355555555", "+13055551234"] {
            XCTAssertEqual(normalized(phone), phone)
        }
    }

    // MARK: - Inválidos

    func test_invalidCharacters() {
        XCTAssertEqual(error("5555abcd"), .invalidCharacters)
        XCTAssertEqual(error("55+555555"), .invalidCharacters)
        XCTAssertEqual(error("*555#"), .invalidCharacters)
    }

    func test_cubanNumberWithWrongLength() {
        XCTAssertEqual(error("5555555"), .invalidCubanNumber)
        XCTAssertEqual(error("+53 5555 555"), .invalidCubanNumber)
        XCTAssertEqual(error("+53 5555 55555"), .invalidCubanNumber)
    }

    func test_foreignNumberWithoutPlus_isRejected() {
        XCTAssertEqual(error("13055551234"), .invalidInternationalNumber)
    }

    func test_invalidInternationalNumber() {
        XCTAssertEqual(error("+"), .invalidInternationalNumber)
        XCTAssertEqual(error("+1234"), .invalidInternationalNumber)
        XCTAssertEqual(error("+0123456789"), .invalidInternationalNumber)
        XCTAssertEqual(error("+1234567890123456"), .invalidInternationalNumber)
    }

    // MARK: - Registro (tolerante)

    func test_normalizedOrOriginal() {
        XCTAssertEqual(PhoneNumberNormalizer.normalizedOrOriginal("5555 5555"), "+5355555555")
        XCTAssertEqual(PhoneNumberNormalizer.normalizedOrOriginal(" 123 "), "123")
        XCTAssertEqual(PhoneNumberNormalizer.normalizedOrOriginal(""), "")
    }
}
