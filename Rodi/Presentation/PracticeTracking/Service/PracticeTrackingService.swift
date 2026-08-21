//
//  PracticeTrackingService.swift
//  Rodi
//

import Combine
import CoreLocation
import Foundation

@MainActor
final class PracticeTrackingService: NSObject, ObservableObject {
    static let shared = PracticeTrackingService()

    private enum Policy {
        static let approachResumeGracePeriod: TimeInterval = 15 * 60
        static let maximumHorizontalAccuracy: CLLocationAccuracy = 60
        static let routeCorridorMeters = 150.0
        static let maximumSampleGap: TimeInterval = 60
        static let maximumForwardMetersPerSecond = 45.0
        static let forwardDistanceToleranceMeters = 80.0

        /// 코스 진입 전과 주차장 도착 확인에는 배터리 사용을 줄이기 위한 위치 목표값을 사용한다.
        static let approachDesiredAccuracy = kCLLocationAccuracyHundredMeters
        static let approachDistanceFilter: CLLocationDistance = 100
        /// 코스 범위에 진입한 뒤에만 진행률 산정을 위해 정밀한 위치 목표값으로 전환한다.
        static let drivingDesiredAccuracy = kCLLocationAccuracyNearestTenMeters
        static let drivingDistanceFilter: CLLocationDistance = 20
    }

    @Published private(set) var session: PracticeTrackingSession?
    @Published private(set) var certificationRevision = 0

    private let locationManager = CLLocationManager()
    private let sessionStore: PracticeTrackingSessionStore
    private var measurementStore: PracticeMeasurementStoring?
    private var practiceRepository: PracticeRepository?
    private var lastInCourseLocation: CLLocation?
    private var isCertificationRequestInFlight = false
    private var certificationTask: Task<Void, Never>?
    private var certificationRequestID = 0
    private var backgroundActivitySession: AnyObject?
    private var didStartSessionInCurrentProcess = false

    private override init() {
        sessionStore = PracticeTrackingSessionStore()
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .automotiveNavigation
        locationManager.desiredAccuracy = Policy.approachDesiredAccuracy
        locationManager.distanceFilter = Policy.approachDistanceFilter
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        session = sessionStore.load()
    }

