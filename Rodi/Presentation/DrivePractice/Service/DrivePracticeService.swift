//
//  DrivePracticeService.swift
//  Rodi
//

import Combine
import CoreLocation

@MainActor
/// DrivePractice의 세션 정책을 조율한다.
/// 경로 판정·세션 저장·완료 전환과 Live Activity 호출만 맡으며,
/// 인증 재시도와 Core Location delegate·백그라운드 수명은 각각 전용 객체에 위임한다.
final class DrivePracticeService: NSObject, ObservableObject {
    static let shared = DrivePracticeService()

    private enum Policy {
        static let approachResumeGracePeriod: TimeInterval = 15 * 60
        static let maximumHorizontalAccuracy: CLLocationAccuracy = 60
        static let routeCorridorMeters = 150.0
        static let maximumSampleGap: TimeInterval = 60
        static let maximumForwardMetersPerSecond = 45.0
        static let forwardDistanceToleranceMeters = 80.0
    }

    @Published private(set) var session: DrivePracticeSession?
    @Published private(set) var certificationRevision = 0

    private let sessionStore: DrivePracticeSessionStore
    private var measurementStore: PracticeMeasurementStoring?
    private var lastInCourseLocation: CLLocation?
    private var certificationService: DrivePracticeCertificationService?
    private var didStartSessionInCurrentProcess = false
    private lazy var locationAdapter = DrivePracticeLocationAdapter(
        onLocation: { [weak self] location in
            self?.receive(location)
        },
        onFailure: { error in
            RodiLogger.warning("Drive practice location failed: \(error.localizedDescription)")
        }
    )

    private override init() {
        sessionStore = DrivePracticeSessionStore()
        super.init()
        session = sessionStore.load()
    }
}


// MARK: - Core Logics
extension DrivePracticeService {
    
    func configure(
        practiceRepository: PracticeRepository,
        measurementStore: PracticeMeasurementStoring
    ) {
        self.measurementStore = measurementStore
        certificationService?.cancel()
        certificationService = DrivePracticeCertificationService(
            practiceRepository: practiceRepository,
            measurementStore: measurementStore,
            didCertify: { [weak self] in
                self?.certificationRevision += 1
            }
        )
    }

    var hasActiveMeasurement: Bool {
        session?.phase.isTerminal == false
    }

    var isSessionFromCurrentProcess: Bool {
        didStartSessionInCurrentProcess
    }

