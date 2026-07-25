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
            courseName: session.courseName
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

    private func contentState(for session: PracticeTrackingSession) -> PracticeLiveActivityAttributes.ContentState {
        PracticeLiveActivityAttributes.ContentState(
            phaseRawValue: session.phase.rawValue,
            approachProgress: session.approachProgress,
            progress: session.courseProgress,
            distanceToCourseStartMeters: session.distanceToCourseStartMeters.map { Int($0.rounded()) }
        )
    }
}