    func configure(
        practiceRepository: PracticeRepository,
        measurementStore: PracticeMeasurementStoring
    ) {
        self.practiceRepository = practiceRepository
        self.measurementStore = measurementStore
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
    ) -> PracticeTrackingStartResult {
        if let prerequisite = locationPrerequisite() { return prerequisite }

        guard routePath.count >= 2 else {
            return .unavailable("코스 경로를 준비하지 못했어요. 잠시 후 다시 시도해주세요.")
        }

        guard session?.phase.isTerminal != false else {
            return .unavailable("진행 중인 연습 측정이 있어요.")
        }

        let session = PracticeTrackingSession(
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
        RodiAnalytics.track(.practiceTrackingStarted(placeType: session.analyticsPlaceType))
        RodiLogger.info("Practice tracking started sessionID=\(session.id.uuidString), courseID=\(course.id)")
        return .started
    }

    func restoreIfNeeded() -> PracticeTrackingRestorationDecision? {
        guard let session, !session.phase.isTerminal else {
            return nil
        }
        guard didStartSessionInCurrentProcess else {
            let decision = PracticeTrackingRestorationDecision.make(
                session: session,
                measurement: measurementStore?.load(),
                now: .now,
                approachGracePeriod: Policy.approachResumeGracePeriod
            )
            switch decision {
            case .continueApproach:
                return decision
            case .discardApproach, .interruptDriving:
                discardRestoredSession(session, decision: decision)
                return decision
            }
        }

        guard locationManager.authorizationStatus == .authorizedWhenInUse
                || locationManager.authorizationStatus == .authorizedAlways
        else {
            return nil
        }
        activateTracking(for: session)
        return nil
    }

    func continueTracking(sessionID: UUID) -> PracticeTrackingStartResult {
        guard let session,
              session.id == sessionID,
              session.phase == .headingToCourse || session.phase == .drivingCourse
        else {
            return .unavailable("이동 중인 연습 기록을 찾지 못했어요.")
        }
        if session.phase == .drivingCourse, didStartSessionInCurrentProcess {
            return .started
        }
        if let prerequisite = locationPrerequisite() { return prerequisite }

        lastInCourseLocation = nil
        activateTracking(for: session)
        return .started
    }

    func cancel() {
        guard let session, !session.phase.isTerminal else { return }
        endActiveSession(session, clearMeasurement: false)
        RodiAnalytics.track(.practiceTrackingCancelled(placeType: session.analyticsPlaceType))
        RodiLogger.info("Practice tracking cancelled")
    }

    /// 로그아웃·회원탈퇴 뒤 이전 계정의 측정 복구 상태가 이어지지 않게 정리한다.
    func endForSessionChange() {
        cancelCertificationRequest()
        stopLocationUpdates()
        endBackgroundActivitySession()
        sessionStore.clear()
        measurementStore?.clear()
        session = nil
        didStartSessionInCurrentProcess = false
        lastInCourseLocation = nil
        cancelLiveActivity()
    }

    private func endActiveSession(
        _ session: PracticeTrackingSession,
        clearMeasurement: Bool
    ) {
        self.session = nil
        sessionStore.clear()
        if clearMeasurement, measurementStore?.load()?.id == session.id {
            measurementStore?.clear()
        }
        cancelLiveActivity()
        stopLocationUpdates()
        endBackgroundActivitySession()
        didStartSessionInCurrentProcess = false
        lastInCourseLocation = nil
        cancelCertificationRequest()
    }

    private func discardRestoredSession(
        _ session: PracticeTrackingSession,
        decision: PracticeTrackingRestorationDecision
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
            applyLocationPolicy(for: session)
            RodiAnalytics.track(.practiceTrackingEnteredCourse(placeType: session.analyticsPlaceType))
            RodiLogger.info(
                "Practice tracking entered course sessionID=\(session.id.uuidString), progress=\(match.progress)"
            )
        }

        if session.isParking {
            session.phase = .completed
            session.courseProgress = 1
            session.completedAt = location.timestamp
            stopLocationUpdates()
            endBackgroundActivitySession()
            didStartSessionInCurrentProcess = false
            finishLiveActivity(session)
            markCertificationPending(for: session)
            self.session = session
            sessionStore.save(session)
            RodiAnalytics.track(.practiceTrackingCompleted(placeType: session.analyticsPlaceType))
            return
        }

        updateDrivingProgress(&session, location: location, timestamp: location.timestamp)

        if session.requiredDrivingDistanceMeters > 0,
           session.drivenRouteDistance >= session.requiredDrivingDistanceMeters {
            session.phase = .completed
            session.completedAt = location.timestamp
            stopLocationUpdates()
            endBackgroundActivitySession()
            didStartSessionInCurrentProcess = false
            finishLiveActivity(session)
            self.session = session
            sessionStore.save(session)
            markCertificationPending(for: session, retryImmediately: false)
            retryCertificationIfNeeded()
            RodiLogger.info(
                "Practice tracking completed sessionID=\(session.id.uuidString), progress=\(session.courseProgress), seconds=\(session.activeDrivingSeconds)"
            )
            RodiAnalytics.track(.practiceTrackingCompleted(placeType: session.analyticsPlaceType))
            return
        }

        self.session = session
        sessionStore.save(session)
        syncLiveActivity(session)
    }

