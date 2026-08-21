import XCTest
@testable import Rodi

final class PracticeTrackingRestorationDecisionTests: XCTestCase {

    func testHeadingSessionWithinGracePeriodCanContinue() {
        let session = makeSession(phase: .headingToCourse)
        let measurement = makeMeasurement(id: session.id, handoffAt: .now.addingTimeInterval(-14 * 60))

        XCTAssertEqual(
            PracticeTrackingRestorationDecision.make(
                session: session,
                measurement: measurement,
                now: .now,
                approachGracePeriod: 15 * 60
            ),
            .continueApproach
        )
    }

    func testExpiredHeadingSessionIsDiscarded() {
        let session = makeSession(phase: .headingToCourse)
        let measurement = makeMeasurement(id: session.id, handoffAt: .now.addingTimeInterval(-16 * 60))

        XCTAssertEqual(
            PracticeTrackingRestorationDecision.make(
                session: session,
                measurement: measurement,
                now: .now,
                approachGracePeriod: 15 * 60
            ),
            .discardApproach
        )
    }

    func testDrivingSessionIsInterruptedAfterProcessRestart() {
        let session = makeSession(phase: .drivingCourse)

        XCTAssertEqual(
            PracticeTrackingRestorationDecision.make(
                session: session,
                measurement: makeMeasurement(id: session.id, handoffAt: .now),
                now: .now,
                approachGracePeriod: 15 * 60
            ),
            .interruptDriving
        )
    }

    func testMismatchedMeasurementDoesNotResumeApproach() {
        let session = makeSession(phase: .headingToCourse)

        XCTAssertEqual(
            PracticeTrackingRestorationDecision.make(
                session: session,
                measurement: makeMeasurement(id: UUID(), handoffAt: .now),
                now: .now,
                approachGracePeriod: 15 * 60
            ),
            .discardApproach
        )
    }

    func testDebugCourseVisitIsRecordedAfterTenSecondExternalReturn() {
        var measurement = makeMeasurement(id: UUID(), handoffAt: .now)
        measurement.lastRodiInactiveAt = .now.addingTimeInterval(-10)

        XCTAssertTrue(
            PracticeReturnReducer.shouldRecordDebugCourseVisit(
                measurement: measurement,
                now: .now
            )
        )
    }

    func testDebugCourseVisitIsNotRecordedBeforeTenSecondExternalReturn() {
        var measurement = makeMeasurement(id: UUID(), handoffAt: .now)
        measurement.lastRodiInactiveAt = .now.addingTimeInterval(-9)

        XCTAssertFalse(
            PracticeReturnReducer.shouldRecordDebugCourseVisit(
                measurement: measurement,
                now: .now
            )
        )
    }

    private func makeSession(phase: PracticeTrackingPhase) -> PracticeTrackingSession {
        .init(
            id: UUID(),
            courseID: 1,
            courseName: "연습 코스",
            placeType: .course,
            rabbitAssetName: nil,
            routePath: [
                .init(latitude: 37.5, longitude: 127.0),
                .init(latitude: 37.51, longitude: 127.01)
            ],
            cumulativeRouteDistanceMeters: [0, 100],
            startedAt: .now,
            phase: phase,
            drivingStartedAt: nil,
            lastAcceptedLocationAt: nil,
            courseProgress: 0,
            activeDrivingSeconds: 0,
            matchedSampleCount: 0,
            initialDistanceToCourseStartMeters: nil,
            distanceToCourseStartMeters: nil,
            lastMatchedLocationAt: nil,
            initialMatchedRouteDistanceMeters: nil,
            furthestMatchedRouteDistanceMeters: nil,
            drivenRouteDistanceMeters: nil,
            completedAt: nil
        )
    }

    private func makeMeasurement(id: UUID, handoffAt: Date) -> PracticeMeasurement {
        .init(
            id: id,
            placeID: 1,
            placeName: "연습 코스",
            mode: .gpsTracking,
            externalHandoffAt: handoffAt,
            status: .tracking
        )
    }
}