    func start(
        course: RodiCourseItem,
        routePath: [RodiCoordinate],
        rabbitAssetName: String = "img_rabbit_navigation"
    ) -> DrivePracticeStartResult {
        if let prerequisite = locationAdapter.locationPrerequisite() { return prerequisite }

        guard routePath.count >= 2 else {
            return .unavailable("코스 경로를 준비하지 못했어요. 잠시 후 다시 시도해주세요.")
        }

        guard session?.phase.isTerminal != false else {
            return .unavailable("진행 중인 연습 측정이 있어요.")
        }

        let session = DrivePracticeSession(
            id: UUID(),
            courseID: course.id,
            courseName: course.name,
            placeType: course.type == .parking ? .parking : .course,
            rabbitAssetName: rabbitAssetName,
            routePath: routePath,
            cumulativeRouteDistanceMeters: PracticeRouteMatcher.cumulativeDistance(for: routePath),
            startedAt: .now,
            phase: .headingToCourse,
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

        self.session = session
        sessionStore.save(session)
        lastInCourseLocation = nil
        activateTracking(for: session)
        RodiAnalytics.track(.drivePracticeStarted(placeType: session.analyticsPlaceType))
        RodiLogger.info("Practice tracking started sessionID=\(session.id.uuidString), courseID=\(course.id)")
        return .started
    }

    func restoreIfNeeded() -> DrivePracticeRestorationDecision? {
        guard let session, !session.phase.isTerminal else {
            return nil
        }
        guard didStartSessionInCurrentProcess else {
            let decision = DrivePracticeRestorationDecision.make(
                session: session,
                measurement: measurementStore?.load(),
                now: .now,
                approachGracePeriod: Policy.approachResumeGracePeriod
            )
            switch decision {
            case .continueApproach:
                cancelLiveActivity(sessionID: session.id)
                return decision
            case .discardApproach, .interruptDriving:
                discardRestoredSession(session, decision: decision)
                return decision
            }
        }

        guard locationAdapter.hasGrantedLocationAuthorization else {
            return nil
        }
        activateTracking(for: session)
        return nil
    }

    func continueTracking(sessionID: UUID) -> DrivePracticeStartResult {
        guard let session,
              session.id == sessionID,
              session.phase == .headingToCourse || session.phase == .drivingCourse
        else {
            return .unavailable("이동 중인 연습 기록을 찾지 못했어요.")
        }
        if session.phase == .drivingCourse, didStartSessionInCurrentProcess {
            return .started
        }
        if let prerequisite = locationAdapter.locationPrerequisite() { return prerequisite }

        lastInCourseLocation = nil
        activateTracking(for: session)
        return .started
    }

    func cancel() {
        guard let session, !session.phase.isTerminal else { return }
        endActiveSession(session, clearMeasurement: false)
        RodiAnalytics.track(.drivePracticeCancelled(placeType: session.analyticsPlaceType))
        RodiLogger.info("Practice tracking cancelled")
    }

    func endForSessionChange() {
        let sessionID = session?.id
        certificationService?.cancel()
        locationAdapter.stopTracking()
        sessionStore.clear()
        measurementStore?.clear()
        session = nil
        didStartSessionInCurrentProcess = false
        lastInCourseLocation = nil
        if let sessionID {
            cancelLiveActivity(sessionID: sessionID)
        }
    }

    private func endActiveSession(
        _ session: DrivePracticeSession,
        clearMeasurement: Bool
    ) {
        self.session = nil
        sessionStore.clear()
        if clearMeasurement, measurementStore?.load()?.id == session.id {
            measurementStore?.clear()
        }
        cancelLiveActivity(sessionID: session.id)
        locationAdapter.stopTracking()
        didStartSessionInCurrentProcess = false
        lastInCourseLocation = nil
        certificationService?.cancel()
    }

    private func discardRestoredSession(
        _ session: DrivePracticeSession,
        decision: DrivePracticeRestorationDecision
    ) {
        endActiveSession(session, clearMeasurement: true)
        RodiLogger.info(
            decision == .interruptDriving
                ? "Practice tracking interrupted after process restart"
                : "Practice tracking approach expired after process restart"
        )
    }

    private func receive(_ location: CLLocation) {
        guard var session, !session.phase.isTerminal else { return }
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= Policy.maximumHorizontalAccuracy,
              abs(location.timestamp.timeIntervalSinceNow) < 15
        else {
            return
        }

        let currentCoordinate = RodiCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        guard let start = session.routePath.first else { return }

        let startDistance = PracticeRouteMatcher.distance(from: currentCoordinate, to: start)
        if session.phase == .headingToCourse, session.initialDistanceToCourseStartMeters == nil {
            session.initialDistanceToCourseStartMeters = startDistance
        }
        session.distanceToCourseStartMeters = startDistance

        session.lastAcceptedLocationAt = location.timestamp

        guard let match = PracticeRouteMatcher.match(
            location: location,
            path: session.routePath,
            cumulativeDistanceMeters: session.cumulativeRouteDistanceMeters
        ), match.distanceToRouteMeters <= Policy.routeCorridorMeters
        else {
            lastInCourseLocation = nil
            self.session = session
            sessionStore.save(session)
            syncLiveActivity(session)
            return
        }

        if session.phase == .headingToCourse {
            session.phase = .drivingCourse
            session.drivingStartedAt = location.timestamp
            session.lastMatchedLocationAt = location.timestamp
            session.initialMatchedRouteDistanceMeters = match.distanceAlongRouteMeters
            session.furthestMatchedRouteDistanceMeters = match.distanceAlongRouteMeters
            session.courseProgress = 0
            locationAdapter.updateTrackingPolicy(phase: session.phase, isParking: session.isParking)
            RodiAnalytics.track(.drivePracticeEnteredCourse(placeType: session.analyticsPlaceType))
            RodiLogger.info(
                "Practice tracking entered course sessionID=\(session.id.uuidString), progress=\(match.progress)"
            )
        }

        if session.isParking {
            session.phase = .completed
            session.courseProgress = 1
            session.completedAt = location.timestamp
            locationAdapter.stopTracking()
            didStartSessionInCurrentProcess = false
            finishLiveActivity(session)
            markCertificationPending(for: session)
            self.session = session
            sessionStore.save(session)
            RodiAnalytics.track(.drivePracticeCompleted(placeType: session.analyticsPlaceType))
            return
        }

        updateDrivingProgress(&session, location: location, timestamp: location.timestamp)

        if session.requiredDrivingDistanceMeters > 0,
           session.drivenRouteDistance >= session.requiredDrivingDistanceMeters {
            session.phase = .completed
            session.completedAt = location.timestamp
            locationAdapter.stopTracking()
            didStartSessionInCurrentProcess = false
            finishLiveActivity(session)
            self.session = session
            sessionStore.save(session)
            markCertificationPending(for: session, retryImmediately: false)
            retryCertificationIfNeeded()
            RodiLogger.info(
                "Practice tracking completed sessionID=\(session.id.uuidString), progress=\(session.courseProgress), seconds=\(session.activeDrivingSeconds)"
            )
            RodiAnalytics.track(.drivePracticeCompleted(placeType: session.analyticsPlaceType))
            return
        }

        self.session = session
        sessionStore.save(session)
        syncLiveActivity(session)
    }

    private func updateDrivingProgress(
        _ session: inout DrivePracticeSession,
        location: CLLocation,
        timestamp: Date
    ) {
        guard session.phase == .drivingCourse else { return }

        defer {
            session.lastMatchedLocationAt = timestamp
            session.matchedSampleCount += 1
        }

        guard let previousTimestamp = session.lastMatchedLocationAt,
              let previousLocation = lastInCourseLocation
        else {
            lastInCourseLocation = location
            return
        }

        let elapsedSeconds = min(
            max(0, timestamp.timeIntervalSince(previousTimestamp)),
            Policy.maximumSampleGap
        )
        session.activeDrivingSeconds += elapsedSeconds

        let travelledDistance = location.distance(from: previousLocation)
        let maximumPlausibleDistance =
            (elapsedSeconds * Policy.maximumForwardMetersPerSecond) + Policy.forwardDistanceToleranceMeters
        guard travelledDistance > 0, travelledDistance <= maximumPlausibleDistance else {
            lastInCourseLocation = location
            return
        }

        session.drivenRouteDistanceMeters = (session.drivenRouteDistanceMeters ?? 0) + travelledDistance
        session.courseProgress = min(session.drivenRouteDistance / session.requiredDrivingDistanceMeters, 1)
        lastInCourseLocation = location
    }

    private func markCertificationPending(
        for session: DrivePracticeSession,
        retryImmediately: Bool = true
    ) {
        guard let measurementStore,
              var measurement = measurementStore.load(),
              measurement.id == session.id
        else { return }
        measurement.status = .certificationPendingRegistration
        measurement.certifiedDistanceMeters = session.isParking
            ? nil
            : Int(session.drivenRouteDistance.rounded())
        measurementStore.save(measurement)
        if retryImmediately {
            retryCertificationIfNeeded()
        }
    }

    func retryCertificationIfNeeded() {
        certificationService?.retryIfNeeded()
    }

    func synchronizeCompletedSessionCertificationIfNeeded() {
        guard let session, session.phase == .completed else { return }
        if session.isParking {
            markCertificationPending(for: session)
        } else {
            markCertificationPending(for: session, retryImmediately: false)
            retryCertificationIfNeeded()
        }
    }

    private func activateTracking(for session: DrivePracticeSession) {
        didStartSessionInCurrentProcess = true
        locationAdapter.startTracking(phase: session.phase, isParking: session.isParking)
        startLiveActivity(for: session)
    }

    private func startLiveActivity(for session: DrivePracticeSession) {
        guard #available(iOS 16.1, *) else { return }
        PracticeLiveActivityService.shared.start(for: session)
    }

    private func syncLiveActivity(_ session: DrivePracticeSession) {
        guard #available(iOS 16.1, *) else { return }
        PracticeLiveActivityService.shared.sync(session)
    }

    private func finishLiveActivity(_ session: DrivePracticeSession) {
        guard #available(iOS 16.1, *) else { return }
        PracticeLiveActivityService.shared.finish(session)
    }

    private func cancelLiveActivity(sessionID: UUID) {
        guard #available(iOS 16.1, *) else { return }
        PracticeLiveActivityService.shared.cancel(sessionID: sessionID)
    }
}
