import XCTest
@testable import Rodi

final class PracticeLiveActivityDeepLinkTests: XCTestCase {

    func testSessionIDRoundTrip() {
        let sessionID = UUID()

        XCTAssertEqual(
            PracticeLiveActivityDeepLink.url(sessionID: sessionID)
                .flatMap(PracticeLiveActivityDeepLink.sessionID),
            sessionID
        )
    }

    func testUnrelatedURLIsIgnored() {
        XCTAssertNil(
            PracticeLiveActivityDeepLink.sessionID(
                from: URL(string: "rodi://practice-records")!
            )
        )
    }
}
