//
//  PracticeLiveActivityPreview.swift
//  Rodi
//

#if DEBUG
import Foundation

@available(iOS 16.1, *)
@MainActor
enum PracticeLiveActivityPreview {
    enum State {
        case headingToCourse
        case drivingCourse
        case drivingCourseJustStarted
        case completed

        fileprivate var phase: DrivePracticePhase {
            switch self {
            case .headingToCourse: .headingToCourse
            case .drivingCourse, .drivingCourseJustStarted: .drivingCourse
            case .completed: .completed
            }
        }

        fileprivate var courseProgress: Double {
            switch self {
            case .headingToCourse: 0
            case .drivingCourse: 0.45
            case .drivingCourseJustStarted: 0.02
            case .completed: 1
            }
        }
    }

    static func show(_ state: State) {
        let service = PracticeLiveActivityService.shared
        service.cancel()
        service.start(for: session(for: state))
        RodiLogger.debug("Practice Live Activity preview requested: state=\(String(describing: state))")
    }

    private static func session(for state: State) -> DrivePracticeSession {
        let phase = state.phase
        let routePath = [
            RodiCoordinate(latitude: 37.582, longitude: 126.984),
            RodiCoordinate(latitude: 37.586, longitude: 126.991)
        ]

        return DrivePracticeSession(
            id: UUID(),
            courseID: 0,
            courseName: "북악스카이웨이 드라이브",
            placeType: .course,
            rabbitAssetName: PracticeLiveActivityRabbitAsset.navigation,
            routePath: routePath,
            cumulativeRouteDistanceMeters: [0, 1_000],
            startedAt: .now,
            phase: phase,
            drivingStartedAt: phase == .drivingCourse || phase == .completed ? .now.addingTimeInterval(-240) : nil,
            lastAcceptedLocationAt: .now,
            courseProgress: state.courseProgress,
            activeDrivingSeconds: phase == .headingToCourse ? 0 : 240,
            matchedSampleCount: phase == .headingToCourse ? 0 : 12,
            initialDistanceToCourseStartMeters: 1_000,
            distanceToCourseStartMeters: phase == .headingToCourse ? 650 : 0,
            lastMatchedLocationAt: .now,
            initialMatchedRouteDistanceMeters: 0,
            furthestMatchedRouteDistanceMeters: state.courseProgress * 1_000,
            drivenRouteDistanceMeters: state.courseProgress * 1_000,
            completedAt: phase == .completed ? .now : nil
        )
    }
}
#endif
