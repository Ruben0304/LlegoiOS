import Foundation
import XCTest
@testable import LlegoiOS

final class SessionErrorPolicyTests: XCTestCase {
    func testOnlyAuthenticationFailuresInvalidateSession() {
        let unauthenticated = Data(#"{"errors":[{"extensions":{"code":"UNAUTHENTICATED"}}]}"#.utf8)
        let forbidden = Data(#"{"errors":[{"extensions":{"code":"FORBIDDEN"}}]}"#.utf8)
        let legacy = Data(#"{"errors":[{"message":"Usuario no autenticado"}]}"#.utf8)
        let codedForbidden = Data(#"{"errors":[{"message":"Usuario no autenticado","extensions":{"code":"FORBIDDEN"}}]}"#.utf8)
        XCTAssertTrue(SessionErrorPolicy.invalidatesSession(status: 401, data: Data()))
        XCTAssertTrue(SessionErrorPolicy.invalidatesSession(status: 200, data: unauthenticated))
        XCTAssertFalse(SessionErrorPolicy.invalidatesSession(status: 403, data: unauthenticated))
        XCTAssertFalse(SessionErrorPolicy.invalidatesSession(status: 200, data: forbidden))
        XCTAssertTrue(SessionErrorPolicy.invalidatesSession(status: 200, data: legacy))
        XCTAssertFalse(SessionErrorPolicy.invalidatesSession(status: 200, data: codedForbidden))
        XCTAssertFalse(SessionErrorPolicy.invalidatesSession(status: 403, data: legacy))
        XCTAssertFalse(SessionErrorPolicy.invalidatesSession(status: 500, data: unauthenticated))
        XCTAssertFalse(SessionErrorPolicy.invalidatesSession(status: 200, data: Data()))
    }

    func testOnlyRequestsUsingCurrentTokenAreEligible() throws {
        var request = URLRequest(url: try XCTUnwrap(URL(string: "https://example.invalid/graphql")))
        request.httpBody = Data(#"{"variables":{"jwt":"test-token"}}"#.utf8)
        XCTAssertTrue(SessionErrorPolicy.usesToken("test-token", request: request))
        XCTAssertFalse(SessionErrorPolicy.usesToken("other-token", request: request))
        request.httpBody = nil
        request.setValue("Bearer test-token", forHTTPHeaderField: "Authorization")
        XCTAssertTrue(SessionErrorPolicy.usesToken("test-token", request: request))
        request.httpBody = Data(#"{"variables":{"jwt":"old-token"}}"#.utf8)
        XCTAssertFalse(SessionErrorPolicy.usesToken("test-token", request: request))
        XCTAssertFalse(SessionErrorPolicy.usesToken("", request: request))
        XCTAssertTrue(SessionErrorPolicy.isBackend(request, baseURL: "https://example.invalid"))
        XCTAssertFalse(SessionErrorPolicy.isBackend(request, baseURL: "https://other.invalid"))
        XCTAssertFalse(SessionErrorPolicy.isBackend(request, baseURL: "http://example.invalid"))
    }

    func testOldResponseCannotInvalidateNewSessionWithSameToken() {
        let old = UUID()
        XCTAssertTrue(SessionErrorPolicy.isCurrent(token: "test", generation: old,
                                                  currentToken: "test", currentGeneration: old))
        XCTAssertFalse(SessionErrorPolicy.isCurrent(token: "test", generation: old,
                                                   currentToken: "test", currentGeneration: UUID()))
        XCTAssertFalse(SessionErrorPolicy.isCurrent(token: "test", generation: old,
                                                   currentToken: "other", currentGeneration: old))
    }
}