    private func updateDrivingProgress(
        _ session: inout PracticeTrackingSession,
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
        for session: PracticeTrackingSession,
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
        guard let repository = practiceRepository,
              let measurementStore,
              !isCertificationRequestInFlight,
              let measurement = measurementStore.load(),
              measurement.mode == .gpsTracking,
              (measurement.status == .certificationPendingRegistration
                  || measurement.status == .certificationPendingVisit)
        else { return }

        certificationTask?.cancel()
        certificationRequestID += 1
        let requestID = certificationRequestID
        isCertificationRequestInFlight = true
        certificationTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if self.certificationRequestID == requestID {
                    self.isCertificationRequestInFlight = false
                    self.certificationTask = nil
                }
            }
            do {
                var current = measurement
                if current.status == .certificationPendingRegistration {
                    let registration = try await repository.register(placeID: current.placeID)
                    guard !Task.isCancelled, self.certificationRequestID == requestID else { return }
                    current.practiceID = registration.practiceID
                    current.status = .certificationPendingVisit
                    measurementStore.save(current)
                }
                guard let practiceID = current.practiceID else { return }
                _ = try await repository.recordVisit(
                    practiceID: practiceID,
                    certifiedDistanceMeters: current.certifiedDistanceMeters
                )
                guard !Task.isCancelled, self.certificationRequestID == requestID else { return }
                current.status = .certified
                measurementStore.save(current)
                self.certificationRevision += 1
            } catch is CancellationError {
                return
            } catch {
                guard self.certificationRequestID == requestID else { return }
                RodiLogger.warning("Practice certification pending")
            }
        }
    }

    private func cancelCertificationRequest() {
        certificationRequestID += 1
        certificationTask?.cancel()
        certificationTask = nil
        isCertificationRequestInFlight = false
    }

    /// 외부 길안내가 열린 뒤에만 측정 후보를 저장하므로, 도착 지점에서 즉시 종료된 세션도 인증 대기 상태로 전환한다.
    func synchronizeCompletedSessionCertificationIfNeeded() {
        guard let session, session.phase == .completed else { return }
        if session.isParking {
            markCertificationPending(for: session)
        } else {
            markCertificationPending(for: session, retryImmediately: false)
            retryCertificationIfNeeded()
        }
    }

    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
    }

    private func locationPrerequisite() -> PracticeTrackingStartResult? {
        guard CLLocationManager.locationServicesEnabled() else {
            return .unavailable("위치 서비스를 켠 뒤 연습 기록을 시작해주세요.")
        }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return .authorizationRequested
        case .authorizedWhenInUse, .authorizedAlways:
            break
        case .denied, .restricted:
            return .unavailable("위치 권한이 없어 이번 길안내에는 연습 기록이 포함되지 않아요.")
        @unknown default:
            return .unavailable("위치 권한 상태를 확인하지 못해 이번 길안내에는 연습 기록이 포함되지 않아요.")
        }

        guard locationManager.accuracyAuthorization == .fullAccuracy else {
            locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "PracticeTracking")
            return .reducedAccuracyRequested
        }
        return nil
    }

    private func activateTracking(for session: PracticeTrackingSession) {
        didStartSessionInCurrentProcess = true
        beginBackgroundActivitySession()
        applyLocationPolicy(for: session)
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        startLiveActivity(for: session)
        syncLiveActivity(session, force: true)
    }

    private func applyLocationPolicy(for session: PracticeTrackingSession) {
        if session.phase == .drivingCourse, !session.isParking {
            locationManager.desiredAccuracy = Policy.drivingDesiredAccuracy
            locationManager.distanceFilter = Policy.drivingDistanceFilter
            return
        }

        locationManager.desiredAccuracy = Policy.approachDesiredAccuracy
        locationManager.distanceFilter = Policy.approachDistanceFilter
    }

    private func beginBackgroundActivitySession() {
        guard #available(iOS 17.0, *), backgroundActivitySession == nil else { return }
        backgroundActivitySession = CLBackgroundActivitySession()
    }

    private func endBackgroundActivitySession() {
        guard #available(iOS 17.0, *),
              let session = backgroundActivitySession as? CLBackgroundActivitySession
        else {
            backgroundActivitySession = nil
            return
        }

        session.invalidate()
        backgroundActivitySession = nil
    }

    private func startLiveActivity(for session: PracticeTrackingSession) {
        guard #available(iOS 16.1, *) else { return }
        PracticeLiveActivityService.shared.start(for: session)
    }

    private func syncLiveActivity(_ session: PracticeTrackingSession, force: Bool = false) {
        guard #available(iOS 16.1, *) else { return }
        PracticeLiveActivityService.shared.sync(session, force: force)
    }

    private func finishLiveActivity(_ session: PracticeTrackingSession) {
        guard #available(iOS 16.1, *) else { return }
        PracticeLiveActivityService.shared.finish(session)
    }

    private func cancelLiveActivity() {
        guard #available(iOS 16.1, *) else { return }
        PracticeLiveActivityService.shared.cancel()
    }
}

private extension PracticeTrackingSession {
    var analyticsPlaceType: String {
        placeType?.rawValue ?? "unknown"
    }
}

extension PracticeTrackingService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            receive(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            RodiLogger.warning("Practice tracking location failed: \(error.localizedDescription)")
        }
    }
}
