import XCTest
@testable import Rodi

final class PracticeLiveActivityUpdatePolicyTests: XCTestCase {
    private let startDate = Date(timeIntervalSince1970: 1_000)

    func testSkipsSmallChangesBeforeMinimumInterval() {
        var policy = PracticeLiveActivityUpdatePolicy()
        policy.record(snapshot(), at: startDate)

        XCTAssertFalse(
            policy.shouldUpdate(
                snapshot(approachProgress: 0.02, courseProgress: 0.02),
                at: startDate.addingTimeInterval(14)
            )
        )
    }

    func testUpdatesForPhaseProgressOrElapsedTime() {
        assertUpdates(with: snapshot(phase: .drivingCourse))
        assertUpdates(with: snapshot(approachProgress: 0.03))
        assertUpdates(with: snapshot(courseProgress: 0.03))

        var policy = PracticeLiveActivityUpdatePolicy()
        policy.record(snapshot(), at: startDate)
        XCTAssertTrue(policy.shouldUpdate(snapshot(), at: startDate.addingTimeInterval(15)))
    }

    func testResetMakesNextSnapshotEligible() {
        var policy = PracticeLiveActivityUpdatePolicy()
        policy.record(snapshot(), at: startDate)
        policy.reset()

        XCTAssertTrue(policy.shouldUpdate(snapshot(), at: startDate))
    }

    private func assertUpdates(
        with nextSnapshot: PracticeLiveActivityUpdatePolicy.Snapshot,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var policy = PracticeLiveActivityUpdatePolicy()
        policy.record(snapshot(), at: startDate)

        XCTAssertTrue(
            policy.shouldUpdate(nextSnapshot, at: startDate.addingTimeInterval(1)),
            file: file,
            line: line
        )
    }

    private func snapshot(
        phase: DrivePracticePhase = .headingToCourse,
        approachProgress: Double = 0,
        courseProgress: Double = 0
    ) -> PracticeLiveActivityUpdatePolicy.Snapshot {
        .init(
            phase: phase,
            approachProgress: approachProgress,
            courseProgress: courseProgress
        )
    }
}
