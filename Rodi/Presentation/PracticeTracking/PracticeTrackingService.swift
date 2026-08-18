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
    private var measurementStore: PracticeMeasurementStoring = PracticeMeasurementStore()
    private var practiceRepository: PracticeRepository?
    private var lastInCourseLocation: CLLocation?
    private var isCertificationRequestInFlight = false
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

    func start(
        course: RodiCourseItem,
        routePath: [RodiCoordinate],
        rabbitAssetName: String = "img_rabbit_navigation"
    ) -> PracticeTrackingStartResult {
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
        didStartSessionInCurrentProcess = true
        lastInCourseLocation = nil
        beginBackgroundActivitySession()
        applyLocationPolicy(for: session)
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        startLiveActivity(for: session)
        syncLiveActivity(session, force: true)
        RodiAnalytics.track(.practiceTrackingStarted(placeType: session.analyticsPlaceType))
        RodiLogger.info("Practice tracking started sessionID=\(session.id.uuidString), courseID=\(course.id)")
        return .started
    }

    func restoreIfNeeded() {
        guard var session, !session.phase.isTerminal else { return }
        guard didStartSessionInCurrentProcess else {
            session.phase = .interrupted
            self.session = session
            sessionStore.save(session)
            measurementStore.clear()
            cancelLiveActivity()
            RodiLogger.info("Practice tracking interrupted after process restart sessionID=\(session.id.uuidString)")
            return
        }

        guard locationManager.authorizationStatus == .authorizedWhenInUse
                || locationManager.authorizationStatus == .authorizedAlways
        else { return }

        beginBackgroundActivitySession()
        applyLocationPolicy(for: session)
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        startLiveActivity(for: session)
        syncLiveActivity(session, force: true)
        RodiLogger.info("Practice tracking restored sessionID=\(session.id.uuidString)")
    }

    func cancel() {
        guard var session, !session.phase.isTerminal else { return }
        session.phase = .cancelled
        self.session = session
        sessionStore.save(session)
        cancelLiveActivity()
        stopLocationUpdates()
        endBackgroundActivitySession()
        didStartSessionInCurrentProcess = false
        lastInCourseLocation = nil
        RodiAnalytics.track(.practiceTrackingCancelled(placeType: session.analyticsPlaceType))
        RodiLogger.info("Practice tracking cancelled sessionID=\(session.id.uuidString)")
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
            markCertificationPending(for: session)
            RodiLogger.info(
                "Practice tracking completed sessionID=\(session.id.uuidString), progress=\(session.courseProgress), seconds=\(session.activeDrivingSeconds)"
            )
            RodiAnalytics.track(.practiceTrackingCompleted(placeType: session.analyticsPlaceType))
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

    private func markCertificationPending(for session: PracticeTrackingSession) {
        guard var measurement = measurementStore.load(), measurement.id == session.id else { return }
        measurement.status = .certificationPendingRegistration
        measurement.certifiedDistanceMeters = session.isParking
            ? nil
            : Int(session.drivenRouteDistance.rounded())
        measurementStore.save(measurement)
        retryCertificationIfNeeded()
    }

    func retryCertificationIfNeeded() {
        guard let repository = practiceRepository,
              !isCertificationRequestInFlight,
              let measurement = measurementStore.load(),
              measurement.mode == .gpsTracking,
              (measurement.status == .certificationPendingRegistration
                  || measurement.status == .certificationPendingVisit)
        else { return }

        isCertificationRequestInFlight = true
        Task { [weak self] in
            guard let self else { return }
            defer { self.isCertificationRequestInFlight = false }
            do {
                var current = measurement
                if current.status == .certificationPendingRegistration {
                    let registration = try await repository.register(placeID: current.placeID)
                    current.practiceID = registration.practiceID
                    current.status = .certificationPendingVisit
                    self.measurementStore.save(current)
                }
                guard let practiceID = current.practiceID else { return }
                _ = try await repository.recordVisit(
                    practiceID: practiceID,
                    certifiedDistanceMeters: current.certifiedDistanceMeters
                )
                current.status = .certified
                self.measurementStore.save(current)
                self.certificationRevision += 1
            } catch {
                RodiLogger.warning("Practice certification pending: \(error.localizedDescription)")
            }
        }
    }

    /// 외부 길안내가 열린 뒤에만 측정 후보를 저장하므로, 도착 지점에서 즉시 종료된 세션도 인증 대기 상태로 전환한다.
    func synchronizeCompletedSessionCertificationIfNeeded() {
        guard let session, session.phase == .completed else { return }
        markCertificationPending(for: session)
    }

    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
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
