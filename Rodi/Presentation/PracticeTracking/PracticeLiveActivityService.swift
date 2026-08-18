//
//  PracticeLiveActivityService.swift
//  Rodi
//

import ActivityKit
import Foundation

@available(iOS 16.1, *)
@MainActor
final class PracticeLiveActivityService {
    static let shared = PracticeLiveActivityService()

    private var activity: Activity<PracticeLiveActivityAttributes>?
    private var lastUpdatedAt: Date?
    private var lastPhase: PracticeTrackingPhase?
    private var lastApproachProgress: Double?
    private var lastCourseProgress: Double?

    private init() {}

    func start(for session: PracticeTrackingSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            RodiLogger.info("Practice Live Activity unavailable: disabled by user")
            return
        }

        if let existing = Activity<PracticeLiveActivityAttributes>.activities.first(where: {
            $0.attributes.sessionID == session.id
        }) {
            activity = existing
            sync(session, force: true)
            return
        }

        let attributes = PracticeLiveActivityAttributes(
            sessionID: session.id,
            courseID: session.courseID,
            courseName: session.courseName,
            placeTypeRawValue: session.placeType?.rawValue ?? PracticeMeasurementPlaceType.course.rawValue,
            rabbitAssetName: session.rabbitAssetName ?? PracticeLiveActivityRabbitAsset.navigation
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                contentState: contentState(for: session),
                pushType: nil
            )
            lastUpdatedAt = .now
            lastPhase = session.phase
            lastApproachProgress = session.approachProgress
            lastCourseProgress = session.courseProgress
            RodiLogger.info("Practice Live Activity started sessionID=\(session.id.uuidString)")
        } catch {
            RodiLogger.warning("Practice Live Activity start failed: \(error.localizedDescription)")
        }
    }

    func sync(_ session: PracticeTrackingSession, force: Bool = false) {
        if activity == nil {
            activity = Activity<PracticeLiveActivityAttributes>.activities.first(where: {
                $0.attributes.sessionID == session.id
            })
        }
        guard let activity else { return }

        let isPhaseChanged = lastPhase != session.phase
        let isUpdateDue = lastUpdatedAt.map { Date.now.timeIntervalSince($0) >= 15 } ?? true
        let isApproachProgressChanged = abs((lastApproachProgress ?? 0) - session.approachProgress) >= 0.03
        let isCourseProgressChanged = abs((lastCourseProgress ?? 0) - session.courseProgress) >= 0.03
        guard force || isPhaseChanged || isUpdateDue || isApproachProgressChanged || isCourseProgressChanged else { return }

        let state = contentState(for: session)
        lastUpdatedAt = .now
        lastPhase = session.phase
        lastApproachProgress = session.approachProgress
        lastCourseProgress = session.courseProgress

        Task {
            await activity.update(using: state)
        }
    }

    func finish(_ session: PracticeTrackingSession) {
        guard let activity else { return }

        let state = contentState(for: session)
        Task {
            await activity.end(
                using: state,
                dismissalPolicy: .after(Date.now.addingTimeInterval(30 * 60))
            )
        }
        self.activity = nil
        lastUpdatedAt = nil
        lastPhase = nil
        lastApproachProgress = nil
        lastCourseProgress = nil
    }

    func cancel() {
        guard let activity else { return }
        Task {
            await activity.end(dismissalPolicy: .immediate)
        }
        self.activity = nil
        lastUpdatedAt = nil
        lastPhase = nil
        lastApproachProgress = nil
        lastCourseProgress = nil
    }

    #if DEBUG
    /// 추천 목록의 빈 상태에서 Live Activity 외형을 빠르게 확인하기 위한 개발용 진입점입니다.
    enum PreviewState {
        case headingToCourse
        case drivingCourse
        case drivingCourseJustStarted
        case completed

        var phase: PracticeTrackingPhase {
            switch self {
            case .headingToCourse: .headingToCourse
            case .drivingCourse, .drivingCourseJustStarted: .drivingCourse
            case .completed: .completed
            }
        }

        var courseProgress: Double {
            switch self {
            case .headingToCourse: 0
            case .drivingCourse: 0.45
            case .drivingCourseJustStarted: 0.02
            case .completed: 1
            }
        }
    }

    func showPreview(state preview: PreviewState) {
        cancel()

        let phase = preview.phase

        let routePath = [
            RodiCoordinate(latitude: 37.582, longitude: 126.984),
            RodiCoordinate(latitude: 37.586, longitude: 126.991)
        ]
        let session = PracticeTrackingSession(
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
            courseProgress: preview.courseProgress,
            activeDrivingSeconds: phase == .headingToCourse ? 0 : 240,
            matchedSampleCount: phase == .headingToCourse ? 0 : 12,
            initialDistanceToCourseStartMeters: 1_000,
            distanceToCourseStartMeters: phase == .headingToCourse ? 650 : 0,
            lastMatchedLocationAt: .now,
            initialMatchedRouteDistanceMeters: 0,
            furthestMatchedRouteDistanceMeters: preview.courseProgress * 1_000,
            drivenRouteDistanceMeters: preview.courseProgress * 1_000,
            completedAt: phase == .completed ? .now : nil
        )

        start(for: session)
        RodiLogger.debug("Practice Live Activity preview requested: state=\(String(describing: preview))")
    }
    #endif

    private func contentState(for session: PracticeTrackingSession) -> PracticeLiveActivityAttributes.ContentState {
        PracticeLiveActivityAttributes.ContentState(
            phaseRawValue: session.phase.rawValue,
            approachProgress: session.approachProgress,
            progress: session.courseProgress,
            distanceToCourseStartMeters: session.distanceToCourseStartMeters.map { Int($0.rounded()) }
        )
    }
}
