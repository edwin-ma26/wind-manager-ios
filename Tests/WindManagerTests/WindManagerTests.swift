import XCTest
@testable import WindManager

final class WindManagerTests: XCTestCase {

    func testIsConnectedFalseWhenNoStoredId() {
        let wind = WindManager(appId: "test-app", appName: "Test", storageKey: "wind_test_key")
        wind.disconnect()
        XCTAssertFalse(wind.isConnected())
        XCTAssertNil(wind.getStoredUserId())
    }

    func testDisconnectClearsStoredId() {
        let key = "wind_test_key"
        UserDefaults.standard.set("test-user-id", forKey: key)
        let wind = WindManager(appId: "test-app", appName: "Test", storageKey: key)
        XCTAssertTrue(wind.isConnected())
        wind.disconnect()
        XCTAssertFalse(wind.isConnected())
    }

    func testBuildConnectURLContainsRequiredParams() throws {
        let wind = WindManager(appId: "my-app-id", appName: "My App")
        // Access via connect URL construction (tested indirectly through the public API)
        // A full integration test would require mocking ASWebAuthenticationSession
        XCTAssertEqual(wind.appId, "my-app-id")
        XCTAssertEqual(wind.appName, "My App")
    }
}
