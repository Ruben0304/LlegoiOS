import XCTest
@testable import LlegoiOS

final class TestIsolationTests: XCTestCase {
    func testAppUsesIsolatedEnvironment() {
        XCTAssertTrue(iOSApp.isTestMode)
        XCTAssertEqual(ApolloClientManager.baseURL, "https://llego-test.invalid")
    }
}
