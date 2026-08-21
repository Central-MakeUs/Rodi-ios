import XCTest
@testable import Rodi

final class AppVersionUpdateCheckerTests: XCTestCase {

    func testRequiresUpdateWhenStoreVersionIsHigher() {
        XCTAssertTrue(
            AppVersionUpdateChecker.requiresUpdate(
                currentVersion: "1.4.1",
                latestVersion: "1.4.2"
            )
        )
    }

    func testDoesNotRequireUpdateForSameOrLowerStoreVersion() {
        XCTAssertFalse(
            AppVersionUpdateChecker.requiresUpdate(
                currentVersion: "1.4.2",
                latestVersion: "1.4.2"
            )
        )
        XCTAssertFalse(
            AppVersionUpdateChecker.requiresUpdate(
                currentVersion: "1.4.2",
                latestVersion: "1.4.1"
            )
        )
    }
}
