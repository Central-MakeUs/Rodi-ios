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
    private var updatePolicy = PracticeLiveActivityUpdatePolicy()
    private var operationTask: Task<Void, Never>?

    private init() {}

    /// 프로세스 종료 콜백이 반환되기 전에 시스템에 Live Activity 종료를 전달합니다.
    /// `applicationWillTerminate`는 동기 콜백이므로 대기 시간을 짧게 제한합니다.
    nonisolated static func endAllBeforeProcessTermination() {
        let completion = DispatchSemaphore(value: 0)

        Task.detached(priority: .userInitiated) {
            defer { completion.signal() }

            for activity in Activity<PracticeLiveActivityAttributes>.activities {
                if #available(iOS 16.2, *) {
                    await activity.end(nil, dismissalPolicy: .immediate)
                } else {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
        }

        // ponytail: UIKit에 async 종료 훅이 없어 최대 2초만 동기 대기한다.
        _ = completion.wait(timeout: .now() + 2)
    }

    func start(for session: DrivePracticeSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            RodiLogger.info("Practice Live Activity unavailable: disabled by user")
            return
        }

        if let existing = Activity<PracticeLiveActivityAttributes>.activities.first(where: {
            $0.attributes.sessionID == session.id
        }) {
            activity = existing
            updatePolicy.reset()
            sync(session)
            return
        }

        let attributes = PracticeLiveActivityContentMapper.attributes(for: session)
        let state = PracticeLiveActivityContentMapper.state(for: session)

        do {
            if #available(iOS 16.2, *) {
                activity = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
            } else {
                activity = try Activity.request(
                    attributes: attributes,
                    contentState: state,
                    pushType: nil
                )
            }
            updatePolicy.record(.init(session), at: .now)
            RodiLogger.info("Practice Live Activity started sessionID=\(session.id.uuidString)")
        } catch {
            RodiLogger.warning("Practice Live Activity start failed: \(error.localizedDescription)")
        }
    }

    func sync(_ session: DrivePracticeSession) {
        guard let activity = resolveActivity(sessionID: session.id) else { return }
        guard updatePolicy.shouldUpdate(.init(session), at: .now) else { return }

        let state = PracticeLiveActivityContentMapper.state(for: session)
        enqueueOperation {
            if #available(iOS 16.2, *) {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            } else {
                await activity.update(using: state)
            }
        }
    }

    func finish(_ session: DrivePracticeSession) {
        guard let activity = resolveActivity(sessionID: session.id) else { return }

        let state = PracticeLiveActivityContentMapper.state(for: session)
        let dismissalPolicy = ActivityUIDismissalPolicy.after(Date.now.addingTimeInterval(30 * 60))
        enqueueOperation {
            if #available(iOS 16.2, *) {
                await activity.end(
                    ActivityContent(state: state, staleDate: nil),
                    dismissalPolicy: dismissalPolicy
                )
            } else {
                await activity.end(using: state, dismissalPolicy: dismissalPolicy)
            }
        }
        clearCachedActivity(activity)
    }

    func cancel() {
        guard let activity else { return }
        enqueueOperation {
            if #available(iOS 16.2, *) {
                await activity.end(nil, dismissalPolicy: .immediate)
            } else {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
        clearCachedActivity(activity)
    }

    /// 프로세스 재실행 뒤에도 시스템이 보관한 동일 세션의 Activity만 종료합니다.
    func cancel(sessionID: UUID) {
        guard let activity = resolveActivity(sessionID: sessionID) else { return }

        self.activity = activity
        cancel()
    }

    private func resolveActivity(sessionID: UUID) -> Activity<PracticeLiveActivityAttributes>? {
        if activity?.attributes.sessionID == sessionID {
            return activity
        }

        let existing = Activity<PracticeLiveActivityAttributes>.activities.first {
            $0.attributes.sessionID == sessionID
        }
        activity = existing
        return existing
    }

    private func enqueueOperation(
        _ operation: @escaping @MainActor @Sendable () async -> Void
    ) {
        let previousOperation = operationTask
        operationTask = Task { @MainActor in
            await previousOperation?.value
            guard !Task.isCancelled else { return }
            await operation()
        }
    }

    private func clearCachedActivity(_ activity: Activity<PracticeLiveActivityAttributes>) {
        if self.activity?.id == activity.id {
            self.activity = nil
        }
        updatePolicy.reset()
    }
}

@available(iOS 16.1, *)
enum PracticeLiveActivityContentMapper {
    static func attributes(for session: DrivePracticeSession) -> PracticeLiveActivityAttributes {
        PracticeLiveActivityAttributes(
            sessionID: session.id,
            courseName: session.courseName,
            placeTypeRawValue: session.placeType?.rawValue ?? PracticeMeasurementPlaceType.course.rawValue,
            rabbitAssetName: session.rabbitAssetName ?? PracticeLiveActivityRabbitAsset.navigation
        )
    }

    static func state(for session: DrivePracticeSession) -> PracticeLiveActivityAttributes.ContentState {
        PracticeLiveActivityAttributes.ContentState(
            phaseRawValue: session.phase.rawValue,
            progress: session.courseProgress,
            distanceToCourseStartMeters: session.distanceToCourseStartMeters.map { Int($0.rounded()) }
        )
    }
}

struct PracticeLiveActivityUpdatePolicy {
    struct Snapshot: Equatable {
        let phase: DrivePracticePhase
        let approachProgress: Double
        let courseProgress: Double

        init(
            phase: DrivePracticePhase,
            approachProgress: Double,
            courseProgress: Double
        ) {
            self.phase = phase
            self.approachProgress = approachProgress
            self.courseProgress = courseProgress
        }

        init(_ session: DrivePracticeSession) {
            self.init(
                phase: session.phase,
                approachProgress: session.approachProgress,
                courseProgress: session.courseProgress
            )
        }
    }

    private static let minimumUpdateInterval: TimeInterval = 15
    private static let minimumProgressChange = 0.03

    private var lastUpdatedAt: Date?
    private var lastPhase: DrivePracticePhase?
    private var lastApproachProgress: Double?
    private var lastCourseProgress: Double?

    mutating func shouldUpdate(_ snapshot: Snapshot, at now: Date) -> Bool {
        let shouldUpdate = lastPhase != snapshot.phase
            || lastUpdatedAt.map { now.timeIntervalSince($0) >= Self.minimumUpdateInterval } ?? true
            || abs((lastApproachProgress ?? 0) - snapshot.approachProgress) >= Self.minimumProgressChange
            || abs((lastCourseProgress ?? 0) - snapshot.courseProgress) >= Self.minimumProgressChange

        if shouldUpdate {
            record(snapshot, at: now)
        }
        return shouldUpdate
    }

    mutating func record(_ snapshot: Snapshot, at date: Date) {
        lastUpdatedAt = date
        lastPhase = snapshot.phase
        lastApproachProgress = snapshot.approachProgress
        lastCourseProgress = snapshot.courseProgress
    }

    mutating func reset() {
        lastUpdatedAt = nil
        lastPhase = nil
        lastApproachProgress = nil
        lastCourseProgress = nil
    }
}
