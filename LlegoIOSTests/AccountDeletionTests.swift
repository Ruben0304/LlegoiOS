import XCTest
@testable import LlegoiOS

/// Eliminación de cuenta programada: el backend manda `scheduledDeletionAt` como
/// `DateTime` (isoformat de Python), con o sin zona horaria.
final class AccountDeletionTests: XCTestCase {

    private func utc(_ raw: String) -> Date? {
        BackendDateParser.parse(raw)
    }

    private let expected = Date(timeIntervalSince1970: 1_793_534_400)  // 2026-11-01T12:00:00Z

    func test_parse_acceptsZoneAwareAndNaiveDates() {
        XCTAssertEqual(utc("2026-11-01T12:00:00Z"), expected)
        XCTAssertEqual(
            utc("2026-11-01T12:00:00.123Z")!.timeIntervalSince1970,
            expected.timeIntervalSince1970 + 0.123, accuracy: 0.001)
        XCTAssertEqual(utc("2026-11-01T12:00:00+00:00"), expected)
        XCTAssertEqual(utc("2026-11-01T08:00:00-04:00"), expected)
        // Naive: el backend guarda UTC.
        XCTAssertEqual(utc("2026-11-01T12:00:00"), expected)
        XCTAssertNotNil(utc("2026-11-01T12:00:00.123456"))
    }

    func test_parse_rejectsGarbage() {
        XCTAssertNil(BackendDateParser.parse(nil))
        XCTAssertNil(BackendDateParser.parse(""))
        XCTAssertNil(BackendDateParser.parse("   "))
        XCTAssertNil(BackendDateParser.parse("mañana"))
    }

    func test_longDateInHavana_usesCubanDay() {
        // 2026-11-02T03:00:00Z son las 23:00 del 1 de noviembre en La Habana (UTC-4).
        let date = utc("2026-11-02T03:00:00Z")!
        XCTAssertEqual(date.longDateInHavana, "1 de noviembre de 2026")
    }

    func test_user_scheduledDeletionSurvivesPersistence() throws {
        let user = User(
            id: "1", email: "a@b.c", fullName: "A", username: "a", phone: nil, role: "user",
            appleUserId: nil, avatar: nil, avatarUrl: nil, savedAddresses: nil,
            defaultAddressId: nil, scheduledDeletionAt: expected)
        let data = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(User.self, from: data)
        XCTAssertEqual(decoded.scheduledDeletionAt, expected)

        let cancelled = decoded.withScheduledDeletion(nil)
        XCTAssertNil(cancelled.scheduledDeletionAt)
        XCTAssertEqual(cancelled.id, "1")
    }

    func test_user_decodesSessionsPersistedBeforeTheField() throws {
        let legacy = """
            {"id":"1","email":"a@b.c","fullName":"A","username":"a","role":"user"}
            """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(User.self, from: legacy)
        XCTAssertNil(decoded.scheduledDeletionAt)
    }
}
